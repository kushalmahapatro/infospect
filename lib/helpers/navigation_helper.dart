part of 'infospect_helper.dart';

/// `InfospectNavigationHelper` aids the `Infospect` class in navigation and window management tasks.
/// This class provides functionalities to open new windows (useful in a desktop environment),
/// navigate to certain screens, and handle the launching of the app.
class InfospectNavigationHelper {
  /// Private constructor for the `InfospectNavigationHelper`.
  ///
  /// - `infospect`: Reference to the main `Infospect` instance.
  InfospectNavigationHelper._(Infospect infospect) : _infospect = infospect;
  final Infospect _infospect;

  final MobileRoutes mobileRoutes = MobileRoutes();

  /// Public view id of the Infospect window when open, otherwise null.
  int? _infospectWindowId;

  /// Cached so [interceptorScreen] can be rebuilt by multiview without wiping
  /// network/log list state (openWindow triggers a root setState that re-runs
  /// every window builder).
  NetworksListNotifier? _networksListNotifier;
  LogsListNotifier? _logsListNotifier;

  /// Tabs currently shown in their own windows (removed from the main sidebar).
  final ValueNotifier<Set<InfospectDesktopTab>> poppedOutTabs =
      ValueNotifier<Set<InfospectDesktopTab>>(<InfospectDesktopTab>{});

  int? _networkWindowId;
  int? _logsWindowId;
  final Map<String, int> _networkBodyWindowIds = <String, int>{};
  bool _listeningForWindowClosures = false;

  /// Determines whether the current theme mode is dark.
  bool get isDarkTheme =>
      Theme.of(_infospect.context!).brightness == Brightness.dark;

  /// Opens the inspector in a new window (applicable only on desktop platforms).
  Future<void> openInspectorInNewWindow() async {
    if (kIsWeb || !InfospectUtil.isDesktop) return;

    if (_infospectWindowId != null &&
        MultiViewDesktop.allWindowViewIds.contains(_infospectWindowId)) {
      final window = MultiViewDesktop.fromId(_infospectWindowId!);
      await window.show();
      await window.focus();
      return;
    }

    _syncPoppedOutFromOpenWindows();

    final bool darkTheme = _infospect.context != null ? isDarkTheme : true;

    _infospectWindowId = await openWindow(
      (context, id) => interceptorScreen(isDarkTheme: darkTheme),
      options: infospectDesktopWindowOptions(
        title: InfospectDataTransfer.windowName,
        size: const Size(1280, 720),
        minimumSize: const Size(800, 600),
        alignment: Alignment.center,
        shellOverrides: ViewShellOverrides(
          appearance: AppShellPatch(
            theme: InfospectTheme.lightTheme,
            darkTheme: InfospectTheme.darkTheme,
            themeMode: darkTheme ? ThemeMode.dark : ThemeMode.light,
          ),
        ),
      ),
    );
    _ensureWindowCloseListener();
  }

  /// Opens [tab] in a separate window and removes it from the main Infospect UI.
  Future<void> popOutDesktopTab(InfospectDesktopTab tab) async {
    if (kIsWeb || !InfospectUtil.isDesktop) return;

    _ensureNotifiers();
    _ensureWindowCloseListener();

    final existingId = _windowIdFor(tab);
    if (existingId != null &&
        MultiViewDesktop.allWindowViewIds.contains(existingId)) {
      await _focusWindow(existingId);
      _markTabPoppedOut(tab);
      return;
    }

    final bool darkTheme = _infospect.context != null ? isDarkTheme : true;
    final windowId = await openWindow(
      (context, id) => _tabWindowScreen(tab),
      options: infospectDesktopWindowOptions(
        title: '${tab.windowTitle} · Infospect',
        size: const Size(1100, 720),
        minimumSize: const Size(720, 480),
        alignment: Alignment.center,
        shellOverrides: ViewShellOverrides(
          appearance: AppShellPatch(
            theme: InfospectTheme.lightTheme,
            darkTheme: InfospectTheme.darkTheme,
            themeMode: darkTheme ? ThemeMode.dark : ThemeMode.light,
          ),
        ),
      ),
    );

    _setWindowIdFor(tab, windowId);
    _markTabPoppedOut(tab);
  }

  /// Focuses an already-open popped-out tab window, if any.
  Future<void> focusPoppedOutDesktopTab(InfospectDesktopTab tab) async {
    final existingId = _windowIdFor(tab);
    if (existingId == null) return;
    if (!MultiViewDesktop.allWindowViewIds.contains(existingId)) return;
    await _focusWindow(existingId);
  }

