import 'dart:convert';

import 'package:equatable/equatable.dart';

/// What part of a network call a breakpoint condition inspects.
enum InfospectBreakpointMatchTarget {
  /// Query / URL parameter (`key` required).
  queryParam,

  /// Request header (`key` required).
  requestHeader,

  /// Raw request body text (no `key`).
  requestBodyText,

  /// JSON request body at dotted path (`key` = path, e.g. `user.id`).
  requestBodyJson,

  /// HTTP response status code (no `key`; `value` is `200` or `200-299`).
  responseStatus,

  /// Raw response body text (no `key`).
  responseBodyText,

  /// JSON response body at dotted path (`key` = path).
  responseBodyJson,
}

/// How a condition compares the observed value.
enum InfospectBreakpointMatchOp {
  /// Key / JSON path exists (value ignored).
  exists,

  /// Exact string equality (case-sensitive for bodies/params; status is numeric).
  equals,

  /// Case-sensitive substring / containment.
  contains,

  /// Status code inclusive range; [InfospectBreakpointCondition.value] like `200-299`.
  inRange,
}

/// One AND-combined filter on top of endpoint / method matching.
class InfospectBreakpointCondition extends Equatable {
  const InfospectBreakpointCondition({
    required this.id,
    required this.target,
    required this.op,
    this.key,
    this.value,
  });

  final String id;
  final InfospectBreakpointMatchTarget target;
  final InfospectBreakpointMatchOp op;

  /// Param name, header name, or JSON path. Unused for status / body-text.
  final String? key;

  /// Expected value, substring, or status / range (`404`, `500-599`).
  final String? value;

  bool get isResponseOnly =>
      target == InfospectBreakpointMatchTarget.responseStatus ||
      target == InfospectBreakpointMatchTarget.responseBodyText ||
      target == InfospectBreakpointMatchTarget.responseBodyJson;

  InfospectBreakpointCondition copyWith({
    String? id,
    InfospectBreakpointMatchTarget? target,
    InfospectBreakpointMatchOp? op,
    String? key,
    String? value,
    bool clearKey = false,
    bool clearValue = false,
  }) {
    return InfospectBreakpointCondition(
      id: id ?? this.id,
      target: target ?? this.target,
      op: op ?? this.op,
      key: clearKey ? null : (key ?? this.key),
      value: clearValue ? null : (value ?? this.value),
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'target': target.name,
      'op': op.name,
      'key': key,
      'value': value,
    };
  }

  factory InfospectBreakpointCondition.fromMap(Map<String, dynamic> map) {
    return InfospectBreakpointCondition(
      id: map['id'] as String? ?? 'cond_${map.hashCode}',
      target: InfospectBreakpointMatchTarget.values.firstWhere(
        (e) => e.name == map['target'],
        orElse: () => InfospectBreakpointMatchTarget.requestBodyText,
      ),
      op: InfospectBreakpointMatchOp.values.firstWhere(
        (e) => e.name == map['op'],
        orElse: () => InfospectBreakpointMatchOp.contains,
      ),
      key: map['key'] as String?,
      value: map['value'] as String?,
    );
  }

  /// Human-readable summary for list chips.
  String get summary {
    final k = key?.trim();
    final v = value?.trim();
    final targetLabel = switch (target) {
      InfospectBreakpointMatchTarget.queryParam => 'query',
      InfospectBreakpointMatchTarget.requestHeader => 'req header',
      InfospectBreakpointMatchTarget.requestBodyText => 'req body',
      InfospectBreakpointMatchTarget.requestBodyJson => 'req json',
      InfospectBreakpointMatchTarget.responseStatus => 'status',
      InfospectBreakpointMatchTarget.responseBodyText => 'res body',
      InfospectBreakpointMatchTarget.responseBodyJson => 'res json',
    };
    final opLabel = switch (op) {
      InfospectBreakpointMatchOp.exists => 'exists',
      InfospectBreakpointMatchOp.equals => '=',
      InfospectBreakpointMatchOp.contains => 'contains',
      InfospectBreakpointMatchOp.inRange => 'in',
    };
    if (op == InfospectBreakpointMatchOp.exists) {
      return '$targetLabel ${k ?? '?'} exists';
    }
    if (k != null && k.isNotEmpty) {
      return '$targetLabel $k $opLabel ${v ?? ''}';
    }
    return '$targetLabel $opLabel ${v ?? ''}';
  }

  @override
  List<Object?> get props => [id, target, op, key, value];
}

