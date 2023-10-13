import 'package:flutter/material.dart';
import 'package:infospect/features/network/models/infospect_network_call.dart';
import 'package:infospect/features/network/ui/details/widgets/details_row_widget.dart';
import 'package:infospect/features/network/ui/list/components/expansion_widget.dart';
import 'package:infospect/helpers/infospect_helper.dart';
import 'package:infospect/utils/common_widgets/conditional_widget.dart';

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
    return ConditionalWidget(
      condition: call.loading || call.response == null,
      ifTrue: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [CircularProgressIndicator(), Text("Waiting for response")],
        ),
      ),
      ifFalse: ListView(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// Errors
              if (call.error != null) ...[
                ExpansionWidget(
                  title: 'Error',
                  children: [
                    DetailsRowWidget(
                      'Message',
                      call.error?.error.toString() ?? '',
                      showDivider: call.error?.stackTrace != null,
                    ),
                    if (call.error?.stackTrace != null)
                      DetailsRowWidget(
                        'Stack Trace',
                        call.error?.stackTrace.toString() ?? '',
                        showDivider: false,
                      ),
                  ],
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
