import 'package:flutter/foundation.dart';

/// `DesktopThemeNotifier` manages the theme state for a desktop application.
/// It is responsible for handling theme-related actions and notifying listeners.
class DesktopThemeNotifier extends ChangeNotifier {
  bool _isDarkTheme = true;

  /// Gets whether the current theme is dark.
  bool get isDarkTheme => _isDarkTheme;

  /// Sets the theme based on the provided value.
  ///
  /// - `isDark`: A boolean indicating whether the theme should be set to dark or not.
  void setTheme(bool isDark) {
    if (_isDarkTheme != isDark) {
      _isDarkTheme = isDark;
      notifyListeners();
    }
  }

  /// Toggles between dark and light theme.
  void toggleTheme() {
    _isDarkTheme = !_isDarkTheme;
    notifyListeners();
  }
}
