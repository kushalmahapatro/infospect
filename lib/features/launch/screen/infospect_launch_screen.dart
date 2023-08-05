import 'package:flutter/material.dart';
import 'package:infospect/features/launch/screen/launch_desktop_screen.dart';
import 'package:infospect/helpers/infospect_helper.dart';

import 'launch_mobile_screen.dart';

class InfospectLaunchScreen extends StatelessWidget {
  final Infospect infospect;
  const InfospectLaunchScreen(this.infospect, {super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth > 600) {
          return LaunchDesktopScreen(infospect);
        } else {
          return LaunchMobileScreen(infospect);
        }
      },
    );
  }
}
