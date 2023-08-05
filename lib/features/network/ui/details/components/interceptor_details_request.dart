import 'package:flutter/material.dart';
import 'package:infospect/features/network/models/infospect_network_call.dart';
import 'package:infospect/features/network/ui/details/widgets/details_row_widget.dart';
import 'package:infospect/features/network/ui/list/components/expansion_widget.dart';
import 'package:infospect/features/network/ui/list/components/trailing_widget.dart';
import 'package:infospect/helpers/infospect_helper.dart';
import 'package:infospect/utils/extensions/int_extension.dart';

class InterceptorDetailsRequest extends StatelessWidget {
  final InfospectNetworkCall call;
  final Infospect infospect;

  const InterceptorDetailsRequest(
    this.call, {
    super.key,
    required this.infospect,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      shrinkWrap: true,
      children: [
        /// General data
        ExpansionWidget(
          title: 'General',
          children: [
            DetailsRowWidget(
              "Url: ",
              'Server: ${call.server}',
              other: 'Endpoint: ${call.endpoint}',
            ),
            DetailsRowWidget(
              "Time:",
              'Start : ${call.request!.time}',
              other: 'Finish : ${call.response!.time.toString()}',
            ),
            DetailsRowWidget("Method: ", call.method),
            DetailsRowWidget(
              "Duration:",
              call.duration.toReadableTime,
              showDivider: false,
            ),
          ],
        ),

        /// Headers
        if (call.request?.headers.isNotEmpty ?? false) ...[
          ExpansionWidget.map(
            title: 'Headers',
            trailing: TrailingWidget(
              text: 'View raw',
              infospect: infospect,
              data: call.request?.headers ?? {},
            ),
            map: call.request?.headers ?? {},
          ),
        ],

        /// Query params
        if (call.request?.queryParameters.isNotEmpty ?? false) ...[
          ExpansionWidget.map(
            title: 'Query Params',
            trailing: TrailingWidget(
              text: 'View raw',
              infospect: infospect,
              data: call.request?.queryParameters ?? {},
            ),
            map: call.request?.queryParameters ?? {},
          ),
        ],

        /// Form data fields
        if (call.request?.formDataFields?.isNotEmpty ?? false) ...[
          ExpansionWidget.map(
            title: 'Form Data Fields',
            map: {for (var e in call.request!.formDataFields!) e.name: e.value},
          ),
        ],

        /// Form data files
        if (call.request?.formDataFiles?.isNotEmpty ?? false) ...[
          ExpansionWidget.map(
            title: 'Form Data Files',
            map: {
              for (var e in call.request!.formDataFiles!)
                e.fileName ?? '': '${e.contentType} / ${e.length} B'
            },
          ),
        ],

        /// Body
        if (call.request?.body != null &&
            (call.request?.body ?? '').toString().isNotEmpty) ...[
          ExpansionWidget.map(
            title: 'Body',
            trailing: TrailingWidget(
              text: 'View Body',
              infospect: infospect,
              data: call.request?.body,
              beautificationRequired: true,
            ),
            map: {'': call.request?.body?.toString() ?? ''},
          ),
        ],

        /// Summary
        ExpansionWidget(
          title: 'Summary',
          children: [
            DetailsRowWidget(
              "Data transmitted",
              "Sent: ${call.request!.size.toReadableBytes}",
              other: 'Received: ${call.response!.size.toReadableBytes}',
            ),
            DetailsRowWidget(
              "Client:",
              call.client,
              showDivider: false,
            ),
          ],
        ),
      ],
    );
  }
}
