import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:infospect/features/logger/models/infospect_log.dart';
import 'package:infospect/infospect.dart';

void main(List<String> args) {
  WidgetsFlutterBinding.ensureInitialized();

  Infospect infospect = Infospect();
  infospect.run(args, myApp: MainApp(infospect: infospect));
}

class MainApp extends StatefulWidget {
  final Infospect infospect;
  const MainApp({super.key, required this.infospect});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  late Dio _dio;

  @override
  void initState() {
    _dio = Dio(
      BaseOptions(
        followRedirects: false,
      ),
    );
    _dio.interceptors.add(widget.infospect.dioInterceptor);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: widget.infospect.getNavigatorKey,
      theme: ThemeData(useMaterial3: true),
      darkTheme: ThemeData.dark(useMaterial3: true),
      themeMode: ThemeMode.dark,
      builder: (context, child) {
        return InfospectInvoker(
          infospect: widget.infospect,
          state: InvokerState.collapsable,
          child: child!,
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
                  _dio.get(
                    'https://official-joke-api.appspot.com/random_joke',
                    options: Options(headers: {'content-type': 'json'}),
                    queryParameters: {'id': timer.tick},
                  );
                  widget.infospect.addLog(
                    InfospectLog(
                      message: 'test log ${timer.tick}',
                      level: DiagnosticLevel.values[timer.tick],
                      error: _getError(timer.tick),
                      stackTrace: StackTrace.current,
                    ),
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
