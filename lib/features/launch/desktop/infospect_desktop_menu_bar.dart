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

/// Whether Flutter can render a **native** system menu bar for Infospect.
///
/// Flutter only ships a native [PlatformMenuBar] implementation on macOS.
/// Windows / Linux fall back to the in-window Material menu bar.
bool infospectSupportsNativeMenuBar() {
  if (kIsWeb) return false;
  return defaultTargetPlatform == TargetPlatform.macOS;
}

/// Menu bar + keyboard shortcuts for the Infospect desktop inspector window.
///
/// - **macOS:** native [PlatformMenuBar] (system menu bar; shortcut glyphs shown
///   by the OS). Does not merge into the host app’s menus while Infospect is
///   open — only one [PlatformMenuBar] can be active per isolate.
/// - **Windows / Linux:** in-window Material [MenuBar] with trailing shortcut
///   labels (native menu bar is not available in Flutter without a plugin).
///
/// Shortcuts are also registered with [HardwareKeyboard] so they work even when
/// focus is inside a search field or list (Multiview window focus quirks).
class InfospectDesktopMenuShell extends StatefulWidget {
  const InfospectDesktopMenuShell({
    super.key,
    required this.infospect,
    required this.networksListNotifier,
    required this.logsListNotifier,
    required this.child,
    this.forceInAppMenuBar = false,
  });

  final Infospect infospect;
  final NetworksListNotifier networksListNotifier;
  final LogsListNotifier logsListNotifier;
  final Widget child;

  /// When true, always use the in-window Material menu (skip native).
  final bool forceInAppMenuBar;

  static const double inAppMenuBarHeight = 34;

  @override
  State<InfospectDesktopMenuShell> createState() =>
      _InfospectDesktopMenuShellState();
}

class _InfospectDesktopMenuShellState extends State<InfospectDesktopMenuShell> {
  late InfospectDesktopMenuActions _actions;
  Map<ShortcutActivator, VoidCallback> _bindings = {};
  DateTime? _lastShortcutAt;

  bool get _useNative =>
      !widget.forceInAppMenuBar && infospectSupportsNativeMenuBar();

  @override
  void initState() {
    super.initState();
    _rebuildActions();
    // Always register: Multiview windows can miss focus-based Shortcuts, and
    // native PlatformMenuBar shortcuts are debounce-guarded against double fire.
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
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_onKeyEvent);
    super.dispose();
  }

  void _rebuildActions() {
    _actions = InfospectDesktopMenuActions(
      context: context,
      infospect: widget.infospect,
      networks: widget.networksListNotifier,
      logs: widget.logsListNotifier,
    );
    _bindings = {
      for (final entry in _actions.shortcutBindings.entries)
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
    if (event is! KeyDownEvent) return false;
    for (final entry in _bindings.entries) {
      if (entry.key.accepts(event, HardwareKeyboard.instance)) {
        entry.value();
        return true;
      }
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    if (_useNative) {
      return PlatformMenuBar(
        menus: _actions.buildNativeMenus(runGuarded: _runShortcut),
        child: widget.child,
      );
    }

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

  /// Native macOS menus — OS draws shortcut labels next to each item.
  ///
  /// [onSelected] is wrapped so a simultaneous [HardwareKeyboard] delivery of
  /// the same shortcut does not run the action twice.
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
    } catch (_) {
      // Host may not be under a MultiViewDesktop ancestor (e.g. tests).
    }
  }
}

/// In-window Material menu bar used when native [PlatformMenuBar] is unavailable.
class InfospectDesktopInAppMenuBar extends StatelessWidget {
  const InfospectDesktopInAppMenuBar({super.key, required this.actions});

  final InfospectDesktopMenuActions actions;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final barFg = theme.colorScheme.onSurface;
    final shortcutFg = theme.colorScheme.onSurface.withValues(alpha: 0.55);
    final barBg = Color.alphaBlend(
      theme.colorScheme.primary.withValues(alpha: 0.06),
      theme.colorScheme.surfaceContainerHigh,
    );
    final borderColor = theme.colorScheme.outlineVariant.withValues(alpha: 0.7);
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