  Widget _tabWindowScreen(InfospectDesktopTab tab) {
    _ensureNotifiers();
    return switch (tab) {
      InfospectDesktopTab.network => DesktopNetworksListScreen(
          _infospect,
          notifier: _networksListNotifier!,
        ),
      InfospectDesktopTab.logs => DesktopLogsListScreen(
          _infospect,
          notifier: _logsListNotifier!,
        ),
    };
  }

  void _ensureNotifiers() {
    _networksListNotifier ??= NetworksListNotifier();
    _logsListNotifier ??= LogsListNotifier(
      infospectLogger: Infospect.instance.infospectLogger,
    );
  }

  void _ensureWindowCloseListener() {
    if (_listeningForWindowClosures || kIsWeb || !InfospectUtil.isDesktop) {
      return;
    }
    _listeningForWindowClosures = true;
    MultiViewDesktop.allWindowIdsNotifier.addListener(_onWindowsChanged);
  }

  void _onWindowsChanged() {
    final ids = MultiViewDesktop.allWindowViewIds;

    if (_infospectWindowId != null && !ids.contains(_infospectWindowId)) {
      _infospectWindowId = null;
    }

    _networkBodyWindowIds
        .removeWhere((_, windowId) => !ids.contains(windowId));

    var changed = false;
    final next = Set<InfospectDesktopTab>.from(poppedOutTabs.value);

    if (_networkWindowId != null && !ids.contains(_networkWindowId)) {
      _networkWindowId = null;
      changed = next.remove(InfospectDesktopTab.network) || changed;
    }
    if (_logsWindowId != null && !ids.contains(_logsWindowId)) {
      _logsWindowId = null;
      changed = next.remove(InfospectDesktopTab.logs) || changed;
    }

    if (changed) {
      poppedOutTabs.value = next;
      _selectFirstVisibleTab();
    }
  }

  void _markTabPoppedOut(InfospectDesktopTab tab) {
    if (poppedOutTabs.value.contains(tab)) return;
    poppedOutTabs.value = {...poppedOutTabs.value, tab};
    _selectFirstVisibleTab();
  }

  void _selectFirstVisibleTab() {
    final selected = InfospectDesktopTab.fromTabIndex(
      LaunchNotifier.instance.selectedTab,
    );
    if (selected != null && !poppedOutTabs.value.contains(selected)) return;

    final remaining = InfospectDesktopTab.values
        .where((tab) => !poppedOutTabs.value.contains(tab));
    if (remaining.isNotEmpty) {
      LaunchNotifier.instance.selectTab(remaining.first.tabIndex);
    }
  }

  void _syncPoppedOutFromOpenWindows() {
    final ids = MultiViewDesktop.allWindowViewIds;
    final next = <InfospectDesktopTab>{};

    if (_networkWindowId != null && ids.contains(_networkWindowId)) {
      next.add(InfospectDesktopTab.network);
    } else {
      _networkWindowId = null;
    }

    if (_logsWindowId != null && ids.contains(_logsWindowId)) {
      next.add(InfospectDesktopTab.logs);
    } else {
      _logsWindowId = null;
    }

    if (!_setEquals(poppedOutTabs.value, next)) {
      poppedOutTabs.value = next;
    }
    _selectFirstVisibleTab();
  }

  bool _setEquals(Set<InfospectDesktopTab> a, Set<InfospectDesktopTab> b) {
    return a.length == b.length && a.containsAll(b);
  }

  int? _windowIdFor(InfospectDesktopTab tab) => switch (tab) {
        InfospectDesktopTab.network => _networkWindowId,
        InfospectDesktopTab.logs => _logsWindowId,
      };

  void _setWindowIdFor(InfospectDesktopTab tab, int id) {
    switch (tab) {
      case InfospectDesktopTab.network:
        _networkWindowId = id;
      case InfospectDesktopTab.logs:
        _logsWindowId = id;
    }
  }

  Future<void> _focusWindow(int windowId) async {
    final window = MultiViewDesktop.fromId(windowId);
    await window.show();
    await window.focus();
  }

