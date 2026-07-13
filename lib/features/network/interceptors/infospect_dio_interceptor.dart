import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:infospect/features/network/breakpoints/infospect_breakpoint_manager.dart';
import 'package:infospect/features/network/models/infospect_form_data.dart';
import 'package:infospect/features/network/models/infospect_network_call.dart';
import 'package:infospect/features/network/models/infospect_network_error.dart';
import 'package:infospect/features/network/models/infospect_network_request.dart';
import 'package:infospect/features/network/models/infospect_network_response.dart';
import 'package:infospect/infospect.dart';

/// `InfospectDioInterceptor` is an implementation of the `InterceptorsWrapper`
/// provided by the `dio` package. This interceptor allows you to monitor and log
/// HTTP requests and responses made using `Dio`.
///
/// The class works with the `Infospect` system to provide detailed logging and
/// insights into the network operations of the application.
///
/// **Usage Example:**
/// ```dart
/// final _dio = Dio(BaseOptions());
/// _dio.interceptors.add(Infospect.instance.dioInterceptor);
/// ```
class InfospectDioInterceptor extends InterceptorsWrapper {
  /// The primary system used for logging and managing network activities.
  final Infospect infospect;

  /// Constructs a new instance of `InfospectDioInterceptor`.
  InfospectDioInterceptor(this.infospect);

