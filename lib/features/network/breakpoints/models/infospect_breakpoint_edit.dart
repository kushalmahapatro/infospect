import 'package:equatable/equatable.dart';
import 'package:infospect/features/network/breakpoints/models/infospect_breakpoint_session.dart';

/// Stores the original and edited payloads for a single breakpoint phase.
class InfospectBreakpointEdit extends Equatable {
  const InfospectBreakpointEdit({
    required this.original,
    required this.edited,
  });

  final InfospectBreakpointPayload original;
  final InfospectBreakpointPayload edited;

  bool get hasChanges => original != edited;

  bool get urlChanged =>
      original.uri != edited.uri || original.endpoint != edited.endpoint;

  bool get methodChanged => original.method != edited.method;

  bool get queryChanged =>
      !_mapEquals(original.queryParameters, edited.queryParameters);

  bool get headersChanged => !_mapEquals(original.headers, edited.headers);

  bool get bodyChanged => original.body != edited.body;

  bool get statusChanged => original.statusCode != edited.statusCode;

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'original': _payloadToMap(original),
      'edited': _payloadToMap(edited),
    };
  }

  factory InfospectBreakpointEdit.fromMap(Map<String, dynamic> map) {
    return InfospectBreakpointEdit(
      original: _payloadFromMap(
        Map<String, dynamic>.from(map['original'] as Map),
      ),
      edited: _payloadFromMap(
        Map<String, dynamic>.from(map['edited'] as Map),
      ),
    );
  }

  static Map<String, dynamic> _payloadToMap(InfospectBreakpointPayload p) {
    return <String, dynamic>{
      'method': p.method,
      'uri': p.uri,
      'endpoint': p.endpoint,
      'headers': p.headers,
      'queryParameters': p.queryParameters,
      'body': p.body,
      'statusCode': p.statusCode,
    };
  }

  static InfospectBreakpointPayload _payloadFromMap(Map<String, dynamic> map) {
    return InfospectBreakpointPayload(
      method: map['method'] as String? ?? '',
      uri: map['uri'] as String? ?? '',
      endpoint: map['endpoint'] as String? ?? '',
      headers: (map['headers'] as Map?)?.map(
            (key, value) => MapEntry(key.toString(), value?.toString() ?? ''),
          ) ??
          const <String, String>{},
      queryParameters: (map['queryParameters'] as Map?)?.map(
            (key, value) => MapEntry(key.toString(), value?.toString() ?? ''),
          ) ??
          const <String, String>{},
      body: map['body'] as String? ?? '',
      statusCode: map['statusCode'] as int?,
    );
  }

  static bool _mapEquals(Map<String, String> a, Map<String, String> b) {
    if (a.length != b.length) return false;
    for (final entry in a.entries) {
      if (b[entry.key] != entry.value) return false;
    }
    return true;
  }

  @override
  List<Object?> get props => [original, edited];
}
