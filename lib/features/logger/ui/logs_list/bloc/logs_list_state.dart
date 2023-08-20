part of 'logs_list_bloc.dart';

/// Represents the state of the logs list in the application.
///
/// This state contains information about the logs, the currently filtered
/// logs, the text searched, and the filters applied.
class LogsListState extends Equatable {
  /// Creates a new instance of [LogsListState].
  ///
  /// - [logs]: The list of all logs.
  /// - [filteredLogs]: The list of logs that match the current search and filters.
  /// - [searchedText]: The text that was searched.
  /// - [filters]: The list of filters applied.
  const LogsListState({
    this.logs = const [],
    this.filteredLogs = const [],
    this.searchedText = '',
    this.filters = const [],
  });

  /// The list of all logs.
  final List<InfospectLog> logs;

  /// The list of logs that match the current search and filters.
  final List<InfospectLog> filteredLogs;

  /// The text that was searched.
  final String searchedText;

  /// The list of filters applied.
  final List<PopupAction> filters;

  @override
  List<Object> get props => [logs, filteredLogs, searchedText, filters];

  /// Creates a copy of this [LogsListState] but with the given fields replaced with the new values.
  LogsListState copyWith({
    List<InfospectLog>? logs,
    List<InfospectLog>? filteredLogs,
    String? searchedText,
    List<PopupAction>? filters,
  }) {
    return LogsListState(
      logs: logs ?? this.logs,
      filteredLogs: filteredLogs ?? this.filteredLogs,
      searchedText: searchedText ?? this.searchedText,
      filters: filters ?? this.filters,
    );
  }
}

/// Represents a state that includes information about a compressed file
/// containing the logs.
///
/// This state extends [LogsListState] and adds an additional property
/// representing the compressed file that contains the logs and can be shared.
final class CompressedLogsFile extends LogsListState {
  /// Creates a new instance of [CompressedLogsFile].
  ///
  /// - [logs]: The list of all logs.
  /// - [filteredLogs]: The list of logs that match the current search and filters.
  /// - [searchedText]: The text that was searched.
  /// - [filters]: The list of filters applied.
  /// - [sharableFile]: The compressed file that can be shared.
  const CompressedLogsFile({
    super.logs,
    super.filteredLogs,
    super.searchedText,
    super.filters,
    required this.sharableFile,
  });

  /// The compressed file that can be shared.
  final File sharableFile;

  @override
  List<Object> get props => super.props..add(sharableFile);
}
