import 'package:cuberto_bottom_bar/cuberto_bottom_bar.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

abstract class NavigationTabData {
  static List<TabData> get tabs {
    return [
      TabData(iconData: FontAwesomeIcons.globe, title: "Network calls"),
      TabData(iconData: FontAwesomeIcons.list, title: "Logs")
    ];
  }
}
