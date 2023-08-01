import 'package:cuberto_bottom_bar/cuberto_bottom_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:infospect/helpers/infospect_helper.dart';
import 'package:infospect/network/models/infospect_network_call.dart';
import 'package:infospect/ui/interceptor_details/bloc/interceptor_details_bloc.dart';
import 'package:infospect/ui/interceptor_details/components/interceptor_details_request.dart';
import 'package:infospect/ui/interceptor_details/components/interceptor_details_response.dart';
import 'package:share_plus/share_plus.dart';

class InterceptorDetailsScreen extends StatelessWidget {
  final Infospect infospect;
  final InfospectNetworkCall call;
  const InterceptorDetailsScreen(this.infospect, this.call, {super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: Text(
          call.server,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: Colors.black),
        ),
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: BlocSelector<InterceptorDetailsBloc, InterceptorDetailsState, int>(
        selector: (state) => state.selectedTab,
        builder: (context, index) {
          return IndexedStack(
            index: index,
            children: [
              InterceptorDetailsRequest(call),
              InterceptorDetailsResponse(call),
              Center(child: Text("Error")),
            ],
          );
        },
      ),
      bottomNavigationBar: BottomNavBarWidget(call),
    );
  }
}

class BottomNavBarWidget extends StatelessWidget {
  final InfospectNetworkCall call;
  const BottomNavBarWidget(
    this.call, {
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
          inactiveIconColor: Colors.black,
          tabs: [
            TabData(iconData: Icons.arrow_upward, title: "Request"),
            TabData(iconData: Icons.arrow_downward, title: "Response"),
            TabData(iconData: Icons.warning, title: "Error"),
            TabData(iconData: FontAwesomeIcons.share, title: "Share"),
          ],
          onTabChangedListener: (position, headline6, backgroundColor) async {
            if (position == 3) {
              Share.share(
                await call.sharableData,
                subject: 'Request Details',
              );
            } else {
              context.read<InterceptorDetailsBloc>().add(
                    DetailsTabChanged(
                      selectedTab: position,
                    ),
                  );
            }
          },
        );
      },
    );
  }
}
