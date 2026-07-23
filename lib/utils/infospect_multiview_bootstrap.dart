import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:infospect/utils/infospect_desktop_window.dart';
import 'package:multiview_desktop/multiview_desktop.dart';

/// Whether desktop entry must use [runMultiApp] instead of [runApp].
///
/// Returns `true` on macOS / Windows / Linux when not running on web.
/// Hosts that wired Multiview native runners **must** use
/// [bootstrapMultiViewApp] (or [Infospect.run]) whenever this is true —
/// plain [runApp] leaves Multiview terminate handling without a Dart listener
/// and can hang quit on macOS.
///
/// [isWeb] / [desktopOs] are injectable for unit tests.
bool isMultiViewDesktopBootstrapRequired({
  bool? isWeb,
  bool? desktopOs,
}) {
  if (isWeb ?? kIsWeb) return false;
  return desktopOs ?? _defaultDesktopOs;
}

bool get _defaultDesktopOs {
  switch (defaultTargetPlatform) {
    case TargetPlatform.macOS:
    case TargetPlatform.windows:
    case TargetPlatform.linux:
      return true;
    case TargetPlatform.android:
    case TargetPlatform.iOS:
    case TargetPlatform.fuchsia:
      return false;
  }
}

/// Boots [app] with [runMultiApp] on desktop Multiview hosts, [runApp] elsewhere.
///
/// Safe even when [Infospect.ensureInitialized] was never called and Infospect
/// logging is disabled — hosts with Multiview natives should always use this
/// (or [Infospect.run]) instead of plain [runApp] on desktop.
///
/// Optional [config] overrides Infospect's default Multiview
/// [MultiAppConfig] (native title-bar buttons enabled).
void bootstrapMultiViewApp(
  Widget app, {
  MultiAppConfig? config,
  bool? isWeb,
  bool? desktopOs,
}) {
  if (isMultiViewDesktopBootstrapRequired(isWeb: isWeb, desktopOs: desktopOs)) {
    runMultiApp(
      home: (context, id) => app,
      config: config ?? infospectMultiAppConfig(),
    );
  } else {
    runApp(app);
  }
}

/// Alias for [bootstrapMultiViewApp].
void bootstrapDesktopApp(
  Widget app, {
  MultiAppConfig? config,
  bool? isWeb,
  bool? desktopOs,
}) {
  bootstrapMultiViewApp(
    app,
    config: config,
    isWeb: isWeb,
    desktopOs: desktopOs,
  );
}
