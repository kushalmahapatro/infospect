import 'package:cuberto_bottom_bar/cuberto_bottom_bar.dart';
import 'package:flutter/material.dart';

class AppBottomBar extends StatelessWidget {
  const AppBottomBar(
      {super.key,
      required this.tabs,
      required this.selectedIndex,
      this.tabChangedCallback});

  final List<BottomBarItem> tabs;
  final ValueChanged<int>? tabChangedCallback;
  final int selectedIndex;

  @override
  Widget build(BuildContext context) {
    return CubertoBottomBar(
      key: const Key("BottomBar"),
      barShadow: const [BoxShadow(blurRadius: 0)],
      selectedTab: selectedIndex,
      tabs: tabs.map((e) => TabData(iconData: e.icon, title: e.title)).toList(),
      inactiveIconColor: Theme.of(context).colorScheme.onSurface,
      barBackgroundColor: Theme.of(context).colorScheme.surface,
      textColor: Theme.of(context).colorScheme.onPrimary,
      onTabChangedListener: (int position, String title, Color? tabColor) {
        tabChangedCallback?.call(position);
      },
    );
  }
}

typedef BottomBarItem = ({IconData icon, String title});
