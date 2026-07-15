import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:infospect/features/launch/notifier/launch_notifier.dart';
import 'package:infospect/features/logger/infospect_logger.dart';
import 'package:infospect/features/launch/screen/infospect_launch_screen.dart';
import 'package:infospect/features/logger/ui/logs_list/notifier/logs_list_notifier.dart';
import 'package:infospect/features/logger/ui/logs_list/screen/desktop_logs_list_screen.dart';
import 'package:infospect/features/network/breakpoints/infospect_breakpoint_manager.dart';
import 'package:infospect/features/network/breakpoints/infospect_breakpoint_presenter.dart';
import 'package:infospect/features/network/interceptors/infospect_dio_interceptor.dart';
import 'package:infospect/features/network/interceptors/infospect_http_client_interceptor.dart';
import 'package:infospect/features/network/models/infospect_network_call.dart';
import 'package:infospect/features/network/models/infospect_network_error.dart';
import 'package:infospect/features/network/models/infospect_network_request.dart';
import 'package:infospect/features/network/models/infospect_network_response.dart';
import 'package:infospect/features/network/ui/details/screen/network_body_window_screen.dart';
import 'package:infospect/features/network/ui/list/notifier/networks_list_notifier.dart';
import 'package:infospect/features/network/ui/list/screen/desktop_networks_list_screen.dart';
import 'package:infospect/infospect.dart';
import 'package:infospect/routes/routes.dart';
import 'package:infospect/utils/data_transfer.dart';
import 'package:infospect/utils/infospect_desktop_window.dart';
import 'package:infospect/utils/infospect_multiview_bootstrap.dart'
    as package_bootstrap;
import 'package:infospect/utils/infospect_util.dart';
import 'package:multiview_desktop/multiview_desktop.dart';
import 'package:rxdart/rxdart.dart';

