import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_json_view/flutter_json_view.dart';
import 'package:infospect/network/models/infospect_network_call.dart';
import 'package:infospect/ui/interceptor_details/bloc/interceptor_details_bloc.dart';
import 'package:infospect/ui/interceptor_details/utils/interceptor_details_helper.dart';
import 'package:infospect/ui/interceptor_details/widgets/details_row_widget.dart';
import 'package:infospect/utils/extensions/int_extension.dart';

class InterceptorDetailsResponse extends StatelessWidget {
  final InfospectNetworkCall call;
  const InterceptorDetailsResponse(this.call, {super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          margin: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.black, width: 2),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DetailsRowWidget('Started at:', call.request!.time.toString()),
              DetailsRowWidget(
                  'Bytes sent:', call.request!.size.toReadableBytes),
              DetailsRowWidget(
                  "Content type:", call.request!.headers.contentType),
              if (call.request?.formDataFields?.isNotEmpty ?? false) ...[
                const DetailsRowWidget('Form data fields: ', ''),
                ...call.request!.formDataFields!
                    .map((field) => DetailsRowWidget(
                          '• ${field.name}:',
                          field.value,
                        ))
                    .toList(),
              ],
              if (call.request?.formDataFiles?.isNotEmpty ?? false) ...[
                const DetailsRowWidget('Form data files: ', ''),
                ...call.request!.formDataFiles!
                    .map((field) => DetailsRowWidget(
                          '• ${field.fileName}:',
                          '${field.contentType} / ${field.length} B',
                        ))
                    .toList(),
              ],
              DetailsRowWidget(
                'Headers: ',
                (call.request?.headers.isEmpty ?? false)
                    ? 'Headers are Empty'
                    : '',
              ),
              ...(call.request?.headers ?? {})
                  .entries
                  .map((e) => DetailsRowWidget(
                        "• ${e.key}:",
                        e.value.toString(),
                      ))
                  .toList(),
              DetailsRowWidget(
                'Query Parameters: ',
                (call.request?.queryParameters.isEmpty ?? false)
                    ? 'Query parameters are empty'
                    : '',
              ),
              ...(call.request?.queryParameters ?? {})
                  .entries
                  .map((e) => DetailsRowWidget(
                        "${e.key}:",
                        e.value.toString(),
                      ))
                  .toList()
            ],
          ),
        ),
        if (call.request?.body != null &&
            (call.request?.body ?? '').toString().isNotEmpty)
          BlocSelector<InterceptorDetailsBloc, InterceptorDetailsState, int>(
            selector: (state) => state.requestBodyType,
            builder: (context, index) {
              return Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () {
                          context.read<InterceptorDetailsBloc>().add(
                                const RequestBodyTypeChanged(index: 0),
                              );
                        },
                        child: Container(
                          height: 40,
                          alignment: Alignment.center,
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            border: index == 1
                                ? Border.all(color: Colors.black, width: 2)
                                : null,
                            color:
                                index == 0 ? Colors.black : Colors.yellow[50],
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'Raw body',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              height: 1,
                              color:
                                  index == 0 ? Colors.yellow[50] : Colors.black,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 5),
                    Expanded(
                      child: InkWell(
                        onTap: () {
                          context.read<InterceptorDetailsBloc>().add(
                                const RequestBodyTypeChanged(index: 1),
                              );
                        },
                        child: Container(
                          height: 40,
                          alignment: Alignment.center,
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            border: index == 0
                                ? Border.all(color: Colors.black, width: 2)
                                : null,
                            color:
                                index == 1 ? Colors.black : Colors.yellow[50],
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'Tree View',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              height: 1,
                              color:
                                  index == 1 ? Colors.yellow[50] : Colors.black,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        if (call.request?.body != null &&
            (call.request?.body ?? '').toString().isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.all(6),
            margin: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.black, width: 2),
            ),
            child: BlocSelector<InterceptorDetailsBloc, InterceptorDetailsState,
                int>(
              selector: (state) => state.requestBodyType,
              builder: (context, index) {
                if (index == 0) {
                  return DetailsRowWidget(
                      "Body:", call.request?.body?.toString() ?? '');
                } else {
                  return JsonView.map(
                    jsonDecode(call.request?.body ?? {}),
                    theme: const JsonViewTheme(
                      backgroundColor: Colors.white,
                      openIcon: Icon(
                        Icons.arrow_drop_down,
                        size: 18,
                        color: Colors.black,
                      ),
                      closeIcon: Icon(
                        Icons.arrow_drop_up,
                        size: 18,
                        color: Colors.black,
                      ),
                      separator: Text(
                        ':',
                        style: TextStyle(
                            color: Colors.black, fontWeight: FontWeight.bold),
                      ),
                    ),
                  );
                }
              },
            ),
          )
        ]
      ],
    );
  }
}
