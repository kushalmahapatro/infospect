import 'dart:convert';

import 'package:infospect/features/network/models/infospect_network_call.dart';
import 'package:infospect/features/network/ui/details/utils/interceptor_details_helper.dart';
import 'package:infospect/utils/extensions/int_extension.dart';
import 'package:infospect/utils/infospect_util.dart';
import 'package:package_info_plus/package_info_plus.dart';

extension NetworkCallExtension on InfospectNetworkCall {
  Future<String> get sharableData async {
    try {
      return await _buildLog() + _buildNetworkCallLog();
    } catch (exception) {
      return "Failed to generate call log";
    }
  }

  Future<String> _buildLog() async {
    final StringBuffer stringBuffer = StringBuffer();
    final packageInfo = await PackageInfo.fromPlatform();
    stringBuffer.write("Infospect - HTTP Inspector\n");
    stringBuffer.write("App name:  ${packageInfo.appName}\n");
    stringBuffer.write("Package: ${packageInfo.packageName}\n");
    stringBuffer.write("Version: ${packageInfo.version}\n");
    stringBuffer.write("Build number: ${packageInfo.buildNumber}\n");
    stringBuffer.write("Generated: ${DateTime.now().toIso8601String()}\n");
    stringBuffer.write("\n");
    return stringBuffer.toString();
  }

  String _buildNetworkCallLog() {
    const JsonEncoder encoder = JsonEncoder.withIndent('  ');

    final StringBuffer stringBuffer = StringBuffer();
    stringBuffer.write("===========================================\n");
    stringBuffer.write("Id: $id\n");
    stringBuffer.write("============================================\n");
    stringBuffer.write("--------------------------------------------\n");
    stringBuffer.write("General data\n");
    stringBuffer.write("--------------------------------------------\n");
    stringBuffer.write("Server: $server \n");
    stringBuffer.write("Method: $method \n");
    stringBuffer.write("Endpoint: $endpoint \n");
    stringBuffer.write("Client: $client \n");
    stringBuffer.write("Duration ${duration.toReadableTime}\n");
    stringBuffer.write("Completed: ${!loading} \n");
    stringBuffer.write("--------------------------------------------\n");
    stringBuffer.write("Request\n");
    stringBuffer.write("--------------------------------------------\n");
    stringBuffer.write("Request time: ${request!.time}\n");
    stringBuffer.write("Request content type: ${request!.contentType}\n");
    stringBuffer
        .write("Request cookies: ${encoder.convert(request!.cookies)}\n");
    stringBuffer
        .write("Request headers: ${encoder.convert(request!.headers)}\n");
    if (request!.queryParameters.isNotEmpty) {
      stringBuffer.write(
        "Request query params: ${encoder.convert(request!.queryParameters)}\n",
      );
    }
    stringBuffer.write(
      "Request size: ${request!.size.toReadableBytes}\n",
    );
    stringBuffer.write(
      "Request body: ${InfospectUtil.formatBody(request!.body, request!.headers.contentType)}\n",
    );
    stringBuffer.write("--------------------------------------------\n");
    stringBuffer.write("Response\n");
    stringBuffer.write("--------------------------------------------\n");
    stringBuffer.write("Response time: ${response!.time}\n");
    stringBuffer.write("Response status: ${response!.status}\n");
    stringBuffer.write(
      "Response size: ${response!.size.toReadableBytes}\n",
    );
    stringBuffer.write(
      "Response headers: ${jsonEncode(response!.headers)}\n",
    );
    stringBuffer.write(
      "Response body: ${InfospectUtil.formatBody(response!.body, response!.headers.contentType)}\n",
    );
    if (error != null) {
      stringBuffer.write("--------------------------------------------\n");
      stringBuffer.write("Error\n");
      stringBuffer.write("--------------------------------------------\n");
      stringBuffer.write("Error: ${error!.error}\n");
      if (error!.stackTrace != null) {
        stringBuffer.write("Error stacktrace: ${error!.stackTrace}\n");
      }
    }
    stringBuffer.write("--------------------------------------------\n");
    stringBuffer.write("Curl\n");
    stringBuffer.write("--------------------------------------------\n");
    stringBuffer.write(cURL);
    stringBuffer.write("\n");
    stringBuffer.write("==============================================\n");
    stringBuffer.write("\n");

    return stringBuffer.toString();
  }
}
