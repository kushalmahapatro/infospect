import 'package:flutter/material.dart';
import 'package:infospect/features/launch/notifier/launch_notifier.dart';
import 'package:infospect/features/launch/models/navigation_tab_data.dart';
import 'package:infospect/features/logger/ui/logs_list/screen/logs_list_screen.dart';
import 'package:infospect/features/logger/ui/logs_list/notifier/logs_list_notifier.dart';
import 'package:infospect/features/network/ui/list/screen/networks_list_screen.dart';
import 'package:infospect/features/network/ui/list/notifier/networks_list_notifier.dart';
import 'package:infospect/infospect.dart';

class LaunchMobileScreen extends StatelessWidget {
  final Infospect infospect;
  final NetworksListNotifier networksListNotifier;
  final LogsListNotifier logsListNotifier;

  const LaunchMobileScreen(
    this.infospect, {
    required this.networksListNotifier,
    required this.logsListNotifier,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final launchNotifier = LaunchNotifier.instance;
    return Scaffold(
      body: ValueListenableBuilder<int>(
        valueListenable: launchNotifier,
        builder: (context, index, _) {
          return IndexedStack(
            index: index,
            children: [
              NetworksListScreen(
                infospect,
                notifier: networksListNotifier,
              ),
              LogsListScreen(
                infospect,
                notifier: logsListNotifier,
              ),
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
    final launchNotifier = LaunchNotifier.instance;
    return ValueListenableBuilder<int>(
      valueListenable: launchNotifier,
      builder: (context, index, _) {
        return AppBottomBar(
          selectedIndex: index,
          tabs: NavigationTabData.tabs,
          tabChangedCallback: (value) {
            launchNotifier.selectTab(value);
          },
        );
      },
    );
  }
}
