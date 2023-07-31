// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flutter/material.dart';
import 'package:infospect/network/models/infospect_network_call.dart';
import 'package:infospect/network/models/infospect_network_response.dart';
import 'package:infospect/ui/common_widgets/conditional_widget.dart';
import 'package:infospect/utils/extensions/date_time_extension.dart';
import 'package:infospect/utils/extensions/int_extension.dart';

part 'desktop_network_call_item.dart';

class NetworkCallItem extends StatelessWidget {
  final InfospectNetworkCall networkCall;
  final Function onItemClicked;

  factory NetworkCallItem.desktop(
      {required InfospectNetworkCall networkCall,
      required Function itemClicked}) {
    return _DesktopNetworkCallItem(
      networkCall: networkCall,
      onItemClicked: itemClicked,
    );
  }

  factory NetworkCallItem.mobile(
      {required InfospectNetworkCall networkCall,
      required Function(InfospectNetworkCall call) itemClicked}) {
    return NetworkCallItem._(
      onItemClicked: itemClicked,
      networkCall: networkCall,
    );
  }

  const NetworkCallItem._(
      {required this.networkCall, required this.onItemClicked});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.black, width: 2),
      ),
      child: InkWell(
        onTap: () => onItemClicked(networkCall),
        enableFeedback: true,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _EndpointWidget(networkCall),
                        const SizedBox(height: 4),
                        _ServerWidget(networkCall),
                        const SizedBox(height: 4),
                        _StatsWidget(networkCall),
                      ],
                    ),
                  ),
                  _ResponseStatusWidget(networkCall),
                ],
              ),
            ),
            // Container(height: 1, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}

class _EndpointWidget extends StatelessWidget {
  final InfospectNetworkCall networkCall;
  const _EndpointWidget(this.networkCall);

  @override
  Widget build(BuildContext context) {
    final color = Colors.green[400];
    return RichText(
      textScaleFactor: MediaQuery.textScaleFactorOf(context),
      maxLines: 10,
      overflow: TextOverflow.ellipsis,
      text: TextSpan(
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: color,
        ),
        children: [
          TextSpan(
              text: '${networkCall.method}:',
              style: const TextStyle(color: Colors.black, fontSize: 12)),
          const WidgetSpan(child: SizedBox(width: 8)),
          TextSpan(text: networkCall.endpoint),
        ],
      ),
    );
  }
}

class _ServerWidget extends StatelessWidget {
  final InfospectNetworkCall networkCall;
  const _ServerWidget(this.networkCall);

  @override
  Widget build(BuildContext context) {
    final color = Colors.green[400];
    return RichText(
      textScaleFactor: MediaQuery.textScaleFactorOf(context),
      overflow: TextOverflow.ellipsis,
      text: TextSpan(
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: color,
        ),
        children: [
          WidgetSpan(
            child: ConditionalWidget(
              condition: networkCall.secure,
              ifTrue: Icon(Icons.lock_outline, color: color, size: 16),
              ifFalse: Icon(Icons.lock_open, color: Colors.red[400], size: 16),
            ),
          ),
          const WidgetSpan(child: SizedBox(width: 2)),
          TextSpan(
            text: networkCall.server,
            style: const TextStyle(color: Colors.black),
          ),
        ],
      ),
    );
  }
}

class _StatsWidget extends StatelessWidget {
  final InfospectNetworkCall networkCall;
  const _StatsWidget(this.networkCall);

  @override
  Widget build(BuildContext context) {
    const style = TextStyle(
      fontSize: 10,
      fontWeight: FontWeight.bold,
    );
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: Text(
            (networkCall.request?.time ?? DateTime.now()).formatTime,
            style: style,
          ),
        ),
        Flexible(
          child: Text(networkCall.duration.toReadableTime, style: style),
        ),
        Flexible(
          child: Text(
              "${(networkCall.request?.size ?? 0).toReadableBytes} / "
              "${(networkCall.response?.size ?? 0).toReadableBytes}",
              style: style),
        )
      ],
    );
  }
}

class _ResponseStatusWidget extends StatelessWidget {
  final InfospectNetworkCall networkCall;
  const _ResponseStatusWidget(this.networkCall);

  @override
  Widget build(BuildContext context) {
    String getStatus(InfospectNetworkResponse response) {
      if (response.status == -1) {
        return "ERR";
      } else if (response.status == 0) {
        return "???";
      } else {
        return "${response.status}";
      }
    }

    return SizedBox(
      width: 40,
      child: Column(
        children: [
          ConditionalWidget(
            condition: networkCall.loading,
            ifTrue: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                color: Colors.red[400],
                strokeWidth: 3,
              ),
            ),
            ifFalse: Text(
              getStatus(networkCall.response!),
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: (networkCall.response?.status ?? -1)
                    .getStatusTextColor(context),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
