import 'package:flutter/material.dart';
import 'package:infospect/utils/common_widgets/app_bottom_bar.dart';

/// Navigation tab data shared by the mobile shell switcher and desktop sidebar.
class NavigationTabData {
  static List<BottomBarItem> get tabs {
    return [
      (
        icon: Icons.public_outlined,
        selectedIcon: Icons.public,
        title: 'Network',
      ),
      (
        icon: Icons.terminal_outlined,
        selectedIcon: Icons.terminal,
        title: 'Logs',
      ),
    ];
  }
}
