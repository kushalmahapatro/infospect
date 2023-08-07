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
    InfospectNetworkCall call = InfospectNetworkCall(options.hashCode);
    InfospectNetworkRequest request = InfospectNetworkRequest();

    final Uri uri = options.uri;

    dynamic body;
    int size = 0;
    List<InfospectFormDataField>? formDataFields;
    List<InfospectFormDataFile>? formDataFiles;
    if (options.data != null) {
      if (options.data is FormData) {
        body += "Form data";

        if (options.data.fields.isNotEmpty == true) {
          final List<InfospectFormDataField> fields = [];
          for (var entry in options.data.fields) {
            fields.add(InfospectFormDataField(entry.key, entry.value));
          }
          formDataFields = fields;
        }
        if (options.data.files.isNotEmpty == true) {
          final List<InfospectFormDataFile> files = [];
          for (var entry in options.data.files) {
            files.add(
              InfospectFormDataFile(
                entry.value.filename,
                entry.value.contentType.toString(),
                entry.value.length,
              ),
            );
          }

          formDataFiles = files;
        }
      } else {
        size = utf8.encode(options.data.toString()).length;
        body = options.data;
      }
    }

    request = request.copyWith(
      headers: options.headers,
      contentType: options.contentType.toString(),
      queryParameters: options.queryParameters,
      formDataFields: formDataFields,
      formDataFiles: formDataFiles,
      body: body,
      size: size,
    );

    infospect.addCall(call.copyWith(
      request: request,
      secure: uri.scheme == "https",
      method: options.method,
      endpoint: options.uri.path,
      server: uri.host,
      client: 'Dio',
      uri: options.uri.toString(),
    ));
    handler.next(options);
  }

  /// Handles dio response and adds data to infospect network call
  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    InfospectNetworkResponse httpResponse = InfospectNetworkResponse();

    dynamic body = '';
    int size = 0;
    if (response.data != null) {
      body = response.data;
      size = utf8.encode(response.data.toString()).length;
    }

    final Map<String, String> headers = {};
    response.headers.forEach((header, values) {
      headers[header] = values.toString();
    });

    infospect.addResponse(
        httpResponse.copyWith(
          status: response.statusCode,
          body: body,
          size: size,
          headers: headers,
        ),
        response.requestOptions.hashCode);
    handler.next(response);
  }

  /// Handles error and adds data to infospect network call
  @override
  void onError(DioError error, ErrorInterceptorHandler handler) {
    InfospectNetworkResponse httpResponse = InfospectNetworkResponse();
    dynamic body = '';
    int size = 0;
    int? status;
    final err = error.toString();
    StackTrace? st;
    if (error is Error) {
      final basicError = error as Error;
      st = basicError.stackTrace;
    }

    infospect.addError(InfospectNetworkError(error: err, stackTrace: st),
        error.requestOptions.hashCode);

    if (error.response == null) {
      status = -1;
      infospect.addResponse(httpResponse, error.requestOptions.hashCode);
    } else {
      status = error.response!.statusCode;

      if (error.response!.data != null) {
        body = error.response!.data;
        size = utf8.encode(error.response!.data.toString()).length;
      }
      final Map<String, String> headers = {};
      error.response!.headers.forEach((header, values) {
        headers[header] = values.toString();
      });

      infospect.addResponse(
        httpResponse.copyWith(
          headers: headers,
          body: body,
          size: size,
          status: status,
        ),
        error.response!.requestOptions.hashCode,
      );
    }
    handler.next(error);
  }
}
