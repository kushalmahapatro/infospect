import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart';
import 'package:infospect/features/logger/models/infospect_log.dart';
import 'package:infospect/features/network/models/infospect_form_data.dart';
import 'package:infospect/features/network/models/infospect_network_call.dart';
import 'package:infospect/features/network/models/infospect_network_error.dart';
import 'package:infospect/features/network/models/infospect_network_request.dart';
import 'package:infospect/features/network/models/infospect_network_response.dart';
import 'package:infospect/helpers/infospect_helper.dart';

class InfospectHttpClientInterceptor extends BaseClient {
  final Infospect infospect;
  final Client client;

  InfospectHttpClientInterceptor(
      {required this.client, required this.infospect});

  @override
  Future<StreamedResponse> send(BaseRequest request) async {
    StreamedResponse? response;
    List<int>? responseBytes;
    try {
      final InfospectNetworkCall httpCall =
          InfospectNetworkCall(request.hashCode);
      final InfospectNetworkRequest httpRequest = InfospectNetworkRequest();
      final InfospectNetworkResponse httpResponse = InfospectNetworkResponse();
      final InfospectNetworkError httpError = InfospectNetworkError();

      if (request is Request && request.body.isNotEmpty) {
        httpRequest.body = request.body;
        httpRequest.size = request.bodyBytes.length;
      }

      if (request is MultipartRequest) {
        final List<InfospectFormDataFile> files = [];
        final List<InfospectFormDataField> fields = [];
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
        httpRequest.formDataFields = fields;
        httpRequest.formDataFiles = files;
      } else if (request is Request) {
        try {
          if (request.body.isNotEmpty) {
            httpRequest.body = request.body;
          }
        } catch (e) {
          infospect.addLog(InfospectLog(message: 'Error in request.body'));
        }
        httpRequest.size = request.bodyBytes.length;
      }

      httpRequest.headers = request.headers;
      httpRequest.time = DateTime.now();
      httpRequest.contentType = request.headers['content-type'];
      httpRequest.queryParameters = request.url.queryParameters;

      httpCall.request = httpRequest;
      httpCall.method = request.method;
      httpCall.endpoint = request.url.path;
      httpCall.loading = true;
      httpCall.client = client.toString();
      httpCall.server = request.url.origin;
      if (request.url.isScheme('https')) {
        httpCall.secure = true;
      }
      response = await client.send(request).onError((e, st) async {
        httpError.error = e;
        httpError.stackTrace = st;
        httpResponse.time = DateTime.now();
        httpCall.setResponse(httpResponse);
        httpCall.error = httpError;
        httpCall.loading = false;
        httpCall.duration =
            httpResponse.time.difference(httpRequest.time).inMilliseconds;

        infospect.addHttpCall(httpCall);
        return StreamedResponse(ByteStream.fromBytes([]), 500);
      });
      if (request is Request || request is MultipartRequest) {
        responseBytes = await response.stream.toBytes();
        try {
          httpResponse.body = utf8.decode(responseBytes);
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
        httpResponse.size = responseBytes.length;
        httpResponse.headers = response.headers;
        httpResponse.status = response.statusCode;
        httpResponse.time = DateTime.now();
        httpCall.setResponse(httpResponse);
        httpCall.loading = false;
        httpCall.duration =
            httpResponse.time.difference(httpRequest.time).inMilliseconds;

        infospect.addHttpCall(httpCall);

        return StreamedResponse(
          ByteStream.fromBytes(responseBytes),
          response.statusCode,
          contentLength: response.contentLength,
          request: request,
          headers: response.headers,
          isRedirect: response.isRedirect,
          persistentConnection: response.persistentConnection,
          reasonPhrase: response.reasonPhrase,
        );
      }
      return response;
    } catch (e, st) {
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
          request: request,
          headers: response.headers,
          isRedirect: response.isRedirect,
          persistentConnection: response.persistentConnection,
          reasonPhrase: response.reasonPhrase,
        );
      }
      return client.send(request);
    }
  }
}
