import 'package:flutter/material.dart';
import 'package:infospect/features/network/models/infospect_network_call.dart';
import 'package:infospect/features/network/ui/details/components/interceptor_details_error.dart';
import 'package:infospect/features/network/ui/details/components/interceptor_details_request.dart';
import 'package:infospect/features/network/ui/details/components/interceptor_details_response.dart';
import 'package:infospect/helpers/infospect_helper.dart';
import 'package:infospect/utils/common_widgets/divider.dart';
import 'package:infospect/utils/extensions/infospect_network/network_response_extension.dart';

class DesktopDetailsScreen extends StatelessWidget {
  const DesktopDetailsScreen(
      {super.key, this.selectedCall, required this.infospect});

  final InfospectNetworkCall? selectedCall;
  final Infospect infospect;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 4),
        Row(
          children: [
            const SizedBox(width: 8),
            if (selectedCall != null)
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: Colors.grey,
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8.0, vertical: 2.0),
                  child: Text(
                    selectedCall?.method ?? '',
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ),
            const SizedBox(width: 8),
            if (selectedCall != null)
              Container(
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    color: selectedCall?.response?.getStatusTextColor(context)),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8.0, vertical: 2.0),
                  child: Text(
                    '${selectedCall?.response?.status ?? ''}',
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ),
            const SizedBox(width: 8),
            Flexible(
              child: SelectableText(
                selectedCall?.uri ?? '',
                style: const TextStyle(fontSize: 12),
              ),
            )
          ],
        ),
        const SizedBox(height: 4),
        AppDivider.horizontal(),
        Flexible(
          child: Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    const SizedBox(height: 4),
                    const Text(
                      'Request',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    AppDivider.horizontal(),
                    if (selectedCall != null)
                      Expanded(
                        child: InterceptorDetailsRequest(
                          selectedCall!,
                          infospect: infospect,
                        ),
                      )
                  ],
                ),
              ),
              AppDivider.vertical(),
              Expanded(
                child: Column(
                  children: [
                    const SizedBox(height: 4),
                    const Text(
                      'Response',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    AppDivider.horizontal(),
                    if (selectedCall != null)
                      Expanded(
                        child: InterceptorDetailsResponse(
                          selectedCall!,
                          infospect: infospect,
                        ),
                      )
                  ],
                ),
              ),
              if (selectedCall != null && selectedCall?.error != null) ...[
                AppDivider.vertical(),
                Expanded(
                  child: Column(
                    children: [
                      const SizedBox(height: 4),
                      const Text(
                        'Error',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      AppDivider.horizontal(),
                      if (selectedCall != null)
                        Expanded(
                          child: InterceptorDetailsError(
                            selectedCall!,
                            infospect: infospect,
                          ),
                        )
                    ],
                  ),
                )
              ]
            ],
          ),
        ),
      ],
    );
  }
}
