import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:infospect/features/network/models/infospect_network_call.dart';
import 'package:infospect/features/network/ui/list/bloc/networks_list_bloc.dart';
import 'package:infospect/features/network/ui/list/components/network_call_app_bar.dart';
import 'package:infospect/features/network/ui/list/components/network_call_item.dart';
import 'package:infospect/helpers/infospect_helper.dart';
import 'package:infospect/routes/routes.dart';

class NetworksListScreen extends StatelessWidget {
  final Infospect infospect;
  const NetworksListScreen(this.infospect, {super.key});

  @override
  Widget build(BuildContext context) {
    final networkListBloc = context.watch<NetworksListBloc>();

    return Scaffold(
      appBar: NetworkCallAppBar(
        hasBottom: networkListBloc.state.filters.isNotEmpty,
        infospect: infospect,
      ),
      body: BlocBuilder<NetworksListBloc, NetworksListState>(
        builder: (context, state) {
          if (state.filteredCalls.isEmpty) {
            return const Center(child: Text("No network calls"));
          }

          return ListView.builder(
            itemCount: state.filteredCalls.length,
            itemBuilder: (context, index) {
              return NetworkCallItem(
                networkCall: state.filteredCalls[index],
                searchedText: state.searchedText,
                onItemClicked: (InfospectNetworkCall call) {
                  mobileRoutes.logsList(context, infospect, call);
                },
              );
            },
          );
        },
      ),
    );
  }
}
