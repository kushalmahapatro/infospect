import 'dart:async';
import 'dart:io';

import 'package:collection/collection.dart';
import 'package:desktop_multi_window/desktop_multi_window.dart';
import 'package:flutter/foundation.dart';
import 'package:infospect/features/network/models/infospect_network_call.dart';
import 'package:infospect/helpers/infospect_helper.dart';
import 'package:infospect/utils/extensions/infospect_network/network_response_extension.dart';
import 'package:infospect/utils/infospect_util.dart';
import 'package:infospect/utils/models/action_model.dart';

/// Notifier for managing networks list state.
/// Handles network calls, filtering, searching, and sharing.
class NetworksListNotifier extends ChangeNotifier {
  final bool _isMultiWindow;
  StreamSubscription? _callsSubscription;

  List<InfospectNetworkCall> _calls = [];
  List<InfospectNetworkCall> _filteredCalls = [];
  String _searchedText = '';
  List<PopupAction> _filters = [];
  File? _sharableFile;

  NetworksListNotifier({required bool isMultiWindow})
      : _isMultiWindow = isMultiWindow {
    _init();
  }

  // Getters
  List<InfospectNetworkCall> get calls => _calls;
  List<InfospectNetworkCall> get filteredCalls => _filteredCalls;
  String get searchedText => _searchedText;
  List<PopupAction> get filters => _filters;
  File? get sharableFile => _sharableFile;

  void _init() {
    _callsSubscription = Infospect.instance.networkCallsSubject.listen((calls) {
      _calls = calls.reversed.toList();
      _filterNetworkCalls();
    });
  }

  void searchNetworkLogs(String text) {
    _searchedText = text;
    _filterNetworkCalls();
  }

  void addFilter(PopupAction action) {
    final finalFilters = List<PopupAction>.from(_filters);

    if (finalFilters
            .firstWhereOrNull((element) => element.name == action.name) !=
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
    if (finalFilters
            .firstWhereOrNull((element) => element.name == action.name) !=
        null) {
      finalFilters.remove(action);
      _filters = finalFilters;
      _filterNetworkCalls();
    }
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
      _filteredCalls = searched.isEmpty ? _calls : filteredList;
      notifyListeners();
      return;
    }

    final listToCheck = filteredList.isEmpty ? _calls : filteredList;
    List<InfospectNetworkCall> list = listToCheck
        .where((element) => _filters
            .map((e) => e.name.toLowerCase())
            .contains(element.method.toLowerCase()))
        .toList();

    final statusList = _filters.where((e) => e.parentId == 'status').toList();

    if (statusList.isNotEmpty) {
      final listToCheck = list.isEmpty ? _calls : filteredList;

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
    }

    _filteredCalls = list;
    notifyListeners();
  }

  Future<void> shareNetworkLogs() async {
    if (_isMultiWindow) {
      DesktopMultiWindow.invokeMethod(
        0,
        'onSend',
        'shareNetworkCallLogs',
      );
      return;
    }

    final networkLogsFile = await InfospectUtil.shareNetworkCallLogs();
    if (networkLogsFile != null) {
      _sharableFile = networkLogsFile;
      notifyListeners();
      // Reset after notification
      _sharableFile = null;
    }
  }

  void clearNetworkLogs() {
    if (_isMultiWindow) {
      DesktopMultiWindow.invokeMethod(
        0,
        'onSend',
        'clearNetworkCallLogs',
      );
    }
    Infospect.instance.clearAllNetworkCalls();
  }

  @override
  void dispose() {
    _callsSubscription?.cancel();
    super.dispose();
  }
}
