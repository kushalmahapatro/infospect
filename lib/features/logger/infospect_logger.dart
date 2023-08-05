import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:infospect/features/logger/models/infospect_log.dart';
import 'package:rxdart/rxdart.dart';

/// The `InfospectLogger` class provides a simple logger for the Infospect application.
class InfospectLogger {
  /// The maximum number of logs to store or `null` for unlimited storage.
  ///
  /// If more logs arrive, the oldest ones (based on their [InfospectLog.timestamp]) will
  /// be removed.
  int? _maximumSize;

  /// A list of logs represented as [ValueNotifier] to enable listeners for log changes.
  // final _logs = ValueNotifier<List<InfospectLog>>([]);

  /// Creates an instance of the `InfospectLogger` class.
  ///
  /// Parameters:
  /// - [maximumSize]: The maximum number of logs to store (default is 1000).
  InfospectLogger({int? maximumSize = 1000}) : _maximumSize = maximumSize;

  /// A [ValueListenable] that allows listening to changes in the list of logs.
  ///
  /// Listeners can be added to this [ValueListenable] to receive updates when new logs are added or cleared.
  ///
  final BehaviorSubject<List<InfospectLog>> callsSubject =
      BehaviorSubject.seeded([]);

  /// Returns the list of logs.
  List<InfospectLog> get logs => callsSubject.value;

  /// Returns the logs as a Map representation.
  ///
  /// The logs are converted to a Map with the key 'logs' containing a list of Map representations
  /// of each log entry using [InfospectLog.toMap()].
  Map<String, List<Map<String, dynamic>>> get logsMap =>
      {'logs': logs.map<Map<String, dynamic>>((e) => e.toMap()).toList()};

  /// Gets the maximum number of logs to store or `null` for unlimited storage.
  ///
  /// If more logs arrive, the oldest ones (based on their [InfospectLog.timestamp]) will
  /// be removed.
  int? get maximumSize => _maximumSize;

  /// Sets the maximum number of logs to store or `null` for unlimited storage.
  ///
  /// If the new maximum size is smaller than the current number of logs, the oldest logs will be removed.
  set maximumSize(int? value) {
    var logs = callsSubject.value;
    _maximumSize = maximumSize;

    if (value != null && logs.length > value) {
      callsSubject.add([...logs.sublist(logs.length - value, logs.length)]);
    }
  }

  /// Adds a new log entry to the logger.
  ///
  /// The log will be inserted in the appropriate position based on its [InfospectLog.timestamp].
  /// If the maximumSize is reached, the oldest logs will be removed.
  ///
  /// Parameters:
  /// - [log]: The log entry to be added.
  void add(InfospectLog log) {
    var logs = callsSubject.value;

    int index;
    if (logs.isEmpty || !log.timestamp.isBefore(logs.last.timestamp)) {
      // Quick path as new logs are usually more recent.
      index = logs.length;
    } else {
      // Binary search to find the insertion index.
      var min = 0;
      var max = logs.length;
      while (min < max) {
        final mid = min + ((max - min) >> 1);
        final item = logs[mid];
        if (log.timestamp.isBefore(item.timestamp)) {
          max = mid;
        } else {
          min = mid + 1;
        }
      }
      assert(min == max);
      index = min;
    }

    var startIndex = 0;
    if (maximumSize != null && logs.length >= maximumSize!) {
      if (index == 0) return;
      startIndex = logs.length - maximumSize! + 1;
    }
    callsSubject.add([
      ...logs.sublist(startIndex, index),
      log,
      ...logs.sublist(index, logs.length),
    ]);
  }

  /// Clears all logs from the logger.
  void clear() => callsSubject.add([]);

  /// Retrieves raw logs from Android's logcat.
  ///
  /// Returns the raw log messages as a [String] (only applicable on Android).
  Future<String> get getAndroidRawLogs async {
    if (!Platform.isAndroid) return '';

    final process = await Process.run('logcat', ['-v', 'raw', '-d']);
    final result = process.stdout as String;
    return result;
  }

  /// Clears raw logs from Android's logcat.
  ///
  /// Clears the raw log messages (only applicable on Android).
  Future<void> clearAndroidRawLogs() async {
    if (Platform.isAndroid) {
      await Process.run('logcat', ['-c']);
    }
  }

  /// Clears all logs stored in the logger.
  void clearLogs() => logs.clear();
}
