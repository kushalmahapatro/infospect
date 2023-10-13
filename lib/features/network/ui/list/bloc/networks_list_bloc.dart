import 'dart:async';
import 'dart:io';

import 'package:bloc/bloc.dart';
import 'package:collection/collection.dart';
import 'package:desktop_multi_window/desktop_multi_window.dart';
import 'package:equatable/equatable.dart';
import 'package:infospect/features/network/models/infospect_network_call.dart';
import 'package:infospect/features/network/ui/list/models/network_action.dart';
import 'package:infospect/helpers/infospect_helper.dart';
import 'package:infospect/utils/extensions/infospect_network/network_response_extension.dart';
import 'package:infospect/utils/infospect_util.dart';
import 'package:infospect/utils/models/action_model.dart';

part 'networks_list_event.dart';
part 'networks_list_state.dart';

class NetworksListBloc extends Bloc<NetworksListEvent, NetworksListState> {
  final bool _isMultiWindow;

  NetworksListBloc({required bool isMultiWindow})
      : _isMultiWindow = isMultiWindow,
        super(const NetworksListState()) {
    /// Listen to the logs changes
    on<CallsChanged>(_onCallsChanged);

    /// Listen to the text searched
    on<NetworkLogsSearched>(_onNetworkLogsSearched);

    /// Listen to the logs filter added
    on<NetworkLogsFilterAdded>(_onNetworkLogsFilterAdded);

    /// Listen to the logs filter removed
    on<NetworkLogsFilterRemoved>(_onNetworkLogsFilterRemoved);

    /// Listen to the share all logs clicked
    on<ShareNetworkLogsClicked>(_onShareNetworkLogs);

    /// Listen to the clear all logs clicked
    on<ClearNetworkLogsClicked>(_onClearNetworkLogs);

    /// Listen to the started event
    _onStarted();
  }

  /// initial call
  void _onStarted() {
    add(CallsChanged(calls: Infospect.instance.networkCallsSubject.value));
  }

  FutureOr<void> _onCallsChanged(
      CallsChanged event, Emitter<NetworksListState> emit) async {
    await emit.forEach(
      Infospect.instance.networkCallsSubject,
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
      NetworkLogsFilterAdded event, Emitter<NetworksListState> emit) async {
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
      NetworkLogsFilterRemoved event, Emitter<NetworksListState> emit) async {
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

  FutureOr<void> _onShareNetworkLogs(
      ShareNetworkLogsClicked event, Emitter<NetworksListState> emit) async {
    if (_isMultiWindow) {
      DesktopMultiWindow.invokeMethod(
        0,
        'onSend',
        MainWindowArguments.shareNetworkCallLogs.name,
      );
      return;
    }
    final File? networkLogsFile = await InfospectUtil.shareNetworkCallLogs();
    if (networkLogsFile != null) {
      emit(
        CompressedNetworkCallLogsFile(
          sharableFile: networkLogsFile,
          calls: state.calls,
          filteredCalls: state.filteredCalls,
          filters: state.filters,
          searchedText: state.searchedText,
        ),
      );
    }
  }

  FutureOr<void> _onClearNetworkLogs(
      ClearNetworkLogsClicked event, Emitter<NetworksListState> emit) {
    if (_isMultiWindow) {
      DesktopMultiWindow.invokeMethod(
        0,
        'onSend',
        MainWindowArguments.clearNetworkCallLogs.name,
      );
    }
    Infospect.instance.clearAllNetworkCalls();
  }
}
