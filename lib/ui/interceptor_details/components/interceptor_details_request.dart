import 'package:flutter/material.dart';
import 'package:infospect/network/models/infospect_network_call.dart';
import 'package:infospect/ui/interceptor/components/expansion_widget.dart';
import 'package:infospect/ui/interceptor_details/widgets/details_row_widget.dart';
import 'package:infospect/utils/extensions/int_extension.dart';

class InterceptorDetailsRequest extends StatelessWidget {
  final InfospectNetworkCall call;

  const InterceptorDetailsRequest(this.call, {super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      shrinkWrap: true,
      children: [
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
            DetailsRowWidget("Duration:", call.duration.toReadableTime),
          ],
        ),
        if (call.request?.headers.isNotEmpty ?? false) ...[
          ExpansionWidget(
            title: 'Headers',
            children: [
              ...(call.request?.headers ?? {})
                  .entries
                  .map(
                    (e) => DetailsRowWidget(
                      "${e.key}:",
                      e.value.toString(),
                    ),
                  )
                  .toList(),
            ],
          ),
        ],
        if (call.request?.queryParameters.isNotEmpty ?? false) ...[
          ExpansionWidget(
            title: 'Query Params',
            children: [
              ...(call.request?.queryParameters ?? {})
                  .entries
                  .map(
                    (e) => DetailsRowWidget(
                      "${e.key}:",
                      e.value.toString(),
                    ),
                  )
                  .toList()
            ],
          ),
        ],
        if (call.request?.formDataFields?.isNotEmpty ?? false) ...[
          ExpansionWidget(
            title: 'Form Data Fields',
            children: [
              ...call.request!.formDataFields!
                  .map(
                    (field) => DetailsRowWidget(
                      field.name,
                      field.value,
                    ),
                  )
                  .toList(),
            ],
          ),
        ],
        if (call.request?.formDataFiles?.isNotEmpty ?? false) ...[
          ExpansionWidget(
            title: 'Form Data files',
            children: [
              ...call.request!.formDataFiles!
                  .map(
                    (field) => DetailsRowWidget(
                      '${field.fileName}',
                      '${field.contentType} / ${field.length} B',
                    ),
                  )
                  .toList(),
            ],
          ),
        ],
        ExpansionWidget(
          title: 'Summary',
          children: [
            DetailsRowWidget(
              "Data transmitted",
              "Sent: ${call.request!.size.toReadableBytes}",
              other: 'Received: ${call.response!.size.toReadableBytes}',
            ),
            DetailsRowWidget("Client:", call.client),
          ],
        ),
      ],
    );
  }
}
