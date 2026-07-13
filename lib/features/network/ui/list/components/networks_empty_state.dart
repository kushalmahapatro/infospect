import 'package:flutter/material.dart';

class NetworksEmptyState extends StatelessWidget {
  const NetworksEmptyState({super.key, required this.hasActiveQuery});

  final bool hasActiveQuery;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Text(
        hasActiveQuery ? 'No matching network calls' : 'No network calls',
        style: theme.textTheme.bodySmall?.copyWith(
          fontSize: 12,
          color: theme.colorScheme.onSurface.withValues(alpha: 0.45),
        ),
      ),
    );
  }
}
