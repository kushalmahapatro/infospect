part of 'infospect_helper.dart';

class InfospectNavigationHelper {
  const InfospectNavigationHelper._(Infospect infospect)
      : _infospect = infospect;
  final Infospect _infospect;

  bool get isDarkTheme =>
      Theme.of(_infospect.context!).brightness == Brightness.dark;

  /// This will open inspector in new window. This will work only on desktop
  Future<void> openInspectorInNewWindow() async {
    if (!kIsWeb && Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
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

  Widget interceptorScreen({
    bool isDarkTheme = true,
    bool isMultiWindow = false,
  }) {
    final ThemeData themeData =
        isDarkTheme ? InfospectTheme.darkTheme : InfospectTheme.lightTheme;
    mobileRoutes.themeData = themeData;
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      localizationsDelegates: const <LocalizationsDelegate<Object>>[],
      supportedLocales: const <Locale>[
        Locale('en', 'US'), // English
      ],
      theme: themeData,
      home: MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (_) => LaunchBloc(),
          ),
          BlocProvider(
            create: (_) => NetworksListBloc(
              isMultiWindow: isMultiWindow,
            ),
          ),
          BlocProvider(
            create: (_) => LogsListBloc(
              infospectLogger: Infospect.instance.infospectLogger,
              isMultiWindow: isMultiWindow,
            ),
          ),
        ],
        child: mobileRoutes.launch(Infospect.instance),
      ),
    );
  }

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

  void run(List<String> args, {required Widget myApp}) {
    if (args.firstOrNull == 'multi_window') {
      runNewWindowInstance(args);
      return;
    }
    runApp(myApp);
    _infospect._runAppCompleter.complete(true);
  }

  void runNewWindowInstance(List<String> args) {
    runApp(
      BlocProvider(
        create: (context) => DesktopThemeCubit(),
        child: BlocBuilder<DesktopThemeCubit, DesktopThemeState>(
          builder: (context, theme) => interceptorScreen(
            isDarkTheme: theme.isDarkTheme,
            isMultiWindow: true,
          ),
        ),
      ),
    );
  }
}