/// Snapshot used when evaluating breakpoint conditions.
class InfospectBreakpointMatchContext {
  const InfospectBreakpointMatchContext({
    required this.method,
    required this.endpoint,
    this.queryParameters = const <String, dynamic>{},
    this.requestHeaders = const <String, dynamic>{},
    this.requestBody,
    this.statusCode,
    this.responseBody,
    this.responseHeaders = const <String, dynamic>{},
    this.isResponsePhase = false,
  });

  final String method;
  final String endpoint;
  final Map<String, dynamic> queryParameters;
  final Map<String, dynamic> requestHeaders;
  final dynamic requestBody;
  final int? statusCode;
  final dynamic responseBody;
  final Map<String, dynamic> responseHeaders;
  final bool isResponsePhase;
}

/// Evaluates a single condition against [context].
bool evaluateBreakpointCondition(
  InfospectBreakpointCondition condition,
  InfospectBreakpointMatchContext context,
) {
  if (condition.isResponseOnly && !context.isResponsePhase) {
    // Response-only filters do not block request-phase matching.
    return true;
  }

  switch (condition.target) {
    case InfospectBreakpointMatchTarget.queryParam:
      return _matchMapEntry(
        context.queryParameters,
        condition,
        caseInsensitiveKey: true,
      );
    case InfospectBreakpointMatchTarget.requestHeader:
      return _matchMapEntry(
        context.requestHeaders,
        condition,
        caseInsensitiveKey: true,
      );
    case InfospectBreakpointMatchTarget.requestBodyText:
      return _matchText(
        _asSearchText(context.requestBody),
        condition,
      );
    case InfospectBreakpointMatchTarget.requestBodyJson:
      return _matchJsonPath(context.requestBody, condition);
    case InfospectBreakpointMatchTarget.responseStatus:
      return _matchStatus(context.statusCode, condition);
    case InfospectBreakpointMatchTarget.responseBodyText:
      return _matchText(
        _asSearchText(context.responseBody),
        condition,
      );
    case InfospectBreakpointMatchTarget.responseBodyJson:
      return _matchJsonPath(context.responseBody, condition);
  }
}

bool _matchMapEntry(
  Map<String, dynamic> source,
  InfospectBreakpointCondition condition, {
  required bool caseInsensitiveKey,
}) {
  final key = condition.key?.trim() ?? '';
  if (key.isEmpty) return false;

  String? resolvedKey;
  for (final entry in source.entries) {
    if (caseInsensitiveKey
        ? entry.key.toLowerCase() == key.toLowerCase()
        : entry.key == key) {
      resolvedKey = entry.key;
      break;
    }
  }

  if (condition.op == InfospectBreakpointMatchOp.exists) {
    return resolvedKey != null;
  }
  if (resolvedKey == null) return false;

  final observed = _stringify(source[resolvedKey]);
  final expected = condition.value ?? '';
  return switch (condition.op) {
    InfospectBreakpointMatchOp.equals => observed == expected,
    InfospectBreakpointMatchOp.contains => observed.contains(expected),
    InfospectBreakpointMatchOp.exists => true,
    InfospectBreakpointMatchOp.inRange => false,
  };
}

bool _matchText(String observed, InfospectBreakpointCondition condition) {
  final expected = condition.value ?? '';
  return switch (condition.op) {
    InfospectBreakpointMatchOp.exists => observed.isNotEmpty,
    InfospectBreakpointMatchOp.equals => observed == expected,
    InfospectBreakpointMatchOp.contains =>
      expected.isEmpty ? true : observed.contains(expected),
    InfospectBreakpointMatchOp.inRange => false,
  };
}

bool _matchJsonPath(dynamic body, InfospectBreakpointCondition condition) {
  final path = condition.key?.trim() ?? '';
  if (path.isEmpty) return false;

  final root = _coerceJson(body);
  if (root == null && condition.op == InfospectBreakpointMatchOp.exists) {
    return false;
  }

  final value = _readJsonPath(root, path);
  if (condition.op == InfospectBreakpointMatchOp.exists) {
    return value != null;
  }
  if (value == null) return false;

  final observed = _stringify(value);
  final expected = condition.value ?? '';
  return switch (condition.op) {
    InfospectBreakpointMatchOp.equals => observed == expected,
    InfospectBreakpointMatchOp.contains => observed.contains(expected),
    InfospectBreakpointMatchOp.exists => true,
    InfospectBreakpointMatchOp.inRange => false,
  };
}

