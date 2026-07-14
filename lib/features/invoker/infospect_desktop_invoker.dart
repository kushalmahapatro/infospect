import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:infospect/features/invoker/infospect_invoker.dart';
import 'package:infospect/features/launch/desktop/infospect_desktop_shortcuts.dart';
import 'package:infospect/helpers/infospect_helper.dart';
import 'package:menu_bar/menu_bar.dart';
import 'package:multiview_desktop/multiview_desktop.dart';

/// Optional host-app menu integration that **appends** Infospect without
/// replacing consumer menus.
///
/// Prefer [InfospectInvoker] when the host already owns its menu bar — that
/// path only registers the open-inspector keyboard shortcut and never touches
/// platform / in-app menus.
///
/// When you do use this widget:
/// - **macOS:** pass the host's existing [PlatformMenuItem]s via [menus]. They
///   are kept and Infospect is appended. Do not also wrap with a separate
///   [PlatformMenuBar] that would race on `setMenus`.
/// - **Windows / Linux:** pass the host's [BarButton]s via [barButtons]. They
///   are shown first; Infospect's "Options" menu is appended.
///
/// Infospect's own desktop inspector window uses an in-window Material
/// [MenuBar] (see `InfospectDesktopMenuShell`) and does not use this widget.
class InfospectDesktopInvoker extends StatelessWidget {
  const InfospectDesktopInvoker({
    super.key,
    required this.child,
    this.menus = const [],
    this.barButtons = const [],
  });

  final Widget child;

  /// Host macOS [PlatformMenuBar] items. Preserved and listed before Infospect.
  final List<PlatformMenuItem> menus;

  /// Host Windows / Linux [MenuBarWidget] buttons. Preserved and listed before
  /// Infospect's Options menu.
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
          shortcut: InfospectDesktopShortcuts.openInspectorMac,
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
  Widget build(BuildContext context) {
    if (kIsWeb) return child;

    if (Platform.isMacOS) {
      return _MacOsMenuBarWidget(this);
    } else if (Platform.isWindows || Platform.isLinux) {
      return _OtherDesktopMenuBarWidget(this);
    }

    return InfospectInvoker(child: child);
  }
}

class _MacOsMenuBarWidget extends StatelessWidget {
  const _MacOsMenuBarWidget(this.invoker);

  final InfospectDesktopInvoker invoker;

  @override
  Widget build(BuildContext context) {
    return PlatformMenuBar(
      menus: InfospectDesktopInvoker.mergePlatformMenus(invoker.menus),
      child: CallbackShortcuts(
        bindings: {
          for (final activator
              in InfospectDesktopShortcuts.openInspectorActivators)
            activator: () {
              Infospect.instance.openInspectorInNewWindow();
            },
        },
        child: invoker.child,
      ),
    );
  }
}

class _OtherDesktopMenuBarWidget extends StatelessWidget {
  const _OtherDesktopMenuBarWidget(this.invoker);

  final InfospectDesktopInvoker invoker;

  @override
  Widget build(BuildContext context) {
    return MenuBarWidget(
      barButtons: InfospectDesktopInvoker.mergeBarButtons(invoker.barButtons),
      child: CallbackShortcuts(
        bindings: {
          for (final activator
              in InfospectDesktopShortcuts.openInspectorActivators)
            activator: () {
              Infospect.instance.openInspectorInNewWindow();
            },
        },
        child: invoker.child,
      ),
    );
  }
}
