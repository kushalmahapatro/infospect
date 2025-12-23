part of 'infospect_helper.dart';

/// `InfospectNavigationHelper` aids the `Infospect` class in navigation and window management tasks.
/// This class provides functionalities to open new windows (useful in a desktop environment),
/// navigate to certain screens, and handle the launching of multiple instances of the app.
class InfospectNavigationHelper {
  /// Private constructor for the `InfospectNavigationHelper`.
  ///
  /// - `infospect`: Reference to the main `Infospect` instance.
  InfospectNavigationHelper._(Infospect infospect) : _infospect = infospect;
  final Infospect _infospect;

  /// Desktop theme notifier for multi-window scenarios
  DesktopThemeNotifier? desktopThemeNotifier;
  final MobileRoutes mobileRoutes = MobileRoutes();

  /// Determines whether the current theme mode is dark.
  bool get isDarkTheme =>
      Theme.of(_infospect.context!).brightness == Brightness.dark;

  /// Opens the inspector in a new window (applicable only on desktop platforms).
  Future<void> openInspectorInNewWindow() async {
    if (!kIsWeb && Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      /// If a sub window is already open, return.
      List<int> subWindowIds = [];
      try {
        subWindowIds = await DesktopMultiWindow.getAllSubWindowIds();
      } catch (_) {}
      if (subWindowIds.isNotEmpty) return;

      final WindowController window = await DesktopMultiWindow.createWindow(
        jsonEncode({'args1': 'Sub window'}),
      );
      window
        ..setFrame(const Offset(0, 0) & const Size(1280, 720))
        ..center()
        ..setTitle('Infospect');

      window.show().then((value) {
        Infospect.instance
          ..sendNetworkCalls()
          ..sendLogs()
          ..sendThemeMode(isDarkTheme: isDarkTheme);
      });
    }
  }

  /// Provides the main widget for the interceptor screen.
  ///
  /// - `isDarkTheme`: Whether to use dark theme. Defaults to `true`.
  /// - `isMultiWindow`: Whether the screen is part of a multi-window environment.
  Widget interceptorScreen({
    bool isDarkTheme = true,
    bool isMultiWindow = false,
  }) {
    final ThemeData themeData =
        isDarkTheme ? InfospectTheme.darkTheme : InfospectTheme.lightTheme;
    mobileRoutes.themeData = themeData;

    // Create notifiers directly
    final networksListNotifier = NetworksListNotifier(
      isMultiWindow: isMultiWindow,
    );
    final logsListNotifier = LogsListNotifier(
      infospectLogger: Infospect.instance.infospectLogger,
      isMultiWindow: isMultiWindow,
    );

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      localizationsDelegates: const <LocalizationsDelegate<Object>>[],
      supportedLocales: const <Locale>[
        Locale('en', 'US'), // English
      ],
      theme: themeData,
      home: mobileRoutes.launch(
        Infospect.instance,
        networksListNotifier: networksListNotifier,
        logsListNotifier: logsListNotifier,
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
          builder: (context) => interceptorScreen(isDarkTheme: isDarkTheme),
        ),
      ).then(
        (onValue) => _infospect.isInfospectOpened.value = false,
      );
    }
  }

  /// Initiates the app with specified arguments.
  ///
  /// - `args`: A list of arguments.
  /// - `myApp`: The main widget to run for the app.
  void run(List<String> args, {required Widget myApp}) {
    if (args.firstOrNull == 'multi_window') {
      runNewWindowInstance(args);
      return;
    }
    runApp(myApp);
    _infospect._runAppCompleter.complete(true);
  }

  /// Initiates a new instance of the app in a new window (useful for multi-window scenarios).
  ///
  /// - `args`: A list of arguments.
  void runNewWindowInstance(List<String> args) {
    desktopThemeNotifier = DesktopThemeNotifier();
    runApp(
      ListenableBuilder(
        listenable: desktopThemeNotifier!,
        builder: (context, child) => interceptorScreen(
          isDarkTheme: desktopThemeNotifier!.isDarkTheme,
          isMultiWindow: true,
        ),
      ),
    );
  }
}
