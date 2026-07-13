import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:infospect/features/network/breakpoints/models/infospect_breakpoint_session.dart';
import 'package:infospect/features/network/breakpoints/models/infospect_network_breakpoint.dart';

/// Manages breakpoint rules and resolves the first matching rule for a call.
class InfospectBreakpointManager {
  InfospectBreakpointManager();

  final ValueNotifier<List<InfospectNetworkBreakpoint>> breakpoints =
      ValueNotifier<List<InfospectNetworkBreakpoint>>(
    <InfospectNetworkBreakpoint>[],
  );

  /// Pending intercept sessions waiting for user action (debug / UI).
  final ValueNotifier<int> pendingCount = ValueNotifier<int>(0);

  final Map<String, Completer<InfospectBreakpointResult>> _pending =
      <String, Completer<InfospectBreakpointResult>>{};

  List<InfospectNetworkBreakpoint> get rules =>
      List<InfospectNetworkBreakpoint>.unmodifiable(breakpoints.value);

  void addBreakpoint(InfospectNetworkBreakpoint breakpoint) {
    breakpoints.value = [...breakpoints.value, breakpoint];
  }

  void updateBreakpoint(InfospectNetworkBreakpoint breakpoint) {
    final next = List<InfospectNetworkBreakpoint>.from(breakpoints.value);
    final index = next.indexWhere((b) => b.id == breakpoint.id);
    if (index == -1) {
      next.add(breakpoint);
    } else {
      next[index] = breakpoint;
    }
    breakpoints.value = next;
  }

  void removeBreakpoint(String id) {
    breakpoints.value =
        breakpoints.value.where((b) => b.id != id).toList(growable: false);
  }

  void clearBreakpoints() {
    breakpoints.value = <InfospectNetworkBreakpoint>[];
  }

  void setEnabled(String id, bool enabled) {
    final next = breakpoints.value
        .map((b) => b.id == id ? b.copyWith(enabled: enabled) : b)
        .toList(growable: false);
    breakpoints.value = next;
  }

  /// Returns the first enabled rule that matches the request.
  InfospectNetworkBreakpoint? findMatch({
    required String method,
    required String endpoint,
  }) {
    for (final rule in breakpoints.value) {
      if (rule.matches(requestMethod: method, requestEndpoint: endpoint)) {
        return rule;
      }
    }
    return null;
  }

  /// Creates a pending session completer tracked by [sessionId].
  Completer<InfospectBreakpointResult> registerPending(String sessionId) {
    final completer = Completer<InfospectBreakpointResult>();
    _pending[sessionId] = completer;
    pendingCount.value = _pending.length;
    completer.future.whenComplete(() {
      _pending.remove(sessionId);
      pendingCount.value = _pending.length;
    });
    return completer;
  }

  bool completePending(String sessionId, InfospectBreakpointResult result) {
    final completer = _pending[sessionId];
    if (completer == null || completer.isCompleted) return false;
    completer.complete(result);
    return true;
  }

  static String newId() =>
      'bp_${DateTime.now().microsecondsSinceEpoch}_${_seq++}';

  static int _seq = 0;

  /// Pretty-prints [body] for the editor when possible.
  static String stringifyBody(dynamic body) {
    if (body == null) return '';
    if (body is String) {
      final trimmed = body.trim();
      if (trimmed.isEmpty) return '';
      try {
        return const JsonEncoder.withIndent('  ').convert(jsonDecode(trimmed));
      } catch (_) {
        return body;
      }
    }
    try {
      return const JsonEncoder.withIndent('  ').convert(body);
    } catch (_) {
      return body.toString();
    }
  }

  /// Parses editor body text back into a JSON value when possible.
  static dynamic parseBody(String body) {
    final trimmed = body.trim();
    if (trimmed.isEmpty) return '';
    try {
      return jsonDecode(trimmed);
    } catch (_) {
      return body;
    }
  }

  static Map<String, String> stringifyMap(Map<String, dynamic>? source) {
    if (source == null || source.isEmpty) return <String, String>{};
    return source.map((key, value) => MapEntry(key, _stringify(value)));
  }

  static String _stringify(dynamic value) {
    if (value == null) return '';
    if (value is String) return value;
    if (value is Iterable && value is! String) {
      return value.map((e) => e?.toString() ?? '').join(', ');
    }
    return value.toString();
  }

  void dispose() {
    for (final completer in _pending.values) {
      if (!completer.isCompleted) {
        completer.completeError(StateError('Breakpoint manager disposed'));
      }
    }
    _pending.clear();
    breakpoints.dispose();
    pendingCount.dispose();
  }
}
