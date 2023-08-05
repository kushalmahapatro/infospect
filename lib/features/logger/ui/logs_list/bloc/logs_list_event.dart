part of 'logs_list_bloc.dart';

sealed class LogsListEvent {
  const LogsListEvent();
}

final class LogsChanged extends LogsListEvent {
  final List<InfospectLog> logs;

  const LogsChanged({required this.logs});
}
