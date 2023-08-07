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
          client: client.toString(),
          server: request.url.origin,
          uri: request.url.toString(),
          secure: request.url.isScheme('https'),
        ),
      );
      response = await client.send(request).onError((e, st) async {
        InfospectNetworkResponse httpResponse =
            InfospectNetworkResponse(status: -1);

        infospect.addResponse(httpResponse, request.hashCode);
        infospect.addError(
            InfospectNetworkError(error: e, stackTrace: st), request.hashCode);

        return StreamedResponse(ByteStream.fromBytes([]), 500);
      });
      InfospectNetworkResponse httpResponse = InfospectNetworkResponse();

      if (request is Request || request is MultipartRequest) {
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

        infospect.addResponse(
          httpResponse.copyWith(
            size: responseBytes.length,
            headers: response.headers,
            status: response.statusCode,
            body: responseBody,
          ),
          request.hashCode,
        );

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