bool _matchStatus(int? status, InfospectBreakpointCondition condition) {
  if (status == null) return false;
  final raw = (condition.value ?? '').trim();
  if (raw.isEmpty) return false;

  if (condition.op == InfospectBreakpointMatchOp.inRange || raw.contains('-')) {
    final parts = raw.split('-');
    if (parts.length != 2) return false;
    final min = int.tryParse(parts[0].trim());
    final max = int.tryParse(parts[1].trim());
    if (min == null || max == null) return false;
    return status >= min && status <= max;
  }

  final expected = int.tryParse(raw);
  if (expected == null) return false;
  return switch (condition.op) {
    InfospectBreakpointMatchOp.equals ||
    InfospectBreakpointMatchOp.contains =>
      status == expected,
    InfospectBreakpointMatchOp.exists => true,
    InfospectBreakpointMatchOp.inRange => false,
  };
}

dynamic _coerceJson(dynamic body) {
  if (body == null) return null;
  if (body is Map || body is List) return body;
  if (body is String) {
    final trimmed = body.trim();
    if (trimmed.isEmpty) return null;
    try {
      return jsonDecode(trimmed);
    } catch (_) {
      return null;
    }
  }
  return null;
}

dynamic _readJsonPath(dynamic root, String path) {
  dynamic current = root;
  for (final segment in path.split('.').where((s) => s.isNotEmpty)) {
    if (current is Map) {
      if (current.containsKey(segment)) {
        current = current[segment];
        continue;
      }
      final asInt = int.tryParse(segment);
      if (asInt != null && current.containsKey(asInt)) {
        current = current[asInt];
        continue;
      }
      return null;
    }
    if (current is List) {
      final index = int.tryParse(segment);
      if (index == null || index < 0 || index >= current.length) return null;
      current = current[index];
      continue;
    }
    return null;
  }
  return current;
}

String _asSearchText(dynamic body) {
  if (body == null) return '';
  if (body is String) return body;
  try {
    return jsonEncode(body);
  } catch (_) {
    return body.toString();
  }
}

String _stringify(dynamic value) {
  if (value == null) return '';
  if (value is String) return value;
  if (value is num || value is bool) return value.toString();
  try {
    return jsonEncode(value);
  } catch (_) {
    return value.toString();
  }
}

/// Operators that make sense for [target] in the editor UI.
List<InfospectBreakpointMatchOp> operatorsForTarget(
  InfospectBreakpointMatchTarget target,
) {
  return switch (target) {
    InfospectBreakpointMatchTarget.responseStatus => const [
        InfospectBreakpointMatchOp.equals,
        InfospectBreakpointMatchOp.inRange,
      ],
    InfospectBreakpointMatchTarget.requestBodyText ||
    InfospectBreakpointMatchTarget.responseBodyText =>
      const [
        InfospectBreakpointMatchOp.contains,
        InfospectBreakpointMatchOp.equals,
      ],
    InfospectBreakpointMatchTarget.queryParam ||
    InfospectBreakpointMatchTarget.requestHeader ||
    InfospectBreakpointMatchTarget.requestBodyJson ||
    InfospectBreakpointMatchTarget.responseBodyJson =>
      const [
        InfospectBreakpointMatchOp.exists,
        InfospectBreakpointMatchOp.equals,
        InfospectBreakpointMatchOp.contains,
      ],
  };
}

String labelForMatchTarget(InfospectBreakpointMatchTarget target) {
  return switch (target) {
    InfospectBreakpointMatchTarget.queryParam => 'Query param',
    InfospectBreakpointMatchTarget.requestHeader => 'Request header',
    InfospectBreakpointMatchTarget.requestBodyText => 'Request body (text)',
    InfospectBreakpointMatchTarget.requestBodyJson => 'Request body (JSON)',
    InfospectBreakpointMatchTarget.responseStatus => 'Response status',
    InfospectBreakpointMatchTarget.responseBodyText => 'Response body (text)',
    InfospectBreakpointMatchTarget.responseBodyJson => 'Response body (JSON)',
  };
}

String labelForMatchOp(InfospectBreakpointMatchOp op) {
  return switch (op) {
    InfospectBreakpointMatchOp.exists => 'Exists',
    InfospectBreakpointMatchOp.equals => 'Equals',
    InfospectBreakpointMatchOp.contains => 'Contains',
    InfospectBreakpointMatchOp.inRange => 'In range',
  };
}

bool matchTargetNeedsKey(InfospectBreakpointMatchTarget target) {
  return target != InfospectBreakpointMatchTarget.requestBodyText &&
      target != InfospectBreakpointMatchTarget.responseBodyText &&
      target != InfospectBreakpointMatchTarget.responseStatus;
}

bool matchOpNeedsValue(InfospectBreakpointMatchOp op) {
  return op != InfospectBreakpointMatchOp.exists;
}
