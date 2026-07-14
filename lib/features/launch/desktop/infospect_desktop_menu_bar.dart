import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:infospect/features/launch/desktop/infospect_desktop_shortcuts.dart';
import 'package:infospect/features/launch/models/infospect_desktop_tab.dart';
import 'package:infospect/features/launch/notifier/launch_notifier.dart';
import 'package:infospect/features/logger/ui/logs_list/notifier/logs_list_notifier.dart';
import 'package:infospect/features/network/breakpoints/ui/breakpoints_list_screen.dart';
import 'package:infospect/features/network/ui/list/notifier/networks_list_notifier.dart';
import 'package:infospect/helpers/infospect_helper.dart';
import 'package:infospect/utils/common_widgets/app_adaptive_dialog.dart';
import 'package:multiview_desktop/multiview_desktop.dart';

/// Native [PlatformMenuBar] is **not** used under Multiview.
///
/// Flutter's `flutter/menu` channel only targets a single main window, so the
/// system menu bar never appears for Infospect secondary Multiview windows.
/// Always use the in-window Material menu instead.
bool infospectSupportsNativeMenuBar() => false;

/// In-window menu bar + keyboard shortcuts for the Infospect desktop inspector.
///
/// Shortcut labels are shown on each menu item. Keys are handled with a
/// focus-gated [HardwareKeyboard] handler so they work inside search fields
/// without affecting other Infospect windows.
class InfospectDesktopMenuShell extends StatefulWidget {
  const InfospectDesktopMenuShell({
    super.key,
    required this.infospect,
    required this.networksListNotifier,
    required this.logsListNotifier,
    required this.child,
    @Deprecated('Native menu is unavailable under Multiview; always in-app.')
    this.forceInAppMenuBar = true,
  });

  final Infospect infospect;
  final NetworksListNotifier networksListNotifier;
  final LogsListNotifier logsListNotifier;
  final Widget child;

  /// Ignored — in-app menu is always used under Multiview.
  @Deprecated('Native menu is unavailable under Multiview; always in-app.')
  final bool forceInAppMenuBar;

  static const double inAppMenuBarHeight = 34;

  @override
  State<InfospectDesktopMenuShell> createState() =>
      _InfospectDesktopMenuShellState();
}

class _InfospectDesktopMenuShellState extends State<InfospectDesktopMenuShell>
    implements WindowListenerCallbacks {
  late InfospectDesktopMenuActions _actions;
  Map<ShortcutActivator, VoidCallback> _bindings = {};
  DateTime? _lastShortcutAt;
  bool _focused = true;
  int? _viewId;

  @override
  void initState() {
    super.initState();
    _rebuildActions();
    HardwareKeyboard.instance.addHandler(_onKeyEvent);
  }

  @override
  void didUpdateWidget(covariant InfospectDesktopMenuShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    _rebuildActions();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _rebuildActions();
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
      _focused = true;
    }
  }

  void _unregisterFocusListener() {
    final id = _viewId;
    if (id == null) return;
    MultiViewDesktop.removeListenerForView(id, this);
    _viewId = null;
  }

  void _rebuildActions() {
    _actions = InfospectDesktopMenuActions(
      context: context,
      infospect: widget.infospect,
      networks: widget.networksListNotifier,
      logs: widget.logsListNotifier,
    );
    // Close-window is owned by [InfospectDesktopWindowShortcuts] on every
    // Infospect window — omit it here to avoid double-handling.
    _bindings = {
      for (final entry in _actions.shortcutBindings.entries)
        if (entry.key != InfospectDesktopShortcuts.closeWindow)
          entry.key: () => _runShortcut(entry.value),
    };
  }

  void _runShortcut(VoidCallback action) {
    final now = DateTime.now();
    if (_lastShortcutAt != null &&
        now.difference(_lastShortcutAt!) < const Duration(milliseconds: 120)) {
      return;
    }
    _lastShortcutAt = now;
    action();
  }

  bool _onKeyEvent(KeyEvent event) {
    if (!_focused || event is! KeyDownEvent) return false;
    for (final entry in _bindings.entries) {
      if (entry.key.accepts(event, HardwareKeyboard.instance)) {
        entry.value();
        return true;
      }
    }
    return false;
  }

  @override
  void onWindowFocus() => _focused = true;

  @override
  void onWindowBlur() => _focused = false;

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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        InfospectDesktopInAppMenuBar(actions: _actions),
        Expanded(child: widget.child),
      ],
    );
  }
}

