# Overview
Infospect meaning Information Inspector is a Flutter plugin for thats empowers the developers to debug the network calls and logs in the app. It is a powerful tools that offer network call interception and logging features, among others. By allowing developers to monitor and intercept network calls, they can efficiently debug network-related issues and optimize app performance. The logging and debugging capabilities aid in understanding app behavior and detecting errors, leading to faster bug resolution.

## Getting started
1. Add the dependency to your pubspec.yaml file. (Replace latest-version with the latest version of the plugin)
```yaml
dependencies:
  infospect: latest-version
```
or 
```console
flutter pub add infospect
```
## Usage

1. Adding args to main, to enable the support of multi window. Plugin used for this [https://pub.dev/packages/desktop_multi_window](https://pub.dev/packages/desktop_multi_window)
```dart
void main(List<String> args){}
```
2. Initialize the plugin in main.dart
```dart
  WidgetsFlutterBinding.ensureInitialized();

  Infospect.ensureInitialized();
```
3. Rather using runApp using, use Infospect.instance.run(args, myApp: EntryWidget());
This will help to set the args and use it when launching the infospect window in Desktop
```dart
  Infospect.instance.run(args, myApp: const MainApp());
```

4. Adding network call interceptor
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
6. Adding logs
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

## Additional information
### Text Style
LogItem text = Theme.of(context).textTheme.labelMedium
![Alt text](images/logs.png)

## Upcoming Feature
1. Breakpoints for network call to edit request and response.
2. Add support for more network client.
3. Feature to share all the logs (adding them to a file).
4. Sorting of the logs and network calls.
5. An example app with multiple screen and good number of network calls and logs.
6. Bug fixes and many more.

** the above order is based on the priority of the feature and the working being done on it.
## Support
This plugin is free to use and currently in its early stages of development. We plan to add many more features soon. Please visit the [Github Project](https://github.com/users/kushalmahapatro/projects/2) to know about the upcoming feature and fixes. If you encounter any issues or would like additional features, please raise an issue in the [GitHub repository](https://github.com/kushalmahapatro/infospect/issues).

 Feel free to contribute to this project by creating a pull request with a clear description of your changes.

If this plugin was useful to you, helped you in any way, saved you a lot of time, or you just want to support the project, I would be very grateful if you buy me a cup of coffee. Your support helps maintain and improve this project.


<a href="https://www.buymeacoffee.com/kushalm" target="_blank"><img src="https://www.buymeacoffee.com/assets/img/custom_images/purple_img.png" alt="Buy Me A Coffee" style="height: 41px !important;width: 174px !important;box-shadow: 0px 3px 2px 0px rgba(190, 190, 190, 0.5) !important;-webkit-box-shadow: 0px 3px 2px 0px rgba(190, 190, 190, 0.5) !important;" ></a>