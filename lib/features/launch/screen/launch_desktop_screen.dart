import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:infospect/features/launch/desktop/infospect_desktop_menu_bar.dart';
import 'package:infospect/features/launch/models/infospect_desktop_tab.dart';
import 'package:infospect/features/launch/models/navigation_tab_data.dart';
import 'package:infospect/features/launch/notifier/launch_notifier.dart';
import 'package:infospect/features/logger/ui/logs_list/notifier/logs_list_notifier.dart';
import 'package:infospect/features/logger/ui/logs_list/screen/desktop_logs_list_screen.dart';
import 'package:infospect/features/network/ui/list/notifier/networks_list_notifier.dart';
import 'package:infospect/features/network/ui/list/screen/desktop_networks_list_screen.dart';
import 'package:infospect/helpers/infospect_helper.dart';

class LaunchDesktopScreen extends StatefulWidget {
  final Infospect infospect;
  final NetworksListNotifier networksListNotifier;
  final LogsListNotifier logsListNotifier;

  const LaunchDesktopScreen(
    this.infospect, {
    required this.networksListNotifier,
    required this.logsListNotifier,
    super.key,
  });

  @override
  State<LaunchDesktopScreen> createState() => _LaunchDesktopScreenState();
}

class _LaunchDesktopScreenState extends State<LaunchDesktopScreen> {
  static const double _minSidebarWidth = 140;
  static const double _maxSidebarWidth = 360;
  static const double _defaultSidebarWidth = 180;
  static const double _dividerHitWidth = 6;

  double _sidebarWidth = _defaultSidebarWidth;

