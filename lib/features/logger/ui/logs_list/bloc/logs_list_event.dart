part of 'logs_list_bloc.dart';

/// `LogsListEvent` is a sealed class representing various events related
/// to logs management. These events are used by the `LogsListBloc` to
/// manage the logs state.
sealed class LogsListEvent {
  const LogsListEvent();
}

/// Event triggered when logs are changed.
///
/// This event should be dispatched with the new list of logs.
final class LogsChanged extends LogsListEvent {
  /// List of updated logs.
  final List<InfospectLog> logs;

  /// Creates a new instance of `LogsChanged`.
  ///
  /// - [logs]: The updated logs list.
  const LogsChanged({required this.logs});
}

/// Event triggered when a search is performed on logs.
final class TextSearched extends LogsListEvent {
  /// The text used for searching within the logs.
  final String text;

  /// Creates a new instance of `TextSearched`.
  ///
  /// - [text]: The text to search.
  const TextSearched({required this.text});
}

/// Event triggered when a filter is added to the logs list.
final class LogsFilterAdded extends LogsListEvent {
  /// The filter action to be added.
  final PopupAction action;

  /// Creates a new instance of `LogsFilterAdded`.
  ///
  /// - [action]: The filter action to be added.
  const LogsFilterAdded({required this.action});
}

/// Event triggered when a filter is removed from the logs list.
final class LogsFilterRemoved extends LogsListEvent {
  /// The filter action to be removed.
  final PopupAction action;

  /// Creates a new instance of `LogsFilterRemoved`.
  ///
  /// - [action]: The filter action to be removed.
  const LogsFilterRemoved({required this.action});
}

/// Event triggered when a request is made to share all logs.
final class ShareAllLogsClicked extends LogsListEvent {
  /// Creates a new instance of `ShareAllLogsClicked`.
  const ShareAllLogsClicked();
}

/// Event triggered when a request is made to clear all logs.
final class ClearAllLogsClicked extends LogsListEvent {
  /// Creates a new instance of `ClearAllLogsClicked`.
  const ClearAllLogsClicked();
}
