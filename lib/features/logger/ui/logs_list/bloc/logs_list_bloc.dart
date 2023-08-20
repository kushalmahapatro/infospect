import 'dart:async';
import 'dart:io';

import 'package:bloc/bloc.dart';
import 'package:collection/collection.dart';
import 'package:desktop_multi_window/desktop_multi_window.dart';
import 'package:equatable/equatable.dart';
import 'package:infospect/features/logger/infospect_logger.dart';
import 'package:infospect/infospect.dart';
import 'package:infospect/utils/infospect_util.dart';
import 'package:infospect/utils/models/action_model.dart';

part 'logs_list_event.dart';
part 'logs_list_state.dart';

class LogsListBloc extends Bloc<LogsListEvent, LogsListState> {
  final InfospectLogger _infospectLogger;
  final bool _isMultiWindow;

  LogsListBloc(
      {required InfospectLogger infospectLogger, required bool isMultiWindow})
      : _infospectLogger = infospectLogger,
        _isMultiWindow = isMultiWindow,
        super(const LogsListState()) {
    /// Listen to the logs changes
    on<LogsChanged>(_onLogsChanged);

    /// Listen to the text searched
    on<TextSearched>(_onTextSearched);

    /// Listen to the logs filter added
    on<LogsFilterAdded>(_onLogsFilterAdded);

    /// Listen to the logs filter removed
    on<LogsFilterRemoved>(_onLogsFilterRemoved);

    /// Listen to the share all logs clicked
    on<ShareAllLogsClicked>(_onShareAllLogsClicked);

    /// Listen to the clear all logs clicked
    on<ClearAllLogsClicked>(_onClearAllLogsClicked);

    _onStarted();
  }

  /// initial call
  void _onStarted() {
    add(LogsChanged(logs: _infospectLogger.callsSubject.value));
  }

  FutureOr<void> _onLogsChanged(
      LogsChanged event, Emitter<LogsListState> emit) async {
    await emit.forEach(
      _infospectLogger.callsSubject,
      onData: (value) {
        return _filterLogs(state.filters, value.reversed.toList());
      },
    );
  }

  FutureOr<void> _onTextSearched(
      TextSearched event, Emitter<LogsListState> emit) async {
    emit(state.copyWith(searchedText: event.text));

    emit(_filterLogs(List.from(state.filters)));
  }

  FutureOr<void> _onLogsFilterAdded(
      LogsFilterAdded event, Emitter<LogsListState> emit) {
    final List<PopupAction> finalFilters = List.from(state.filters);

    if (finalFilters
            .firstWhereOrNull((element) => element.name == event.action.name) !=
        null) {
      finalFilters.remove(event.action);
    } else {
      finalFilters.add(event.action);
    }
    emit(state.copyWith(filters: finalFilters));

    emit(_filterLogs(finalFilters));
  }

  FutureOr<void> _onLogsFilterRemoved(
      LogsFilterRemoved event, Emitter<LogsListState> emit) {
    final List<PopupAction> finalFilters = List.from(state.filters);
    if (finalFilters
            .firstWhereOrNull((element) => element.name == event.action.name) !=
        null) {
      finalFilters.remove(event.action);
      emit(state.copyWith(filters: finalFilters));

      emit(_filterLogs(finalFilters));
    }
  }

  LogsListState _filterLogs(
    List<PopupAction> filter, [
    List<InfospectLog>? totalLogs,
  ]) {
    List<InfospectLog> filteredList = [];
    final List<InfospectLog> logs = totalLogs ?? state.logs;

    final searched = state.searchedText.toLowerCase();

    if (searched.isNotEmpty) {
      filteredList = logs.where(
        (element) {
          return element.error.toString().toLowerCase().contains(searched) ||
              element.message.toLowerCase().contains(searched) ||
              element.stackTrace.toString().toLowerCase().contains(searched) ||
              element.timestamp.toString().toLowerCase().contains(searched);
        },
      ).toList();
    }

    if (filter.isEmpty) {
      final logsToShow = searched.isEmpty ? logs : filteredList;
      return state.copyWith(filteredLogs: logsToShow, logs: totalLogs);
    }

    final listToCheck =
        filteredList.isEmpty && searched.isEmpty ? logs : filteredList;

    final list = listToCheck
        .where((element) => filter
            .map((e) => e.id.toString().toLowerCase())
            .contains(element.level.name.toString().toLowerCase()))
        .toList();

    return state.copyWith(
      logs: logs.toList(),
      filteredLogs: list,
    );
  }

  FutureOr<void> _onShareAllLogsClicked(
      ShareAllLogsClicked event, Emitter<LogsListState> emit) async {
    if (_isMultiWindow) {
      DesktopMultiWindow.invokeMethod(
        0,
        'onSend',
        MainWindowArguments.shareLogs.name,
      );
      return;
    }
    final File? logsFile = await InfospectUtil.shareLogs();
    if (logsFile != null) {
      emit(
        CompressedLogsFile(
          sharableFile: logsFile,
          logs: state.logs,
          filteredLogs: state.filteredLogs,
          filters: state.filters,
          searchedText: state.searchedText,
        ),
      );
    }
  }

  FutureOr<void> _onClearAllLogsClicked(
      ClearAllLogsClicked event, Emitter<LogsListState> emit) {
    if (_isMultiWindow) {
      DesktopMultiWindow.invokeMethod(
        0,
        'onSend',
        MainWindowArguments.clearLogs.name,
      );
    }
    Infospect.instance.clearAllLogs();
  }
}
