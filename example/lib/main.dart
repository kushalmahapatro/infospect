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
    return InfospectInvoker(
      infospect: widget.infospect,
      child: MaterialApp(
        navigatorKey: widget.infospect.getNavigatorKey,
        home: Scaffold(
          body: Center(
            child: ElevatedButton(
              onPressed: () {
                _dio.get(
                  'https://official-joke-api.appspot.com/random_joke',
                  options: Options(headers: {'content-type': 'json'}),
                  queryParameters: {'id': 1},
                );
                Timer.periodic(const Duration(seconds: 2), (timer) {
                  if (timer.tick >= 30) {
                    timer.cancel();
                  }
                  widget.infospect.addLog(
                    InfospectLog(
                      message: 'test log ${timer.tick}',
                      level: DiagnosticLevel.debug,
                      error: 'Error',
                      stackTrace: StackTrace.current,
                    ),
                  );
                });
              },
              child: const Text('Example App'),
            ),
          ),
        ),
      ),
    );
  }
}
