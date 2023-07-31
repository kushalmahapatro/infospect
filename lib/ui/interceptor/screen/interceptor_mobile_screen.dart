import 'package:cuberto_bottom_bar/cuberto_bottom_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:infospect/network/models/infospect_network_call.dart';
import 'package:infospect/ui/interceptor/bloc/bloc/interceptor_bloc.dart';
import 'package:infospect/ui/interceptor/components/network_call_item.dart';
import 'package:infospect/ui/interceptor/reusable_widgets/search_bar_widget.dart';

class InterceptorMobileScreen extends StatelessWidget {
  const InterceptorMobileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.yellow[50],
      appBar: AppBar(
        backgroundColor: Colors.yellow[50],
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        title: const SearchBarWidget(),
        actions: const [AppBarActionWidget()],
      ),
      body: BlocSelector<InterceptorBloc, InterceptorState, int>(
        selector: (state) => state.selectedTab,
        builder: (context, index) {
          return IndexedStack(
            index: index,
            children: const [
              NetworkCallsWidget(),
              Center(child: Text("Logs")),
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
    return BlocSelector<InterceptorBloc, InterceptorState, int>(
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
            TabData(iconData: FontAwesomeIcons.globe, title: "Network calls"),
            TabData(iconData: FontAwesomeIcons.list, title: "Logs")
          ],
          onTabChangedListener: (position, headline6, backgroundColor) {
            context.read<InterceptorBloc>().add(
                  TabChanged(
                    selectedTab: position,
                  ),
                );
          },
        );
      },
    );
  }
}

class AppBarActionWidget extends StatelessWidget {
  const AppBarActionWidget({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      itemBuilder: (_) {
        return [
          PopupMenuItem<String>(
            child: Container(),
          )
        ];
      },
      icon: const Icon(Icons.more_vert),
    );
  }
}

class NetworkCallsWidget extends StatelessWidget {
  const NetworkCallsWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocSelector<InterceptorBloc, InterceptorState,
        List<InfospectNetworkCall>>(
      selector: (state) => state.networkCalls,
      builder: (context, calls) {
        if (calls.isEmpty) {
          return const Center(child: Text("No network calls"));
        }

        return ListView.builder(
          itemCount: calls.length,
          itemBuilder: (context, index) {
            return NetworkCallItem.mobile(
              networkCall: calls[index],
              itemClicked: (call) {},
            );
          },
        );
      },
    );
  }
}
