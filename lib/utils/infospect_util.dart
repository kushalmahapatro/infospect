import 'dart:convert';
import 'dart:developer' as dev;
import 'dart:io';

import 'package:infospect/features/logger/models/infospect_log.dart';
import 'package:infospect/infospect.dart';
import 'package:package_info_plus/package_info_plus.dart';

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

  static Future<void> addAppLaunchLog() async {
    final StringBuffer stringBuffer = StringBuffer();
    final packageInfo = await PackageInfo.fromPlatform();
    stringBuffer.write("App name:  ${packageInfo.appName}\n");
    stringBuffer.write("Package: ${packageInfo.packageName}\n");
    stringBuffer.write("Version: ${packageInfo.version}\n");
    stringBuffer.write("Build number: ${packageInfo.buildNumber}\n");
    stringBuffer.write("Started at: ${DateTime.now().toIso8601String()}\n");
    stringBuffer.write("\n");

    Infospect.instance.addLog(
      InfospectLog(
        message: 'APP STARTED',
        stackTrace: StackTrace.fromString(
          stringBuffer.toString(),
        ),
      ),
    );
  }
}
