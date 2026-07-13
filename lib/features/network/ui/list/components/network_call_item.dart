import 'package:flutter/material.dart';
import 'package:infospect/features/network/models/infospect_network_call.dart';
import 'package:infospect/utils/common_widgets/highlight_text_widget.dart';
import 'package:infospect/utils/extensions/date_time_extension.dart';
import 'package:infospect/utils/extensions/infospect_network/network_response_extension.dart';
import 'package:infospect/utils/extensions/int_extension.dart';

/// Compact mobile network call row.
class NetworkCallItem extends StatelessWidget {
  const NetworkCallItem({
    super.key,
    required this.networkCall,
    required this.onItemClicked,
    this.onAddBreakpoint,
    this.searchedText = '',
    this.zebra = false,
  });

  final InfospectNetworkCall networkCall;
  final ValueChanged<InfospectNetworkCall> onItemClicked;
  final ValueChanged<InfospectNetworkCall>? onAddBreakpoint;
  final String searchedText;
  final bool zebra;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusColor = networkCall.loading
        ? theme.colorScheme.primary
        : (networkCall.response?.getStatusTextColor(context) ??
            theme.colorScheme.outline);
    final borderColor =
        theme.colorScheme.outlineVariant.withValues(alpha: 0.35);
    final background = zebra
        ? theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.18)
        : Colors.transparent;

    final path = networkCall.endpoint.isNotEmpty
        ? networkCall.endpoint
        : networkCall.uri;
    final muted = theme.colorScheme.onSurface.withValues(alpha: 0.55);
    final metaStyle = theme.textTheme.labelSmall?.copyWith(
      fontSize: 10,
      fontFamily: 'monospace',
      height: 1.2,
      color: muted,
    );

    final duration = networkCall.loading
        ? '…'
        : networkCall.duration.toReadableTime;
    final up = (networkCall.request?.size ?? 0).toReadableBytes;
    final down = (networkCall.response?.size ?? 0).toReadableBytes;
    final time =
        (networkCall.request?.time ?? networkCall.createdTime).formatTime;

    return Material(
      color: background,
      child: InkWell(
        onTap: () => onItemClicked(networkCall),
        onLongPress: onAddBreakpoint == null
            ? null
            : () => onAddBreakpoint!(networkCall),
        child: DecoratedBox(
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(color: statusColor, width: 3),
              bottom: BorderSide(color: borderColor),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 6, 10, 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _MethodPill(method: networkCall.method),
                    const SizedBox(width: 5),
                    _StatusPill(networkCall: networkCall),
                    if (networkCall.error != null) ...[
                      const SizedBox(width: 4),
                      Icon(
                        Icons.error_outline_rounded,
                        size: 12,
                        color: theme.colorScheme.error,
                      ),
                    ],
                    const Spacer(),
                    Text(time, style: metaStyle),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Expanded(
                      child: HighlightText(
                        text: path,
                        highlight:
                            searchedText.isEmpty ? null : searchedText,
                        ignoreCase: true,
                        selectable: false,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontSize: 12,
                          fontFamily: 'monospace',
                          fontWeight: FontWeight.w600,
                          height: 1.25,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '$duration · $up↑ $down↓',
                      style: metaStyle,
                    ),
                  ],
                ),
                if (networkCall.server.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  HighlightText(
                    text: networkCall.server,
                    highlight: searchedText.isEmpty ? null : searchedText,
                    ignoreCase: true,
                    selectable: false,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: metaStyle,
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

class _MethodPill extends StatelessWidget {
  const _MethodPill({required this.method});

  final String method;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(3),
        color: theme.colorScheme.primary.withValues(alpha: 0.16),
      ),
      child: Text(
        method.toUpperCase(),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.2,
          height: 1.2,
          color: theme.colorScheme.primary,
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.networkCall});

  final InfospectNetworkCall networkCall;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (networkCall.loading) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(3),
          color: theme.colorScheme.primary.withValues(alpha: 0.12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 8,
              height: 8,
              child: CircularProgressIndicator(
                strokeWidth: 1.2,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              '…',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                height: 1.2,
                color: theme.colorScheme.primary,
              ),
            ),
          ],
        ),
      );
    }

    final color = networkCall.response?.getStatusTextColor(context) ??
        theme.colorScheme.outline;
    final label = networkCall.response?.statusString ?? 'ERR';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(3),
        color: color.withValues(alpha: 0.16),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          height: 1.2,
          color: color,
        ),
      ),
    );
  }
}
