import 'dart:async';
import 'dart:io';

import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:infospect/features/logger/infospect_logger.dart';
import 'package:infospect/infospect.dart';
import 'package:infospect/utils/infospect_util.dart';
import 'package:infospect/utils/models/action_model.dart';

/// Notifier for managing logs list state.
/// Handles logs, filtering, searching, and sharing.
class LogsListNotifier extends ChangeNotifier {
  final InfospectLogger _infospectLogger;
  StreamSubscription? _logsSubscription;

  List<InfospectLog> _logs = [];
  List<InfospectLog> _filteredLogs = [];
  String _searchedText = '';
  List<PopupAction> _filters = [];

  LogsListNotifier({required InfospectLogger infospectLogger})
    : _infospectLogger = infospectLogger {
    _init();
  }

  // Getters
  List<InfospectLog> get logs => _logs;
  List<InfospectLog> get filteredLogs => _filteredLogs;
  String get searchedText => _searchedText;
  List<PopupAction> get filters => _filters;
  ValueChanged<File>? onShareAllLogs;

  void _init() {
    _logsSubscription = _infospectLogger.callsSubject.listen((logs) {
      _logs = logs.reversed.toList();
      _filterLogs();
    });
  }

  void searchText(String text) {
    _searchedText = text;
    _filterLogs();
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
    _filterLogs();
  }

  void removeFilter(PopupAction action) {
    final finalFilters = List<PopupAction>.from(_filters);
    if (finalFilters.firstWhereOrNull(
          (element) => element.name == action.name,
        ) !=
        null) {
      finalFilters.remove(action);
      _filters = finalFilters;
      _filterLogs();
    }
  }

  void _filterLogs() {
    List<InfospectLog> filteredList = [];
    final searched = _searchedText.toLowerCase();

    if (searched.isNotEmpty) {
      filteredList = _logs.where((element) {
        return element.error.toString().toLowerCase().contains(searched) ||
            element.message.toLowerCase().contains(searched) ||
            element.stackTrace.toString().toLowerCase().contains(searched) ||
            element.timestamp.toString().toLowerCase().contains(searched);
      }).toList();
    }

    if (_filters.isEmpty) {
      _filteredLogs = searched.isEmpty ? _logs : filteredList;
      notifyListeners();
      return;
    }

    final listToCheck = filteredList.isEmpty && searched.isEmpty
        ? _logs
        : filteredList;

    final list = listToCheck
        .where(
          (element) => _filters
              .map((e) => e.id.toString().toLowerCase())
              .contains(element.level.name.toString().toLowerCase()),
        )
        .toList();

    _filteredLogs = list;
    notifyListeners();
  }

  Future<void> shareAllLogs() async {
    final logsFile = await InfospectUtil.shareLogs();
    if (logsFile != null) {
      onShareAllLogs?.call(logsFile);
    }
  }

  Future<void> clearAllLogs() async {
    Infospect.instance.clearAllLogs();
  }

  @override
  void dispose() {
    _logsSubscription?.cancel();
    super.dispose();
  }
}
