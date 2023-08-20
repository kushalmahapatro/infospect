import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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
