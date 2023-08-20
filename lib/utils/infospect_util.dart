import 'dart:convert';
import 'dart:developer' as dev;
import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:flutter/foundation.dart';
import 'package:infospect/features/network/models/infospect_network_call.dart';
import 'package:infospect/infospect.dart';
import 'package:infospect/utils/extensions/infospect_log/infospect_log_extension.dart';
import 'package:infospect/utils/extensions/infospect_network/network_call_extension.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

typedef ShareFileData = ({
  RandomAccessFile randomAccessFile,
  String path,
  Directory directory
});

enum MainWindowArguments {
  shareNetworkCallLogs,
  shareLogs,
  clearNetworkCallLogs,
  clearLogs,
}

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

    ///package_info_plus [TODO]
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

  static Future<File?> shareLogs() async {
    const String name = 'logs';

    final ShareFileData shareFileData = await _getShareFileData(name);
    for (final InfospectLog item in Infospect.instance.infospectLogger.logs) {
      shareFileData.randomAccessFile.writeStringSync(item.sharableData);
    }
    shareFileData.randomAccessFile.flushSync();
    shareFileData.randomAccessFile.closeSync();
    return await _getCompressedFile(name, shareFileData);
  }

  static Future<File?> shareNetworkCallLogs() async {
    const String name = 'network_calls_log';
    final ShareFileData shareFileData = await _getShareFileData(name);

    for (int i = 1;
        i <= Infospect.instance.networkCallsSubject.value.length;
        i++) {
      final InfospectNetworkCall item =
          Infospect.instance.networkCallsSubject.value.elementAt(i - 1);
      shareFileData.randomAccessFile.writeStringSync(
        '$i:{[${item.method}] -> ${item.uri}}\n'
        '${await item.sharableData}\n',
      );
    }
    shareFileData.randomAccessFile.flushSync();
    shareFileData.randomAccessFile.closeSync();

    return await _getCompressedFile(name, shareFileData);
  }

  /// Compress the file and return the compressed file
  static Future<File?> _getCompressedFile(
      String name, ShareFileData shareFileData) async {
    final String zipFileName = 'infospect_$name.tar.gz';
    final String zipFilePath = join(shareFileData.path, zipFileName);
    if (!shareFileData.directory.existsSync()) {
      return null;
    }

    await TarFileEncoder().tarDirectory(
      shareFileData.directory,
      filename: zipFilePath,
      compression: TarFileEncoder.GZIP,
    );

    return File(zipFilePath);
  }

  /// Get the file to share with the [RandomAccessFile] and the [Directory]
  static Future<ShareFileData> _getShareFileData(String name) async {
    final String path = await getPath();
    final String logsPath = join(path, 'infospect', '$name/');
    final Directory directory = Directory(logsPath);
    if (!directory.existsSync()) {
      directory.createSync(recursive: true);
    }
    final String filePath = join(logsPath, '$name.txt');
    File file;
    if (FileSystemEntity.typeSync(filePath) == FileSystemEntityType.notFound) {
      file = await File(filePath).create();
    } else {
      file = File(filePath);
    }
    final RandomAccessFile randomAccessFile =
        file.openSync(mode: FileMode.writeOnlyAppend);

    return (
      randomAccessFile: randomAccessFile,
      path: path,
      directory: directory
    );
  }

  /// Get the path to store the logs
  static Future<String> getPath() async {
    if (defaultTargetPlatform == TargetPlatform.windows) {
      final Directory internalCacheDirectory =
          await getApplicationSupportDirectory();
      return join(internalCacheDirectory.path, 'infospect');
    } else {
      final Directory internalCacheDirectory = await getTemporaryDirectory();
      return internalCacheDirectory.path;
    }
  }
}
