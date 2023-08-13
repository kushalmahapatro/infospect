import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:infospect/features/launch/bloc/launch_bloc.dart';
import 'package:infospect/features/launch/models/navigation_tab_data.dart';
import 'package:infospect/features/logger/ui/logs_list/screen/desktop_logs_list_screen.dart';
import 'package:infospect/features/network/ui/list/screen/desktop_networks_list_screen.dart';
import 'package:infospect/helpers/infospect_helper.dart';
import 'package:infospect/helpers/model_theme.dart';
import 'package:infospect/utils/common_widgets/divider.dart';

class LaunchDesktopScreen extends StatelessWidget {
  final Infospect infospect;
  const LaunchDesktopScreen(this.infospect, {super.key});

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback(
      (_) {
        var brightness = MediaQuery.of(context).platformBrightness;
        if (context.read<ModelTheme>().isDark !=
            (brightness == Brightness.dark)) {
          context.read<ModelTheme>().isDark = brightness == Brightness.dark;
        }
      },
    );

    return Scaffold(
      body: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _FirstSection(),
          AppDivider.vertical(),
          _SecondSection(infospect),
        ],
      ),
    );
  }
}

class _SecondSection extends StatelessWidget {
  final Infospect infospect;
  const _SecondSection(this.infospect);
  @override
  Widget build(BuildContext context) {
    return Flexible(
      flex: 8,
      child: BlocSelector<LaunchBloc, LaunchState, int>(
        selector: (state) => state.selectedTab,
        builder: (context, selectedIndex) {
          return IndexedStack(
            index: selectedIndex,
            children: [
              DesktopNetworksListScreen(infospect),
              DesktopLogsListScreen(infospect)
            ],
          );
        },
      ),
    );
  }
}

class _FirstSection extends StatelessWidget {
  const _FirstSection();

  @override
  Widget build(BuildContext context) {
    return Flexible(
      flex: 2,
      child: BlocSelector<LaunchBloc, LaunchState, int>(
        selector: (state) => state.selectedTab,
        builder: (context, selectedIndex) {
          return Scaffold(
            appBar: AppBar(toolbarHeight: 40),
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
                      onTap: () => context.read<LaunchBloc>().add(
                            TabChanged(
                              selectedTab: index,
                            ),
                          ),
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
    final unSelectedColor = Theme.of(context).colorScheme.onBackground;
    final selectedColor = Theme.of(context).colorScheme.background;
    if (selected) {
      return inverse ? unSelectedColor : selectedColor;
    } else {
      return inverse ? selectedColor : unSelectedColor;
    }
  }
}
