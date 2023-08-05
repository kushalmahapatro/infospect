import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:infospect/features/network/models/infospect_network_call.dart';
import 'package:infospect/helpers/infospect_helper.dart';

part 'networks_list_event.dart';
part 'networks_list_state.dart';

class NetworksListBloc extends Bloc<NetworksListEvent, NetworksListState> {
  final Infospect _infospect;

  NetworksListBloc({required Infospect infospect})
      : _infospect = infospect,
        super(const NetworksListState()) {
    on<CallsChanged>(_onCallsChanged);

    _onStarted();
  }

  FutureOr<void> _onCallsChanged(
      CallsChanged event, Emitter<NetworksListState> emit) {
    emit.forEach(
      _infospect.callsSubject,
      onData: (value) => state.copyWith(calls: value),
    );
  }

  void _onStarted() {
    add(CallsChanged(calls: _infospect.callsSubject.value));
  }
}
