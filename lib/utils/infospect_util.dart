import 'dart:convert';
import 'dart:developer' as dev;
import 'dart:io';

class InfospectUtil {
  static bool get isDesktop =>
      (Platform.isLinux || Platform.isWindows || Platform.isMacOS);
  static void log(
    String message, {
    Object? error,
    StackTrace? stackTrace,
  }) {
    dev.log(message, error: error, stackTrace: stackTrace);
  }

  static const JsonEncoder encoder = JsonEncoder.withIndent('  ');

  static String _parseJson(dynamic json) {
    try {
      return encoder.convert(json);
    } catch (exception) {
      return json.toString();
    }
  }

  static dynamic _decodeJson(dynamic body) {
    try {
      return json.decode(body as String);
    } catch (exception) {
      return body;
    }
  }

  static String formatBody(dynamic body, String? contentType) {
    try {
      if (body == null) {
        return 'Empty';
      }

      var bodyContent = 'Empty';

      if (contentType == null ||
          !contentType.toLowerCase().contains('application/json')) {
        final bodyTemp = body.toString();

        if (bodyTemp.isNotEmpty) {
          bodyContent = bodyTemp;
        }
      } else {
        if (body is String && body.contains("\n")) {
          bodyContent = body;
        } else {
          if (body is String) {
            if (body.isNotEmpty) {
              //body is minified json, so decode it to a map and let the encoder pretty print this map
              bodyContent = jsonDecode(_decodeJson(body));
            }
          } else if (body is Stream) {
            bodyContent = 'stream';
          } else {
            bodyContent = _parseJson(body);
          }
        }
      }

      return bodyContent;
    } catch (exception) {
      return 'Failed$body';
    }
  }
}
