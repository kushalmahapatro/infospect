import 'dart:io';

import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:infospect/features/launch/notifier/launch_notifier.dart';
import 'package:infospect/features/launch/models/navigation_tab_data.dart';
import 'package:infospect/features/logger/ui/logs_list/notifier/logs_list_notifier.dart';
import 'package:infospect/features/network/ui/list/notifier/networks_list_notifier.dart';
import 'package:infospect/features/logger/ui/logs_list/screen/desktop_logs_list_screen.dart';
import 'package:infospect/features/network/ui/list/screen/desktop_networks_list_screen.dart';
import 'package:infospect/helpers/infospect_helper.dart';
import 'package:infospect/utils/common_widgets/divider.dart';

class LaunchDesktopScreen extends StatelessWidget {
  final Infospect infospect;
  final NetworksListNotifier networksListNotifier;
  final LogsListNotifier logsListNotifier;

  const LaunchDesktopScreen(
    this.infospect, {
    required this.networksListNotifier,
    required this.logsListNotifier,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    infospect.handleMultiWindowReceivedData(context);

    return Scaffold(
      body: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _FirstSection(infospect),
          AppDivider.vertical(),
          _SecondSection(
            infospect,
            networksListNotifier: networksListNotifier,
            logsListNotifier: logsListNotifier,
          ),
        ],
      ),
    );
  }
}

class _SecondSection extends StatelessWidget {
  final Infospect infospect;
  final NetworksListNotifier networksListNotifier;
  final LogsListNotifier logsListNotifier;

  const _SecondSection(
    this.infospect, {
    required this.networksListNotifier,
    required this.logsListNotifier,
  });
  @override
  Widget build(BuildContext context) {
    final launchNotifier = LaunchNotifier.instance;
    return Flexible(
      flex: 8,
      child: ValueListenableBuilder<int>(
        valueListenable: launchNotifier,
        builder: (context, selectedIndex, _) {
          return IndexedStack(
            index: selectedIndex,
            children: [
              DesktopNetworksListScreen(
                infospect,
                notifier: networksListNotifier,
              ),
              DesktopLogsListScreen(
                infospect,
                notifier: logsListNotifier,
              ),
            ],
          );
        },
      ),
    );
  }
}

class _FirstSection extends StatelessWidget {
  const _FirstSection(this.infospect);

  final Infospect infospect;

  @override
  Widget build(BuildContext context) {
    final launchNotifier = LaunchNotifier.instance;
    return Flexible(
      flex: 2,
      child: ValueListenableBuilder<int>(
        valueListenable: launchNotifier,
        builder: (context, selectedIndex, _) {
          return Scaffold(
            appBar: AppBar(
              toolbarHeight: 40,
              leading: _AppBarLeadingWidget(
                infospect: infospect,
              ),
            ),
            body: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: NavigationTabData.tabs.mapIndexed(
                (index, item) {
                  return Container(
                    decoration: BoxDecoration(
                      color: _getSelectionColor(
                        context,
                        selected: selectedIndex == index,
                        inverse: true,
                      ),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    width: double.maxFinite,
                    padding:
                        const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                    margin:
                        const EdgeInsets.symmetric(vertical: 2, horizontal: 4),
                    child: InkWell(
                      onTap: () => launchNotifier.selectTab(index),
                      child: Row(
                        children: [
                          Icon(
                            item.icon,
                            size: 14,
                            color: _getSelectionColor(
                              context,
                              selected: selectedIndex == index,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            item.title.toUpperCase(),
                            style: TextStyle(
                              fontSize: 10,
                              color: _getSelectionColor(
                                context,
                                selected: selectedIndex == index,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ).toList(),
            ),
          );
        },
      ),
    );
  }

  Color _getSelectionColor(BuildContext context,
      {required bool selected, bool inverse = false}) {
    final Color unSelectedColor = Theme.of(context).colorScheme.onSurface;
    final Color selectedColor = Theme.of(context).colorScheme.surface;
    if (selected) {
      return inverse ? unSelectedColor : selectedColor;
    } else {
      return inverse ? selectedColor : unSelectedColor;
    }
  }
}

class _AppBarLeadingWidget extends StatelessWidget {
  const _AppBarLeadingWidget({
    required this.infospect,
  });

  final Infospect infospect;

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      return const SizedBox();
    } else if (Platform.isMacOS || Platform.isLinux || Platform.isWindows) {
      return const SizedBox();
    }
    return IconButton(
      icon: const Icon(Icons.chevron_left),
      onPressed: () {
        infospect.getNavigatorKey?.currentState?.pop();
      },
    );
  }
}
