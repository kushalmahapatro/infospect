import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:infospect/features/network/ui/details/widgets/details_row_widget.dart';

class ExpansionWidget extends StatelessWidget {
  final String title;
  final List<Widget> children;
  final Widget? trailing;
  final bool initiallyExpanded;

  factory ExpansionWidget.map({
    required Map<String, dynamic> map,
    required String title,
    Widget? trailing,
    bool initiallyExpanded = true,
    Key? key,
  }) {
    return ExpansionWidget(
      key: key,
      title: title,
      trailing: trailing,
      initiallyExpanded: initiallyExpanded,
      children: [
        ...map.entries.mapIndexed(
          (i, e) => DetailsRowWidget(
            e.key,
            e.value.toString(),
            showDivider: i != map.length - 1,
          ),
        ),
      ],
    );
  }

  const ExpansionWidget({
    super.key,
    required this.title,
    required this.children,
    this.trailing,
    this.initiallyExpanded = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final borderColor =
        theme.colorScheme.outlineVariant.withValues(alpha: 0.5);

    return Container(
      margin: const EdgeInsets.fromLTRB(6, 0, 6, 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: borderColor),
        color: theme.colorScheme.surface,
      ),
      clipBehavior: Clip.antiAlias,
      child: Theme(
        data: theme.copyWith(dividerColor: Colors.transparent),
        child: ListTileTheme(
          data: const ListTileThemeData(
            dense: true,
            visualDensity: VisualDensity(horizontal: 0, vertical: -4),
            minVerticalPadding: 0,
            contentPadding: EdgeInsets.symmetric(horizontal: 8),
          ),
          child: ExpansionTile(
            initiallyExpanded: initiallyExpanded,
            dense: true,
            visualDensity: const VisualDensity(horizontal: 0, vertical: -4),
            tilePadding: const EdgeInsets.symmetric(horizontal: 8),
            childrenPadding: const EdgeInsets.fromLTRB(8, 0, 4, 4),
            expandedAlignment: Alignment.centerLeft,
            controlAffinity: ListTileControlAffinity.trailing,
            backgroundColor: theme.colorScheme.surfaceContainerHighest
                .withValues(alpha: 0.06),
            collapsedBackgroundColor: theme.colorScheme.surfaceContainerHighest
                .withValues(alpha: 0.18),
            iconColor: theme.colorScheme.onSurface.withValues(alpha: 0.5),
            collapsedIconColor:
                theme.colorScheme.onSurface.withValues(alpha: 0.5),
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      height: 1.1,
                    ),
                  ),
                ),
                ?trailing,
              ],
            ),
            children: children,
          ),
        ),
      ),
    );
  }
}
