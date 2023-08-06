part of 'logs_list_bloc.dart';

class LogsListState extends Equatable {
  const LogsListState({
    this.logs = const [],
    this.filteredLogs = const [],
    this.searchedText = '',
  });

  final List<InfospectLog> logs;
  final List<InfospectLog> filteredLogs;
  final String searchedText;

  @override
  List<Object> get props => [...logs, ...filteredLogs, searchedText];

  LogsListState copyWith({
    List<InfospectLog>? logs,
    List<InfospectLog>? filteredLogs,
    String? searchedText,
  }) {
    return LogsListState(
      logs: logs ?? this.logs,
      filteredLogs: filteredLogs ?? this.filteredLogs,
      searchedText: searchedText ?? this.searchedText,
    );
  }
}
