part of 'logs_list_bloc.dart';

class LogsListState extends Equatable {
  const LogsListState({
    this.logs = const [],
    this.filteredLogs = const [],
    this.searchedText = '',
    this.filters = const [],
  });

  final List<InfospectLog> logs;
  final List<InfospectLog> filteredLogs;
  final String searchedText;
  final List<PopupAction> filters;

  @override
  List<Object> get props => [logs, filteredLogs, searchedText, filters];

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

final class CompressedLogsFile extends LogsListState {
  const CompressedLogsFile({
    super.logs,
    super.filteredLogs,
    super.searchedText,
    super.filters,
    required this.sharableFile,
  });

  final File sharableFile;

  @override
  List<Object> get props => super.props..add(sharableFile);
}
