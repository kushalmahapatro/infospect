part of 'infospect_helper.dart';

/// `InfospectLogHelper` is a utility class designed to assist `Infospect` in handling logging tasks.
/// This class acts as an intermediary between `Infospect` and its logger, encapsulating
/// the logic for adding logs, aggregating multiple logs, and clearing all logs.
class InfospectLogHelper {
  /// The private constructor for the `InfospectLogHelper` class.
  ///
  /// - `infospect`: The reference to the parent `Infospect` instance.
  const InfospectLogHelper._(Infospect infospect) : _infospect = infospect;

  final Infospect _infospect;

  /// Adds a single `InfospectLog` entry to the logger of the `Infospect` instance.
  ///
  /// - `log`: The log entry to be added.
  void addLog(InfospectLog log) {
    // Adds the log entry to the logger.
    _infospect.infospectLogger.add(log);

    // Sends the log to any potential subscribers or handlers.
    _infospect.sendLogs([log]);
  }

  /// Aggregates and adds multiple `InfospectLog` entries to the logger of the `Infospect` instance.
  ///
  /// - `logs`: The list of log entries to be added.
  void addLogs(List<InfospectLog> logs) {
    // Appends the list of logs to the logger.
    _infospect.infospectLogger.logs.addAll(logs);

    // Sends the logs to any potential subscribers or handlers.
    _infospect.sendLogs(logs);
  }

  /// Clears all the logs from the logger of the `Infospect` instance.
  void clearAllLogs() {
    _infospect.infospectLogger.logs.clear();
    _infospect.infospectLogger.clear();
  }
}
