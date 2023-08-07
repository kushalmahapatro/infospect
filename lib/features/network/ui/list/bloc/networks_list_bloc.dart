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

    on<NetworkLogsSearched>(_onNetworkLogsSearched);

    _onStarted();
  }

  FutureOr<void> _onCallsChanged(
      CallsChanged event, Emitter<NetworksListState> emit) async {
    await emit.forEach(
      _infospect.callsSubject,
      onData: (value) {
        final searched = state.searchedText.toLowerCase();

        final list = searched.isNotEmpty
            ? value.reversed
                .where((element) =>
                    element.uri.toLowerCase().contains(state.searchedText))
                .toList()
            : value.reversed.toList();

        final newState = state.copyWith(
          filteredCalls: list,
          calls: value.reversed.toList(),
        );

        return newState;
      },
    );
  }

  FutureOr<void> _onNetworkLogsSearched(
      NetworkLogsSearched event, Emitter<NetworksListState> emit) async {
    emit(state.copyWith(searchedText: event.text));

    final searched = state.searchedText.toLowerCase();
    if (searched.isEmpty) {
      emit(state.copyWith(filteredCalls: state.calls));
      return;
    }

    final list = state.calls
        .where(
            (element) => element.uri.toLowerCase().contains(state.searchedText))
        .toList();

    emit(state.copyWith(filteredCalls: List.from(list)));
  }

  /// initial call
  void _onStarted() {
    add(CallsChanged(calls: _infospect.callsSubject.value));
  }
}
