import 'dart:async';
import 'dart:convert';

// ignore: depend_on_referenced_packages
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
// ignore: depend_on_referenced_packages
import 'package:http/http.dart';
import 'package:infospect/infospect.dart';

///

void main(List<String> args) {
  WidgetsFlutterBinding.ensureInitialized();

  /// Initialize the `Infospect` instance.
  ///handle the data received to the main window from Infospect window
  Infospect.ensureInitialized(logAppLaunch: true).handleMainWindowReceiveData();

  /// Run the app with the `Infospect` instance.
  /// The `Infospect` instance is a singleton and can be accessed anywhere in the app.
  /// As per the args if, it contains 'multi_window' then the app will be launched in multi-window mode.
  /// else normal runApp will be called.
  Infospect.instance.run(args, myApp: const MainApp());
}

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> with AppLoggerMixin, AppNetworkCall {
  late Dio _dio;
  late Client _client;
  int radioValue = 1;

  @override
  void initState() {
    /// Add the `InfospectDioInterceptor` to the `Dio` instance.
    _dio = Dio(BaseOptions(followRedirects: false));
    _dio.interceptors.add(Infospect.instance.dioInterceptor);

    /// Add the `InfospectHttpClientInterceptor` to the `Client` instance.
    _client = Client();
    _client = Infospect.instance.httpClientInterceptor(client: _client);

    super.initState();
  }

  @override
  String get tag => 'MainApp';

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
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
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Text('Select a network library to test'),
                _RadioGroup(
                  radioValue: radioValue,
                  onRadioValueChanged: onRadioValueChanged,
                ),
                SizedBox(
                  width: double.maxFinite,
                  child: ElevatedButton(
                    onPressed: _onPressed,
                    child: const Text('Click here to test'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void onRadioValueChanged(value) {
    if (value != null) {
      setState(() {
        radioValue = value;
      });
    }
  }

  void _onPressed() {
    Timer.periodic(
      const Duration(seconds: 2),
      (timer) {
        if (timer.tick >= 8) {
          timer.cancel();
        }

        /// Call the network library
        if (radioValue == 1) {
          dioCall(dio: _dio, index: timer.tick);
        } else {
          httpCall(httpClient: _client, index: timer.tick);
        }

        /// Log something
        log(
          DiagnosticLevel.values[timer.tick],
          'test log ${timer.tick}',
          error: _getError(timer.tick),
          stackTrace: StackTrace.current,
        );
      },
    );
  }

  String _getError(int tick) {
    String error = '';
    int i = 0;
    while (i < tick) {
      i++;
      error += 'Error ';
    }
    return error;
  }
}

class _RadioGroup extends StatelessWidget {
  const _RadioGroup({
    required this.radioValue,
    required this.onRadioValueChanged,
  });

  final int radioValue;
  final void Function(int? value) onRadioValueChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Flexible(
          child: RadioListTile(
            value: 1,
            groupValue: radioValue,
            onChanged: onRadioValueChanged,
            title: const Text('Dio'),
          ),
        ),
        Flexible(
          child: RadioListTile(
            value: 2,
            groupValue: radioValue,
            onChanged: onRadioValueChanged,
            title: const Text('Http'),
          ),
        )
      ],
    );
  }
}

enum Method { get, post, put, delete, patch, head, option, repeat }

mixin AppNetworkCall {
  Future<dynamic> dioCall({required Dio dio, required index}) async {
    final val = (
      'https://official-joke-api.appspot.com/random_joke?client=dio',
      Options(headers: {'content-type': 'json'}),
      {'id': index},
    );

    switch (Method.values[(index - 1)]) {
      case Method.get:
        return dio.get(val.$1, options: val.$2, queryParameters: val.$3);

      case Method.post:
        return dio.post(val.$1,
            options: val.$2, queryParameters: val.$3, data: jsonEncode(val.$3));

      case Method.put:
        return dio.put(val.$1, options: val.$2, queryParameters: val.$3);

      case Method.delete:
        return dio.delete(val.$1, options: val.$2, queryParameters: val.$3);

      case Method.patch:
        return dio.patch(val.$1, options: val.$2, queryParameters: val.$3);

      case Method.head:
        return dio.head(val.$1, options: val.$2, queryParameters: val.$3);

      case Method.option:
        return dio.get(val.$1, options: val.$2, queryParameters: val.$3);

      case Method.repeat:
        return dio.post(val.$1, options: val.$2, queryParameters: val.$3);
    }
  }

  Future<dynamic> httpCall({required Client httpClient, required index}) async {
    final val = (
      Uri.parse(
          'https://official-joke-api.appspot.com/random_joke?client=http&id=$index'),
      {'id': '$index'}
    );

    switch (Method.values[(index - 1)]) {
      case Method.get:
        return httpClient.get(val.$1);

      case Method.post:
        return httpClient.post(val.$1, body: jsonEncode(val.$2));

      case Method.put:
        return httpClient.put(val.$1);

      case Method.delete:
        return httpClient.delete(val.$1);

      case Method.patch:
        return httpClient.patch(val.$1);

      case Method.head:
        return httpClient.head(val.$1);

      case Method.option:
        return httpClient.get(val.$1);

      case Method.repeat:
        return httpClient.post(val.$1);
    }
  }
}

mixin AppLoggerMixin {
  String get tag;

  void logDebug(
    String message, {
    String? tag,
    Object? error,
    StackTrace? stackTrace,
  }) {
    _log(
      DiagnosticLevel.debug,
      message,
      tag: tag ?? this.tag,
      error: error,
      stackTrace: stackTrace,
    );
  }

  void logError(
    String message, {
    String? tag,
    Object? error,
    StackTrace? stackTrace,
  }) {
    _log(
      DiagnosticLevel.error,
      message,
      tag: tag ?? this.tag,
      error: error,
      stackTrace: stackTrace,
    );
  }

  void logInfo(
    String message, {
    String? tag,
    Object? error,
    StackTrace? stackTrace,
  }) {
    _log(
      DiagnosticLevel.info,
      message,
      tag: tag ?? this.tag,
      error: error,
      stackTrace: stackTrace,
    );
  }

  void logWarning(
    String message, {
    String? tag,
    Object? error,
    StackTrace? stackTrace,
  }) {
    _log(
      DiagnosticLevel.warning,
      message,
      tag: tag ?? this.tag,
      error: error,
      stackTrace: stackTrace,
    );
  }

  void log(
    DiagnosticLevel level,
    String message, {
    String? tag,
    Object? error,
    StackTrace? stackTrace,
  }) {
    _log(
      level,
      message,
      tag: tag ?? this.tag,
      error: error,
      stackTrace: stackTrace,
    );
  }

  void _log(
    DiagnosticLevel level,
    String message, {
    String? tag,
    Object? error,
    StackTrace? stackTrace,
  }) {
    String logMessage = message;
    if (tag != null) {
      logMessage = '[$tag]: $message';
    }

    Infospect.instance.addLog(
      InfospectLog(
        message: logMessage,
        level: level,
        error: error,
        stackTrace: stackTrace,
      ),
    );
  }
}
