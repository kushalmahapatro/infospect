import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

({IconData icon, Color color}) getIconAndColor(DiagnosticLevel level) {
  return switch (level) {
    DiagnosticLevel.hidden => (
        icon: Icons.hide_source,
        color: Colors.black.withOpacity(0.6),
      ),
    DiagnosticLevel.fine => (
        icon: Icons.bubble_chart_outlined,
        color: Colors.black.withOpacity(0.6),
      ),
    DiagnosticLevel.debug => (
        icon: Icons.bug_report_outlined,
        color: Colors.black,
      ),
    DiagnosticLevel.info => (
        icon: Icons.info_outline,
        color: Colors.black,
      ),
    DiagnosticLevel.warning => (
        icon: Icons.warning_outlined,
        color: Colors.orange,
      ),
    DiagnosticLevel.hint => (
        icon: Icons.privacy_tip_outlined,
        color: Colors.black.withOpacity(0.6),
      ),
    DiagnosticLevel.summary => (
        icon: Icons.subject,
        color: Colors.black,
      ),
    DiagnosticLevel.error => (
        icon: Icons.error_outlined,
        color: Colors.red,
      ),
    DiagnosticLevel.off => (
        icon: Icons.not_interested_outlined,
        color: Colors.blue,
      ),
  };
}

String? stringifiedLog(dynamic object) {
  if (object == null) return null;
  if (object is String) return object.trim();
  if (object is DiagnosticsNode) return object.toStringDeep();

  try {
    object.toJson();

    dynamic toEncodable(dynamic object) {
      try {
        return object.toJson();
      } catch (_) {
        try {
          return '$object';
        } catch (_) {
          return describeIdentity(object);
        }
      }
    }

    return JsonEncoder.withIndent('  ', toEncodable).convert(object);
  } catch (_) {}

  try {
    return '$object'.trim();
  } catch (_) {
    return describeIdentity(object);
  }
}