/// Shared menu / shortcut actions for the Infospect desktop window.
class InfospectDesktopMenuActions {
  InfospectDesktopMenuActions({
    required this.context,
    required this.infospect,
    required this.networks,
    required this.logs,
  });

  final BuildContext context;
  final Infospect infospect;
  final NetworksListNotifier networks;
  final LogsListNotifier logs;

  Map<ShortcutActivator, VoidCallback> get shortcutBindings => {
        InfospectDesktopShortcuts.networkTab: selectNetwork,
        InfospectDesktopShortcuts.logsTab: selectLogs,
        InfospectDesktopShortcuts.breakpoints: openBreakpoints,
        InfospectDesktopShortcuts.clearNetwork: clearNetwork,
        InfospectDesktopShortcuts.shareNetwork: shareNetwork,
        InfospectDesktopShortcuts.popOutNetwork: popOutNetwork,
        InfospectDesktopShortcuts.clearLogs: clearLogs,
        InfospectDesktopShortcuts.shareLogs: shareLogs,
        InfospectDesktopShortcuts.popOutLogs: popOutLogs,
        InfospectDesktopShortcuts.closeWindow: closeWindow,
      };

  /// Kept for tests / hosts that want the same menu model as a [PlatformMenuBar].
  List<PlatformMenuItem> buildNativeMenus({
    void Function(VoidCallback action)? runGuarded,
  }) {
    void run(VoidCallback action) {
      if (runGuarded != null) {
        runGuarded(action);
      } else {
        action();
      }
    }

    return [
      PlatformMenu(
        label: 'View',
        menus: [
          PlatformMenuItem(
            label: 'Network',
            shortcut: InfospectDesktopShortcuts.networkTab,
            onSelected: () => run(selectNetwork),
          ),
          PlatformMenuItem(
            label: 'Logs',
            shortcut: InfospectDesktopShortcuts.logsTab,
            onSelected: () => run(selectLogs),
          ),
          PlatformMenuItemGroup(
            members: [
              PlatformMenuItem(
                label: 'Breakpoints…',
                shortcut: InfospectDesktopShortcuts.breakpoints,
                onSelected: () => run(openBreakpoints),
              ),
            ],
          ),
        ],
      ),
      PlatformMenu(
        label: 'Network',
        menus: [
          PlatformMenuItem(
            label: 'Clear Network Calls',
            shortcut: InfospectDesktopShortcuts.clearNetwork,
            onSelected: () => run(clearNetwork),
          ),
          PlatformMenuItem(
            label: 'Share Network Calls',
            shortcut: InfospectDesktopShortcuts.shareNetwork,
            onSelected: () => run(shareNetwork),
          ),
          PlatformMenuItemGroup(
            members: [
              PlatformMenuItem(
                label: 'Open Network in New Window',
                shortcut: InfospectDesktopShortcuts.popOutNetwork,
                onSelected: () => run(popOutNetwork),
              ),
            ],
          ),
        ],
      ),
      PlatformMenu(
        label: 'Logs',
        menus: [
          PlatformMenuItem(
            label: 'Clear Logs',
            shortcut: InfospectDesktopShortcuts.clearLogs,
            onSelected: () => run(clearLogs),
          ),
          PlatformMenuItem(
            label: 'Share Logs',
            shortcut: InfospectDesktopShortcuts.shareLogs,
            onSelected: () => run(shareLogs),
          ),
          PlatformMenuItemGroup(
            members: [
              PlatformMenuItem(
                label: 'Open Logs in New Window',
                shortcut: InfospectDesktopShortcuts.popOutLogs,
                onSelected: () => run(popOutLogs),
              ),
            ],
          ),
        ],
      ),
      PlatformMenu(
        label: 'Window',
        menus: [
          PlatformMenuItem(
            label: 'Close Window',
            shortcut: InfospectDesktopShortcuts.closeWindow,
            onSelected: () => run(closeWindow),
          ),
        ],
      ),
    ];
  }

