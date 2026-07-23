import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:infospect/features/invoker/infospect_invoker.dart';
import 'package:infospect/features/launch/desktop/infospect_desktop_shortcuts.dart';
import 'package:infospect/helpers/infospect_helper.dart';
import 'package:menu_bar/menu_bar.dart';
import 'package:multiview_desktop/multiview_desktop.dart';

/// Optional host-app helpers that **append** Infospect without replacing
/// consumer menus.
///
/// Prefer [InfospectInvoker] when the host already owns its menu bar — that
/// path only registers the open-inspector keyboard shortcut.
///
/// **Do not** wrap the host in a [PlatformMenuBar] from this widget: Flutter
/// allows only one active [PlatformMenuBar] per isolate, and the Infospect
/// inspector window installs its own native menus on macOS. Use
/// [mergePlatformMenus] inside the host’s existing [PlatformMenuBar] instead.
///
/// On Windows / Linux, pass host [barButtons] so they are preserved and
/// Infospect is appended to the in-app [MenuBarWidget].
class InfospectDesktopInvoker extends StatefulWidget {
  const InfospectDesktopInvoker({
    super.key,
    required this.child,
    this.menus = const [],
    this.barButtons = const [],
  });

  final Widget child;

  /// Host macOS menu items to merge via [mergePlatformMenus] (for hosts that
  /// build their own [PlatformMenuBar]). Not applied automatically — see
  /// [mergePlatformMenus].
  final List<PlatformMenuItem> menus;

  /// Host Windows / Linux [MenuBarWidget] buttons. Preserved and listed before
  /// Infospect's menu.
  final List<BarButton> barButtons;

  /// Builds the Infospect [PlatformMenu] for hosts that already own a
  /// [PlatformMenuBar] and only need to insert one item.
  static PlatformMenu platformMenu({
    Future<void> Function()? onOpen,
  }) {
    return PlatformMenu(
      label: 'Infospect',
      menus: <PlatformMenuItem>[
        PlatformMenuItem(
          onSelected: () async {
            await (onOpen ?? Infospect.instance.openInspectorInNewWindow)();
          },
          shortcut: InfospectDesktopShortcuts.isApple
              ? InfospectDesktopShortcuts.openInspectorMac
              : InfospectDesktopShortcuts.openInspectorOther,
          label: 'Open Infospect',
        ),
      ],
    );
  }

  /// Appends Infospect to [hostMenus] without dropping host entries.
  static List<PlatformMenuItem> mergePlatformMenus(
    List<PlatformMenuItem> hostMenus, {
    Future<void> Function()? onOpen,
  }) {
    return [
      ...hostMenus,
      platformMenu(onOpen: onOpen),
    ];
  }

  /// Builds the Infospect [BarButton] for Windows / Linux in-app menu bars.
  static BarButton barButton({
    Future<void> Function()? onOpen,
  }) {
    return BarButton(
      text: const Text('Infospect'),
      submenu: SubMenu(
        menuItems: [
          MenuButton(
            text: const Text('Open Infospect'),
            shortcutText: InfospectDesktopShortcuts.openInspectorLabel,
            shortcut: InfospectDesktopShortcuts.isApple
                ? InfospectDesktopShortcuts.openInspectorMac
                : InfospectDesktopShortcuts.openInspectorOther,
            onTap: () async {
              await (onOpen ?? Infospect.instance.openInspectorInNewWindow)();
            },
          ),
        ],
      ),
    );
  }

  /// Appends Infospect to [hostButtons] without dropping host entries.
  static List<BarButton> mergeBarButtons(
    List<BarButton> hostButtons, {
    Future<void> Function()? onOpen,
  }) {
    return [
      ...hostButtons,
      barButton(onOpen: onOpen),
    ];
  }

  /// Appends an "Open Infospect" dock / taskbar item. Multiview
  /// [MultiViewDesktop.setMenuItems] replaces the full list — always pass the
  /// merged result of this helper (never Infospect-only items).
  static List<TaskbarMenuItem> mergeTaskbarMenus(
    List<TaskbarMenuItem> hostItems, {
    VoidCallback? onOpen,
  }) {
    return [
      ...hostItems,
      TaskbarMenuItem(
        title: 'Open Infospect',
        onPressed: onOpen ??
            () {
              Infospect.instance.openInspectorInNewWindow();
            },
      ),
    ];
  }

  @override
  State<InfospectDesktopInvoker> createState() =>
      _InfospectDesktopInvokerState();
}

class _InfospectDesktopInvokerState extends State<InfospectDesktopInvoker> {
  @override
  void initState() {
    super.initState();
    HardwareKeyboard.instance.addHandler(_onKeyEvent);
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_onKeyEvent);
    super.dispose();
  }

  bool _onKeyEvent(KeyEvent event) {
    if (event is! KeyDownEvent) return false;
    for (final activator in InfospectDesktopShortcuts.openInspectorActivators) {
      if (activator.accepts(event, HardwareKeyboard.instance)) {
        Infospect.instance.openInspectorInNewWindow();
        return true;
      }
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) return widget.child;

    // macOS: do not install PlatformMenuBar here — the Infospect inspector
    // window owns the native menu bar. Hosts should use mergePlatformMenus.
    if (Platform.isMacOS) {
      return widget.child;
    }

    if (Platform.isWindows || Platform.isLinux) {
      return MenuBarWidget(
        barButtons:
            InfospectDesktopInvoker.mergeBarButtons(widget.barButtons),
        child: widget.child,
      );
    }

    return InfospectInvoker(child: widget.child);
  }
}
