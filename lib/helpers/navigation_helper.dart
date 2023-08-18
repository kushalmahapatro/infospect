part of 'infospect_helper.dart';

class InfospectNavigationHelper {
  const InfospectNavigationHelper._(Infospect infospect)
      : _infospect = infospect;
  final Infospect _infospect;

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
                infospect: Infospect.instance,
              ),
            ),
            BlocProvider(
              create: (_) => LogsListBloc(
                infospectLogger: Infospect.instance.infospectLogger,
              ),
            ),
          ],
          child: mobileRoutes.launch(Infospect.instance),
        ),
      );

  Widget openInterceptor() =>
      Navigator(onGenerateRoute: (settings) => interceptorScreen());

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
        interceptorScreen(),
      ).then(
        (onValue) => _infospect.isInfospectOpened.value = false,
      );
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
          child: myApp,
        ),
      );
    }
  }
}
