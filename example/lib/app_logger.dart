import 'package:flutter/material.dart';
import 'package:infospect/infospect.dart';

mixin AppLoggerMixin {
  String get tag;

  void logDebug(
    String message, {
    String? tag,
    Object? error,
    StackTrace? stackTrace,
  }) {
    _log(
      DiagnosticLevel.debug,
      message,
      tag: tag ?? this.tag,
      error: error,
      stackTrace: stackTrace,
    );
  }

  void logError(
    String message, {
    String? tag,
    Object? error,
    StackTrace? stackTrace,
  }) {
    _log(
      DiagnosticLevel.error,
      message,
      tag: tag ?? this.tag,
      error: error,
      stackTrace: stackTrace,
    );
  }

  void logInfo(
    String message, {
    String? tag,
    Object? error,
    StackTrace? stackTrace,
  }) {
    _log(
      DiagnosticLevel.info,
      message,
      tag: tag ?? this.tag,
      error: error,
      stackTrace: stackTrace,
    );
  }

  void logWarning(
    String message, {
    String? tag,
    Object? error,
    StackTrace? stackTrace,
  }) {
    _log(
      DiagnosticLevel.warning,
      message,
      tag: tag ?? this.tag,
      error: error,
      stackTrace: stackTrace,
    );
  }

  void lgoOthers(
    DiagnosticLevel level,
    String message, {
    String? tag,
    Object? error,
    StackTrace? stackTrace,
  }) {
    _log(
      level,
      message,
      tag: tag ?? this.tag,
      error: error,
      stackTrace: stackTrace,
    );
  }

  void _log(
    DiagnosticLevel level,
    String message, {
    String? tag,
    Object? error,
    StackTrace? stackTrace,
  }) {
    String logMessage = message;
    if (tag != null) {
      logMessage = '[$tag]: $message';
    }

    Infospect.instance.addLog(
      InfospectLog(
        message: logMessage,
        level: level,
        error: error,
        stackTrace: stackTrace,
      ),
    );
  }
}
