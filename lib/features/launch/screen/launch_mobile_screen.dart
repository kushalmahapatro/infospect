import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:infospect/features/launch/bloc/launch_bloc.dart';
import 'package:infospect/features/launch/models/navigation_tab_data.dart';
import 'package:infospect/features/logger/ui/logs_list/screen/logs_list_screen.dart';
import 'package:infospect/features/network/ui/list/screen/networks_list_screen.dart';
import 'package:infospect/infospect.dart';

class LaunchMobileScreen extends StatelessWidget {
  final Infospect infospect;
  const LaunchMobileScreen(this.infospect, {super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
        return AppBottomBar(
          selectedIndex: index,
          tabs: NavigationTabData.tabs,
          tabChangedCallback: (value) {
            context.read<LaunchBloc>().add(
                  TabChanged(
                    selectedTab: value,
                  ),
                );
          },
        );
      },
    );
  }
}
