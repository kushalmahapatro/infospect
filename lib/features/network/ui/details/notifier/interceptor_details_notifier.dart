import 'package:flutter/foundation.dart';

/// Notifier for managing interceptor details screen state.
/// Handles tab selection and request body type changes.
class InterceptorDetailsNotifier extends ChangeNotifier {
  int _selectedTab = 0;
  int _requestBodyType = 0;

  /// Gets the currently selected tab index.
  int get selectedTab => _selectedTab;

  /// Gets the currently selected request body type index.
  int get requestBodyType => _requestBodyType;

  /// Changes the selected tab.
  ///
  /// - [selectedTab]: The index of the tab to select.
  void changeTab(int selectedTab) {
    if (_selectedTab != selectedTab) {
      _selectedTab = selectedTab;
      notifyListeners();
    }
  }

  /// Changes the request body type.
  ///
  /// - [index]: The index of the request body type.
  void changeRequestBodyType(int index) {
    if (_requestBodyType != index) {
      _requestBodyType = index;
      notifyListeners();
    }
  }
}
