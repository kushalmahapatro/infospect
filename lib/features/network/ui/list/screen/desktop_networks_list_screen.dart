import 'package:desktop_multi_window/desktop_multi_window.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:infospect/features/logger/models/infospect_log.dart';
import 'package:infospect/features/network/models/infospect_network_call.dart';
import 'package:infospect/features/network/ui/details/screen/desktop_details_screen.dart';
import 'package:infospect/features/network/ui/list/bloc/networks_list_bloc.dart';
import 'package:infospect/features/network/ui/list/components/network_call_app_bar.dart';
import 'package:infospect/features/network/ui/list/desktop_components/desktop_call_list_states.dart';
import 'package:infospect/features/network/ui/list/desktop_components/draggable_table.dart';
import 'package:infospect/helpers/infospect_helper.dart';
import 'package:infospect/utils/common_widgets/divider.dart';

class DesktopNetworksListScreen extends StatefulWidget {
  final Infospect infospect;
  const DesktopNetworksListScreen(this.infospect, {super.key});

  @override
  State<DesktopNetworksListScreen> createState() =>
      _DesktopNetworksListScreenState();
}

class _DesktopNetworksListScreenState
    extends DesktopNetworksListScreenState<DesktopNetworksListScreen> {
  @override
  void initState() {
    DesktopMultiWindow.setMethodHandler(_handleMethodCallback);

    super.initState();
  }

  Future<dynamic> _handleMethodCallback(
      MethodCall call, int fromWindowId) async {
    if (call.arguments is Map && (call.arguments as Map).containsKey('logs')) {
      for (final log in ((call.arguments as Map)['logs'] as List)) {
        widget.infospect.infospectLogger.add(InfospectLog.fromMap(log));
        setState(() {});
      }
    }
    if (call.arguments is Map &&
        (call.arguments as Map).containsKey('network')) {
      if ((call.arguments as Map)['network'] is List &&
          ((call.arguments as Map)['network'] as List).isNotEmpty) {
        List<InfospectNetworkCall>? events = [];
        for (final log in ((call.arguments as Map)['network'] as List)) {
          try {
            final InfospectNetworkCall call = InfospectNetworkCall.fromMap(log);
            events.add(call);
          } catch (e, st) {
            debugPrint('Error while adding call: $e, stack: $st');
            widget.infospect.infospectLogger.add(
              InfospectLog(
                level: DiagnosticLevel.error,
                message: 'Error while adding call: $e',
                stackTrace: st,
                error: e,
                timestamp: DateTime.now(),
              ),
            );
          }
        }
        if (events.isNotEmpty) {
          widget.infospect.removeCalls();
          widget.infospect.callsSubject.add(events.reversed.toList());
          setState(() {});
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final networkListBloc = context.watch<NetworksListBloc>();

    return Scaffold(
      appBar: NetworkCallAppBar.desktop(
        infospect: widget.infospect,
        hasBottom: networkListBloc.state.filters.isNotEmpty,
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return DraggableTable(
                  infospect: widget.infospect,
                  onCallSelected: (call) => updateSelectedCall(call),
                  selectedCall: selectedCall,
                  constraints: constraints,
                );
              },
            ),
          ),
          AppDivider.horizontal(),
          Expanded(
            child: DesktopDetailsScreen(
              selectedCall: selectedCall,
              infospect: widget.infospect,
              topicHelper: topicHelper,
              responseTopicHelper: responseTopicHelper,
              selectedTopic: selectedTopic,
              selectedResponseTopic: selectedResponseTopic,
              onResponseTopicSelected: (value) =>
                  updateSelectedResponseTopic(value),
              onTopicSelected: (value) => updateSelectedTopic(value),
            ),
          ),
        ],
      ),
    );
  }
}
