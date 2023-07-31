import 'package:flutter/material.dart';
import 'package:infospect/ui/interceptor/screen/interceptor_desktop_screen.dart';

import 'interceptor_mobile_screen.dart';

class InfospectInterceptorScreen extends StatelessWidget {
  const InfospectInterceptorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth > 600) {
          return const InterceptorDesktopScreen();
        } else {
          return const InterceptorMobileScreen();
        }
      },
    );
  }
}
