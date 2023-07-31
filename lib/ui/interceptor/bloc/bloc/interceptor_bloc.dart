import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:infospect/helpers/infospect_helper.dart';
import 'package:infospect/logger/infospect_logger.dart';
import 'package:infospect/network/models/infospect_network_call.dart';
import 'package:meta/meta.dart';

part 'interceptor_event.dart';
part 'interceptor_state.dart';

class InterceptorBloc extends Bloc<InterceptorEvent, InterceptorState> {
  final Infospect _infospect;
  final InfospectLogger _infospectLogger;
  InterceptorBloc(
      {required Infospect infospect, required InfospectLogger infospectLogger})
      : _infospect = infospect,
        _infospectLogger = infospectLogger,
        super(const InterceptorState()) {
    on<TabChanged>(_onTabChanged);

    on<CallsChanged>(_onCallsChanged);

    _onStarted();
  }

  FutureOr<void> _onTabChanged(
      TabChanged event, Emitter<InterceptorState> emit) {
    emit(state.copyWith(selectedTab: event.selectedTab));
  }

  FutureOr<void> _onCallsChanged(
      CallsChanged event, Emitter<InterceptorState> emit) {
    emit(state.copyWith(networkCalls: event.calls));
  }

  void _onStarted() async {
    _infospect.callsSubject.listen(
      (value) {
        if (!isClosed) {
          add(CallsChanged(calls: value));
        }
      },
    );
  }
}
