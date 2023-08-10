import 'package:flutter/material.dart';
import 'package:infospect/features/network/models/infospect_network_call.dart';
import 'package:infospect/utils/common_widgets/conditional_widget.dart';
import 'package:infospect/utils/common_widgets/highlight_text_widget.dart';
import 'package:infospect/utils/extensions/date_time_extension.dart';
import 'package:infospect/utils/extensions/infospect_network/network_response_extension.dart';
import 'package:infospect/utils/extensions/int_extension.dart';

class NetworkCallItem extends StatelessWidget {
  final InfospectNetworkCall networkCall;
  final Function onItemClicked;
  final String searchedText;

  const NetworkCallItem({
    super.key,
    required this.networkCall,
    required this.onItemClicked,
    this.searchedText = '',
  });

  @override
  Widget build(BuildContext context) {
    const style = TextStyle(
      fontSize: 10,
      fontWeight: FontWeight.bold,
      height: 1,
      color: Colors.black45,
    );
    return InkWell(
      onTap: () => onItemClicked(networkCall),
      enableFeedback: true,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8),
        decoration: const BoxDecoration(
            border:
                Border(bottom: BorderSide(width: 1, color: Colors.black12))),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 4),
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 4,
                children: [
                  ConditionalWidget(
                    condition: networkCall.loading,
                    ifTrue: SizedBox(
                      width: 10,
                      height: 10,
                      child: CircularProgressIndicator(
                        color: Colors.red[400],
                        strokeWidth: 1,
                      ),
                    ),
                    ifFalse: Container(
                      height: 10,
                      width: 10,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color:
                            networkCall.response?.getStatusTextColor(context),
                      ),
                    ),
                  ),
                  Text(
                    networkCall.method,
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 12,
                      height: 1,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  _ResponseStatusWidget(networkCall),
                  Text(
                    ' • ${(networkCall.request?.time ?? DateTime.now()).formatTime}',
                    style: style,
                  ),
                  Text(' • ${networkCall.duration.toReadableTime}',
                      style: style),
                  Text(
                    " • ${(networkCall.request?.size ?? 0).toReadableBytes} ↑ / "
                    "${(networkCall.response?.size ?? 0).toReadableBytes} ↓",
                    style: style,
                  )
                ],
              ),
              const SizedBox(height: 4),
              HighlightText(
                text: networkCall.uri,
                highlight: searchedText,
                selectable: false,
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 14,
                  height: 1,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
            ],
          ),
        ),
      ),
    );
  }
}

class _ResponseStatusWidget extends StatelessWidget {
  final InfospectNetworkCall networkCall;
  const _ResponseStatusWidget(this.networkCall);

  @override
  Widget build(BuildContext context) {
    return ConditionalWidget(
      condition: networkCall.loading,
      ifTrue: const SizedBox.shrink(),
      ifFalse: Text(
        ' • ${networkCall.response?.statusString ?? ''}',
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: Colors.black45,
          height: 1,
        ),
      ),
    );
  }
}