  void selectNetwork() {
    final popped = infospect.poppedOutDesktopTabs.value;
    if (popped.contains(InfospectDesktopTab.network)) {
      infospect.focusPoppedOutDesktopTab(InfospectDesktopTab.network);
      return;
    }
    LaunchNotifier.instance.selectTab(InfospectDesktopTab.network.tabIndex);
  }

  void selectLogs() {
    final popped = infospect.poppedOutDesktopTabs.value;
    if (popped.contains(InfospectDesktopTab.logs)) {
      infospect.focusPoppedOutDesktopTab(InfospectDesktopTab.logs);
      return;
    }
    LaunchNotifier.instance.selectTab(InfospectDesktopTab.logs.tabIndex);
  }

  void openBreakpoints() {
    BreakpointsListScreen.open(context);
  }

  void clearNetwork() {
    AppAdaptiveDialog.show(
      context,
      tag: 'network_calls',
      title: 'Clear Network Call Logs?',
      body:
          'Are you sure you want to clear all network call logs? This will clear up the list.',
      onPositiveActionClick: networks.clearNetworkLogs,
    );
  }

  void shareNetwork() {
    networks.shareNetworkLogs();
  }

  void popOutNetwork() {
    final popped = infospect.poppedOutDesktopTabs.value;
    if (popped.contains(InfospectDesktopTab.network)) {
      infospect.focusPoppedOutDesktopTab(InfospectDesktopTab.network);
      return;
    }
    infospect.popOutDesktopTab(InfospectDesktopTab.network);
  }

  void clearLogs() {
    AppAdaptiveDialog.show(
      context,
      tag: 'logs',
      title: 'Clear Logs?',
      body:
          'Are you sure you want to clear all logs? This will clear up the list.',
      onPositiveActionClick: logs.clearAllLogs,
    );
  }

  void shareLogs() {
    logs.shareAllLogs();
  }

  void popOutLogs() {
    final popped = infospect.poppedOutDesktopTabs.value;
    if (popped.contains(InfospectDesktopTab.logs)) {
      infospect.focusPoppedOutDesktopTab(InfospectDesktopTab.logs);
      return;
    }
    infospect.popOutDesktopTab(InfospectDesktopTab.logs);
  }

  void closeWindow() {
    try {
      MultiViewDesktop.of(context).closeWindow();
    } catch (_) {}
  }
}

/// In-window Material menu bar with trailing shortcut labels.
class InfospectDesktopInAppMenuBar extends StatelessWidget {
  const InfospectDesktopInAppMenuBar({super.key, required this.actions});

  final InfospectDesktopMenuActions actions;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final barFg = theme.colorScheme.onSurface;
    final shortcutFg = theme.colorScheme.onSurface.withValues(alpha: 0.55);
    final barBg = Color.alphaBlend(
      theme.colorScheme.primary.withValues(alpha: 0.08),
      theme.colorScheme.surfaceContainerHigh,
    );
    final borderColor = theme.colorScheme.outlineVariant.withValues(alpha: 0.75);
    final shortcutStyle = TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w500,
      color: shortcutFg,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
    final barLabelStyle = theme.textTheme.labelLarge?.copyWith(
      fontSize: 12,
      fontWeight: FontWeight.w600,
      color: barFg,
    );

