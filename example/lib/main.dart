import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
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
    _dio = Dio(BaseOptions(
      followRedirects: false,
    ));
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
              onPressed: () {},
              child: const Text('Example App'),
            ),
          ),
        ),
      ),
    );
  }
}
