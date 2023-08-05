part of 'logs_list_bloc.dart';

class LogsListState extends Equatable {
  const LogsListState({
    this.logs = const [],
  });

  final List<InfospectLog> logs;

  @override
  List<Object> get props => [logs];

  LogsListState copyWith({
    List<InfospectLog>? logs,
  }) {
    return LogsListState(
      logs: logs ?? this.logs,
    );
  }
}
