import 'package:flutter/foundation.dart';

/// Notifier responsible for handling the state of the application's launch phase,
/// especially related to tab changes.
///
/// This replaces the previous BLoC implementation with a simple ValueNotifier.
class LaunchNotifier extends ValueNotifier<int> {
  /// Private constructor for singleton pattern.
  LaunchNotifier._() : super(0);

  /// Singleton instance of [LaunchNotifier].
  static final LaunchNotifier _instance = LaunchNotifier._();

  /// Gets the singleton instance of [LaunchNotifier].
  static LaunchNotifier get instance => _instance;

  /// Selects a tab by its index.
  ///
  /// - [index]: The index of the tab to select.
  void selectTab(int index) {
    value = index;
  }

  /// Gets the currently selected tab index.
  int get selectedTab => value;
}
