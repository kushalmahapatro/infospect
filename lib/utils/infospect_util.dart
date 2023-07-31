import 'dart:developer' as dev;

class InfospectUtil {
  static void log(
    String message, {
    Object? error,
    StackTrace? stackTrace,
  }) {
    dev.log(message, error: error, stackTrace: stackTrace);
  }
}
