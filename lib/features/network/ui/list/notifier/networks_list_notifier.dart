import 'dart:async';
import 'dart:io';

import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:infospect/features/network/models/infospect_network_call.dart';
import 'package:infospect/helpers/infospect_helper.dart';
import 'package:infospect/utils/extensions/infospect_network/network_response_extension.dart';
import 'package:infospect/utils/infospect_util.dart';
import 'package:infospect/utils/models/action_model.dart';

/// Sort order for network calls by [InfospectNetworkCall.createdTime].
enum NetworkCallsTimeSort {
  /// Oldest first.
  ascending,

  /// Newest first.
  descending,
}

/// Notifier for managing networks list state.
/// Handles network calls, filtering, searching, and sharing.
class NetworksListNotifier extends ChangeNotifier {
  StreamSubscription? _callsSubscription;

  List<InfospectNetworkCall> _calls = [];
  List<InfospectNetworkCall> _filteredCalls = [];
  String _searchedText = '';
  List<PopupAction> _filters = [];
  NetworkCallsTimeSort _timeSort = NetworkCallsTimeSort.descending;

  NetworksListNotifier() {
    _init();
  }

  // Getters
  List<InfospectNetworkCall> get calls => _calls;
  List<InfospectNetworkCall> get filteredCalls => _filteredCalls;
  String get searchedText => _searchedText;
  List<PopupAction> get filters => _filters;
  NetworkCallsTimeSort get timeSort => _timeSort;
  bool get isTimeSortAscending => _timeSort == NetworkCallsTimeSort.ascending;
  ValueChanged<File>? onShareAllNetworkCalls;

  void _init() {
    _callsSubscription = Infospect.instance.networkCallsSubject.listen((calls) {
      _calls = List<InfospectNetworkCall>.from(calls);
      _filterNetworkCalls();
    });
  }

  void searchNetworkLogs(String text) {
    _searchedText = text;
    _filterNetworkCalls();
  }

  void addFilter(PopupAction action) {
    final finalFilters = List<PopupAction>.from(_filters);

    if (finalFilters.firstWhereOrNull(
          (element) => element.name == action.name,
        ) !=
        null) {
      finalFilters.remove(action);
    } else {
      finalFilters.add(action);
    }

    _filters = finalFilters;
    _filterNetworkCalls();
  }

  void removeFilter(PopupAction action) {
    final finalFilters = List<PopupAction>.from(_filters);
    if (finalFilters.firstWhereOrNull(
          (element) => element.name == action.name,
        ) !=
        null) {
      finalFilters.remove(action);
      _filters = finalFilters;
      _filterNetworkCalls();
    }
  }

  /// Toggles time sort between ascending and descending.
  void toggleTimeSort() {
    _timeSort = _timeSort == NetworkCallsTimeSort.ascending
        ? NetworkCallsTimeSort.descending
        : NetworkCallsTimeSort.ascending;
    _filterNetworkCalls();
  }

  void _filterNetworkCalls() {
    List<InfospectNetworkCall> filteredList = [];
    final searched = _searchedText.toLowerCase();

    if (searched.isNotEmpty) {
      filteredList = _calls
          .where((element) => element.uri.toLowerCase().contains(searched))
          .toList();
    }

    if (_filters.isEmpty) {
      _filteredCalls = _sortByTime(searched.isEmpty ? _calls : filteredList);
      notifyListeners();
      return;
    }

    final listToCheck = filteredList.isEmpty ? _calls : filteredList;
    List<InfospectNetworkCall> list = listToCheck
        .where(
          (element) => _filters
              .map((e) => e.name.toLowerCase())
              .contains(element.method.toLowerCase()),
        )
        .toList();

    final statusList = _filters.where((e) => e.parentId == 'status').toList();

    if (statusList.isNotEmpty) {
      final listToCheck = list.isEmpty ? _calls : filteredList;

      for (var element in statusList) {
        if (element.id == 'success') {
          list = listToCheck
              .where(
                (element) =>
                    (element.response?.statusString ?? '').contains('OK'),
              )
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
    }

    _filteredCalls = _sortByTime(list);
    notifyListeners();
  }

  List<InfospectNetworkCall> _sortByTime(List<InfospectNetworkCall> calls) {
    final sorted = List<InfospectNetworkCall>.from(calls);
    sorted.sort((a, b) {
      final compare = a.createdTime.compareTo(b.createdTime);
      return _timeSort == NetworkCallsTimeSort.ascending ? compare : -compare;
    });
    return sorted;
  }

  Future<void> shareNetworkLogs() async {
    final networkLogsFile = await InfospectUtil.shareNetworkCallLogs();
    if (networkLogsFile != null) {
      onShareAllNetworkCalls?.call(networkLogsFile);
    }
  }

  Future<void> clearNetworkLogs() async {
    Infospect.instance.clearAllNetworkCalls();
  }

  @override
  void dispose() {
    _callsSubscription?.cancel();
    super.dispose();
  }
}
