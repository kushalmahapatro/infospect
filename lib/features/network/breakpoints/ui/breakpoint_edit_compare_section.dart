import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:infospect/features/network/breakpoints/models/infospect_breakpoint_edit.dart';
import 'package:infospect/features/network/ui/list/components/expansion_widget.dart';
import 'package:infospect/utils/common_widgets/infospect_toast.dart';

/// Shows original vs edited values captured at a breakpoint.
class BreakpointEditCompareSection extends StatelessWidget {
  const BreakpointEditCompareSection({
    super.key,
    required this.title,
    required this.edit,
    this.isResponse = false,
  });

  final String title;
  final InfospectBreakpointEdit edit;
  final bool isResponse;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final rows = <_CompareRow>[
      if (edit.methodChanged)
        _CompareRow(
          label: 'Method',
          original: edit.original.method,
          edited: edit.edited.method,
        ),
      if (edit.urlChanged)
        _CompareRow(
          label: 'URL',
          original: edit.original.uri,
          edited: edit.edited.uri,
        ),
      if (!isResponse && edit.queryChanged)
        _CompareRow(
          label: 'Query',
          original: _formatMap(edit.original.queryParameters),
          edited: _formatMap(edit.edited.queryParameters),
        ),
      if (edit.headersChanged)
        _CompareRow(
          label: 'Headers',
          original: _formatMap(edit.original.headers),
          edited: _formatMap(edit.edited.headers),
        ),
      if (isResponse && edit.statusChanged)
        _CompareRow(
          label: 'Status',
          original: '${edit.original.statusCode ?? '-'}',
          edited: '${edit.edited.statusCode ?? '-'}',
        ),
      if (edit.bodyChanged)
        _CompareRow(
          label: 'Body',
          original: edit.original.body.isEmpty ? '(empty)' : edit.original.body,
          edited: edit.edited.body.isEmpty ? '(empty)' : edit.edited.body,
          monospace: true,
        ),
    ];

    if (rows.isEmpty && !edit.hasChanges) {
      rows.add(
        const _CompareRow(
          label: 'Result',
          original: 'No fields changed',
          edited: 'Continued as-is',
        ),
      );
    }

    return ExpansionWidget(
      title: title,
      initiallyExpanded: edit.hasChanges,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
          child: Column(
            children: [
              for (final row in rows) ...[
                _CompareCard(row: row, theme: theme),
                if (row != rows.last) const SizedBox(height: 8),
              ],
            ],
          ),
        ),
      ],
    );
  }

  static String _formatMap(Map<String, String> map) {
    if (map.isEmpty) return '(empty)';
    return map.entries.map((e) => '${e.key}: ${e.value}').join('\n');
  }
}

class _CompareRow {
  const _CompareRow({
    required this.label,
    required this.original,
    required this.edited,
    this.monospace = false,
  });

  final String label;
  final String original;
  final String edited;
  final bool monospace;
}

class _CompareCard extends StatelessWidget {
  const _CompareCard({required this.row, required this.theme});

  final _CompareRow row;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final border = theme.colorScheme.outlineVariant.withValues(alpha: 0.45);

    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 6),
            child: Text(
              row.label,
              style: theme.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w700,
                fontSize: 11,
              ),
            ),
          ),
          Divider(height: 1, color: border),
          _Side(
            label: 'Original',
            value: row.original,
            monospace: row.monospace,
            color: theme.colorScheme.error.withValues(alpha: 0.08),
            labelColor: theme.colorScheme.error,
          ),
          Divider(height: 1, color: border),
          _Side(
            label: 'Edited',
            value: row.edited,
            monospace: row.monospace,
            color: theme.colorScheme.primary.withValues(alpha: 0.08),
            labelColor: theme.colorScheme.primary,
          ),
        ],
      ),
    );
  }
}

class _Side extends StatelessWidget {
  const _Side({
    required this.label,
    required this.value,
    required this.monospace,
    required this.color,
    required this.labelColor,
  });

  final String label;
  final String value;
  final bool monospace;
  final Color color;
  final Color labelColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: color,
      child: InkWell(
        onLongPress: () {
          Clipboard.setData(ClipboardData(text: value));
          InfospectToast.show(
            context,
            'Copied $label',
            duration: const Duration(seconds: 1),
            icon: Icons.copy_rounded,
          );
        },
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.labelSmall?.copyWith(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: labelColor,
                ),
              ),
              const SizedBox(height: 4),
              SelectableText(
                value,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontSize: 11,
                  height: 1.35,
                  fontFamily: monospace ? 'monospace' : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
