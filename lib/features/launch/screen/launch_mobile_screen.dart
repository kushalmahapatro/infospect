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

  void _close(BuildContext context) {
    final hostContext = infospect.context;
    if (hostContext != null && hostContext.mounted) {
      Navigator.of(hostContext).pop();
      return;
    }
    Navigator.of(context).maybePop();
  }

  @override
  Widget build(BuildContext context) {
    final launchNotifier = LaunchNotifier.instance;
    final theme = Theme.of(context);

    return ValueListenableBuilder<int>(
      valueListenable: launchNotifier,
      builder: (context, index, _) {
        return Scaffold(
          backgroundColor: theme.colorScheme.surface,
          body: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppSegmentedTabBar(
                  selectedIndex: index,
                  tabs: NavigationTabData.tabs,
                  tabChangedCallback: launchNotifier.selectTab,
                  leading: IconButton(
                    tooltip: 'Close',
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 40,
                      minHeight: 40,
                    ),
                    icon: const Icon(Icons.arrow_back_rounded, size: 20),
                    onPressed: () => _close(context),
                  ),
                ),
                Expanded(
                  child: IndexedStack(
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
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
