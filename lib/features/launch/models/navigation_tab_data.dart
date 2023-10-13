import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:infospect/utils/common_widgets/app_bottom_bar.dart';

/// An class that provides navigation tab data for bottom navigation.
class NavigationTabData {
  static List<BottomBarItem> get tabs {
    return [
      (icon: FontAwesomeIcons.globe, title: "Network calls"),
      (icon: FontAwesomeIcons.list, title: "Logs")
    ];
  }
}
