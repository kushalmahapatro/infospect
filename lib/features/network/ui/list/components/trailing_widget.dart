import 'package:flutter/material.dart';
import 'package:infospect/infospect.dart';
import 'package:infospect/routes/routes.dart';

class TrailingWidget extends StatelessWidget {
  final String text;
  final Infospect infospect;
  final Map<String, dynamic> data;
  final bool beautificationRequired;

  const TrailingWidget({
    super.key,
    required this.text,
    required this.infospect,
    required this.data,
    this.beautificationRequired = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return TextButton(
      style: TextButton.styleFrom(
        visualDensity: VisualDensity.compact,
        padding: const EdgeInsets.symmetric(horizontal: 6),
        minimumSize: const Size(0, 22),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      onPressed: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => MobileRoutes().rawDataViewer(
            data: data,
            beautificationRequired: beautificationRequired,
          ),
        ),
      ),
      child: Text(
        text,
        style: theme.textTheme.labelSmall?.copyWith(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          height: 1.1,
          color: theme.colorScheme.primary,
        ),
      ),
    );
  }
}
