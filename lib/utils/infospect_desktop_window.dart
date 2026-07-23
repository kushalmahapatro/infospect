import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:infospect/features/launch/desktop/infospect_desktop_shortcuts.dart';
import 'package:infospect/styling/themes/infospect_theme.dart';
import 'package:multiview_desktop/multiview_desktop.dart';

/// Shared desktop window chrome for Infospect.
///
/// [multiview_desktop]'s `resetWindowToDefaults` hides native min / max / close
/// buttons when [WindowOptions.windowButtonVisibility] is null. Always pass
/// these defaults for the host app and every Infospect secondary window.
///
/// When [enableCloseShortcut] is true (default), wraps the window shell so
/// ⌘W / Ctrl+W closes **this** focused Infospect window.
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
  bool enableCloseShortcut = true,
}) {
  final ViewShellOverrides? merged;
  if (!enableCloseShortcut) {
    merged = shellOverrides;
  } else {
    merged = ViewShellOverrides.merge(
      shellOverrides,
      ViewShellOverrides(
        builder: (context, child) {
          final built =
              shellOverrides?.builder?.call(context, child) ?? child;
          return InfospectDesktopWindowShortcuts(
            child: built ?? const SizedBox.shrink(),
          );
        },
      ),
    );
  }

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
    shellOverrides: merged,
  );
}

/// Theme shell used by Infospect secondary windows.
ViewShellOverrides infospectDesktopThemeShell({required bool darkTheme}) {
  return ViewShellOverrides(
    appearance: AppShellPatch(
      theme: InfospectTheme.lightTheme,
      darkTheme: InfospectTheme.darkTheme,
      themeMode: darkTheme ? ThemeMode.dark : ThemeMode.light,
    ),
  );
}

/// [MultiAppConfig] used by [Infospect.run] so the host desktop window keeps
/// native title-bar buttons after multiview startup reset.
///
/// Host window does **not** get Infospect's close-window shortcut.
MultiAppConfig infospectMultiAppConfig() {
  return MultiAppConfig(
    globalWindowOptions: infospectDesktopWindowOptions(
      enableCloseShortcut: false,
    ),
  );
}

/// Focus-gated ⌘W / Ctrl+W that closes the Multiview window owning [child].
///
/// Uses [HardwareKeyboard] (reliable in Multiview) but only acts while this
/// window is focused, so other Infospect windows are not closed by accident.
class InfospectDesktopWindowShortcuts extends StatefulWidget {
  const InfospectDesktopWindowShortcuts({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  State<InfospectDesktopWindowShortcuts> createState() =>
      _InfospectDesktopWindowShortcutsState();
}

class _InfospectDesktopWindowShortcutsState
    extends State<InfospectDesktopWindowShortcuts>
    implements WindowListenerCallbacks {
  bool _focused = true;
  int? _viewId;
  DateTime? _lastCloseAt;

  @override
  void initState() {
    super.initState();
    HardwareKeyboard.instance.addHandler(_onKeyEvent);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncFocusListener();
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_onKeyEvent);
    _unregisterFocusListener();
    super.dispose();
  }

  void _syncFocusListener() {
    if (kIsWeb) return;
    try {
      final id = MultiViewDesktop.getIdByContext(context);
      if (_viewId == id) return;
      _unregisterFocusListener();
      _viewId = id;
      MultiViewDesktop.addListenerForView(id, this);
    } catch (_) {
      // Tests / non-Multiview trees: treat as focused.
      _focused = true;
    }
  }

  void _unregisterFocusListener() {
    final id = _viewId;
    if (id == null) return;
    MultiViewDesktop.removeListenerForView(id, this);
    _viewId = null;
  }

  bool _onKeyEvent(KeyEvent event) {
    if (!_focused || event is! KeyDownEvent) return false;
    if (!InfospectDesktopShortcuts.closeWindow
        .accepts(event, HardwareKeyboard.instance)) {
      return false;
    }

    final now = DateTime.now();
    if (_lastCloseAt != null &&
        now.difference(_lastCloseAt!) < const Duration(milliseconds: 120)) {
      return true;
    }
    _lastCloseAt = now;
    _closeThisWindow();
    return true;
  }

  void _closeThisWindow() {
    try {
      MultiViewDesktop.of(context).closeWindow();
    } catch (_) {
      // No Multiview ancestor (widget tests).
    }
  }

  @override
  void onWindowFocus() {
    _focused = true;
  }

  @override
  void onWindowBlur() {
    _focused = false;
  }

  @override
  void onWindowClose() {}

  @override
  void onWindowMaximize() {}

  @override
  void onWindowUnmaximize() {}

  @override
  void onWindowMinimize() {}

  @override
  void onWindowRestore() {}

  @override
  void onWindowResize() {}

  @override
  void onWindowResized() {}

  @override
  void onWindowMove() {}

  @override
  void onWindowMoved() {}

  @override
  void onWindowEnterFullScreen() {}

  @override
  void onWindowLeaveFullScreen() {}

  @override
  void onWindowEvent(String eventName) {}

  @override
  Widget build(BuildContext context) {
    return CallbackShortcuts(
      bindings: {
        InfospectDesktopShortcuts.closeWindow: _closeThisWindow,
      },
      child: Focus(
        autofocus: true,
        skipTraversal: true,
        child: widget.child,
      ),
    );
  }
}