  /// Provides the main widget for the interceptor screen.
  ///
  /// On desktop multi-view windows this is a page widget (the entry shell is
  /// provided by [multiview_desktop]). On mobile / in-route navigation it is
  /// wrapped in a [MaterialApp].
  ///
  /// - `isDarkTheme`: Whether to use dark theme. Defaults to `true`.
  /// - `wrapInMaterialApp`: When true, wraps content in [MaterialApp].
  Widget interceptorScreen({
    bool isDarkTheme = true,
    bool wrapInMaterialApp = false,
  }) {
    final ThemeData themeData =
        isDarkTheme ? InfospectTheme.darkTheme : InfospectTheme.lightTheme;
    mobileRoutes.themeData = themeData;

    _ensureNotifiers();

    final Widget home = mobileRoutes.launch(
      Infospect.instance,
      networksListNotifier: _networksListNotifier!,
      logsListNotifier: _logsListNotifier!,
    );

    if (!wrapInMaterialApp) {
      return home;
    }

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      localizationsDelegates: const <LocalizationsDelegate<Object>>[],
      supportedLocales: const <Locale>[
        Locale('en', 'US'),
      ],
      theme: themeData,
      home: home,
    );
  }

  /// Opens a network call body (with request metadata) in a new desktop window.
  ///
  /// If the same call + body kind is already open, focuses that window instead.
  Future<void> openNetworkBodyInNewWindow({
    required InfospectNetworkCall call,
    required NetworkBodyKind kind,
    bool detailsInitiallyExpanded = false,
  }) async {
    if (kIsWeb || !InfospectUtil.isDesktop) return;

    _ensureWindowCloseListener();

    final bodyKey = _networkBodyWindowKey(call.id, kind);
    final existingId = _networkBodyWindowIds[bodyKey];
    if (existingId != null &&
        MultiViewDesktop.allWindowViewIds.contains(existingId)) {
      await _focusWindow(existingId);
      return;
    }

    final bool darkTheme = _infospect.context != null ? isDarkTheme : true;
    final title =
        kind == NetworkBodyKind.request ? 'Request Body' : 'Response Body';

    final windowId = await openWindow(
      (context, id) => NetworkBodyWindowScreen(
        call: call,
        kind: kind,
        detailsInitiallyExpanded: detailsInitiallyExpanded,
      ),
      options: infospectDesktopWindowOptions(
        title: '$title · ${call.method} ${call.endpoint}',
        size: const Size(980, 760),
        minimumSize: const Size(560, 420),
        alignment: Alignment.center,
        shellOverrides: ViewShellOverrides(
          appearance: AppShellPatch(
            theme: InfospectTheme.lightTheme,
            darkTheme: InfospectTheme.darkTheme,
            themeMode: darkTheme ? ThemeMode.dark : ThemeMode.light,
          ),
        ),
      ),
    );

    _networkBodyWindowIds[bodyKey] = windowId;
  }

  String _networkBodyWindowKey(int callId, NetworkBodyKind kind) =>
      '$callId:${kind.name}';

  /// Opens raw / JSON map data in a new desktop window (headers, etc.).
  Future<void> openRawDataInNewWindow({
    required Map<String, dynamic> data,
    String title = 'Body',
    bool beautificationRequired = true,
  }) async {
    if (kIsWeb || !InfospectUtil.isDesktop) return;

    final bool darkTheme = _infospect.context != null ? isDarkTheme : true;

    await openWindow(
      (context, id) => mobileRoutes.rawDataViewer(
        data: data,
        beautificationRequired: beautificationRequired,
        title: title,
        standaloneWindow: true,
      ),
      options: infospectDesktopWindowOptions(
        title: title,
        size: const Size(900, 700),
        minimumSize: const Size(480, 360),
        alignment: Alignment.center,
        shellOverrides: ViewShellOverrides(
          appearance: AppShellPatch(
            theme: InfospectTheme.lightTheme,
            darkTheme: InfospectTheme.darkTheme,
            themeMode: darkTheme ? ThemeMode.dark : ThemeMode.light,
          ),
        ),
      ),
    );
  }

  /// Navigates to the interceptor screen.
  void navigateToInterceptor() {
    if (Infospect.instance.context == null) {
      InfospectUtil.log(
        "Cant start HTTP Inspector. Please add NavigatorKey to your application",
      );
      return;
    }
    if (!_infospect.isInfospectOpened.value) {
      _infospect.isInfospectOpened.value = true;
      Navigator.push<void>(
        _infospect.context!,
        MaterialPageRoute<dynamic>(
          builder: (context) => interceptorScreen(
            isDarkTheme: isDarkTheme,
            wrapInMaterialApp: true,
          ),
        ),
      ).then(
        (onValue) => _infospect.isInfospectOpened.value = false,
      );
    }
  }

  /// Initiates the app.
  ///
  /// On desktop this uses [runMultiApp] so Infospect can open a secondary
  /// window in the same Flutter engine. On mobile / web this uses [runApp].
  ///
  /// - `args`: Kept for API compatibility; unused with multiview_desktop.
  /// - `myApp`: The main widget to run for the app.
  void run(List<String> args, {required Widget myApp}) {
    if (!kIsWeb && InfospectUtil.isDesktop) {
      runMultiApp(
        home: (context, id) => myApp,
        config: infospectMultiAppConfig(),
      );
    } else {
      runApp(myApp);
    }
    if (!_infospect._runAppCompleter.isCompleted) {
      _infospect._runAppCompleter.complete(true);
    }
  }
}
