import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart';
import 'package:infospect/features/logger/models/infospect_log.dart';
import 'package:infospect/features/network/breakpoints/infospect_breakpoint_manager.dart';
import 'package:infospect/features/network/breakpoints/models/infospect_breakpoint_edit.dart';
import 'package:infospect/features/network/breakpoints/models/infospect_breakpoint_session.dart';
import 'package:infospect/features/network/models/infospect_form_data.dart';
import 'package:infospect/features/network/models/infospect_network_call.dart';
import 'package:infospect/features/network/models/infospect_network_error.dart';
import 'package:infospect/features/network/models/infospect_network_request.dart';
import 'package:infospect/features/network/models/infospect_network_response.dart';
import 'package:infospect/helpers/infospect_helper.dart';

/// `InfospectHttpClientInterceptor` provides a mechanism to intercept and
/// monitor HTTP requests and their responses within a Flutter application.
/// This class is an integral part of the `Infospect` toolset, providing detailed
/// insights into the network operations of the application.
///
/// **Example Usage:**
/// ```dart
/// final http.Client client = http.Client();
/// client = Infospect.instance.httpClientInterceptor(client: client);
/// ```
class InfospectHttpClientInterceptor extends BaseClient {
  final Infospect infospect;
  final Client client;

  /// Constructs a new instance of `InfospectHttpClientInterceptor`.
  ///
  /// The [client] is the original HTTP client that the application would
  /// typically use to make network requests.
  ///
  /// The [infospect] is the primary system that manages and logs network activities.
  InfospectHttpClientInterceptor({
    required this.client,
    required this.infospect,
  });

