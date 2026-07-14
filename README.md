# Overview

Infospect meaning Information Inspector is a Flutter plugin for that empowers the developers to
debug the network calls and logs in the app. It is a powerful tools that offer network call
interception and logging features, among others. By allowing developers to monitor and intercept
network calls, they can efficiently debug network-related issues and optimize app performance. The
logging and debugging capabilities aid in understanding app behavior and detecting errors, leading
to faster bug resolution.

## Preview

##### iOS
![](https://raw.githubusercontent.com/kushalmahapatro/infospect/main/images/preview/ios.gif)
##### macOS
![](https://raw.githubusercontent.com/kushalmahapatro/infospect/main/images/preview/mac.gif)
##### Linux (Ubuntu VM in mac) - Opening Infospect in new Window
![](https://raw.githubusercontent.com/kushalmahapatro/infospect/main/images/preview/linux(ubuntu%20vm).gif)
##### Windows 10 (VM in mac) - Opening Infospect in new Window
![](https://raw.githubusercontent.com/kushalmahapatro/infospect/main/images/preview/windows.gif)

## Migrating from 0.1.5

Upgrading from **0.1.5** to **0.2.0**? See **[MIGRATION.md](MIGRATION.md)** for consumer breaking changes (Flutter / SDK floors, `multiview_desktop` desktop runner setup, and obsolete multi-window IPC APIs).

## Getting started

1. Add the dependency to your pubspec.yaml file. (Replace latest-version with the latest version of
   the plugin)

  ```yaml
  dependencies:
    infospect: latest-version
  ```

or using the below command

  ```console
  flutter pub add infospect
  ```

## Usage

1. Initialize the plugin in main.dart

  ```dart
    Infospect.ensureInitialized();
  ```
  
  ```dart
  Infospect ensureInitialized({
    int maxCallsCount = 1000,
    GlobalKey<NavigatorState>? navigatorKey,
    bool logAppLaunch = false,
    void Function(String path)? onShareAllNetworkCalls,
    void Function(String path)? onShareAllLogs,
  }
  ```

In ensureInitialized we can configure the **maxCallCount** `int` for both network calls and logs,
defaults to 1000.
A **navigatorKey** `GlobalKey<NavigatorState>` that will be used for navigation and dialog, if not
provided a new key will be created.
A bool value to **logAppLaunch**, if true will log the app launch with details like below, defaults to
true,

  ```
  App name:  Example
  Package: com.example.example
  Version: 0.1.0
  Build number: 0.1.0
  Started at: 2023-08-20T13:39:56.531974
  ```

A call back to handle the share functionality for all the network calls **onShareAllNetworkCalls**,
This will provide the path of the compressed file name infospect_network_calls_log.tar.gz, which can
be shared accordingly.
If not provided, the default platform share option will be invoked.

A call back to handle the share functionality for all the logs **onShareAllLogs**,
This will provide the path of the compressed file name infospect_logs.tar.gz, which can be shared
accordingly.
If not provided, the default platform share option will be invoked.

2. Rather than using `runApp`, use `Infospect.instance.run(args, myApp: EntryWidget())`.
   On desktop this starts [multiview_desktop](https://pub.dev/packages/multiview_desktop) so Infospect
   can open in a secondary OS window on the same Flutter engine (no separate isolate / IPC).
   On mobile this behaves like a normal `runApp`.
  ```dart
    Infospect.instance.run(args, myApp: const MainApp());
  ```

   Desktop hosts also need the [multiview_desktop platform setup](https://pub.dev/packages/multiview_desktop)
   in their macOS / Windows / Linux runners (see the package README and the Infospect example app).

3. Adding network call interceptor
   a. dio:
  ```dart
    _dio = Dio(BaseOptions());
    _dio.interceptors.add(Infospect.instance.dioInterceptor);
  ```
  b. http:
  ```dart
    http.Client client = http.Client();
    client = Infospect.instance.httpClientInterceptor(client: client);
  ```
4. Adding logs
  ```dart
    Infospect.instance.addLog(
      InfospectLog(
        message: logMessage,
        level: level,
        error: error,
        stackTrace: stackTrace,
      ),
    );
  ```
  5. Adding invoker to get and overlay button to open the infospect window
  state:  `alwaysOpened`, `collapsible`, `autoCollapse`

  Drag the bubble to dock it on any screen edge. Long-press to hide it; tap the thin edge nub to show it again. Optional `initialEdge` / `initialAlign` set the starting dock.

  ```dart
    InfospectInvoker(
      state: InvokerState.collapsible,
      initialEdge: InvokerEdge.right,
      initialAlign: 0.85,
      child: child,
    );
  ```
  This can be wrapped around the child widget returned from the builder method of MaterialApp.
  By this, the invoker will be available on all the screens of the app.

  If a navigator key is provided in the ensureInitialized method, then the navigator key can be used here, if not provided a new navigator key will be created by Infospect and can be accessed using `Infospect.instance.getNavigatorKey` and can be used as below
  ```dart
    MaterialApp(
      navigatorKey: Infospect.instance.getNavigatorKey,
      theme: ThemeData(useMaterial3: true),
      darkTheme: ThemeData.dark(useMaterial3: true),
      themeMode: ThemeMode.dark,
      builder: (context, child) {
        return InfospectInvoker(
          state: InvokerState.collapsible,
          child: child ?? const SizedBox.shrink(),
        );
      },
      home: const MainApp(),
    )
  ```
  In desktop the infospect window will be opened in a new window, and it can be invoked by clicking on the invoker or using the mentioned shortcut keys
  > macOS: `⌘ + ⌥ + i` (Command + Option + i)
  > Windows: `Ctrl + Alt + i`
  > Linux: `Ctrl + Alt + i`

  But in mobile the infospect window will be opened in a new route.

6. Network breakpoints (Proxyman-style, without a proxy)

   Pause matching requests and/or responses so you can edit headers, query
   params, and body before the call continues — the same workflow proxy tools
   provide, powered by Infospect's Dio / `http` interceptors.

   **Add a breakpoint from code**

   ```dart
   // Pause every method for this path:
   Infospect.instance.addEndpointBreakpoint(endpoint: '/api/users');

   // Pause only POST:
   Infospect.instance.addEndpointBreakpoint(
     endpoint: '/api/users',
     method: 'POST',
   );

   // Path prefix match:
   Infospect.instance.addEndpointBreakpoint(endpoint: '/api/users*');
   ```

   **Add / manage breakpoints in the UI**

   - Network tab → overflow menu → **Breakpoints**
   - Desktop: right-click a network call → **Add breakpoint**
   - Mobile: long-press a network call → adds a breakpoint for that method + path

   When a rule matches:

   - **Mobile:** a fullscreen dialog opens to edit the request; after the
     server responds, another dialog opens for the response.
   - **Desktop:** the same editors open in a new window.

   Use **Continue** to send the (possibly edited) request / response ahead, or
   **Abort** to cancel the call.

   Edited calls keep both the **original** and **edited** URL / params /
   headers / body (and response status) on the logged call, shown as an
   Original vs Edited section in request / response details.

   **UI / integration tests**

   ```console
   flutter test test/breakpoint_ui_test.dart
   # Refresh golden screenshots after intentional UI changes:
   flutter test test/breakpoint_ui_test.dart --update-goldens
   ```

## Upcoming Feature

1. Add support for more network client.
2. An example app having multiple screens to show the usage of the plugin with network call and selection for respective network library to be intercepted and logger implementation.
3. Bug fixes and many more.


## Support

This plugin is free to use and currently in its early stages of development. We plan to add many
more features soon. Please visit
the [Github Project](https://github.com/users/kushalmahapatro/projects/2) to know about the upcoming
feature and fixes. If you encounter any issues or would like additional features, please raise an
issue in the [GitHub repository](https://github.com/kushalmahapatro/infospect/issues).

Feel free to contribute to this project by creating a pull request with a clear description of your
changes.

If this plugin was useful to you, helped you in any way, saved you a lot of time, or you just want
to support the project, I would be very grateful if you buy me a cup of coffee. Your support helps
maintain and improve this project.


<a href="https://www.buymeacoffee.com/kushalm" target="_blank"><img src="https://www.buymeacoffee.com/assets/img/custom_images/purple_img.png" alt="Buy Me A Coffee" style="height: 41px !important;width: 174px !important;box-shadow: 0px 3px 2px 0px rgba(190, 190, 190, 0.5) !important;-webkit-box-shadow: 0px 3px 2px 0px rgba(190, 190, 190, 0.5) !important;" ></a>