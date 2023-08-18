import 'dart:async';
import 'dart:convert';
import 'dart:io';

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

part 'log_helper.dart';
part 'multi_window_helper.dart';
part 'navigation_helper.dart';
part 'network_call_helper.dart';

class Infospect {
  Infospect._({
    this.maxCallsCount = 1000,
    GlobalKey<NavigatorState>? navigatorKey,
    bool logAppLaunch = true,
  })  : _navigatorKey = navigatorKey ?? GlobalKey<NavigatorState>(),
        infospectLogger = InfospectLogger() {
    _instance = this;
    _infospectLogHelper = InfospectLogHelper._(this);
    _infospectNavigationHelper = InfospectNavigationHelper._(this);
    _infospectNetworkCallHelper = InfospectNetworkCallHelper._(this);
    _infospectMultiWindowHelper = InfospectMultiWindowHelper._(this);

    if (logAppLaunch) {
      InfospectUtil.addAppLaunchLog();
    }
  }
  static Infospect get instance => checkInstance(_instance);
  static Infospect? _instance;

  final int maxCallsCount;
  final GlobalKey<NavigatorState>? _navigatorKey;
  late InfospectLogHelper _infospectLogHelper;
  late InfospectNavigationHelper _infospectNavigationHelper;
  late InfospectNetworkCallHelper _infospectNetworkCallHelper;
  late InfospectMultiWindowHelper _infospectMultiWindowHelper;

  ValueNotifier<bool> isInfospectOpened = ValueNotifier(false);

  final BehaviorSubject<List<InfospectNetworkCall>> networkCallsSubject =
      BehaviorSubject.seeded([]);

  final InfospectLogger infospectLogger;

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

  /// get the navigator key
  GlobalKey<NavigatorState>? get getNavigatorKey => _navigatorKey;

  Brightness get brightness => PlatformDispatcher.instance.platformBrightness;

  BuildContext? get context => _navigatorKey?.currentState?.overlay?.context;

  /// run app
  void run(List<String> args, {required Widget myApp}) =>
      _infospectNavigationHelper.run(args, myApp: myApp);

  /// Logs
  void addLog(InfospectLog log) => _infospectLogHelper.addLog(log);

  void addLogs(List<InfospectLog> logs) => _infospectLogHelper.addLogs(logs);

  /// Navigation
  Future<void> openInspectorInNewWindow() =>
      _infospectNavigationHelper.openInspectorInNewWindow();

  MaterialPageRoute _interceptorScreen() =>
      _infospectNavigationHelper.interceptorScreen();

  Widget openInterceptor() =>
      Navigator(onGenerateRoute: (settings) => _interceptorScreen());

  void navigateToInterceptor() =>
      _infospectNavigationHelper.navigateToInterceptor();

  /// multi window
  void sendNetworkCalls() => _infospectMultiWindowHelper.sendNetworkCalls();

  void sendLogs([List<InfospectLog>? logs]) =>
      _infospectMultiWindowHelper.sendLogs(logs);

  /// Network calls
  void addCall(InfospectNetworkCall call) =>
      _infospectNetworkCallHelper.addCall(call);

  void addError(InfospectNetworkError error, int requestId) =>
      _infospectNetworkCallHelper.addError(error, requestId);

  void addResponse(InfospectNetworkResponse response, int requestId) =>
      _infospectNetworkCallHelper.addResponse(response, requestId);

  void addHttpCall(InfospectNetworkCall httpCall) =>
      _infospectNetworkCallHelper.addHttpCall(httpCall);

  void removeCalls() => _infospectNetworkCallHelper.removeCalls();

  /// interceptors
  InfospectDioInterceptor get dioInterceptor =>
      _infospectNetworkCallHelper.dioInterceptor;

  InfospectHttpClientInterceptor httpClientInterceptor(
          {required Client client}) =>
      _infospectNetworkCallHelper.httpClientInterceptor(client: client);

  /// Dispose subjects and subscriptions
  void dispose() {
    networkCallsSubject.close();
    isInfospectOpened.dispose();
  }
}
