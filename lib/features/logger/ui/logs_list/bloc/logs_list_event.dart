part of 'logs_list_bloc.dart';

sealed class LogsListEvent {
  const LogsListEvent();
}

final class LogsChanged extends LogsListEvent {
  final List<InfospectLog> logs;

  const LogsChanged({required this.logs});
}

final class TextSearched extends LogsListEvent {
  final String text;

  const TextSearched({required this.text});
}

final class LogsFilterAdded extends LogsListEvent {
  final PopupAction action;

  const LogsFilterAdded({required this.action});
}

final class LogsFilterRemoved extends LogsListEvent {
  final PopupAction action;

  const LogsFilterRemoved({required this.action});
}
