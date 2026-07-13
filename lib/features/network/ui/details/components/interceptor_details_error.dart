import 'package:flutter/material.dart';
import 'package:infospect/features/network/models/infospect_network_call.dart';
import 'package:infospect/features/network/ui/details/widgets/details_row_widget.dart';
import 'package:infospect/features/network/ui/list/components/expansion_widget.dart';
import 'package:infospect/helpers/infospect_helper.dart';

class InterceptorDetailsError extends StatelessWidget {
  final InfospectNetworkCall call;
  final Infospect infospect;
  const InterceptorDetailsError(
    this.call, {
    super.key,
    required this.infospect,
  });

  @override
  Widget build(BuildContext context) {
    final error = call.error;
    if (error == null) {
      return const _AwaitingResponseState(message: 'No error for this call');
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(0, 6, 0, 8),
      children: [
        ExpansionWidget(
          title: 'Error',
          children: [
            DetailsRowWidget(
              'Message',
              error.error.toString(),
              showDivider: error.stackTrace != null,
            ),
            if (error.stackTrace != null)
              DetailsRowWidget(
                'Stack Trace',
                error.stackTrace.toString(),
                showDivider: false,
              ),
          ],
        ),
      ],
    );
  }
}

class _AwaitingResponseState extends StatelessWidget {
  const _AwaitingResponseState({this.message = 'Waiting for response'});

  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            message,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
            ),
          ),
        ],
      ),
    );
  }
}