  void _onDragUpdate(DragUpdateDetails details, double maxWidth) {
    final maxAllowed = math.min(_maxSidebarWidth, maxWidth * 0.45);
    setState(() {
      _sidebarWidth = (_sidebarWidth + details.delta.dx)
          .clamp(_minSidebarWidth, maxAllowed);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final borderColor =
        theme.colorScheme.outlineVariant.withValues(alpha: 0.55);

    return Scaffold(
      body: InfospectDesktopMenuShell(
        infospect: widget.infospect,
        networksListNotifier: widget.networksListNotifier,
        logsListNotifier: widget.logsListNotifier,
        child: ValueListenableBuilder<Set<InfospectDesktopTab>>(
          valueListenable: widget.infospect.poppedOutDesktopTabs,
          builder: (context, poppedOut, _) {
            final visibleTabs = InfospectDesktopTab.values
                .where((tab) => !poppedOut.contains(tab))
                .toList(growable: false);
            final showSidebar = visibleTabs.isNotEmpty;

            return LayoutBuilder(
              builder: (context, constraints) {
                final maxAllowed =
                    math.min(_maxSidebarWidth, constraints.maxWidth * 0.45);
                final sidebarWidth =
                    _sidebarWidth.clamp(_minSidebarWidth, maxAllowed);

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (showSidebar) ...[
                      SizedBox(
                        width: sidebarWidth,
                        child: _Sidebar(
                          infospect: widget.infospect,
                          visibleTabs: visibleTabs,
                          poppedOutTabs: poppedOut,
                        ),
                      ),
                      _ResizeHandle(
                        color: borderColor,
                        hitWidth: _dividerHitWidth,
                        onDragUpdate: (details) =>
                            _onDragUpdate(details, constraints.maxWidth),
                      ),
                    ],
                    Expanded(
                      child: _ContentPane(
                        infospect: widget.infospect,
                        networksListNotifier: widget.networksListNotifier,
                        logsListNotifier: widget.logsListNotifier,
                        visibleTabs: visibleTabs,
                        poppedOutTabs: poppedOut,
                      ),
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _ResizeHandle extends StatefulWidget {
  const _ResizeHandle({
    required this.color,
    required this.hitWidth,
    required this.onDragUpdate,
  });

  final Color color;
  final double hitWidth;
  final GestureDragUpdateCallback onDragUpdate;

  @override
  State<_ResizeHandle> createState() => _ResizeHandleState();
}

class _ResizeHandleState extends State<_ResizeHandle> {
  bool _hovering = false;
  bool _dragging = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final active = _hovering || _dragging;
    final lineColor = active ? theme.colorScheme.primary : widget.color;

    return MouseRegion(
      cursor: SystemMouseCursors.resizeColumn,
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onHorizontalDragStart: (_) => setState(() => _dragging = true),
        onHorizontalDragUpdate: widget.onDragUpdate,
        onHorizontalDragEnd: (_) => setState(() => _dragging = false),
        onHorizontalDragCancel: () => setState(() => _dragging = false),
        child: SizedBox(
          width: widget.hitWidth,
          child: Center(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 100),
              width: active ? 2 : 1,
              color: lineColor,
            ),
          ),
        ),
      ),
    );
  }
}

class _ContentPane extends StatelessWidget {
  const _ContentPane({
    required this.infospect,
    required this.networksListNotifier,
    required this.logsListNotifier,
    required this.visibleTabs,
    required this.poppedOutTabs,
  });

  final Infospect infospect;
  final NetworksListNotifier networksListNotifier;
  final LogsListNotifier logsListNotifier;
  final List<InfospectDesktopTab> visibleTabs;
  final Set<InfospectDesktopTab> poppedOutTabs;

  @override
  Widget build(BuildContext context) {
    if (visibleTabs.isEmpty) {
      return _AllTabsPoppedOutState(
        infospect: infospect,
        poppedOutTabs: poppedOutTabs,
      );
    }

    final showNetwork = visibleTabs.contains(InfospectDesktopTab.network);
    final showLogs = visibleTabs.contains(InfospectDesktopTab.logs);

    if (showNetwork && !showLogs) {
      return DesktopNetworksListScreen(
        infospect,
        notifier: networksListNotifier,
      );
    }
    if (!showNetwork && showLogs) {
      return DesktopLogsListScreen(
        infospect,
        notifier: logsListNotifier,
      );
    }

    final launchNotifier = LaunchNotifier.instance;
    return ValueListenableBuilder<int>(
      valueListenable: launchNotifier,
      builder: (context, selectedIndex, _) {
        return IndexedStack(
          index: selectedIndex,
          children: [
            DesktopNetworksListScreen(
              infospect,
              notifier: networksListNotifier,
            ),
            DesktopLogsListScreen(
              infospect,
              notifier: logsListNotifier,
            ),
          ],
        );
      },
    );
  }
}

class _AllTabsPoppedOutState extends StatelessWidget {
  const _AllTabsPoppedOutState({
    required this.infospect,
    required this.poppedOutTabs,
  });

  final Infospect infospect;
  final Set<InfospectDesktopTab> poppedOutTabs;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ColoredBox(
      color: theme.colorScheme.surface,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Infospect',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Network and Logs are open in separate windows. '
                  'Close a window to bring that tab back here.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: 20),
                ...InfospectDesktopTab.values
                    .where(poppedOutTabs.contains)
                    .map(
                      (tab) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: OutlinedButton.icon(
                          onPressed: () =>
                              infospect.focusPoppedOutDesktopTab(tab),
                          icon: Icon(
                            tab == InfospectDesktopTab.network
                                ? Icons.public
                                : Icons.terminal,
                            size: 16,
                          ),
                          label: Text('Focus ${tab.windowTitle}'),
                        ),
                      ),
                    ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Sidebar extends StatelessWidget {
  const _Sidebar({
    required this.infospect,
    required this.visibleTabs,
    required this.poppedOutTabs,
  });

  final Infospect infospect;
  final List<InfospectDesktopTab> visibleTabs;
  final Set<InfospectDesktopTab> poppedOutTabs;

  @override
  Widget build(BuildContext context) {
    final launchNotifier = LaunchNotifier.instance;
    final theme = Theme.of(context);
    final allTabs = NavigationTabData.tabs;

    return ColoredBox(
      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.22),
      child: ValueListenableBuilder<int>(
        valueListenable: launchNotifier,
        builder: (context, selectedIndex, _) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                height: 40,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: _AppBarLeadingWidget(infospect: infospect),
                  ),
                ),
              ),
              Divider(
                height: 1,
                thickness: 1,
                color:
                    theme.colorScheme.outlineVariant.withValues(alpha: 0.55),
              ),
              const SizedBox(height: 4),
              ...visibleTabs.map((tab) {
                final item = allTabs[tab.tabIndex];
                final selected = selectedIndex == tab.tabIndex;
                return Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  child: _SidebarTab(
                    icon: selected ? item.selectedIcon : item.icon,
                    title: item.title,
                    selected: selected,
                    onTap: () => launchNotifier.selectTab(tab.tabIndex),
                    onPopOut: () => infospect.popOutDesktopTab(tab),
                  ),
                );
              }),
              if (poppedOutTabs.isNotEmpty) ...[
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    'Opened in new window',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.45),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                ...poppedOutTabs.map((tab) {
                  final item = allTabs[tab.tabIndex];
                  return Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    child: _SidebarTab(
                      icon: item.icon,
                      title: item.title,
                      selected: false,
                      dimmed: true,
                      trailingIcon: Icons.open_in_new,
                      onTap: () => infospect.focusPoppedOutDesktopTab(tab),
                      onPopOut: () => infospect.focusPoppedOutDesktopTab(tab),
                    ),
                  );
                }),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _SidebarTab extends StatefulWidget {
  const _SidebarTab({
    required this.icon,
    required this.title,
    required this.selected,
    required this.onTap,
    required this.onPopOut,
    this.dimmed = false,
    this.trailingIcon,
  });

  final IconData icon;
  final String title;
  final bool selected;
  final bool dimmed;
  final IconData? trailingIcon;
  final VoidCallback onTap;
  final VoidCallback onPopOut;

  @override
  State<_SidebarTab> createState() => _SidebarTabState();
}

class _SidebarTabState extends State<_SidebarTab> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final canPopOut = !kIsWeb &&
        !widget.dimmed &&
        (defaultTargetPlatform == TargetPlatform.macOS ||
            defaultTargetPlatform == TargetPlatform.linux ||
            defaultTargetPlatform == TargetPlatform.windows);
    final showPopOut = canPopOut && _hovering;
    final foreground = widget.selected
        ? theme.colorScheme.onSurface
        : theme.colorScheme.onSurface.withValues(
            alpha: widget.dimmed ? 0.45 : 0.62,
          );

    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: Material(
        color: widget.selected
            ? theme.colorScheme.onSurface.withValues(alpha: 0.12)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(5),
        child: InkWell(
          onTap: widget.onTap,
          onDoubleTap: canPopOut ? widget.onPopOut : null,
          borderRadius: BorderRadius.circular(5),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 8),
            child: Row(
              children: [
                Icon(widget.icon, size: 14, color: foreground),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.title,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: widget.selected
                          ? FontWeight.w600
                          : FontWeight.w500,
                      color: widget.selected
                          ? theme.colorScheme.onSurface
                          : theme.colorScheme.onSurface.withValues(
                              alpha: widget.dimmed ? 0.5 : 0.72,
                            ),
                    ),
                  ),
                ),
                if (showPopOut || widget.trailingIcon != null)
                  Tooltip(
                    message: widget.dimmed
                        ? 'Focus window'
                        : 'Open in new window',
                    waitDuration: const Duration(milliseconds: 400),
                    child: InkWell(
                      onTap: widget.onPopOut,
                      borderRadius: BorderRadius.circular(4),
                      child: Padding(
                        padding: const EdgeInsets.all(2),
                        child: Icon(
                          widget.trailingIcon ?? Icons.open_in_new,
                          size: 12,
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.55),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AppBarLeadingWidget extends StatelessWidget {
  const _AppBarLeadingWidget({
    required this.infospect,
  });

  final Infospect infospect;

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      return const SizedBox.shrink();
    } else if (Platform.isMacOS || Platform.isLinux || Platform.isWindows) {
      return Text(
        'Infospect',
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
      );
    }
    return IconButton(
      icon: const Icon(Icons.chevron_left),
      onPressed: () {
        infospect.getNavigatorKey?.currentState?.pop();
      },
    );
  }
}
