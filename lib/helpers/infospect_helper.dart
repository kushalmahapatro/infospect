import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:desktop_multi_window/desktop_multi_window.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart';
import 'package:infospect/features/launch/bloc/launch_bloc.dart';
import 'package:infospect/features/logger/infospect_logger.dart';
import 'package:infospect/features/logger/ui/logs_list/bloc/logs_list_bloc.dart';
import 'package:infospect/features/network/interceptors/infospect_dio_interceptor.dart';
import 'package:infospect/features/network/interceptors/infospect_http_client_interceptor.dart';
import 'package:infospect/features/network/models/infospect_network_call.dart';
import 'package:infospect/features/network/models/infospect_network_error.dart';
import 'package:infospect/features/network/models/infospect_network_response.dart';
import 'package:infospect/features/network/ui/list/bloc/networks_list_bloc.dart';
import 'package:infospect/helpers/desktop_theme_cubit/desktop_theme_cubit.dart';
import 'package:infospect/infospect.dart';
import 'package:infospect/routes/routes.dart';
import 'package:infospect/utils/infospect_util.dart';
import 'package:rxdart/rxdart.dart';
import 'package:share_plus/share_plus.dart';

part 'log_helper.dart';
part 'multi_window_helper.dart';
part 'navigation_helper.dart';
part 'network_call_helper.dart';

/// `Infospect` is a utility class designed to facilitate monitoring and debugging activities,
/// such as logging network calls, navigating within the app, managing multi-window actions,
/// and handling application logs.
class Infospect {
  /// The private constructor for the `Infospect` class.
  ///
  /// - `maxCallsCount`: The maximum number of network calls to retain. Defaults to 1000.
  /// - `navigatorKey`: Optional key for the navigator.
  /// - `logAppLaunch`: Flag to determine if app launch should be logged.
  /// - `onShareAllNetworkCalls`: Callback triggered to share all network calls.
  /// - `onShareAllLogs`: Callback triggered to share all logs.
  Infospect._({
    this.maxCallsCount = 1000,
    GlobalKey<NavigatorState>? navigatorKey,
    bool logAppLaunch = false,
    this.onShareAllNetworkCalls,
    this.onShareAllLogs,
  })  : _navigatorKey = navigatorKey ?? GlobalKey<NavigatorState>(),
        infospectLogger = InfospectLogger() {
    _instance = this;
    _infospectLogHelper = InfospectLogHelper._(this);
    _infospectNavigationHelper = InfospectNavigationHelper._(this);
    _infospectNetworkCallHelper = InfospectNetworkCallHelper._(this);
    _infospectMultiWindowHelper = InfospectMultiWindowHelper._(this);

    _logAppLaunch(logAppLaunch);
  }

  Future<void> _logAppLaunch(bool logAppLaunch) async {
    if (logAppLaunch && await _runAppCompleter.future) {
      InfospectUtil.addAppLaunchLog();
    }
  }

  static Infospect get instance => checkInstance(_instance);
  static Infospect? _instance;

  /// parameters
  final int maxCallsCount;
  final void Function(String path)? onShareAllNetworkCalls;
  final void Function(String path)? onShareAllLogs;
  final GlobalKey<NavigatorState>? _navigatorKey;

  /// helpers
  late InfospectLogHelper _infospectLogHelper;
  late InfospectNavigationHelper _infospectNavigationHelper;
  late InfospectNetworkCallHelper _infospectNetworkCallHelper;
  late InfospectMultiWindowHelper _infospectMultiWindowHelper;

  /// completer
  late final Completer<bool> _runAppCompleter = Completer<bool>();

  ValueNotifier<bool> isInfospectOpened = ValueNotifier(false);

  final BehaviorSubject<List<InfospectNetworkCall>> networkCallsSubject =
      BehaviorSubject.seeded([]);

  final InfospectLogger infospectLogger;

  /// Ensures the `Infospect` instance is initialized.
  /// If it's not initialized, it will initialize it with the provided arguments.
  ///
  /// Returns the initialized instance of `Infospect`.
  static Infospect ensureInitialized({
    int maxCallsCount = 1000,
    GlobalKey<NavigatorState>? navigatorKey,
    bool logAppLaunch = false,
    void Function(String path)? onShareAllNetworkCalls,
    void Function(String path)? onShareAllLogs,
  }) {
    if (Infospect._instance == null) {
      Infospect._(
        maxCallsCount: maxCallsCount,
        navigatorKey: navigatorKey,
        logAppLaunch: logAppLaunch,
        onShareAllLogs: onShareAllLogs,
        onShareAllNetworkCalls: onShareAllNetworkCalls,
      );
    }
    return Infospect.instance;
  }

  /// Checks if the `Infospect` instance is initialized and throws an error
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

  /// Logs an instance of `InfospectLog`.
  void addLog(InfospectLog log) => _infospectLogHelper.addLog(log);

  void addLogs(List<InfospectLog> logs) => _infospectLogHelper.addLogs(logs);

  void clearAllLogs() => _infospectLogHelper.clearAllLogs();

  /// Navigates to the interceptor.
  Future<void> openInspectorInNewWindow() =>
      _infospectNavigationHelper.openInspectorInNewWindow();

  void navigateToInterceptor() =>
      _infospectNavigationHelper.navigateToInterceptor();

  /// multi window
  void sendNetworkCalls() => _infospectMultiWindowHelper.sendNetworkCalls();

  void sendLogs([List<InfospectLog>? logs]) =>
      _infospectMultiWindowHelper.sendLogs(logs);

  void sendThemeMode({required bool isDarkTheme}) =>
      _infospectMultiWindowHelper.sendThemeMode(isDarkTheme);

  void handleMultiWindowReceivedData(BuildContext context) =>
      _infospectMultiWindowHelper.handleMultiWindowReceivedData(context);

  void handleMainWindowReceiveData() =>
      _infospectMultiWindowHelper.handleMainWindowReceiveData();

  /// Network calls
  void addCall(InfospectNetworkCall call) =>
      _infospectNetworkCallHelper.addCall(call);

  void addError(InfospectNetworkError error, int requestId) =>
      _infospectNetworkCallHelper.addError(error, requestId);

  void addResponse(InfospectNetworkResponse response, int requestId) =>
      _infospectNetworkCallHelper.addResponse(response, requestId);

  void addHttpCall(InfospectNetworkCall httpCall) =>
      _infospectNetworkCallHelper.addHttpCall(httpCall);

  void clearAllNetworkCalls() =>
      _infospectNetworkCallHelper.clearAllNetworkCalls();

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