  /// Intercepts outgoing HTTP requests made using the provided [client].
  ///
  /// Matching breakpoints can pause the call so headers / params / body can
  /// be edited before the request is sent, and again when the response arrives.
  @override
  Future<StreamedResponse> send(BaseRequest request) async {
    StreamedResponse? response;
    List<int>? responseBytes;
    BaseRequest outgoing = request;

    try {
      InfospectNetworkCall httpCall = InfospectNetworkCall(request.hashCode);
      InfospectNetworkRequest httpRequest = InfospectNetworkRequest();
      dynamic requestBody = '';
      int requestSize = 0;
      final List<InfospectFormDataFile> files = [];
      final List<InfospectFormDataField> fields = [];

      if (request is Request && request.body.isNotEmpty) {
        requestBody = request.body;
        requestSize = request.bodyBytes.length;
      }

      if (request is MultipartRequest) {
        request.fields.forEach((key, value) {
          fields.add(InfospectFormDataField(key, value));
        });

        for (final entry in request.files) {
          files.add(
            InfospectFormDataFile(
              entry.filename,
              entry.contentType.toString(),
              entry.length,
            ),
          );
        }
      } else if (request is Request) {
        try {
          if (request.body.isNotEmpty) {
            requestBody = request.body;
          }
        } catch (e) {
          infospect.addLog(InfospectLog(message: 'Error in request.body'));
        }
        requestSize = request.bodyBytes.length;
      }

      httpRequest = httpRequest.copyWith(
        body: requestBody,
        size: requestSize,
        formDataFields: fields,
        formDataFiles: files,
        headers: request.headers,
        contentType: request.headers['content-type'],
        queryParameters: request.url.queryParameters,
      );

      infospect.addCall(
        httpCall.copyWith(
          request: httpRequest,
          method: request.method,
          endpoint: request.url.path,
          loading: true,
          client: client.runtimeType.toString(),
          server: request.url.origin,
          uri: request.url.toString(),
          secure: request.url.isScheme('https'),
        ),
      );

      final requestResult = await infospect.interceptRequestIfNeeded(
        method: request.method,
        endpoint: request.url.path,
        uri: request.url.toString(),
        headers: Map<String, dynamic>.from(request.headers),
        queryParameters: Map<String, dynamic>.from(request.url.queryParameters),
        body: request is Request ? request.body : null,
        requestId: request.hashCode,
      );

      if (requestResult != null) {
        if (requestResult.aborted) {
          infospect.addError(
            InfospectNetworkError(
              error: 'Request aborted at Infospect breakpoint',
            ),
            request.hashCode,
          );
          infospect.addResponse(
            InfospectNetworkResponse(status: -1),
            request.hashCode,
          );
          throw ClientException(
            'Request aborted at Infospect breakpoint',
            request.url,
          );
        }
        final original = InfospectBreakpointPayload(
          method: request.method,
          uri: request.url.toString(),
          endpoint: request.url.path,
          headers: InfospectBreakpointManager.stringifyMap(
            Map<String, dynamic>.from(request.headers),
          ),
          queryParameters: InfospectBreakpointManager.stringifyMap(
            Map<String, dynamic>.from(request.url.queryParameters),
          ),
          body: request is Request ? request.body : '',
        );
        final edited = _withRebuiltUri(requestResult.payload, original.uri);
        outgoing = _applyRequestEdits(request, edited);
        infospect.applyRequestBreakpointEdit(
          requestId: request.hashCode,
          edit: InfospectBreakpointEdit(original: original, edited: edited),
        );
      }

      response = await client.send(outgoing).onError((e, st) async {
        InfospectNetworkResponse httpResponse =
            InfospectNetworkResponse(status: -1);

        infospect.addResponse(httpResponse, request.hashCode);
        infospect.addError(
          InfospectNetworkError(error: e, stackTrace: st),
          request.hashCode,
        );

        return StreamedResponse(ByteStream.fromBytes([]), 500);
      });

      InfospectNetworkResponse httpResponse = InfospectNetworkResponse();

      if (outgoing is Request || outgoing is MultipartRequest) {
        dynamic responseBody = '';

        responseBytes = await response.stream.toBytes();
        try {
          responseBody = utf8.decode(responseBytes);
        } catch (e, st) {
          infospect.addLog(
            InfospectLog(
              message: 'Error while decoding response bytes',
              error: e.toString(),
              stackTrace: st,
              level: DiagnosticLevel.error,
            ),
          );
        }

        var statusCode = response.statusCode;
        var responseHeaders = Map<String, String>.from(response.headers);
        var finalBody = responseBody;
        var finalBytes = responseBytes;

        final originalResponse = InfospectBreakpointPayload(
          method: outgoing.method,
          uri: outgoing.url.toString(),
          endpoint: outgoing.url.path,
          headers: Map<String, String>.from(responseHeaders),
          body: responseBody is String
              ? responseBody
              : InfospectBreakpointManager.stringifyBody(responseBody),
          statusCode: statusCode,
        );

        final responseResult = await infospect.interceptResponseIfNeeded(
          method: outgoing.method,
          endpoint: outgoing.url.path,
          uri: outgoing.url.toString(),
          headers: Map<String, dynamic>.from(responseHeaders),
          body: responseBody,
          statusCode: statusCode,
          requestId: request.hashCode,
          requestHeaders: Map<String, dynamic>.from(outgoing.headers),
          queryParameters:
              Map<String, dynamic>.from(outgoing.url.queryParameters),
          requestBody: outgoing is Request ? outgoing.body : null,
        );

        if (responseResult != null) {
          if (responseResult.aborted) {
            infospect.addError(
              InfospectNetworkError(
                error: 'Response aborted at Infospect breakpoint',
              ),
              request.hashCode,
            );
            throw ClientException(
              'Response aborted at Infospect breakpoint',
              outgoing.url,
            );
          }

          final edited = responseResult.payload;
          statusCode = edited.statusCode ?? statusCode;
          responseHeaders = Map<String, String>.from(edited.headers);
          finalBody = edited.body;
          finalBytes = utf8.encode(edited.body);
          infospect.applyResponseBreakpointEdit(
            requestId: request.hashCode,
            edit: InfospectBreakpointEdit(
              original: originalResponse,
              edited: edited,
            ),
          );
        }

        infospect.addResponse(
          httpResponse.copyWith(
            size: finalBytes.length,
            headers: responseHeaders,
            status: statusCode,
            body: finalBody,
          ),
          request.hashCode,
        );

        if (statusCode != 200) {
          infospect.addError(
            InfospectNetworkError(
              error: response.reasonPhrase,
              stackTrace: StackTrace.fromString(
                finalBody is String ? finalBody : finalBody.toString(),
              ),
            ),
            request.hashCode,
          );
        }

        return StreamedResponse(
          ByteStream.fromBytes(finalBytes),
          statusCode,
          contentLength: finalBytes.length,
          request: outgoing,
          headers: responseHeaders,
          isRedirect: response.isRedirect,
          persistentConnection: response.persistentConnection,
          reasonPhrase: response.reasonPhrase,
        );
      }
      return response;
    } catch (e, st) {
      if (e is ClientException) {
        rethrow;
      }
      infospect.addLog(
        InfospectLog(
          message: 'Error while intercepting network all',
          error: e.toString(),
          stackTrace: st,
          level: DiagnosticLevel.error,
        ),
      );

      if (response != null) {
        return StreamedResponse(
          ByteStream.fromBytes(responseBytes ?? []),
          response.statusCode,
          contentLength: response.contentLength,
          request: outgoing,
          headers: response.headers,
          isRedirect: response.isRedirect,
          persistentConnection: response.persistentConnection,
          reasonPhrase: response.reasonPhrase,
        );
      }
      return client.send(outgoing);
    }
  }

  BaseRequest _applyRequestEdits(
    BaseRequest original,
    InfospectBreakpointPayload payload,
  ) {
    final uri = original.url.replace(
      queryParameters: payload.queryParameters,
    );

    if (original is Request) {
      final next = Request(original.method, uri)
        ..followRedirects = original.followRedirects
        ..maxRedirects = original.maxRedirects
        ..persistentConnection = original.persistentConnection;
      next.headers.addAll(payload.headers);
      if (payload.body.isNotEmpty) {
        next.body = payload.body;
      }
      return next;
    }

    if (original is MultipartRequest) {
      final next = MultipartRequest(original.method, uri)
        ..followRedirects = original.followRedirects
        ..maxRedirects = original.maxRedirects
        ..persistentConnection = original.persistentConnection
        ..fields.addAll(original.fields)
        ..files.addAll(original.files);
      next.headers.clear();
      next.headers.addAll(payload.headers);
      return next;
    }

    original.headers
      ..clear()
      ..addAll(payload.headers);
    return original;
  }

  InfospectBreakpointPayload _withRebuiltUri(
    InfospectBreakpointPayload payload,
    String originalUri,
  ) {
    try {
      final rebuilt = Uri.parse(originalUri).replace(
        queryParameters:
            payload.queryParameters.isEmpty ? null : payload.queryParameters,
      );
      return payload.copyWith(
        uri: rebuilt.toString(),
        endpoint: rebuilt.path.isEmpty ? payload.endpoint : rebuilt.path,
      );
    } catch (_) {
      return payload;
    }
  }
}
