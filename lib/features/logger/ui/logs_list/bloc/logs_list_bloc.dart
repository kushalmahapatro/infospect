import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:infospect/features/logger/infospect_logger.dart';
import 'package:infospect/features/logger/models/infospect_log.dart';

part 'logs_list_event.dart';
part 'logs_list_state.dart';

class LogsListBloc extends Bloc<LogsListEvent, LogsListState> {
  final InfospectLogger _infospectLogger;

  LogsListBloc({required InfospectLogger infospectLogger})
      : _infospectLogger = infospectLogger,
        super(const LogsListState()) {
    on<LogsChanged>(_onLogsChanged);

    on<TextSearched>(_onTextSearched);

    _onStarted();
  }

  FutureOr<void> _onLogsChanged(
      LogsChanged event, Emitter<LogsListState> emit) async {
    await emit.forEach(
      _infospectLogger.callsSubject,
      onData: (value) {
        final searched = state.searchedText.toLowerCase();

        final list = searched.isNotEmpty
            ? value.reversed.where((element) {
                return element.error
                        .toString()
                        .toLowerCase()
                        .contains(searched) ||
                    element.message.toLowerCase().contains(searched) ||
                    element.stackTrace
                        .toString()
                        .toLowerCase()
                        .contains(searched) ||
                    element.timestamp
                        .toString()
                        .toLowerCase()
                        .contains(searched);
              }).toList()
            : value.reversed.toList();

        return state.copyWith(
          logs: value.reversed.toList(),
          filteredLogs: list,
        );
      },
    );
  }

  FutureOr<void> _onTextSearched(
      TextSearched event, Emitter<LogsListState> emit) async {
    emit(state.copyWith(searchedText: event.text));

    final searched = state.searchedText.toLowerCase();

    if (searched.isEmpty) {
      emit(state.copyWith(filteredLogs: state.logs));
      return;
    }

    final list = state.logs.where((element) {
      return element.error.toString().toLowerCase().contains(searched) ||
          element.message.toLowerCase().contains(searched) ||
          element.stackTrace.toString().toLowerCase().contains(searched) ||
          element.timestamp.toString().toLowerCase().contains(searched);
    }).toList();

    emit(state.copyWith(filteredLogs: list));
  }

  void _onStarted() {
    add(LogsChanged(logs: _infospectLogger.callsSubject.value));
  }
}