part 'log_helper.dart';
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
  }) : _navigatorKey = navigatorKey ?? GlobalKey<NavigatorState>(),
       infospectLogger = InfospectLogger(),
       breakpointManager = InfospectBreakpointManager() {
    _instance = this;
    _infospectLogHelper = InfospectLogHelper._(this);
    _infospectNavigationHelper = InfospectNavigationHelper._(this);
    _infospectNetworkCallHelper = InfospectNetworkCallHelper._(this);
    _breakpointPresenter = InfospectBreakpointPresenter(this);

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
  late InfospectBreakpointPresenter _breakpointPresenter;

  /// completer
  late final Completer<bool> _runAppCompleter = Completer<bool>();

  ValueNotifier<bool> isInfospectOpened = ValueNotifier(false);

  final BehaviorSubject<List<InfospectNetworkCall>> networkCallsSubject =
      BehaviorSubject.seeded([]);

  final InfospectLogger infospectLogger;

  /// Proxyman-style endpoint breakpoints (request / response editing).
  final InfospectBreakpointManager breakpointManager;

  /// When true, breakpoint editors always use in-app dialogs instead of
  /// desktop secondary windows. Useful for widget / integration tests.
  bool preferInAppBreakpointDialogs = false;

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
  static Infospect checkInstance(Infospect? instance) {
    if (instance == null) {
      throw FlutterError.fromParts(<DiagnosticsNode>[
        ErrorSummary('Infospect is not yet initialized'),
        ErrorDescription(
          'This probably indicates that Infospect.instance was used but was not initialized',
        ),
        ErrorHint('To fix this use Infospect.ensureInitialized() at the main'),
      ]);
    }

    return instance;
  }

  /// get the navigator key
  GlobalKey<NavigatorState>? get getNavigatorKey => _navigatorKey;

  Brightness get brightness => PlatformDispatcher.instance.platformBrightness;

  BuildContext? get context => _navigatorKey?.currentState?.overlay?.context;

  /// get the launch screen widget
  Widget infospectLaunchScreen({
    required NetworksListNotifier networksListNotifier,
    required LogsListNotifier logsListNotifier,
  }) {
    return InfospectLaunchScreen(
      this,
      networksListNotifier: networksListNotifier,
      logsListNotifier: logsListNotifier,
    );
  }

  /// Boots [myApp] via [bootstrapMultiViewApp] (Multiview on desktop, [runApp]
  /// elsewhere). Prefer this or [Infospect.bootstrapMultiViewApp] over plain
  /// [runApp] whenever Multiview native runners are wired.
  ///
  /// - `args`: Kept for API compatibility; unused with multiview_desktop
  ///   (secondary windows share one isolate — no `multi_window` CLI args).
  /// - `myApp`: The main widget to run for the app.
  void run(List<String> args, {required Widget myApp}) =>
      _infospectNavigationHelper.run(args, myApp: myApp);

  /// Desktop-safe entry that does **not** require [ensureInitialized].
  ///
  /// Use when Multiview natives are installed but Infospect logging may be
  /// disabled (e.g. production builds that skip inspector init).
  static void bootstrapMultiViewApp(
    Widget app, {
    MultiAppConfig? config,
  }) {
    package_bootstrap.bootstrapMultiViewApp(app, config: config);
  }

  /// Alias for [bootstrapMultiViewApp].
  static void bootstrapDesktopApp(
    Widget app, {
    MultiAppConfig? config,
  }) {
    Infospect.bootstrapMultiViewApp(app, config: config);
  }

  /// Whether desktop entry must use Multiview ([runMultiApp]) instead of
  /// [runApp]. See [isMultiViewDesktopBootstrapRequired].
  static bool get requiresMultiViewDesktopBootstrap =>
      package_bootstrap.isMultiViewDesktopBootstrapRequired();

  /// Logs an instance of `InfospectLog`.
  void addLog(InfospectLog log) => _infospectLogHelper.addLog(log);

  void addLogs(List<InfospectLog> logs) => _infospectLogHelper.addLogs(logs);

  void clearAllLogs() => _infospectLogHelper.clearAllLogs();

  /// Navigates to the interceptor.
  Future<void> openInspectorInNewWindow() =>
      _infospectNavigationHelper.openInspectorInNewWindow();

  /// Opens a network call body with request metadata in a new desktop window.
  Future<void> openNetworkBodyInNewWindow({
    required InfospectNetworkCall call,
    required NetworkBodyKind kind,
    bool detailsInitiallyExpanded = false,
  }) =>
      _infospectNavigationHelper.openNetworkBodyInNewWindow(
        call: call,
        kind: kind,
        detailsInitiallyExpanded: detailsInitiallyExpanded,
      );

  /// Opens JSON / raw data (e.g. headers) in a new desktop window.
  Future<void> openRawDataInNewWindow({
    required Map<String, dynamic> data,
    String title = 'Body',
    bool beautificationRequired = true,
  }) => _infospectNavigationHelper.openRawDataInNewWindow(
    data: data,
    title: title,
    beautificationRequired: beautificationRequired,
  );

  /// Tabs currently shown in their own desktop windows (removed from the main
  /// Infospect sidebar until those windows close).
  ValueListenable<Set<InfospectDesktopTab>> get poppedOutDesktopTabs =>
      _infospectNavigationHelper.poppedOutTabs;

  /// Opens [tab] in a separate desktop window and removes it from the main
  /// Infospect window sidebar.
  Future<void> popOutDesktopTab(InfospectDesktopTab tab) =>
      _infospectNavigationHelper.popOutDesktopTab(tab);

  /// Focuses an already-open popped-out tab window, if any.
  Future<void> focusPoppedOutDesktopTab(InfospectDesktopTab tab) =>
      _infospectNavigationHelper.focusPoppedOutDesktopTab(tab);

  void navigateToInterceptor() =>
      _infospectNavigationHelper.navigateToInterceptor();

  /// No-ops kept for API compatibility with 0.1.x.
  ///
  /// With [multiview_desktop], all windows share one isolate and Infospect
  /// state — remove these calls when you migrate (see MIGRATION.md).
  @Deprecated('Unnecessary with multiview_desktop shared-isolate windows')
  void sendNetworkCalls() {}

  @Deprecated('Unnecessary with multiview_desktop shared-isolate windows')
  void sendLogs([List<InfospectLog>? logs]) {}

  @Deprecated('Unnecessary with multiview_desktop shared-isolate windows')
  void sendThemeMode({required bool isDarkTheme}) {}

  @Deprecated('Unnecessary with multiview_desktop shared-isolate windows')
  void handleMultiWindowReceivedData(BuildContext context) {}

  @Deprecated('Unnecessary with multiview_desktop shared-isolate windows')
  void handleMainWindowReceiveData() {}

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

  /// Records that a breakpoint interacted with [requestId].
  void markBreakpointTrace({
    required int requestId,
    bool requestHit = false,
    bool responseHit = false,
    bool requestEdited = false,
    bool responseEdited = false,
  }) =>
      _infospectNetworkCallHelper.markBreakpointTrace(
        requestId: requestId,
        requestHit: requestHit,
        responseHit: responseHit,
        requestEdited: requestEdited,
        responseEdited: responseEdited,
      );

  /// Stores original + edited request data and updates the live logged request.
  void applyRequestBreakpointEdit({
    required int requestId,
    required InfospectBreakpointEdit edit,
  }) =>
      _infospectNetworkCallHelper.applyRequestBreakpointEdit(
        requestId: requestId,
        edit: edit,
      );

  /// Stores original + edited response data for a breakpoint.
  void applyResponseBreakpointEdit({
    required int requestId,
    required InfospectBreakpointEdit edit,
  }) =>
      _infospectNetworkCallHelper.applyResponseBreakpointEdit(
        requestId: requestId,
        edit: edit,
      );

  /// interceptors
  InfospectDioInterceptor get dioInterceptor =>
      _infospectNetworkCallHelper.dioInterceptor;

  InfospectHttpClientInterceptor httpClientInterceptor({
    required Client client,
  }) => _infospectNetworkCallHelper.httpClientInterceptor(client: client);

  /// Breakpoints
  List<InfospectNetworkBreakpoint> get breakpoints => breakpointManager.rules;

  void addBreakpoint(InfospectNetworkBreakpoint breakpoint) =>
      breakpointManager.addBreakpoint(breakpoint);

  void updateBreakpoint(InfospectNetworkBreakpoint breakpoint) =>
      breakpointManager.updateBreakpoint(breakpoint);

  void removeBreakpoint(String id) => breakpointManager.removeBreakpoint(id);

  void clearBreakpoints() => breakpointManager.clearBreakpoints();

  /// Adds a breakpoint for [endpoint], optionally scoped to [method].
  ///
  /// When [method] is omitted, every HTTP method for that endpoint is paused.
  InfospectNetworkBreakpoint addEndpointBreakpoint({
    required String endpoint,
    String? method,
    bool breakOnRequest = true,
    bool breakOnResponse = true,
    bool enabled = true,
    List<InfospectBreakpointCondition> conditions =
        const <InfospectBreakpointCondition>[],
  }) {
    final breakpoint = InfospectNetworkBreakpoint(
      id: InfospectBreakpointManager.newId(),
      endpoint: endpoint,
      method: method,
      enabled: enabled,
      breakOnRequest: breakOnRequest,
      breakOnResponse: breakOnResponse,
      conditions: conditions,
    );
    addBreakpoint(breakpoint);
    return breakpoint;
  }

  /// Pauses for request editing when a matching breakpoint rule exists.
  Future<InfospectBreakpointResult?> interceptRequestIfNeeded({
    required String method,
    required String endpoint,
    required String uri,
    required Map<String, dynamic> headers,
    required Map<String, dynamic> queryParameters,
    required dynamic body,
    int? requestId,
  }) async {
    final match = breakpointManager.findMatch(
      InfospectBreakpointMatchContext(
        method: method,
        endpoint: endpoint,
        queryParameters: queryParameters,
        requestHeaders: headers,
        requestBody: body,
        isResponsePhase: false,
      ),
    );
    if (match == null || !match.breakOnRequest) return null;

    if (requestId != null) {
      markBreakpointTrace(requestId: requestId, requestHit: true);
    }

    final payload = InfospectBreakpointPayload(
      method: method,
      uri: uri,
      endpoint: endpoint,
      headers: InfospectBreakpointManager.stringifyMap(headers),
      queryParameters: InfospectBreakpointManager.stringifyMap(queryParameters),
      body: InfospectBreakpointManager.stringifyBody(body),
    );

    final result = await _breakpointPresenter.present(
      phase: InfospectBreakpointPhase.request,
      payload: payload,
    );

    if (requestId != null && !result.aborted) {
      final edited = result.payload != payload;
      if (edited) {
        markBreakpointTrace(requestId: requestId, requestEdited: true);
      }
    }

    return result;
  }

  /// Pauses for response editing when a matching breakpoint rule exists.
  Future<InfospectBreakpointResult?> interceptResponseIfNeeded({
    required String method,
    required String endpoint,
    required String uri,
    required Map<String, dynamic> headers,
    required dynamic body,
    int? statusCode,
    int? requestId,
    Map<String, dynamic> requestHeaders = const <String, dynamic>{},
    Map<String, dynamic> queryParameters = const <String, dynamic>{},
    dynamic requestBody,
  }) async {
    final match = breakpointManager.findMatch(
      InfospectBreakpointMatchContext(
        method: method,
        endpoint: endpoint,
        queryParameters: queryParameters,
        requestHeaders: requestHeaders,
        requestBody: requestBody,
        statusCode: statusCode,
        responseBody: body,
        responseHeaders: headers,
        isResponsePhase: true,
      ),
    );
    if (match == null || !match.breakOnResponse) return null;

    if (requestId != null) {
      markBreakpointTrace(requestId: requestId, responseHit: true);
    }

    final payload = InfospectBreakpointPayload(
      method: method,
      uri: uri,
      endpoint: endpoint,
      headers: InfospectBreakpointManager.stringifyMap(headers),
      body: InfospectBreakpointManager.stringifyBody(body),
      statusCode: statusCode,
    );

    final result = await _breakpointPresenter.present(
      phase: InfospectBreakpointPhase.response,
      payload: payload,
    );

    if (requestId != null && !result.aborted) {
      final edited = result.payload != payload;
      if (edited) {
        markBreakpointTrace(requestId: requestId, responseEdited: true);
      }
    }

    return result;
  }

  /// Dispose subjects and subscriptions
  void dispose() {
    networkCallsSubject.close();
    isInfospectOpened.dispose();
    breakpointManager.dispose();
  }
}
