import 'package:flutter/material.dart';
import 'package:infospect/network/models/infospect_network_call.dart';
import 'package:infospect/ui/interceptor_details/widgets/details_row_widget.dart';
import 'package:infospect/utils/extensions/int_extension.dart';

class InterceptorDetailsOverview extends StatelessWidget {
  final InfospectNetworkCall call;
  const InterceptorDetailsOverview(this.call, {super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(6),
      margin: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.black, width: 2),
      ),
      child: ListView(
        shrinkWrap: true,
        children: [
          DetailsRowWidget("Method: ", call.method),
          DetailsRowWidget("Server: ", call.server),
          DetailsRowWidget("Endpoint: ", call.endpoint),
          DetailsRowWidget("Started:", call.request!.time.toString()),
          DetailsRowWidget("Finished:", call.response!.time.toString()),
          DetailsRowWidget("Duration:", call.duration.toReadableTime),
          DetailsRowWidget("Bytes sent:", call.request!.size.toReadableBytes),
          DetailsRowWidget(
              "Bytes received:", call.response!.size.toReadableBytes),
          DetailsRowWidget("Client:", call.client),
          DetailsRowWidget("Secure:", call.secure.toString()),
        ],
      ),
    );
  }
}
