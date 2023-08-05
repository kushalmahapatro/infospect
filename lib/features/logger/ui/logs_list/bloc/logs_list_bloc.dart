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
    on<LogsChanged>(
      (event, emit) {
        emit.forEach(
          _infospectLogger.callsSubject,
          onData: (value) => state.copyWith(logs: value),
        );
      },
    );

    _onStarted();
  }

  void _onStarted() {
    add(LogsChanged(logs: _infospectLogger.callsSubject.value));
  }
}
