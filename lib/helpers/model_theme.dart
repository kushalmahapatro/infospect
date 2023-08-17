import 'package:flutter/material.dart';

class ModelTheme extends ChangeNotifier {
  late bool _isDark;

  bool get isDark => _isDark;

  ModelTheme() {
    _isDark = false;

    notifyListeners();
  }

//Switching the themes
  set isDark(bool value) {
    _isDark = value;

    notifyListeners();
  }
}
