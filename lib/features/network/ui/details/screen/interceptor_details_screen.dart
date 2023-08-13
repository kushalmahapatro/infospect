import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:infospect/features/network/models/infospect_network_call.dart';
import 'package:infospect/features/network/ui/details/bloc/interceptor_details_bloc.dart';
import 'package:infospect/features/network/ui/details/components/interceptor_details_error.dart';
import 'package:infospect/features/network/ui/details/components/interceptor_details_request.dart';
import 'package:infospect/features/network/ui/details/components/interceptor_details_response.dart';
import 'package:infospect/helpers/infospect_helper.dart';
import 'package:infospect/utils/common_widgets/app_bottom_bar.dart';
import 'package:infospect/utils/extensions/infospect_network/network_call_extension.dart';
import 'package:share_plus/share_plus.dart';

class InterceptorDetailsScreen extends StatelessWidget {
  final Infospect infospect;
  final InfospectNetworkCall call;
  const InterceptorDetailsScreen(this.infospect, this.call, {super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: Text(
          call.server,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: BlocSelector<InterceptorDetailsBloc, InterceptorDetailsState, int>(
        selector: (state) => state.selectedTab,
        builder: (context, index) {
          return IndexedStack(
            index: index,
            children: [
              InterceptorDetailsRequest(call, infospect: infospect),
              InterceptorDetailsResponse(call, infospect: infospect),
              InterceptorDetailsError(call, infospect: infospect),
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
    final tabs = [
      (icon: Icons.arrow_upward, title: "Request"),
      (icon: Icons.arrow_downward, title: "Response"),
      (icon: Icons.warning, title: "Error"),
      (icon: Icons.share, title: "Share")
    ];
    if (call.error == null) {
      tabs.removeAt(2);
    }
    return BlocSelector<InterceptorDetailsBloc, InterceptorDetailsState, int>(
      selector: (state) => state.selectedTab,
      builder: (context, index) {
        return AppBottomBar(
          selectedIndex: index,
          tabs: tabs,
          tabChangedCallback: (position) async {
            if (position == tabs.length - 1) {
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