    ButtonStyle barButtonStyle() => ButtonStyle(
          foregroundColor: WidgetStatePropertyAll(barFg),
          textStyle: WidgetStatePropertyAll(barLabelStyle),
          padding: const WidgetStatePropertyAll(
            EdgeInsets.symmetric(horizontal: 10),
          ),
          minimumSize: const WidgetStatePropertyAll(
            Size(0, InfospectDesktopMenuShell.inAppMenuBarHeight),
          ),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          visualDensity: VisualDensity.compact,
          overlayColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.hovered) ||
                states.contains(WidgetState.focused) ||
                states.contains(WidgetState.pressed)) {
              return barFg.withValues(alpha: 0.1);
            }
            return null;
          }),
        );

    MenuItemButton item({
      required String label,
      required VoidCallback onPressed,
      required String shortcutText,
    }) {
      return MenuItemButton(
        onPressed: onPressed,
        trailingIcon: Padding(
          padding: const EdgeInsets.only(left: 28),
          child: Text(shortcutText, style: shortcutStyle),
        ),
        child: Text(label),
      );
    }

    return Material(
      color: barBg,
      elevation: 0,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: borderColor),
          ),
        ),
        child: SizedBox(
          height: InfospectDesktopMenuShell.inAppMenuBarHeight,
          width: double.infinity,
          child: Align(
            alignment: Alignment.centerLeft,
            child: MenuBar(
              style: MenuStyle(
                backgroundColor:
                    const WidgetStatePropertyAll(Colors.transparent),
                elevation: const WidgetStatePropertyAll(0),
                padding: const WidgetStatePropertyAll(EdgeInsets.zero),
                minimumSize: const WidgetStatePropertyAll(
                  Size(0, InfospectDesktopMenuShell.inAppMenuBarHeight),
                ),
                maximumSize: const WidgetStatePropertyAll(
                  Size(
                    double.infinity,
                    InfospectDesktopMenuShell.inAppMenuBarHeight,
                  ),
                ),
              ),
              children: [
                SubmenuButton(
                  style: barButtonStyle(),
                  menuChildren: [
                    item(
                      label: 'Network',
                      onPressed: actions.selectNetwork,
                      shortcutText: InfospectDesktopShortcuts.networkTabLabel,
                    ),
                    item(
                      label: 'Logs',
                      onPressed: actions.selectLogs,
                      shortcutText: InfospectDesktopShortcuts.logsTabLabel,
                    ),
                    const Divider(height: 8),
                    item(
                      label: 'Breakpoints…',
                      onPressed: actions.openBreakpoints,
                      shortcutText: InfospectDesktopShortcuts.breakpointsLabel,
                    ),
                  ],
                  child: const Text('View'),
                ),
                SubmenuButton(
                  style: barButtonStyle(),
                  menuChildren: [
                    item(
                      label: 'Clear Network Calls',
                      onPressed: actions.clearNetwork,
                      shortcutText: InfospectDesktopShortcuts.clearNetworkLabel,
                    ),
                    item(
                      label: 'Share Network Calls',
                      onPressed: actions.shareNetwork,
                      shortcutText: InfospectDesktopShortcuts.shareNetworkLabel,
                    ),
                    const Divider(height: 8),
                    item(
                      label: 'Open Network in New Window',
                      onPressed: actions.popOutNetwork,
                      shortcutText:
                          InfospectDesktopShortcuts.popOutNetworkLabel,
                    ),
                  ],
                  child: const Text('Network'),
                ),
                SubmenuButton(
                  style: barButtonStyle(),
                  menuChildren: [
                    item(
                      label: 'Clear Logs',
                      onPressed: actions.clearLogs,
                      shortcutText: InfospectDesktopShortcuts.clearLogsLabel,
                    ),
                    item(
                      label: 'Share Logs',
                      onPressed: actions.shareLogs,
                      shortcutText: InfospectDesktopShortcuts.shareLogsLabel,
                    ),
                    const Divider(height: 8),
                    item(
                      label: 'Open Logs in New Window',
                      onPressed: actions.popOutLogs,
                      shortcutText: InfospectDesktopShortcuts.popOutLogsLabel,
                    ),
                  ],
                  child: const Text('Logs'),
                ),
                SubmenuButton(
                  style: barButtonStyle(),
                  menuChildren: [
                    item(
                      label: 'Close Window',
                      onPressed: actions.closeWindow,
                      shortcutText: InfospectDesktopShortcuts.closeWindowLabel,
                    ),
                  ],
                  child: const Text('Window'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
