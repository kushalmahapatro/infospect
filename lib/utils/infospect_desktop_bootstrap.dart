import 'package:flutter/material.dart';
import 'package:infospect/utils/infospect_multiview_bootstrap.dart';
import 'package:multiview_desktop/multiview_desktop.dart';

/// Desktop Multiview bootstrap for hosts that may gate Infospect behind a flag.
///
/// When Multiview native runners are installed, Dart must call [runMultiApp]
/// even if Infospect logging / [Infospect.ensureInitialized] is skipped.
/// Plain [runApp] on desktop leaves windows hidden and quit cancelled.
///
/// Prefer [Infospect.run] when the inspector is enabled. When Infospect is off
/// but Multiview runners remain, call [runAppOrMultiApp] (or
/// [Infospect.bootstrapMultiViewApp]).
///
/// See package `DESKTOP_COMPATIBILITY.md`.
class InfospectDesktopBootstrap {
  const InfospectDesktopBootstrap._();

  /// Whether desktop entry must use Multiview ([runMultiApp]) instead of
  /// [runApp]. Injectable [isWeb] / [desktopOs] support unit tests.
  static bool isDesktopMultiViewRequired({
    bool? isWeb,
    bool? desktopOs,
  }) {
    return isMultiViewDesktopBootstrapRequired(
      isWeb: isWeb,
      desktopOs: desktopOs,
    );
  }

  /// Boots [app] with [runMultiApp] on desktop Multiview hosts, [runApp]
  /// elsewhere. Does not require Infospect to be initialized.
  static void runAppOrMultiApp(
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
}
