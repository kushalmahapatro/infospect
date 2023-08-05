import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:infospect/features/network/models/infospect_form_data.dart';
import 'package:infospect/features/network/models/infospect_network_call.dart';
import 'package:infospect/features/network/models/infospect_network_error.dart';
import 'package:infospect/features/network/models/infospect_network_request.dart';
import 'package:infospect/features/network/models/infospect_network_response.dart';
import 'package:infospect/infospect.dart';

class InfospectDioInterceptor extends InterceptorsWrapper {
  final Infospect infospect;

  /// Creates dio interceptor
  InfospectDioInterceptor(this.infospect);

  /// Handles dio request and creates infospect network call based on it
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final InfospectNetworkCall call = InfospectNetworkCall(options.hashCode);

    final Uri uri = options.uri;
    call.method = options.method;
    var path = options.uri.path;
    if (path.isEmpty) {
      path = "/";
    }
    call.endpoint = path;
    call.server = uri.host;
    call.client = "Dio";
    call.uri = options.uri.toString();

    if (uri.scheme == "https") {
      call.secure = true;
    }

    final InfospectNetworkRequest request = InfospectNetworkRequest();

    final dynamic data = options.data;
    if (data == null) {
      request.size = 0;
      request.body = "";
    } else {
      if (data is FormData) {
        request.body += "Form data";

        if (data.fields.isNotEmpty == true) {
          final List<InfospectFormDataField> fields = [];
          for (var entry in data.fields) {
            fields.add(InfospectFormDataField(entry.key, entry.value));
          }
          request.formDataFields = fields;
        }
        if (data.files.isNotEmpty == true) {
          final List<InfospectFormDataFile> files = [];
          for (var entry in data.files) {
            files.add(
              InfospectFormDataFile(
                entry.value.filename,
                entry.value.contentType.toString(),
                entry.value.length,
              ),
            );
          }

          request.formDataFiles = files;
        }
      } else {
        request.size = utf8.encode(data.toString()).length;
        request.body = data;
      }
    }

    request.time = DateTime.now();
    request.headers = options.headers;
    request.contentType = options.contentType.toString();
    request.queryParameters = options.queryParameters;

    call.request = request;
    call.response = InfospectNetworkResponse();

    infospect.addCall(call);
    handler.next(options);
  }

  /// Handles dio response and adds data to infospect network call
  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    final httpResponse = InfospectNetworkResponse();
    httpResponse.status = response.statusCode;

    if (response.data == null) {
      httpResponse.body = "";
      httpResponse.size = 0;
    } else {
      httpResponse.body = response.data;
      httpResponse.size = utf8.encode(response.data.toString()).length;
    }

    httpResponse.time = DateTime.now();
    final Map<String, String> headers = {};
    response.headers.forEach((header, values) {
      headers[header] = values.toString();
    });
    httpResponse.headers = headers;

    infospect.addResponse(httpResponse, response.requestOptions.hashCode);
    handler.next(response);
  }

  /// Handles error and adds data to infospect network call
  @override
  void onError(DioError error, ErrorInterceptorHandler handler) {
    final httpError = InfospectNetworkError();
    httpError.error = error.toString();
    if (error is Error) {
      final basicError = error as Error;
      httpError.stackTrace = basicError.stackTrace;
    }

    infospect.addError(httpError, error.requestOptions.hashCode);
    final httpResponse = InfospectNetworkResponse();
    httpResponse.time = DateTime.now();
    if (error.response == null) {
      httpResponse.status = -1;
      infospect.addResponse(httpResponse, error.requestOptions.hashCode);
    } else {
      httpResponse.status = error.response!.statusCode;

      if (error.response!.data == null) {
        httpResponse.body = "";
        httpResponse.size = 0;
      } else {
        httpResponse.body = error.response!.data;
        httpResponse.size = utf8.encode(error.response!.data.toString()).length;
      }
      final Map<String, String> headers = {};
      error.response!.headers.forEach((header, values) {
        headers[header] = values.toString();
      });
      httpResponse.headers = headers;
      infospect.addResponse(
        httpResponse,
        error.response!.requestOptions.hashCode,
      );
    }
    handler.next(error);
  }
}
