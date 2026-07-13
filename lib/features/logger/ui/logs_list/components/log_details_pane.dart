import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:infospect/features/logger/models/infospect_log.dart';
import 'package:infospect/features/logger/ui/logs_list/utils/log_helper.dart';
import 'package:infospect/utils/common_widgets/highlight_text_widget.dart';
import 'package:infospect/utils/extensions/infospect_log/infospect_log_extension.dart';

/// Shared log inspection surface used by the desktop detail pane and mobile
/// details screen.
class LogDetailsContent extends StatelessWidget {
  const LogDetailsContent({
    super.key,
    required this.log,
    this.searchedText = '',
    this.showHeader = true,
  });

  final InfospectLog log;
  final String searchedText;
  final bool showHeader;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final borderColor = theme.colorScheme.outlineVariant.withValues(
      alpha: 0.55,
    );
    final errorText = stringifiedLog(log.error);
    final stackText = stringifiedLog(log.stackTrace);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (showHeader) LogDetailsHeaderBar(log: log),
        Expanded(
          child: DecoratedBox(
            decoration: BoxDecoration(
              border: showHeader
                  ? Border(top: BorderSide(color: borderColor))
                  : null,
            ),
            child: ListView(
              padding: const EdgeInsets.all(10),
              children: [
                _LogSection(
                  title: 'Message',
                  body: log.message,
                  searchedText: searchedText,
                ),
                if (errorText != null) ...[
                  const SizedBox(height: 10),
                  _LogSection(
                    title: 'Error',
                    body: errorText,
                    searchedText: searchedText,
                  ),
                ],
                if (stackText != null) ...[
                  const SizedBox(height: 10),
                  _LogSection(
                    title: 'Stack Trace',
                    body: stackText,
                    searchedText: searchedText,
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class LogDetailsHeaderBar extends StatelessWidget {
  const LogDetailsHeaderBar({super.key, required this.log});

  final InfospectLog log;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ({IconData icon, Color color}) logData = getIconAndColor(
      log.level,
      context,
    );

    return Container(
      height: 34,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
      child: Row(
        children: [
          _Pill(
            label: log.level.name,
            background: logData.color.withValues(alpha: 0.22),
            foreground: logData.color,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: SelectableText(
              log.timestamp.toString(),
              maxLines: 1,
              style: theme.textTheme.bodySmall?.copyWith(
                fontSize: 12,
                fontFamily: 'monospace',
              ),
            ),
          ),
          IconButton(
            tooltip: 'Copy log',
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
            icon: Icon(
              Icons.copy_rounded,
              size: 14,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
            ),
            onPressed: () =>
                Clipboard.setData(ClipboardData(text: log.sharableData)),
          ),
        ],
      ),
    );
  }
}

class _LogSection extends StatelessWidget {
  const _LogSection({
    required this.title,
    required this.body,
    required this.searchedText,
  });

  final String title;
  final String body;
  final String searchedText;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final borderColor = theme.colorScheme.outlineVariant.withValues(
      alpha: 0.55,
    );

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: borderColor),
        color: theme.colorScheme.surface,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            height: 34,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withValues(
                alpha: 0.28,
              ),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(5),
              ),
              border: Border(bottom: BorderSide(color: borderColor)),
            ),
            child: Row(
              children: [
                Text(
                  title,
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                IconButton(
                  tooltip: 'Copy $title',
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 28,
                    minHeight: 28,
                  ),
                  icon: Icon(
                    Icons.copy_rounded,
                    size: 14,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
                  ),
                  onPressed: () => Clipboard.setData(ClipboardData(text: body)),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(10),
            child: HighlightText(
              text: body,
              highlight: searchedText.isEmpty ? null : searchedText,
              ignoreCase: true,
              style: theme.textTheme.bodySmall?.copyWith(
                fontSize: 12,
                fontFamily: 'monospace',
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({
    required this.label,
    required this.background,
    required this.foreground,
  });

  final String label;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        color: background,
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: foreground,
        ),
      ),
    );
  }
}
