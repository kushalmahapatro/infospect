import 'package:flutter/material.dart';
import 'package:infospect/helpers/infospect_helper.dart';
import 'package:infospect/ui/interceptor/screen/interceptor_desktop_screen.dart';

import 'interceptor_mobile_screen.dart';

class InfospectInterceptorScreen extends StatelessWidget {
  final Infospect infospect;
  const InfospectInterceptorScreen(this.infospect, {super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth > 600) {
          return InterceptorDesktopScreen(infospect);
        } else {
          return InterceptorMobileScreen(infospect);
        }
      },
    );
  }
}
