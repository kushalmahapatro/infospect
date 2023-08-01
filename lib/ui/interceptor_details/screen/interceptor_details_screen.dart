import 'package:cuberto_bottom_bar/cuberto_bottom_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:infospect/helpers/infospect_helper.dart';
import 'package:infospect/network/models/infospect_network_call.dart';
import 'package:infospect/ui/interceptor_details/bloc/interceptor_details_bloc.dart';
import 'package:infospect/ui/interceptor_details/components/interceptor_details_overview.dart';
import 'package:infospect/ui/interceptor_details/components/interceptor_details_request.dart';

class InterceptorDetailsScreen extends StatelessWidget {
  final Infospect infospect;
  final InfospectNetworkCall call;
  const InterceptorDetailsScreen(this.infospect, this.call, {super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.yellow[50],
      appBar: AppBar(
        backgroundColor: Colors.yellow[50],
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: BlocSelector<InterceptorDetailsBloc, InterceptorDetailsState, int>(
        selector: (state) => state.selectedTab,
        builder: (context, index) {
          return IndexedStack(
            index: index,
            children: [
              InterceptorDetailsOverview(call),
              InterceptorDetailsRequest(call),
              Center(child: Text("Response")),
              Center(child: Text("Error")),
            ],
          );
        },
      ),
      bottomNavigationBar: const BottomNavBarWidget(),
    );
  }
}

class BottomNavBarWidget extends StatelessWidget {
  const BottomNavBarWidget({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return BlocSelector<InterceptorDetailsBloc, InterceptorDetailsState, int>(
      selector: (state) => state.selectedTab,
      builder: (context, index) {
        return CubertoBottomBar(
          key: const Key("BottomBar"),
          barShadow: const [BoxShadow(blurRadius: 0)],
          selectedTab: index,
          barBackgroundColor: Colors.yellow[50],
          inactiveIconColor: Colors.black,
          textColor: Colors.yellow[50],
          tabs: [
            TabData(iconData: Icons.info_outline, title: "Overview"),
            TabData(iconData: Icons.arrow_upward, title: "Request"),
            TabData(iconData: Icons.arrow_downward, title: "Response"),
            TabData(iconData: Icons.warning, title: "Error"),
          ],
          onTabChangedListener: (position, headline6, backgroundColor) {
            context.read<InterceptorDetailsBloc>().add(
                  DetailsTabChanged(
                    selectedTab: position,
                  ),
                );
          },
        );
      },
    );
  }
}
