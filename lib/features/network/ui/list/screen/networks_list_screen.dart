import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:infospect/features/network/models/infospect_network_call.dart';
import 'package:infospect/features/network/ui/details/bloc/interceptor_details_bloc.dart';
import 'package:infospect/features/network/ui/details/screen/interceptor_details_screen.dart';
import 'package:infospect/features/network/ui/list/bloc/networks_list_bloc.dart';
import 'package:infospect/features/network/ui/list/components/network_call_item.dart';
import 'package:infospect/helpers/infospect_helper.dart';

class NetworksListScreen extends StatelessWidget {
  final Infospect infospect;
  const NetworksListScreen(this.infospect, {super.key});

  @override
  Widget build(BuildContext context) {
    return BlocSelector<NetworksListBloc, NetworksListState,
        List<InfospectNetworkCall>>(
      selector: (state) => state.calls.reversed.toList(),
      builder: (context, calls) {
        if (calls.isEmpty) {
          return const Center(child: Text("No network calls"));
        }

        return ListView.builder(
          itemCount: calls.length,
          itemBuilder: (context, index) {
            return NetworkCallItem.mobile(
              networkCall: calls[index],
              itemClicked: (InfospectNetworkCall call) {
                Navigator.push<void>(
                  infospect.context!,
                  MaterialPageRoute(
                    builder: (context) => BlocProvider(
                      create: (context) => InterceptorDetailsBloc(),
                      child: InterceptorDetailsScreen(
                        infospect,
                        call,
                      ),
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}
