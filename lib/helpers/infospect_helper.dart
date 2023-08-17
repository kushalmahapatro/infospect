import 'dart:async';
import 'dart:io';

import 'package:collection/collection.dart';
import 'package:desktop_multi_window/desktop_multi_window.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart';
import 'package:infospect/features/launch/bloc/launch_bloc.dart';
import 'package:infospect/features/logger/infospect_logger.dart';
import 'package:infospect/features/logger/models/infospect_log.dart';
import 'package:infospect/features/logger/ui/logs_list/bloc/logs_list_bloc.dart';
import 'package:infospect/features/network/interceptors/infospect_dio_interceptor.dart';
import 'package:infospect/features/network/interceptors/infospect_http_client_interceptor.dart';
import 'package:infospect/features/network/models/infospect_network_call.dart';
import 'package:infospect/features/network/models/infospect_network_error.dart';
import 'package:infospect/features/network/models/infospect_network_response.dart';
import 'package:infospect/features/network/ui/list/bloc/networks_list_bloc.dart';
import 'package:infospect/helpers/model_theme.dart';
import 'package:infospect/routes/routes.dart';
import 'package:infospect/utils/infospect_util.dart';
// ignore: depend_on_referenced_packages
import 'package:provider/provider.dart';
import 'package:rxdart/rxdart.dart';

class Infospect {
  Infospect._({
    this.maxCallsCount = 1000,
    GlobalKey<NavigatorState>? navigatorKey,
  }) : _navigatorKey = navigatorKey ?? GlobalKey<NavigatorState>() {
    _instance = this;
  }

  static Infospect get instance => checkInstance(_instance);
  static Infospect? _instance;

  final int maxCallsCount;
  final GlobalKey<NavigatorState>? _navigatorKey;

  ValueNotifier<bool> isInspectorOpened = ValueNotifier(false);

  final BehaviorSubject<List<InfospectNetworkCall>> callsSubject =
      BehaviorSubject.seeded([]);

  final InfospectLogger infospectLogger = InfospectLogger();

  GlobalKey<NavigatorState>? get getNavigatorKey => _navigatorKey;

  Brightness get brightness => PlatformDispatcher.instance.platformBrightness;

  BuildContext? get context => _navigatorKey?.currentState?.overlay?.context;

  /// This will open inspector in new window. This will work only on desktop
  Future<void> openInspectorInNewWindow() async {
    if (!kIsWeb && Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      final window = await DesktopMultiWindow.createWindow();
      window
        ..setFrame(const Offset(0, 0) & const Size(1280, 720))
        ..center()
        ..setTitle('Infospect');

      window.show().then((value) {
        this
          ..sendNetworkCalls()
          ..sendLogs();
      });
    }
  }

  MaterialPageRoute interceptorScreen() => MaterialPageRoute<dynamic>(
        builder: (context) => MultiBlocProvider(
          providers: [
            BlocProvider(
              create: (_) => LaunchBloc(),
            ),
            BlocProvider(
              create: (_) => NetworksListBloc(
                infospect: this,
              ),
            ),
            BlocProvider(
              create: (_) => LogsListBloc(
                infospectLogger: infospectLogger,
              ),
            ),
          ],
          child: mobileRoutes.launch(this),
        ),
      );

  Widget openInterceptor() =>
      Navigator(onGenerateRoute: (settings) => interceptorScreen());

  void navigateToInterceptor() {
    if (context == null) {
      InfospectUtil.log(
        "Cant start HTTP Inspector. Please add NavigatorKey to your application",
      );
      return;
    }
    if (!isInspectorOpened.value) {
      isInspectorOpened.value = true;
      Navigator.push<void>(
        context!,
        interceptorScreen(),
      ).then(
        (onValue) => isInspectorOpened.value = false,
      );
    }
  }

  Future<void> _sendDataToSubWindow({required Map<String, List> data}) async {
    if (Platform.isAndroid || Platform.isIOS) return;
    List<int> subWindowIds = [];

    try {
      subWindowIds = await DesktopMultiWindow.getAllSubWindowIds();
    } catch (_) {}

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
    final int index = _selectCall(requestId);

    if (index == -1) {
      InfospectUtil.log("Selected call is null");
      return;
    }

    final InfospectNetworkCall selectedCall = callsSubject.value[index];
    callsSubject.value[index] =
        selectedCall.copyWith(error: error, loading: false);
    callsSubject.add([...callsSubject.value]);
    sendNetworkCalls();
  }

  void addResponse(InfospectNetworkResponse response, int requestId) {
    final int index = _selectCall(requestId);

    if (index == -1) {
      InfospectUtil.log("Selected call is null");
      return;
    }

    final InfospectNetworkCall selectedCall = callsSubject.value[index];

    callsSubject.value[index] = selectedCall.copyWith(
      loading: false,
      response: response,
      duration: response.time.millisecondsSinceEpoch -
          (selectedCall.request!.time).millisecondsSinceEpoch,
    );

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

  int _selectCall(int requestId) =>
      callsSubject.value.indexWhere((call) => call.id == requestId);

  void addLog(InfospectLog log) {
    // if (Platform.isAndroid || Platform.isIOS) {
    infospectLogger.add(log);
    // }
    sendLogs([log]);
  }

  void addLogs(List<InfospectLog> logs) {
    if (Platform.isAndroid || Platform.isIOS) {
      infospectLogger.logs.addAll(logs);
    }
    sendLogs(logs);
  }

  void sendLogs([List<InfospectLog>? logs]) {
    if (logs == null) {
      _sendDataToSubWindow(data: infospectLogger.logsMap);
    } else {
      _sendDataToSubWindow(data: {
        'logs': logs.map<Map<String, dynamic>>((e) => e.toMap()).toList()
      });
    }
  }

  void run(List<String> args, {required Widget myApp}) {
    if (args.firstOrNull == 'multi_window') {
      runApp(
        ChangeNotifierProvider(
          create: (_) => ModelTheme(),
          builder: (context, child) => child ?? const SizedBox.shrink(),
          child: Consumer<ModelTheme>(
            builder: (context, ModelTheme themeNotifier, child) {
              return MaterialApp(
                debugShowCheckedModeBanner: false,
                localizationsDelegates: const <LocalizationsDelegate<Object>>[],
                supportedLocales: const <Locale>[
                  Locale('en', 'US'), // English
                ],
                theme: themeNotifier.isDark
                    ? ThemeData.dark(useMaterial3: true)
                    : ThemeData(useMaterial3: true),
                home: openInterceptor(),
              );
            },
          ),
        ),
      );
    } else {
      runApp(
        ChangeNotifierProvider(
            create: (_) => ModelTheme(),
            builder: (context, child) => child ?? const SizedBox.shrink(),
            child: myApp),
      );
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
  }

  static Infospect ensureInitialized(
      {int maxCallsCount = 1000, GlobalKey<NavigatorState>? navigatorKey}) {
    if (Infospect._instance == null) {
      Infospect._(
        maxCallsCount: maxCallsCount,
        navigatorKey: navigatorKey,
      );
    }
    return Infospect.instance;
  }

  static checkInstance(Infospect? instance) {
    if (instance == null) {
      throw FlutterError.fromParts(<DiagnosticsNode>[
        ErrorSummary('Infospect is not yet initialized'),
        ErrorDescription(
            'This probably indicates that Infospect.instance was used but was not initialized'),
        ErrorHint('To fix this use Infospect.ensureInitialized() at the main'),
      ]);
    }

    return instance;
  }
}
