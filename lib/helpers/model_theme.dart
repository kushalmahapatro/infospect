import 'package:flutter/material.dart';

class ModelTheme extends ChangeNotifier {
  late bool _isDark;

  bool get isDark => _isDark;

  ModelTheme() {
    _isDark = false;

    getPreferences();
  }

//Switching the themes
  set isDark(bool value) {
    _isDark = value;

    notifyListeners();
  }

  getPreferences() async {
    notifyListeners();
  }
}