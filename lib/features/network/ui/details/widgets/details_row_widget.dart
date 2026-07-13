import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Compact key/value row used in mobile network call details sections.
class DetailsRowWidget extends StatelessWidget {
  final String name;
  final String value;
  final String? other;
  final bool showDivider;

  const DetailsRowWidget(
    this.name,
    this.value, {
    super.key,
    this.other,
    this.showDivider = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final borderColor =
        theme.colorScheme.outlineVariant.withValues(alpha: 0.35);
    final label = name.replaceAll(':', '').trim();
    final hasOther = (other ?? '').isNotEmpty;
    final copyText = hasOther ? '$value\n$other' : value;
    final labelStyle = theme.textTheme.labelSmall?.copyWith(
      fontSize: 10,
      fontWeight: FontWeight.w600,
      height: 1.2,
      color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
    );
    final valueStyle = theme.textTheme.bodySmall?.copyWith(
      fontSize: 11,
      fontFamily: 'monospace',
      height: 1.25,
      color: theme.colorScheme.onSurface,
    );

    return Column(
      children: [
        InkWell(
          onLongPress: () => Clipboard.setData(ClipboardData(text: copyText)),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (label.isNotEmpty)
                  SizedBox(
                    width: 72,
                    child: Text(label, style: labelStyle),
                  ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SelectableText(value, style: valueStyle),
                      if (hasOther) ...[
                        const SizedBox(height: 1),
                        SelectableText(
                          other!,
                          style: valueStyle?.copyWith(
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.75),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                InkWell(
                  onTap: () => Clipboard.setData(ClipboardData(text: copyText)),
                  borderRadius: BorderRadius.circular(4),
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Icon(
                      Icons.copy_rounded,
                      size: 12,
                      color:
                          theme.colorScheme.onSurface.withValues(alpha: 0.35),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (showDivider) Divider(height: 1, thickness: 1, color: borderColor),
      ],
    );
  }
}
