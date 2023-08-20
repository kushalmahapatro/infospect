import 'dart:async';

import 'package:dio/dio.dart';
import 'package:example/app_logger.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:infospect/infospect.dart';

void main(List<String> args) {
  WidgetsFlutterBinding.ensureInitialized();
  Infospect.ensureInitialized(logAppLaunch: true).handleMainWindowReceiveData();

  Infospect.instance.run(args, myApp: const MainApp());
}

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> with AppLoggerMixin {
  late Dio _dio;

  @override
  void initState() {
    _dio = Dio(BaseOptions(followRedirects: false));
    _dio.interceptors.add(Infospect.instance.dioInterceptor);
    super.initState();

    http.Client client = http.Client();
    client = Infospect.instance.httpClientInterceptor(client: client);
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
          child: ElevatedButton(
            onPressed: () {
              Timer.periodic(
                const Duration(seconds: 2),
                (timer) {
                  if (timer.tick >= 8) {
                    timer.cancel();
                  }
                  switch (timer.tick) {
                    case 1:
                      _dio.get(
                        'https://official-joke-api.appspot.com/random_joke',
                        options: Options(headers: {'content-type': 'json'}),
                        queryParameters: {'id': timer.tick},
                      );
                      break;
                    case 2:
                      _dio.put(
                        'https://official-joke-api.appspot.com/random_joke',
                        options: Options(headers: {'content-type': 'json'}),
                        queryParameters: {'id': timer.tick},
                      );
                      break;
                    case 3:
                      _dio.post(
                        'https://official-joke-api.appspot.com/random_joke',
                        options: Options(headers: {'content-type': 'json'}),
                        queryParameters: {'id': timer.tick},
                      );
                      break;
                    case 4:
                      _dio.delete(
                        'https://official-joke-api.appspot.com/random_joke',
                        options: Options(headers: {'content-type': 'json'}),
                        queryParameters: {'id': timer.tick},
                      );
                      break;
                    case 5:
                      _dio.head(
                        'https://official-joke-api.appspot.com/random_joke',
                        options: Options(headers: {'content-type': 'json'}),
                        queryParameters: {'id': timer.tick},
                      );
                      break;
                    case 6:
                      _dio.download(
                        'https://official-joke-api.appspot.com/random_joke',
                        '',
                        options: Options(headers: {'content-type': 'json'}),
                        queryParameters: {'id': timer.tick},
                      );
                      break;
                    case 7:
                      _dio.patch(
                        'https://official-joke-api.appspot.com/random_joke',
                        options: Options(headers: {'content-type': 'json'}),
                        queryParameters: {'id': timer.tick},
                      );
                      break;
                  }

                  lgoOthers(
                    DiagnosticLevel.values[timer.tick],
                    'test log ${timer.tick}',
                    error: _getError(timer.tick),
                    stackTrace: StackTrace.current,
                  );
                },
              );
            },
            child: const Text('Example App'),
          ),
        ),
      ),
    );
  }

  _getError(int tick) {
    String error = '';
    int i = 0;
    while (i < tick) {
      i++;
      error += 'Error ';
    }
    return error;
  }
}
