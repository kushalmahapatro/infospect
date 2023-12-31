import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Retrieves the corresponding [IconData] and [Color] based on the given
/// [DiagnosticLevel].
///
/// The method uses the theme data provided by the `BuildContext` to determine
/// the appropriate icon and color values for each diagnostic level.
///
/// - [level]: The `DiagnosticLevel` which determines the output icon and color.
/// - [context]: The build context which is used to obtain theme information.
///
/// **Returns:** A tuple containing the corresponding icon and color for the given level.
///
/// **Example usage:**
/// ```dart
/// final result = getIconAndColor(DiagnosticLevel.warning, context);
/// Icon icon = Icon(result.icon, color: result.color);
/// ```
({IconData icon, Color color}) getIconAndColor(
    DiagnosticLevel level, BuildContext context) {
  final ColorScheme colorScheme = Theme.of(context).colorScheme;
  return switch (level) {
    DiagnosticLevel.hidden => (
        icon: Icons.hide_source,
        color: colorScheme.onSurface.withOpacity(0.6),
      ),
    DiagnosticLevel.fine => (
        icon: Icons.bubble_chart_outlined,
        color: colorScheme.onSurface.withOpacity(0.6),
      ),
    DiagnosticLevel.debug => (
        icon: Icons.bug_report_outlined,
        color: colorScheme.onSurface,
      ),
    DiagnosticLevel.info => (
        icon: Icons.info_outline,
        color: colorScheme.onSurface,
      ),
    DiagnosticLevel.warning => (
        icon: Icons.warning_outlined,
        color: Colors.orange,
      ),
    DiagnosticLevel.hint => (
        icon: Icons.privacy_tip_outlined,
        color: colorScheme.onSurface.withOpacity(0.6),
      ),
    DiagnosticLevel.summary => (
        icon: Icons.subject,
        color: colorScheme.onSurface,
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

/// Converts the given [object] into its string representation.
///
/// The method attempts multiple strategies to stringify the provided object.
/// If the object is a `String`, it is trimmed. If the object is a `DiagnosticsNode`,
/// a deep string representation is returned. If the object provides a `toJson` method,
/// the object is stringified using JSON serialization.
///
/// - [object]: The object to be stringified.
///
/// **Returns:** The string representation of the object or `null` if the object is null.
///
/// **Example usage:**
/// ```dart
/// final object = {"key": "value"};
/// final stringRepresentation = stringifiedLog(object);
/// print(stringRepresentation);  // Outputs: '{\n  "key": "value"\n}'
/// ```
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
