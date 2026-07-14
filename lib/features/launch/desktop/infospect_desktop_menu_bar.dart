import 'package:flutter/material.dart';
import 'package:infospect/features/launch/desktop/infospect_desktop_shortcuts.dart';
import 'package:infospect/features/launch/models/infospect_desktop_tab.dart';
import 'package:infospect/features/launch/notifier/launch_notifier.dart';
import 'package:infospect/features/logger/ui/logs_list/notifier/logs_list_notifier.dart';
import 'package:infospect/features/network/breakpoints/ui/breakpoints_list_screen.dart';
import 'package:infospect/features/network/ui/list/notifier/networks_list_notifier.dart';
import 'package:infospect/helpers/infospect_helper.dart';
import 'package:infospect/utils/common_widgets/app_adaptive_dialog.dart';
import 'package:multiview_desktop/multiview_desktop.dart';

/// In-window menu bar + keyboard shortcuts for the Infospect desktop layout.
///
/// Scoped to the Infospect window only — does **not** call
/// `platformMenuDelegate.setMenus` or Multiview `setMenuItems`, so host app
/// menu bars and dock/taskbar menus are never replaced.
class InfospectDesktopMenuShell extends StatelessWidget {
  const InfospectDesktopMenuShell({
    super.key,
    required this.infospect,
    required this.networksListNotifier,
    required this.logsListNotifier,
    required this.child,
  });

  final Infospect infospect;
  final NetworksListNotifier networksListNotifier;
  final LogsListNotifier logsListNotifier;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final actions = _InfospectDesktopMenuActions(
      context: context,
      infospect: infospect,
      networks: networksListNotifier,
      logs: logsListNotifier,
    );

    return CallbackShortcuts(
      bindings: actions.shortcutBindings,
      child: Focus(
        autofocus: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _InfospectDesktopMenuBar(actions: actions),
            Expanded(child: child),
          ],
        ),
      ),
    );
  }
}

class _InfospectDesktopMenuActions {
  _InfospectDesktopMenuActions({
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
    } catch (_) {
      // Host may not be under a MultiViewDesktop ancestor (e.g. tests).
    }
  }
}

class _InfospectDesktopMenuBar extends StatelessWidget {
  const _InfospectDesktopMenuBar({required this.actions});

  final _InfospectDesktopMenuActions actions;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final labelStyle = theme.textTheme.labelLarge?.copyWith(
      fontSize: 12,
      fontWeight: FontWeight.w500,
    );

    return Material(
      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
      child: SizedBox(
        height: 28,
        child: MenuBar(
          style: MenuStyle(
            backgroundColor: WidgetStatePropertyAll(
              theme.colorScheme.surface.withValues(alpha: 0),
            ),
            elevation: const WidgetStatePropertyAll(0),
            padding: const WidgetStatePropertyAll(
              EdgeInsets.symmetric(horizontal: 4),
            ),
          ),
          children: [
            SubmenuButton(
              style: ButtonStyle(
                textStyle: WidgetStatePropertyAll(labelStyle),
                padding: const WidgetStatePropertyAll(
                  EdgeInsets.symmetric(horizontal: 8),
                ),
                minimumSize: const WidgetStatePropertyAll(Size(0, 28)),
                visualDensity: VisualDensity.compact,
              ),
              menuChildren: [
                MenuItemButton(
                  onPressed: actions.selectNetwork,
                  shortcut: InfospectDesktopShortcuts.networkTab,
                  child: const Text('Network'),
                ),
                MenuItemButton(
                  onPressed: actions.selectLogs,
                  shortcut: InfospectDesktopShortcuts.logsTab,
                  child: const Text('Logs'),
                ),
                const Divider(),
                MenuItemButton(
                  onPressed: actions.openBreakpoints,
                  shortcut: InfospectDesktopShortcuts.breakpoints,
                  child: const Text('Breakpoints…'),
                ),
              ],
              child: const Text('View'),
            ),
            SubmenuButton(
              style: ButtonStyle(
                textStyle: WidgetStatePropertyAll(labelStyle),
                padding: const WidgetStatePropertyAll(
                  EdgeInsets.symmetric(horizontal: 8),
                ),
                minimumSize: const WidgetStatePropertyAll(Size(0, 28)),
                visualDensity: VisualDensity.compact,
              ),
              menuChildren: [
                MenuItemButton(
                  onPressed: actions.clearNetwork,
                  shortcut: InfospectDesktopShortcuts.clearNetwork,
                  child: const Text('Clear Network Calls'),
                ),
                MenuItemButton(
                  onPressed: actions.shareNetwork,
                  shortcut: InfospectDesktopShortcuts.shareNetwork,
                  child: const Text('Share Network Calls'),
                ),
                const Divider(),
                MenuItemButton(
                  onPressed: actions.popOutNetwork,
                  shortcut: InfospectDesktopShortcuts.popOutNetwork,
                  child: const Text('Open Network in New Window'),
                ),
              ],
              child: const Text('Network'),
            ),
            SubmenuButton(
              style: ButtonStyle(
                textStyle: WidgetStatePropertyAll(labelStyle),
                padding: const WidgetStatePropertyAll(
                  EdgeInsets.symmetric(horizontal: 8),
                ),
                minimumSize: const WidgetStatePropertyAll(Size(0, 28)),
                visualDensity: VisualDensity.compact,
              ),
              menuChildren: [
                MenuItemButton(
                  onPressed: actions.clearLogs,
                  shortcut: InfospectDesktopShortcuts.clearLogs,
                  child: const Text('Clear Logs'),
                ),
                MenuItemButton(
                  onPressed: actions.shareLogs,
                  shortcut: InfospectDesktopShortcuts.shareLogs,
                  child: const Text('Share Logs'),
                ),
                const Divider(),
                MenuItemButton(
                  onPressed: actions.popOutLogs,
                  shortcut: InfospectDesktopShortcuts.popOutLogs,
                  child: const Text('Open Logs in New Window'),
                ),
              ],
              child: const Text('Logs'),
            ),
            SubmenuButton(
              style: ButtonStyle(
                textStyle: WidgetStatePropertyAll(labelStyle),
                padding: const WidgetStatePropertyAll(
                  EdgeInsets.symmetric(horizontal: 8),
                ),
                minimumSize: const WidgetStatePropertyAll(Size(0, 28)),
                visualDensity: VisualDensity.compact,
              ),
              menuChildren: [
                MenuItemButton(
                  onPressed: actions.closeWindow,
                  shortcut: InfospectDesktopShortcuts.closeWindow,
                  child: const Text('Close Window'),
                ),
              ],
              child: const Text('Window'),
            ),
          ],
        ),
      ),
    );
  }
}
