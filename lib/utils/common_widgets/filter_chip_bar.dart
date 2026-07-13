import 'package:flutter/material.dart';
import 'package:infospect/utils/models/action_model.dart';

/// Compact horizontal strip of removable filter chips under list app bars.
class FilterChipBar extends StatelessWidget implements PreferredSizeWidget {
  const FilterChipBar({
    super.key,
    required this.filters,
    required this.onDeleted,
    this.isDesktop = false,
  });

  final List<PopupAction> filters;
  final ValueChanged<PopupAction> onDeleted;
  final bool isDesktop;

  @override
  Size get preferredSize => Size.fromHeight(isDesktop ? 30 : 36);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final borderColor =
        theme.colorScheme.outlineVariant.withValues(alpha: 0.45);

    return Container(
      alignment: Alignment.centerLeft,
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: borderColor)),
      ),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(
          horizontal: isDesktop ? 6 : 10,
          vertical: isDesktop ? 2 : 4,
        ),
        itemCount: filters.length,
        separatorBuilder: (_, _) => SizedBox(width: isDesktop ? 4 : 6),
        itemBuilder: (context, index) {
          final filter = filters[index];
          return _FilterChip(
            label: filter.name,
            compact: isDesktop,
            onDeleted: () => onDeleted(filter),
          );
        },
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.onDeleted,
    required this.compact,
  });

  final String label;
  final VoidCallback onDeleted;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InputChip(
      label: Text(label),
      onDeleted: onDeleted,
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      padding: EdgeInsets.symmetric(horizontal: compact ? 2 : 4),
      labelPadding: EdgeInsets.only(
        left: compact ? 4 : 6,
        right: compact ? 0 : 2,
      ),
      labelStyle: theme.textTheme.labelSmall?.copyWith(
        fontSize: compact ? 10 : 11,
        fontWeight: FontWeight.w600,
        height: 1.1,
        color: theme.colorScheme.onPrimaryContainer,
      ),
      side: BorderSide.none,
      backgroundColor: theme.colorScheme.primaryContainer.withValues(
        alpha: 0.85,
      ),
      deleteIcon: Icon(
        Icons.close_rounded,
        size: compact ? 12 : 14,
        color: theme.colorScheme.onPrimaryContainer.withValues(alpha: 0.75),
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(compact ? 4 : 6),
      ),
    );
  }
}
