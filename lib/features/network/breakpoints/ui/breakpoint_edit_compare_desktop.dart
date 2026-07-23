import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:infospect/features/network/breakpoints/models/infospect_breakpoint_edit.dart';

/// Desktop-native Original vs Edited panel (side-by-side diff table).
///
/// Place inside a [Flexible] / [Expanded] parent. When collapsed it sizes to
/// the header; when expanded the body scrolls within the allocated flex space.
class BreakpointEditCompareDesktop extends StatefulWidget {
  const BreakpointEditCompareDesktop({
    super.key,
    required this.edit,
    this.isResponse = false,
    this.initiallyExpanded = false,
    this.onExpandedChanged,
  });

  final InfospectBreakpointEdit edit;
  final bool isResponse;
  final bool initiallyExpanded;
  final ValueChanged<bool>? onExpandedChanged;

  @override
  State<BreakpointEditCompareDesktop> createState() =>
      _BreakpointEditCompareDesktopState();
}

class _BreakpointEditCompareDesktopState
    extends State<BreakpointEditCompareDesktop> {
  late bool _expanded;

  @override
  void initState() {
    super.initState();
    _expanded = widget.initiallyExpanded;
  }

  List<_DiffRow> get _rows {
    final edit = widget.edit;
    final rows = <_DiffRow>[
      if (edit.methodChanged)
        _DiffRow('Method', edit.original.method, edit.edited.method),
      if (edit.urlChanged)
        _DiffRow('URL', edit.original.uri, edit.edited.uri),
      if (!widget.isResponse && edit.queryChanged)
        _DiffRow(
          'Query',
          _formatMap(edit.original.queryParameters),
          _formatMap(edit.edited.queryParameters),
        ),
      if (edit.headersChanged)
        _DiffRow(
          'Headers',
          _formatMap(edit.original.headers),
          _formatMap(edit.edited.headers),
        ),
      if (widget.isResponse && edit.statusChanged)
        _DiffRow(
          'Status',
          '${edit.original.statusCode ?? '-'}',
          '${edit.edited.statusCode ?? '-'}',
        ),
      if (edit.bodyChanged)
        _DiffRow(
          'Body',
          edit.original.body.isEmpty ? '(empty)' : edit.original.body,
          edit.edited.body.isEmpty ? '(empty)' : edit.edited.body,
          monospace: true,
        ),
    ];
    if (rows.isEmpty) {
      rows.add(
        const _DiffRow('Result', 'No fields changed', 'Continued as-is'),
      );
    }
    return rows;
  }

  static String _formatMap(Map<String, String> map) {
    if (map.isEmpty) return '(empty)';
    return map.entries.map((e) => '${e.key}: ${e.value}').join('\n');
  }

  void _toggle() {
    setState(() => _expanded = !_expanded);
    widget.onExpandedChanged?.call(_expanded);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final border = theme.colorScheme.outlineVariant.withValues(alpha: 0.55);
    final rows = _rows;
    final changeCount = widget.edit.hasChanges ? rows.length : 0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: border),
          color:
              theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.18),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: _expanded ? MainAxisSize.max : MainAxisSize.min,
          children: [
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _toggle,
                borderRadius: BorderRadius.vertical(
                  top: const Radius.circular(5),
                  bottom: _expanded ? Radius.zero : const Radius.circular(5),
                ),
                child: SizedBox(
                  height: 32,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Row(
                      children: [
                        Icon(
                          _expanded ? Icons.expand_more : Icons.chevron_right,
                          size: 16,
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.55),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Original vs Edited',
                          style: theme.textTheme.labelSmall?.copyWith(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(3),
                            color: theme.colorScheme.tertiary
                                .withValues(alpha: 0.18),
                          ),
                          child: Text(
                            changeCount == 0
                                ? 'unchanged'
                                : '$changeCount change${changeCount == 1 ? '' : 's'}',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.tertiary,
                            ),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          _expanded ? 'Collapse' : 'Expand',
                          style: theme.textTheme.labelSmall?.copyWith(
                            fontSize: 10,
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.45),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            if (_expanded) ...[
              Divider(height: 1, thickness: 1, color: border),
              _DiffHeader(border: border),
              Expanded(
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(5),
                  ),
                  child: ListView.separated(
                    padding: EdgeInsets.zero,
                    itemCount: rows.length,
                    separatorBuilder: (_, _) =>
                        Divider(height: 1, thickness: 1, color: border),
                    itemBuilder: (context, index) =>
                        _DiffRowView(row: rows[index]),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _DiffHeader extends StatelessWidget {
  const _DiffHeader({required this.border});

  final Color border;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      height: 26,
      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
      child: Row(
        children: [
          SizedBox(
            width: 72,
            child: Padding(
              padding: const EdgeInsets.only(left: 8),
              child: Text(
                'Field',
                style: theme.textTheme.labelSmall?.copyWith(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
                ),
              ),
            ),
          ),
          Container(width: 1, color: border),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(left: 8),
              child: Text(
                'Original',
                style: theme.textTheme.labelSmall?.copyWith(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.error,
                ),
              ),
            ),
          ),
          Container(width: 1, color: border),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(left: 8),
              child: Text(
                'Edited',
                style: theme.textTheme.labelSmall?.copyWith(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DiffRow {
  const _DiffRow(
    this.label,
    this.original,
    this.edited, {
    this.monospace = false,
  });

  final String label;
  final String original;
  final String edited;
  final bool monospace;
}

class _DiffRowView extends StatelessWidget {
  const _DiffRowView({required this.row});

  final _DiffRow row;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final border = theme.colorScheme.outlineVariant.withValues(alpha: 0.4);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 72,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 6, 6, 6),
              child: Text(
                row.label,
                style: theme.textTheme.labelSmall?.copyWith(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
                ),
              ),
            ),
          ),
          Container(width: 1, color: border),
          Expanded(
            child: _Cell(
              value: row.original,
              monospace: row.monospace,
              background: theme.colorScheme.error.withValues(alpha: 0.05),
            ),
          ),
          Container(width: 1, color: border),
          Expanded(
            child: _Cell(
              value: row.edited,
              monospace: row.monospace,
              background: theme.colorScheme.primary.withValues(alpha: 0.05),
            ),
          ),
        ],
      ),
    );
  }
}

class _Cell extends StatelessWidget {
  const _Cell({
    required this.value,
    required this.monospace,
    required this.background,
  });

  final String value;
  final bool monospace;
  final Color background;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: background,
      child: InkWell(
        onLongPress: () {
          Clipboard.setData(ClipboardData(text: value));
        },
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
          child: SelectableText(
            value,
            style: theme.textTheme.bodySmall?.copyWith(
              fontSize: 11,
              height: 1.35,
              fontFamily: monospace ? 'monospace' : null,
            ),
          ),
        ),
      ),
    );
  }
}
