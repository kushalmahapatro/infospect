import 'package:flutter/material.dart';
import 'package:infospect/features/network/breakpoints/ui/breakpoints_list_screen.dart';
import 'package:infospect/features/network/ui/list/models/network_action.dart';
import 'package:infospect/features/network/ui/list/notifier/networks_list_notifier.dart';
import 'package:infospect/infospect.dart';
import 'package:infospect/utils/common_widgets/app_adaptive_dialog.dart';
import 'package:infospect/utils/common_widgets/filter_chip_bar.dart';

class NetworkCallAppBar extends StatefulWidget implements PreferredSizeWidget {
  const NetworkCallAppBar({
    super.key,
    this.hasBottom = false,
    required this.infospect,
    required this.notifier,
  }) : isDesktop = false;

  const NetworkCallAppBar.desktop({
    super.key,
    this.hasBottom = false,
    required this.infospect,
    required this.notifier,
  }) : isDesktop = true;

  final bool hasBottom;
  final Infospect infospect;
  final NetworksListNotifier notifier;
  final bool isDesktop;

  static const double _mobileToolbarHeight = 40;

  @override
  State<NetworkCallAppBar> createState() => _NetworkCallAppBarState();

  @override
  Size get preferredSize {
    if (isDesktop) {
      return Size.fromHeight(hasBottom ? 74 : 40);
    }
    return Size.fromHeight(
      _mobileToolbarHeight + (hasBottom ? 36 : 0),
    );
  }
}

class _NetworkCallAppBarState extends State<NetworkCallAppBar> {
  late final TextEditingController _controller = TextEditingController();
  late final FocusNode _focusNode = FocusNode();

  @override
  Widget build(BuildContext context) {
    final networkNotifier = widget.notifier;
    final theme = Theme.of(context);

    if (!widget.isDesktop) {
      return Material(
        color: theme.colorScheme.surface,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: NetworkCallAppBar._mobileToolbarHeight,
              child: Padding(
                padding: const EdgeInsets.only(left: 10, right: 4),
                child: Row(
                  children: [
                    Expanded(
                      child: AppSearchBar(
                        controller: _controller,
                        focusNode: _focusNode,
                        isDesktop: false,
                        onChanged: networkNotifier.searchNetworkLogs,
                      ),
                    ),
                    AppBarActionWidget(
                      actionModel: NetworkAction.filterModel,
                      selectedActions: networkNotifier.filters,
                      tooltip: 'Filter',
                      onItemSelected: networkNotifier.addFilter,
                      selected: networkNotifier.filters.isNotEmpty,
                    ),
                    AppBarActionWidget<NetworkActionType>(
                      actionModel: NetworkAction.menuModel,
                      tooltip: 'More',
                      onItemSelected: (value) {
                        if (value.id == NetworkActionType.breakpoints) {
                          BreakpointsListScreen.open(context);
                        } else if (value.id == NetworkActionType.share) {
                          networkNotifier.shareNetworkLogs();
                        } else if (value.id == NetworkActionType.clear) {
                          AppAdaptiveDialog.show(
                            context,
                            tag: 'network_calls',
                            title: 'Clear Network Call Logs?',
                            body:
                                'Are you sure you want to clear all network call logs? This will clear up the list.',
                            onPositiveActionClick:
                                networkNotifier.clearNetworkLogs,
                          );
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
            if (widget.hasBottom)
              FilterChipBar(
                filters: networkNotifier.filters,
                onDeleted: networkNotifier.removeFilter,
              ),
          ],
        ),
      );
    }

    return AppBar(
      automaticallyImplyLeading: false,
      elevation: 0,
      toolbarHeight: 40,
      scrolledUnderElevation: 0,
      backgroundColor: theme.colorScheme.surface,
      title: AppSearchBar(
        controller: _controller,
        focusNode: _focusNode,
        isDesktop: true,
        onChanged: networkNotifier.searchNetworkLogs,
      ),
      actions: [
        AppBarActionWidget(
          actionModel: NetworkAction.filterModel,
          selectedActions: networkNotifier.filters,
          tooltip: 'Filter',
          onItemSelected: networkNotifier.addFilter,
          selected: networkNotifier.filters.isNotEmpty,
        ),
        AppBarActionWidget<NetworkActionType>(
          actionModel: NetworkAction.menuModel,
          tooltip: 'More',
          onItemSelected: (value) {
            if (value.id == NetworkActionType.breakpoints) {
              BreakpointsListScreen.open(context);
            } else if (value.id == NetworkActionType.share) {
              networkNotifier.shareNetworkLogs();
            } else if (value.id == NetworkActionType.clear) {
              AppAdaptiveDialog.show(
                context,
                tag: 'network_calls',
                title: 'Clear Network Call Logs?',
                body:
                    'Are you sure you want to clear all network call logs? This will clear up the list.',
                onPositiveActionClick: networkNotifier.clearNetworkLogs,
              );
            }
          },
        ),
        const SizedBox(width: 4),
      ],
      bottom: widget.hasBottom
          ? FilterChipBar(
              filters: networkNotifier.filters,
              isDesktop: true,
              onDeleted: networkNotifier.removeFilter,
            )
          : null,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }
}
