import 'package:flutter/material.dart';
import 'package:infospect/features/launch/screen/launch_desktop_screen.dart';
import 'package:infospect/features/logger/ui/logs_list/notifier/logs_list_notifier.dart';
import 'package:infospect/features/network/ui/list/notifier/networks_list_notifier.dart';
import 'package:infospect/helpers/infospect_helper.dart';

import 'launch_mobile_screen.dart';

class InfospectLaunchScreen extends StatelessWidget {
  final Infospect infospect;
  final NetworksListNotifier networksListNotifier;
  final LogsListNotifier logsListNotifier;

  const InfospectLaunchScreen(
    this.infospect, {
    required this.networksListNotifier,
    required this.logsListNotifier,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth > 600) {
          return LaunchDesktopScreen(
            infospect,
            networksListNotifier: networksListNotifier,
            logsListNotifier: logsListNotifier,
          );
        } else {
          return LaunchMobileScreen(
            infospect,
            networksListNotifier: networksListNotifier,
            logsListNotifier: logsListNotifier,
          );
        }
      },
    );
  }
}
