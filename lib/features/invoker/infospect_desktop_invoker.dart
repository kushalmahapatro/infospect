import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:infospect/infospect.dart';
import 'package:menu_bar/menu_bar.dart';

class InfospectDesktopInvoker extends StatelessWidget {
  const InfospectDesktopInvoker({
    super.key,
    required this.child,
    this.menus = const [],
  });
  final Widget child;
  final List<PlatformMenuItem> menus;

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

class _MacOsMenuBarWidget extends StatefulWidget {
  const _MacOsMenuBarWidget(this.invoker);

  final InfospectDesktopInvoker invoker;

  @override
  State<_MacOsMenuBarWidget> createState() => _MacOsMenuBarWidgetState();
}

class _MacOsMenuBarWidgetState extends State<_MacOsMenuBarWidget> {
  @override
  void initState() {
    WidgetsBinding.instance.platformMenuDelegate.setMenus(
      [
        ...widget.invoker.menus,
        _invokerMenu,
        if (PlatformProvidedMenuItem.hasMenu(PlatformProvidedMenuItemType.quit))
          const PlatformProvidedMenuItem(
              type: PlatformProvidedMenuItemType.quit),
      ],
    );
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return widget.invoker.child;
  }

  PlatformMenuItemGroup get _invokerMenu {
    return PlatformMenuItemGroup(
      members: [
        PlatformMenu(
          label: 'Options',
          menus: <PlatformMenuItem>[
            PlatformMenuItem(
              onSelected: () async {
                await Infospect.instance.openInspectorInNewWindow();
              },
              shortcut: const SingleActivator(
                LogicalKeyboardKey.keyI,
                meta: true,
              ),
              label: 'Infospect',
            ),
          ],
        )
      ],
    );
  }

  @override
  void didUpdateWidget(covariant _MacOsMenuBarWidget oldWidget) {
    if (oldWidget.invoker.menus != widget.invoker.menus) {
      WidgetsBinding.instance.platformMenuDelegate.setMenus(
        [
          ...widget.invoker.menus,
          _invokerMenu,
          if (PlatformProvidedMenuItem.hasMenu(
              PlatformProvidedMenuItemType.quit))
            const PlatformProvidedMenuItem(
                type: PlatformProvidedMenuItemType.quit),
        ],
      );
    }
    super.didUpdateWidget(oldWidget);
  }
}

class _OtherDesktopMenuBarWidget extends StatefulWidget {
  const _OtherDesktopMenuBarWidget(this.invoker);

  final InfospectDesktopInvoker invoker;

  @override
  State<_OtherDesktopMenuBarWidget> createState() =>
      _OtherDesktopMenuBarWidgetState();
}

class _OtherDesktopMenuBarWidgetState
    extends State<_OtherDesktopMenuBarWidget> {
  List<BarButton> _menuButton = [];
  set menuButtons(List<BarButton> menus) => _menuButton = menus;

  @override
  void initState() {
    _menuButton.add(_invokerMenu);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return MenuBarWidget(
      barButtons: _menuButton,
      child: widget.invoker.child,
    );
  }

  @override
  void didUpdateWidget(covariant _OtherDesktopMenuBarWidget oldWidget) {
    if (oldWidget.invoker.menus != widget.invoker.menus) {
      menuButtons = [_invokerMenu];
      setState(() {});
    }
    super.didUpdateWidget(oldWidget);
  }

  BarButton get _invokerMenu {
    return BarButton(
      text: const Text('Options'),
      submenu: SubMenu(
        menuItems: [
          MenuButton(
            text: const Text('Infospect'),
            shortcutText: 'Ctrl+Alt+I',
            shortcut: const SingleActivator(
              LogicalKeyboardKey.keyI,
              control: true,
              alt: true,
            ),
            onTap: () async =>
                await Infospect.instance.openInspectorInNewWindow(),
          )
        ],
      ),
    );
  }
}
