import 'package:equatable/equatable.dart';

/// A Proxyman-style network breakpoint rule.
///
/// When an outgoing request matches [endpoint] (and optionally [method]),
/// Infospect pauses the call so the developer can inspect and edit the
/// request and/or response before it continues to the client.
class InfospectNetworkBreakpoint extends Equatable {
  /// Stable identifier for this rule.
  final String id;

  /// Path (or path pattern) to match, e.g. `/api/users` or `/api/users*`.
  ///
  /// Matching is case-sensitive against the request path. A trailing `*`
  /// means prefix match. Empty or `/` matches every path.
  final String endpoint;

  /// HTTP method to match (e.g. `GET`, `POST`).
  ///
  /// When `null` or empty, any method matches.
  final String? method;

  /// Whether this rule is active.
  final bool enabled;

  /// Pause before the request is sent so headers / params / body can be edited.
  final bool breakOnRequest;

  /// Pause after the response arrives so status / headers / body can be edited.
  final bool breakOnResponse;

  const InfospectNetworkBreakpoint({
    required this.id,
    required this.endpoint,
    this.method,
    this.enabled = true,
    this.breakOnRequest = true,
    this.breakOnResponse = true,
  });

  InfospectNetworkBreakpoint copyWith({
    String? id,
    String? endpoint,
    String? method,
    bool clearMethod = false,
    bool? enabled,
    bool? breakOnRequest,
    bool? breakOnResponse,
  }) {
    return InfospectNetworkBreakpoint(
      id: id ?? this.id,
      endpoint: endpoint ?? this.endpoint,
      method: clearMethod ? null : (method ?? this.method),
      enabled: enabled ?? this.enabled,
      breakOnRequest: breakOnRequest ?? this.breakOnRequest,
      breakOnResponse: breakOnResponse ?? this.breakOnResponse,
    );
  }

  /// Whether [requestMethod] + [requestEndpoint] match this rule.
  bool matches({
    required String requestMethod,
    required String requestEndpoint,
  }) {
    if (!enabled) return false;
    if (!breakOnRequest && !breakOnResponse) return false;

    final methodFilter = method?.trim();
    if (methodFilter != null && methodFilter.isNotEmpty) {
      if (methodFilter.toUpperCase() != requestMethod.toUpperCase()) {
        return false;
      }
    }

    return _endpointMatches(requestEndpoint);
  }

  bool _endpointMatches(String requestEndpoint) {
    final pattern = _normalizePath(endpoint);
    final path = _normalizePath(requestEndpoint);

    if (pattern.isEmpty || pattern == '/') {
      return true;
    }

    if (pattern.endsWith('*')) {
      final prefix = pattern.substring(0, pattern.length - 1);
      return path.startsWith(prefix);
    }

    return path == pattern;
  }

  static String _normalizePath(String value) {
    var path = value.trim();
    if (path.isEmpty) return '/';

    // Strip scheme + host if a full URI was provided.
    if (path.contains('://')) {
      try {
        path = Uri.parse(path).path;
      } catch (_) {
        // Keep raw value.
      }
    }

    if (!path.startsWith('/')) {
      path = '/$path';
    }

    if (path.length > 1 && path.endsWith('/') && !path.endsWith('*/')) {
      path = path.substring(0, path.length - 1);
    }

    return path;
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'endpoint': endpoint,
      'method': method,
      'enabled': enabled,
      'breakOnRequest': breakOnRequest,
      'breakOnResponse': breakOnResponse,
    };
  }

  factory InfospectNetworkBreakpoint.fromMap(Map<String, dynamic> map) {
    return InfospectNetworkBreakpoint(
      id: map['id'] as String,
      endpoint: map['endpoint'] as String? ?? '/',
      method: map['method'] as String?,
      enabled: map['enabled'] as bool? ?? true,
      breakOnRequest: map['breakOnRequest'] as bool? ?? true,
      breakOnResponse: map['breakOnResponse'] as bool? ?? true,
    );
  }

  @override
  List<Object?> get props => [
        id,
        endpoint,
        method,
        enabled,
        breakOnRequest,
        breakOnResponse,
      ];
}
