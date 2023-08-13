import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:collection/collection.dart';
import 'package:equatable/equatable.dart';
import 'package:infospect/features/network/models/infospect_network_call.dart';
import 'package:infospect/features/network/ui/list/models/network_action.dart';
import 'package:infospect/helpers/infospect_helper.dart';
import 'package:infospect/utils/extensions/infospect_network/network_response_extension.dart';
import 'package:infospect/utils/models/action_model.dart';

part 'networks_list_event.dart';
part 'networks_list_state.dart';

class NetworksListBloc extends Bloc<NetworksListEvent, NetworksListState> {
  final Infospect _infospect;

  NetworksListBloc({required Infospect infospect})
      : _infospect = infospect,
        super(const NetworksListState()) {
    on<CallsChanged>(_onCallsChanged);

    on<NetworkLogsSearched>(_onNetworkLogsSearched);

    on<NetowrkLogsFilterAdded>(_onNetworkLogsFilterAdded);

    on<NetowrkLogsFilterRemoved>(_onNetworkLogsFilterRemoved);

    _onStarted();
  }

  FutureOr<void> _onCallsChanged(
      CallsChanged event, Emitter<NetworksListState> emit) async {
    await emit.forEach(
      _infospect.callsSubject,
      onData: (value) {
        return _filterNetworkCalls(
          List.from(state.filters),
          value.reversed.toList(),
        );
      },
    );
  }

  FutureOr<void> _onNetworkLogsSearched(
      NetworkLogsSearched event, Emitter<NetworksListState> emit) async {
    emit(state.copyWith(searchedText: event.text));

    emit(_filterNetworkCalls(List.from(state.filters)));
  }

  FutureOr<void> _onNetworkLogsFilterAdded(
      NetowrkLogsFilterAdded event, Emitter<NetworksListState> emit) async {
    final List<PopupAction> finalFilters = List.from(state.filters);

    if (finalFilters
            .firstWhereOrNull((element) => element.name == event.action.name) !=
        null) {
      finalFilters.remove(event.action);
    } else {
      finalFilters.add(event.action);
    }
    emit(state.copyWith(filters: finalFilters));

    emit(_filterNetworkCalls(finalFilters));
  }

  FutureOr<void> _onNetworkLogsFilterRemoved(
      NetowrkLogsFilterRemoved event, Emitter<NetworksListState> emit) async {
    final List<PopupAction> finalFilters = List.from(state.filters);
    if (finalFilters
            .firstWhereOrNull((element) => element.name == event.action.name) !=
        null) {
      finalFilters.remove(event.action);
      emit(state.copyWith(filters: finalFilters));

      emit(_filterNetworkCalls(finalFilters));
    }
  }

  NetworksListState _filterNetworkCalls(
    List<PopupAction> finalFilters, [
    List<InfospectNetworkCall>? totalCalls,
  ]) {
    List<InfospectNetworkCall> filteredList = [];
    final List<InfospectNetworkCall> calls = (totalCalls ?? state.calls);

    final String searched = state.searchedText.toLowerCase();
    if (searched.isNotEmpty) {
      filteredList = calls
          .where((element) => element.uri.toLowerCase().contains(searched))
          .toList();
    }

    if (finalFilters.isEmpty) {
      final callsToShow = searched.isEmpty ? calls : filteredList;

      return state.copyWith(filteredCalls: callsToShow, calls: totalCalls);
    }

    final listToCheck = filteredList.isEmpty ? calls : filteredList;
    List<InfospectNetworkCall> list = listToCheck
        .where((element) => finalFilters
            .map((e) => e.name.toLowerCase())
            .contains(element.method.toLowerCase()))
        .toList();

    final List<PopupAction> statusList = finalFilters
        .where((e) => e.parentId == NetworkActionType.status)
        .toList();

    if (statusList.isNotEmpty) {
      final listToCheck = list.isEmpty ? calls : filteredList;

      for (var element in statusList) {
        if (element.id == 'success') {
          list = listToCheck
              .where((element) =>
                  (element.response?.statusString ?? '').contains('OK'))
              .toList();
        } else if (element.id == 'error') {
          list = listToCheck
              .where(
                (element) =>
                    !(element.response?.statusString ?? '').contains('OK'),
              )
              .toList();
        }
      }

      return state.copyWith(filteredCalls: list, calls: totalCalls);
    }

    return state.copyWith(filteredCalls: list, calls: totalCalls);
  }

  /// initial call
  void _onStarted() {
    add(CallsChanged(calls: _infospect.callsSubject.value));
  }
}