  /// Intercepts outgoing HTTP requests made using `Dio`.
  ///
  /// This method logs request details using the `Infospect` system before
  /// the actual request is made. Matching breakpoints can pause the call so
  /// headers / params / body can be edited before the request continues.
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    _onRequest(options, handler);
  }

  Future<void> _onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    try {
      InfospectNetworkCall call = InfospectNetworkCall(options.hashCode);
      InfospectNetworkRequest request = InfospectNetworkRequest();

      final Uri uri = options.uri;

      dynamic loggedBody = '';
      int size = 0;
      List<InfospectFormDataField>? formDataFields;
      List<InfospectFormDataFile>? formDataFiles;
      if (options.data != null) {
        if (options.data is FormData) {
          loggedBody = 'Form data';

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
          loggedBody = options.data;
        }
      }

      request = request.copyWith(
        headers: options.headers,
        contentType: options.contentType.toString(),
        queryParameters: options.queryParameters,
        formDataFields: formDataFields,
        formDataFiles: formDataFiles,
        body: loggedBody is String
            ? loggedBody
            : InfospectBreakpointManager.stringifyBody(loggedBody),
        size: size,
      );

      infospect.addCall(call.copyWith(
        request: request,
        secure: uri.scheme == 'https',
        method: options.method,
        endpoint: options.uri.path,
        server: uri.host,
        client: 'Dio',
        uri: options.uri.toString(),
      ));
    } catch (e, st) {
      infospect.addLog(
        InfospectLog(
          message: e.toString(),
          stackTrace: st,
          error: e,
          level: DiagnosticLevel.error,
        ),
      );
    }

    try {
      final result = await infospect.interceptRequestIfNeeded(
        method: options.method,
        endpoint: options.uri.path,
        uri: options.uri.toString(),
        headers: Map<String, dynamic>.from(options.headers),
        queryParameters: Map<String, dynamic>.from(options.queryParameters),
        body: options.data is FormData ? null : options.data,
      );

      if (result != null) {
        if (result.aborted) {
          handler.reject(
            DioException(
              requestOptions: options,
              type: DioExceptionType.cancel,
              error: 'Request aborted at Infospect breakpoint',
              message: 'Request aborted at Infospect breakpoint',
            ),
          );
          return;
        }
        _applyRequestEdits(options, result.payload);
        _updateLoggedRequest(options.hashCode, result.payload);
      }
    } catch (e, st) {
      infospect.addLog(
        InfospectLog(
          message: 'Breakpoint request intercept failed: $e',
          stackTrace: st,
          error: e,
          level: DiagnosticLevel.error,
        ),
      );
    }

    handler.next(options);
  }

  /// Intercepts the response for an HTTP request made using `Dio`.
  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    _onResponse(response, handler);
  }

  Future<void> _onResponse(
    Response response,
    ResponseInterceptorHandler handler,
  ) async {
    try {
      final result = await infospect.interceptResponseIfNeeded(
        method: response.requestOptions.method,
        endpoint: response.requestOptions.uri.path,
        uri: response.requestOptions.uri.toString(),
        headers: _dioHeadersToMap(response.headers),
        body: response.data,
        statusCode: response.statusCode,
      );

      if (result != null) {
        if (result.aborted) {
          handler.reject(
            DioException(
              requestOptions: response.requestOptions,
              response: response,
              type: DioExceptionType.cancel,
              error: 'Response aborted at Infospect breakpoint',
              message: 'Response aborted at Infospect breakpoint',
            ),
          );
          return;
        }
        _applyResponseEdits(response, result.payload);
      }
    } catch (e, st) {
      infospect.addLog(
        InfospectLog(
          message: 'Breakpoint response intercept failed: $e',
          stackTrace: st,
          error: e,
          level: DiagnosticLevel.error,
        ),
      );
    }

    try {
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
        response.requestOptions.hashCode,
      );
    } catch (e, st) {
      infospect.addLog(
        InfospectLog(
          message: e.toString(),
          stackTrace: st,
          error: e,
          level: DiagnosticLevel.error,
        ),
      );
    }
    handler.next(response);
  }

  /// Intercepts any errors that occur when making an HTTP request using `Dio`.
  @override
  void onError(DioException error, ErrorInterceptorHandler handler) {
    try {
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

      infospect.addError(
        InfospectNetworkError(error: err, stackTrace: st),
        error.requestOptions.hashCode,
      );

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
    } catch (e, st) {
      infospect.addLog(
        InfospectLog(
          message: e.toString(),
          stackTrace: st,
          error: e,
          level: DiagnosticLevel.error,
        ),
      );
    }
    handler.next(error);
  }

  void _applyRequestEdits(
    RequestOptions options,
    InfospectBreakpointPayload payload,
  ) {
    options.headers
      ..clear()
      ..addAll(payload.headers);
    options.queryParameters
      ..clear()
      ..addAll(payload.queryParameters);

    if (options.data is! FormData) {
      options.data = InfospectBreakpointManager.parseBody(payload.body);
      if (options.data is String && (options.data as String).isEmpty) {
        options.data = null;
      }
    }
  }

  void _applyResponseEdits(
    Response response,
    InfospectBreakpointPayload payload,
  ) {
    if (payload.statusCode != null) {
      response.statusCode = payload.statusCode;
    }
    response.data = InfospectBreakpointManager.parseBody(payload.body);

    final headers = Headers();
    payload.headers.forEach((key, value) {
      headers.set(key, value);
    });
    response.headers = headers;
  }

  void _updateLoggedRequest(int requestId, InfospectBreakpointPayload payload) {
    final calls = List<InfospectNetworkCall>.from(
      infospect.networkCallsSubject.value,
    );
    final index = calls.indexWhere((call) => call.id == requestId);
    if (index == -1) return;

    final existing = calls[index];
    final request = existing.request?.copyWith(
          headers: payload.headers,
          queryParameters: payload.queryParameters,
          body: payload.body,
          size: utf8.encode(payload.body).length,
        ) ??
        InfospectNetworkRequest(
          headers: payload.headers,
          queryParameters: payload.queryParameters,
          body: payload.body,
          size: utf8.encode(payload.body).length,
        );

    calls[index] = existing.copyWith(
      request: request,
      uri: payload.uri,
      endpoint: payload.endpoint,
      method: payload.method,
    );
    infospect.networkCallsSubject.add(calls);
  }

  Map<String, dynamic> _dioHeadersToMap(Headers headers) {
    final map = <String, dynamic>{};
    headers.forEach((name, values) {
      map[name] = values.join(', ');
    });
    return map;
  }
}
