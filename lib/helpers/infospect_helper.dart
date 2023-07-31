import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:collection/collection.dart';
import 'package:desktop_multi_window/desktop_multi_window.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
// ignore: depend_on_referenced_packages
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:http/http.dart';
import 'package:infospect/logger/infospect_logger.dart';
import 'package:infospect/logger/models/infospect_log.dart';
import 'package:infospect/network/interceptors/infospect_dio_interceptor.dart';
import 'package:infospect/network/interceptors/infospect_http_client_interceptor.dart';
import 'package:infospect/network/models/infospect_network_call.dart';
import 'package:infospect/network/models/infospect_network_error.dart';
import 'package:infospect/network/models/infospect_network_response.dart';
import 'package:infospect/ui/interceptor/bloc/bloc/interceptor_bloc.dart';
import 'package:infospect/ui/interceptor/screen/infospect_interceptor_screen.dart';
import 'package:infospect/utils/infospect_util.dart';
import 'package:rxdart/rxdart.dart';

class Infospect {
  final int maxCallsCount;

  final GlobalKey<NavigatorState>? _navigatorKey;

  ValueNotifier<bool> isInspectorOpened = ValueNotifier(false);

  final BehaviorSubject<List<InfospectNetworkCall>> callsSubject =
      BehaviorSubject.seeded([]);

  StreamSubscription? _callsSubscription;

  final InfospectLogger infospectLogger = InfospectLogger();

  Infospect({
    this.maxCallsCount = 1000,
    GlobalKey<NavigatorState>? navigatorKey,
  }) : _navigatorKey = navigatorKey ?? GlobalKey<NavigatorState>() {
    _callsSubscription =
        callsSubject.interval(const Duration(milliseconds: 500)).listen(
              (_) => _onCallsChanged(),
            );
  }

  void _onCallsChanged() async {
    // if (callsSubject.value.isNotEmpty) {
    //   _onCallsChanged();
    // }
  }

  GlobalKey<NavigatorState>? get getNavigatorKey => _navigatorKey;

  Brightness get brightness => PlatformDispatcher.instance.platformBrightness;

  BuildContext? get context => _navigatorKey?.currentState?.overlay?.context;

  /// This will open inspector in new window. This will work only on desktop
  Future<void> openInspectorInNewWindow() async {
    if (!kIsWeb && Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      // widget._devOptions.getInterceptorDialog(context);
      final window = await DesktopMultiWindow.createWindow(jsonEncode({
        'args1': 'Sub window',
        'args2': 100,
        'args3': true,
        'business': 'business_test',
      }));
      window
        ..setFrame(const Offset(0, 0) & const Size(1280, 720))
        ..center()
        ..setTitle('Dev options');

      window.show().then((value) {
        this
          ..sendNetworkCalls()
          ..sendLogs();
      });
    }
  }

  MaterialPageRoute get interceptorScreen => MaterialPageRoute<dynamic>(
        builder: (context) => BlocProvider(
          create: (context) => InterceptorBloc(
            infospect: this,
            infospectLogger: infospectLogger,
          ),
          child: const InfospectInterceptorScreen(),
        ),
      );

  Widget openInterceptor() =>
      Navigator(onGenerateRoute: (settings) => interceptorScreen);

  void navigateToInterceptor() {
    if (context == null) {
      InfospectUtil.log(
        "Cant start HTTP Inspector. Please add NavigatorKey to your application",
      );
      return;
    }
    if (!isInspectorOpened.value) {
      isInspectorOpened.value = true;
      Navigator.push<void>(context!, interceptorScreen).then(
        (onValue) => isInspectorOpened.value = false,
      );
    }
  }

  Future<void> _sendDataToSubWindow({required Map<String, List> data}) async {
    if (Platform.isAndroid || Platform.isIOS) return;
    List<int> subWindowIds = await DesktopMultiWindow.getAllSubWindowIds();

    /// Return if there's no sub windows
    if (subWindowIds.isEmpty) return;

    for (final windowId in subWindowIds) {
      DesktopMultiWindow.invokeMethod(windowId, 'broadcast', data);
    }
  }

  void sendNetworkCalls() {
    final List data = (callsSubject.value)
        .map<Map<String, dynamic>>((e) => e.toMap())
        .toList();

    _sendDataToSubWindow(data: {'network': data});
  }

  void addCall(InfospectNetworkCall call) {
    final callsCount = callsSubject.value.length;
    if (callsCount >= maxCallsCount) {
      final originalCalls = callsSubject.value;
      final calls = List<InfospectNetworkCall>.from(originalCalls);
      calls.sort(
        (call1, call2) => call1.createdTime.compareTo(call2.createdTime),
      );
      final indexToReplace = originalCalls.indexOf(calls.first);
      originalCalls[indexToReplace] = call;

      callsSubject.add(originalCalls);
    } else {
      callsSubject.add([...callsSubject.value, call]);
    }
    sendNetworkCalls();
  }

  void addError(InfospectNetworkError error, int requestId) {
    final InfospectNetworkCall? selectedCall = _selectCall(requestId);

    if (selectedCall == null) {
      InfospectUtil.log("Selected call is null");
      return;
    }

    selectedCall.error = error;
    callsSubject.add([...callsSubject.value]);
    sendNetworkCalls();
  }

  void addResponse(InfospectNetworkResponse response, int requestId) {
    final InfospectNetworkCall? selectedCall = _selectCall(requestId);

    if (selectedCall == null) {
      InfospectUtil.log("Selected call is null");
      return;
    }
    selectedCall.loading = false;
    selectedCall.response = response;
    selectedCall.duration = response.time.millisecondsSinceEpoch -
        (selectedCall.request!.time).millisecondsSinceEpoch;

    callsSubject.add([...callsSubject.value]);
    sendNetworkCalls();
  }

  void addHttpCall(InfospectNetworkCall httpCall) {
    assert(httpCall.request != null, "Http call request can't be null");
    assert(httpCall.response != null, "Http call response can't be null");
    callsSubject.add([...callsSubject.value, httpCall]);
    sendNetworkCalls();
  }

  void removeCalls() {
    callsSubject.add([]);
    sendNetworkCalls();
  }

  InfospectNetworkCall? _selectCall(int requestId) =>
      callsSubject.value.firstWhereOrNull((call) => call.id == requestId);

  void addLog(InfospectLog log) {
    infospectLogger.logs.add(log);
    sendLogs();
  }

  void addLogs(List<InfospectLog> logs) {
    infospectLogger.logs.addAll(logs);
    sendLogs();
  }

  void sendLogs() {
    _sendDataToSubWindow(data: infospectLogger.logsMap);
  }

  void run(List<String> args, {required Widget myApp}) {
    if (args.firstOrNull == 'multi_window') {
      runApp(
        MaterialApp(
          debugShowCheckedModeBanner: false,
          localizationsDelegates: const <LocalizationsDelegate<Object>>[
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
          ],
          supportedLocales: const <Locale>[
            Locale('en', 'US'), // English
          ],
          home: openInterceptor(),
        ),
      );
    } else {
      runApp(myApp);
    }
  }

  InfospectDioInterceptor get dioInterceptor => InfospectDioInterceptor(this);

  InfospectHttpClientInterceptor httpClientInterceptor(
          {required Client client}) =>
      InfospectHttpClientInterceptor(client: client, infospect: this);

  /// Dispose subjects and subscriptions
  void dispose() {
    callsSubject.close();
    isInspectorOpened.dispose();
    _callsSubscription?.cancel();
  }
}
