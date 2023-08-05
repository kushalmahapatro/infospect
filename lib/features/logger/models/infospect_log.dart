import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';

/// Represents a log entry for the Infospect application.
@immutable
class InfospectLog {
  /// The log level indicating the severity of the log.
  final DiagnosticLevel level;

  /// The timestamp when the log was created.
  final DateTime timestamp;

  /// The log message.
  final String message;

  /// The error associated with the log (if any).
  final dynamic error;

  /// The stack trace associated with the log (if available).
  final StackTrace? stackTrace;

  /// Creates an instance of the `InfospectLog` class.
  ///
  /// Parameters:
  /// - [level]: The log level indicating the severity of the log (default is [DiagnosticLevel.info]).
  /// - [timestamp]: The timestamp when the log was created (default is the current time).
  /// - [message]: The log message.
  /// - [error]: The error associated with the log (optional).
  /// - [stackTrace]: The stack trace associated with the log (optional).
  InfospectLog({
    this.level = DiagnosticLevel.info,
    DateTime? timestamp,
    required this.message,
    this.error,
    this.stackTrace,
  })  : assert(
          level != DiagnosticLevel.off,
          '`DiagnosticLevel.off` is a "[special] level indicating that no '
          'diagnostics should be shown" and should not be used as a value.',
        ),
        assert(timestamp == null || !timestamp.isUtc),
        timestamp = timestamp ?? DateTime.now();

  /// Generates a hash code for the `InfospectLog` object.
  @override
  int get hashCode => Object.hash(level, timestamp, message, error, stackTrace);

  /// Checks if this `InfospectLog` object is equal to another object.
  @override
  bool operator ==(Object other) {
    return other is InfospectLog &&
        level == other.level &&
        timestamp == other.timestamp &&
        message == other.message &&
        error == other.error &&
        stackTrace == other.stackTrace;
  }

  /// Converts the `InfospectLog` object into a Map representation.
  ///
  /// Returns a Map with the following key-value pairs:
  /// - 'level': The name of the log level as a String.
  /// - 'timestamp': The timestamp when the log was created in milliseconds since epoch.
  /// - 'message': The log message as a String.
  /// - 'error': The error associated with the log as a String representation (if available).
  /// - 'stackTrace': The stack trace associated with the log as a String representation (if available).
  Map<String, dynamic> toMap() {
    Map<String, dynamic> map = <String, dynamic>{};
    map['level'] = level.name;
    map['timestamp'] = timestamp.millisecondsSinceEpoch.toString();
    map['message'] = message;
    map['error'] = error.toString();
    map['stackTrace'] = stackTrace.toString();
    return map;
  }

  /// Creates an instance of the `InfospectLog` class from a Map representation.
  ///
  /// Parameters:
  /// - [map]: A Map containing the key-value pairs representing the `InfospectLog` object.
  ///
  /// Returns an instance of the `InfospectLog` class with the data populated from the provided Map.
  static InfospectLog fromMap(Map map) {
    return InfospectLog(
      message: map['message'] ?? '',
      level: DiagnosticLevel.values
              .firstWhereOrNull((element) => element.name == map['level']) ??
          DiagnosticLevel.info,
      timestamp: map['timestamp'] != null
          ? DateTime.fromMillisecondsSinceEpoch(
              int.tryParse(map['timestamp'].toString()) ?? 0)
          : null,
      error: map['error'] ?? '',
      stackTrace: map['stackTrace'] != null
          ? StackTrace.fromString(map['stackTrace'].toString())
          : null,
    );
  }
}
