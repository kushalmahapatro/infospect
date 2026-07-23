import 'package:equatable/equatable.dart';

/// Whether the intercept is pausing a request or a response.
enum InfospectBreakpointPhase { request, response }

/// Editable snapshot shown in the breakpoint dialog / window.
class InfospectBreakpointPayload extends Equatable {
  final String method;
  final String uri;
  final String endpoint;
  final Map<String, String> headers;
  final Map<String, String> queryParameters;
  final String body;

  /// Response status code (only meaningful for [InfospectBreakpointPhase.response]).
  final int? statusCode;

  const InfospectBreakpointPayload({
    required this.method,
    required this.uri,
    required this.endpoint,
    this.headers = const <String, String>{},
    this.queryParameters = const <String, String>{},
    this.body = '',
    this.statusCode,
  });

  InfospectBreakpointPayload copyWith({
    String? method,
    String? uri,
    String? endpoint,
    Map<String, String>? headers,
    Map<String, String>? queryParameters,
    String? body,
    int? statusCode,
    bool clearStatusCode = false,
  }) {
    return InfospectBreakpointPayload(
      method: method ?? this.method,
      uri: uri ?? this.uri,
      endpoint: endpoint ?? this.endpoint,
      headers: headers ?? this.headers,
      queryParameters: queryParameters ?? this.queryParameters,
      body: body ?? this.body,
      statusCode: clearStatusCode ? null : (statusCode ?? this.statusCode),
    );
  }

  @override
  List<Object?> get props => [
        method,
        uri,
        endpoint,
        headers,
        queryParameters,
        body,
        statusCode,
      ];
}

/// Result returned when the user finishes (or dismisses) a breakpoint editor.
class InfospectBreakpointResult {
  /// When true, the call should be cancelled instead of continuing.
  final bool aborted;

  /// Edited payload to apply when [aborted] is false.
  final InfospectBreakpointPayload payload;

  const InfospectBreakpointResult({
    required this.aborted,
    required this.payload,
  });

  factory InfospectBreakpointResult.continueWith(
    InfospectBreakpointPayload payload,
  ) {
    return InfospectBreakpointResult(aborted: false, payload: payload);
  }

  factory InfospectBreakpointResult.abort(InfospectBreakpointPayload payload) {
    return InfospectBreakpointResult(aborted: true, payload: payload);
  }
}
