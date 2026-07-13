import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:infospect/features/logger/models/infospect_log.dart';
import 'package:infospect/features/logger/ui/logs_list/utils/log_helper.dart';
import 'package:infospect/utils/common_widgets/highlight_text_widget.dart';
import 'package:infospect/utils/extensions/infospect_log/infospect_log_extension.dart';

/// Full-content log row styled like a native desktop console entry.
class LogItemWidget extends StatefulWidget {
  const LogItemWidget({
    super.key,
    required this.log,
    required this.searchedText,
    this.selected = false,
    this.onTap,
  });

  final InfospectLog log;
  final String searchedText;
  final bool selected;
  final VoidCallback? onTap;

  /// Stable zebra stripe based on the log itself (not list index), so
  /// prepending new entries does not flip row backgrounds.
  bool get zebra => log.hashCode.isOdd;

  @override
  State<LogItemWidget> createState() => _LogItemWidgetState();
}

class _LogItemWidgetState extends State<LogItemWidget> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ({IconData icon, Color color}) logData = getIconAndColor(
      widget.log.level,
      context,
    );
    final borderColor = theme.colorScheme.outlineVariant.withValues(
      alpha: 0.35,
    );

    final errorText = stringifiedLog(widget.log.error);
    final stackText = stringifiedLog(widget.log.stackTrace);

    final rawTimestamp = widget.log.timestamp.toString();
    final timeStartIndex = rawTimestamp.indexOf(' ') + 1;
    final formattedTimestamp = rawTimestamp.substring(timeStartIndex);

    final Color background;
    if (widget.selected) {
      background = theme.colorScheme.primary.withValues(alpha: 0.14);
    } else if (_hovering) {
      background = theme.colorScheme.onSurface.withValues(alpha: 0.06);
    } else if (widget.zebra) {
      background = theme.colorScheme.surfaceContainerHighest.withValues(
        alpha: 0.18,
      );
    } else {
      background = Colors.transparent;
    }

    final bodyStyle = theme.textTheme.bodySmall?.copyWith(
      fontSize: 12,
      fontFamily: 'monospace',
      height: 1.4,
      color: theme.colorScheme.onSurface,
    );
    final mutedLabelStyle = theme.textTheme.labelSmall?.copyWith(
      fontSize: 10,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.2,
      color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
    );

    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      cursor: widget.onTap != null
          ? SystemMouseCursors.click
          : SystemMouseCursors.basic,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: background,
            border: Border(
              left: BorderSide(color: logData.color, width: 3),
              bottom: BorderSide(color: borderColor),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _LevelPill(
                      label: widget.log.level.name,
                      icon: logData.icon,
                      color: logData.color,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: HighlightText(
                        text: formattedTimestamp,
                        highlight: widget.searchedText.isEmpty
                            ? null
                            : widget.searchedText,
                        ignoreCase: true,
                        selectable: false,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.labelMedium?.copyWith(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'monospace',
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.7,
                          ),
                        ),
                      ),
                    ),
                    // Always reserve space so showing the copy control
                    // does not shift layout and re-trigger hover.
                    SizedBox(
                      width: 28,
                      height: 28,
                      child: IgnorePointer(
                        ignoring: !(_hovering || widget.selected),
                        child: AnimatedOpacity(
                          duration: const Duration(milliseconds: 120),
                          opacity: (_hovering || widget.selected) ? 1 : 0,
                          child: IconButton(
                            tooltip: 'Copy log',
                            visualDensity: VisualDensity.compact,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(
                              minWidth: 28,
                              minHeight: 28,
                            ),
                            icon: Icon(
                              Icons.copy_rounded,
                              size: 14,
                              color: theme.colorScheme.onSurface.withValues(
                                alpha: 0.55,
                              ),
                            ),
                            onPressed: () => Clipboard.setData(
                              ClipboardData(text: widget.log.sharableData),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                HighlightText(
                  text: widget.log.message,
                  highlight: widget.searchedText.isEmpty
                      ? null
                      : widget.searchedText,
                  ignoreCase: true,
                  style: bodyStyle,
                ),
                if (errorText != null) ...[
                  const SizedBox(height: 8),
                  Text('Error', style: mutedLabelStyle),
                  const SizedBox(height: 2),
                  HighlightText(
                    text: errorText,
                    highlight: widget.searchedText.isEmpty
                        ? null
                        : widget.searchedText,
                    ignoreCase: true,
                    style: bodyStyle?.copyWith(
                      color: theme.colorScheme.error.withValues(alpha: 0.9),
                    ),
                  ),
                ],
                if (stackText != null) ...[
                  const SizedBox(height: 8),
                  Text('Stack Trace', style: mutedLabelStyle),
                  const SizedBox(height: 2),
                  HighlightText(
                    text: stackText,
                    highlight: widget.searchedText.isEmpty
                        ? null
                        : widget.searchedText,
                    ignoreCase: true,
                    style: bodyStyle?.copyWith(
                      fontSize: 11,
                      color: theme.colorScheme.onSurface.withValues(
                        alpha: 0.75,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LevelPill extends StatelessWidget {
  const _LevelPill({
    required this.label,
    required this.icon,
    required this.color,
  });

  final String label;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        color: color.withValues(alpha: 0.16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
