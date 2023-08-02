import 'package:flutter/material.dart';
import 'package:infospect/helpers/infospect_helper.dart';
import 'package:infospect/network/models/infospect_network_call.dart';
import 'package:infospect/network/ui/interceptor_details/widgets/details_row_widget.dart';
import 'package:infospect/network/ui/interceptor_list/components/expansion_widget.dart';
import 'package:infospect/network/ui/interceptor_list/components/trailing_widget.dart';
import 'package:infospect/utils/common_widgets/conditional_widget.dart';
import 'package:infospect/utils/extensions/infospect_network/network_response_extension.dart';
import 'package:infospect/utils/extensions/int_extension.dart';

class InterceptorDetailsResponse extends StatelessWidget {
  final InfospectNetworkCall call;
  final Infospect infospect;
  const InterceptorDetailsResponse(
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
              /// General Data
              ExpansionWidget(
                title: 'General',
                children: [
                  DetailsRowWidget(
                      'Received at:', call.response!.time.toString()),
                  DetailsRowWidget(
                      'Bytes received:', call.response!.size.toReadableBytes),
                  DetailsRowWidget(
                    "Status:",
                    call.response!.statusString,
                    showDivider: false,
                  ),
                ],
              ),

              /// Headers
              if (call.response?.headers?.isNotEmpty ?? false) ...[
                ExpansionWidget.map(
                  title: 'Headers',
                  trailing: TrailingWidget(
                    text: 'View raw',
                    infospect: infospect,
                    data: call.response?.headers ?? {},
                  ),
                  map: call.response?.headers ?? {},
                ),
              ],
            ],
          ),

          /// Body
          if (call.response?.body != null &&
              (call.response?.body ?? '').toString().isNotEmpty) ...[
            ExpansionWidget.map(
              title: 'Body',
              trailing: TrailingWidget(
                text: 'View Body',
                infospect: infospect,
                data: call.response?.body,
                beautificationRequired: true,
              ),
              map: {'': call.response?.body?.toString() ?? ''},
            ),
          ]
        ],
      ),
    );
  }
}
