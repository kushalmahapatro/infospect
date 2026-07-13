import 'package:flutter/material.dart';

class LogsEmptyState extends StatelessWidget {
  const LogsEmptyState({super.key, required this.hasActiveQuery});

  final bool hasActiveQuery;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Text(
        hasActiveQuery ? 'No matching logs' : 'No logs',
        style: theme.textTheme.bodySmall?.copyWith(
          fontSize: 12,
          color: theme.colorScheme.onSurface.withValues(alpha: 0.45),
        ),
      ),
    );
  }
}
