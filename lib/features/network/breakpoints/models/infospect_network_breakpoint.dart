import 'package:equatable/equatable.dart';
import 'package:infospect/features/network/breakpoints/models/infospect_breakpoint_condition.dart';

/// A Proxyman-style network breakpoint rule.
///
/// When an outgoing call matches [endpoint] / [method] and every entry in
/// [conditions], Infospect pauses the request and/or response for editing.
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

  /// Extra AND-combined filters (query, headers, body, status, …).
  final List<InfospectBreakpointCondition> conditions;

  const InfospectNetworkBreakpoint({
    required this.id,
    required this.endpoint,
    this.method,
    this.enabled = true,
    this.breakOnRequest = true,
    this.breakOnResponse = true,
    this.conditions = const <InfospectBreakpointCondition>[],
  });

  InfospectNetworkBreakpoint copyWith({
    String? id,
    String? endpoint,
    String? method,
    bool clearMethod = false,
    bool? enabled,
    bool? breakOnRequest,
    bool? breakOnResponse,
    List<InfospectBreakpointCondition>? conditions,
  }) {
    return InfospectNetworkBreakpoint(
      id: id ?? this.id,
      endpoint: endpoint ?? this.endpoint,
      method: clearMethod ? null : (method ?? this.method),
      enabled: enabled ?? this.enabled,
      breakOnRequest: breakOnRequest ?? this.breakOnRequest,
      breakOnResponse: breakOnResponse ?? this.breakOnResponse,
      conditions: conditions ?? this.conditions,
    );
  }

  /// Whether this rule matches [context] for the current intercept phase.
  ///
  /// Response-only conditions (status / response body) do not pause at the
  /// request phase: a rule that only constrains the response is evaluated
  /// again when the response arrives.
  bool matches(InfospectBreakpointMatchContext context) {
    if (!enabled) return false;
    if (!breakOnRequest && !breakOnResponse) return false;

    final methodFilter = method?.trim();
    if (methodFilter != null && methodFilter.isNotEmpty) {
      if (methodFilter.toUpperCase() != context.method.toUpperCase()) {
        return false;
      }
    }

    if (!_endpointMatches(context.endpoint)) return false;

    if (conditions.isEmpty) return true;

    if (!context.isResponsePhase) {
      final requestConditions = conditions
          .where((c) => !c.isResponseOnly)
          .toList(growable: false);
      final hasResponseOnly = conditions.any((c) => c.isResponseOnly);
      if (requestConditions.isEmpty && hasResponseOnly) {
        return false;
      }
      for (final condition in requestConditions) {
        if (!evaluateBreakpointCondition(condition, context)) {
          return false;
        }
      }
      return true;
    }

    for (final condition in conditions) {
      if (!evaluateBreakpointCondition(condition, context)) {
        return false;
      }
    }
    return true;
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
      'conditions': conditions.map((c) => c.toMap()).toList(growable: false),
    };
  }

  factory InfospectNetworkBreakpoint.fromMap(Map<String, dynamic> map) {
    final rawConditions = map['conditions'];
    return InfospectNetworkBreakpoint(
      id: map['id'] as String,
      endpoint: map['endpoint'] as String? ?? '/',
      method: map['method'] as String?,
      enabled: map['enabled'] as bool? ?? true,
      breakOnRequest: map['breakOnRequest'] as bool? ?? true,
      breakOnResponse: map['breakOnResponse'] as bool? ?? true,
      conditions: rawConditions is List
          ? rawConditions
              .whereType<Map>()
              .map(
                (e) => InfospectBreakpointCondition.fromMap(
                  Map<String, dynamic>.from(e),
                ),
              )
              .toList(growable: false)
          : const <InfospectBreakpointCondition>[],
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
        conditions,
      ];
}
