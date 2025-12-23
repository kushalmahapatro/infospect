import 'package:flutter/foundation.dart';
import 'package:infospect/features/network/ui/raw_data_viewer/models/raw_data_view.dart';

/// Notifier for managing raw data viewer state.
/// Handles search value and view type changes.
class RawDataViewerNotifier extends ChangeNotifier {
  String _searchValue = '';
  RawDataView _view = RawDataView.beautified;

  /// Gets the current search value.
  String get searchValue => _searchValue;

  /// Gets the current view type.
  RawDataView get view => _view;

  /// Changes the search value.
  ///
  /// - [value]: The new search value.
  void changeSearchValue(String value) {
    if (_searchValue != value) {
      _searchValue = value;
      notifyListeners();
    }
  }

  /// Changes the view type.
  ///
  /// - [view]: The new view type.
  void changeView(RawDataView view) {
    if (_view != view) {
      _view = view;
      notifyListeners();
    }
  }
}
