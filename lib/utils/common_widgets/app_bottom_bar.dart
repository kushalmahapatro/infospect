import 'package:flutter/material.dart';

typedef BottomBarItem = ({IconData icon, IconData selectedIcon, String title});

/// Compact top segmented tab strip used by the mobile Infospect shell.
class AppSegmentedTabBar extends StatelessWidget {
  const AppSegmentedTabBar({
    super.key,
    required this.tabs,
    required this.selectedIndex,
    this.tabChangedCallback,
    this.leading,
  });

  final List<BottomBarItem> tabs;
  final ValueChanged<int>? tabChangedCallback;
  final int selectedIndex;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final borderColor =
        theme.colorScheme.outlineVariant.withValues(alpha: 0.5);

    return Material(
      color: theme.colorScheme.surface,
      child: Container(
        height: 44,
        padding: const EdgeInsets.fromLTRB(4, 6, 8, 6),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: borderColor)),
        ),
        child: Row(
          children: [
            ?leading,
            Expanded(
              child: Row(
                children: [
                  for (var i = 0; i < tabs.length; i++) ...[
                    if (i > 0) const SizedBox(width: 4),
                    Expanded(
                      child: _SegmentChip(
                        tab: tabs[i],
                        selected: selectedIndex == i,
                        onTap: () => tabChangedCallback?.call(i),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SegmentChip extends StatelessWidget {
  const _SegmentChip({
    required this.tab,
    required this.selected,
    required this.onTap,
  });

  final BottomBarItem tab;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final foreground = selected
        ? theme.colorScheme.primary
        : theme.colorScheme.onSurface.withValues(alpha: 0.58);

    return Material(
      color: selected
          ? theme.colorScheme.primary.withValues(alpha: 0.14)
          : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: SizedBox(
          height: 32,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                selected ? tab.selectedIcon : tab.icon,
                size: 15,
                color: foreground,
              ),
              const SizedBox(width: 5),
              Text(
                tab.title,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                  height: 1.1,
                  color: foreground,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Backward-compatible alias for [AppSegmentedTabBar].
@Deprecated('Use AppSegmentedTabBar')
class AppBottomBar extends AppSegmentedTabBar {
  const AppBottomBar({
    super.key,
    required super.tabs,
    required super.selectedIndex,
    super.tabChangedCallback,
    super.leading,
  });
}
