import 'package:flutter/material.dart';
import 'package:multiview_desktop/multiview_desktop.dart';

/// Shared desktop window chrome for Infospect.
///
/// [multiview_desktop]'s `resetWindowToDefaults` hides native min / max / close
/// buttons when [WindowOptions.windowButtonVisibility] is null. Always pass
/// these defaults for the host app and every Infospect secondary window.
WindowOptions infospectDesktopWindowOptions({
  String? title,
  Size? size,
  Size? minimumSize,
  Size? maximumSize,
  Alignment? alignment = Alignment.center,
  Color? backgroundColor,
  bool? fullScreen,
  bool? alwaysOnTop,
  ViewShellOverrides? shellOverrides,
}) {
  return WindowOptions(
    title: title,
    size: size,
    minimumSize: minimumSize,
    maximumSize: maximumSize,
    alignment: alignment,
    backgroundColor: backgroundColor,
    fullScreen: fullScreen,
    alwaysOnTop: alwaysOnTop,
    titleBarStyle: TitleBarStyle.normal,
    windowButtonVisibility: true,
    shellOverrides: shellOverrides,
  );
}

/// [MultiAppConfig] used by [Infospect.run] so the host desktop window keeps
/// native title-bar buttons after multiview startup reset.
MultiAppConfig infospectMultiAppConfig() {
  return MultiAppConfig(
    globalWindowOptions: infospectDesktopWindowOptions(),
  );
}
