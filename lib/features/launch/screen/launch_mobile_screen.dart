import 'package:cuberto_bottom_bar/cuberto_bottom_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:infospect/features/launch/bloc/launch_bloc.dart';
import 'package:infospect/features/launch/models/navigation_tab_data.dart';
import 'package:infospect/features/logger/ui/logs_list/screen/logs_list_screen.dart';
import 'package:infospect/features/network/ui/list/screen/networks_list_screen.dart';
import 'package:infospect/helpers/infospect_helper.dart';

class LaunchMobileScreen extends StatelessWidget {
  final Infospect infospect;
  const LaunchMobileScreen(this.infospect, {super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: BlocSelector<LaunchBloc, LaunchState, int>(
        selector: (state) => state.selectedTab,
        builder: (context, index) {
          return IndexedStack(
            index: index,
            children: [
              NetworksListScreen(infospect),
              LogsListScreen(infospect),
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
    return BlocSelector<LaunchBloc, LaunchState, int>(
      selector: (state) => state.selectedTab,
      builder: (context, index) {
        return CubertoBottomBar(
          key: const Key("BottomBar"),
          barShadow: const [BoxShadow(blurRadius: 0)],
          selectedTab: index,
          inactiveIconColor: Colors.black,
          tabs: NavigationTabData.tabs,
          onTabChangedListener: (position, headline6, backgroundColor) {
            context.read<LaunchBloc>().add(
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
