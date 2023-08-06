import 'dart:math';

import 'package:cuberto_bottom_bar/cuberto_bottom_bar.dart';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:infospect/features/launch/bloc/launch_bloc.dart';
import 'package:infospect/features/logger/ui/logs_list/bloc/logs_list_bloc.dart';
import 'package:infospect/features/logger/ui/logs_list/screen/logs_list_screen.dart';
import 'package:infospect/features/network/ui/list/bloc/networks_list_bloc.dart';
import 'package:infospect/features/network/ui/list/screen/networks_list_screen.dart';
import 'package:infospect/features/search/bloc/search_bloc.dart';
import 'package:infospect/features/search/component/search_bar_widget.dart';
import 'package:infospect/helpers/infospect_helper.dart';

class LaunchMobileScreen extends StatelessWidget {
  final Infospect infospect;
  const LaunchMobileScreen(this.infospect, {super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const SearchBarWidget(),
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
          tabs: [
            TabData(iconData: FontAwesomeIcons.globe, title: "Network calls"),
            TabData(iconData: FontAwesomeIcons.list, title: "Logs")
          ],
          onTabChangedListener: (position, headline6, backgroundColor) {
            context.read<LaunchBloc>().add(
                  TabChanged(
                    selectedTab: position,
                  ),
                );
            final networkSearchedtext =
                context.read<NetworksListBloc>().state.searchedText;
            final logSearchedtext =
                context.read<LogsListBloc>().state.searchedText;
            final bloc = context.read<SearchBloc>();

            if (position == 0) {
              bloc.add(SearchTextSet(text: logSearchedtext));
              bloc.add(SearchTextSet(text: networkSearchedtext));
            } else {
              bloc.add(SearchTextSet(text: networkSearchedtext));
              bloc.add(SearchTextSet(text: logSearchedtext));
            }
          },
        );
      },
    );
  }
}
