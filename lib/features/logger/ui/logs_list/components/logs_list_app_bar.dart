import 'package:flutter/material.dart';
import 'package:infospect/features/logger/ui/logs_list/notifier/logs_list_notifier.dart';
import 'package:infospect/features/logger/ui/logs_list/models/logs_action.dart';
import 'package:infospect/infospect.dart';
import 'package:infospect/utils/common_widgets/app_adaptive_dialog.dart';
import 'package:infospect/utils/common_widgets/filter_chip_bar.dart';

class LogsListAppBar extends StatefulWidget implements PreferredSizeWidget {
  const LogsListAppBar({
    super.key,
    this.hasBottom = false,
    required this.infospect,
    required this.notifier,
  }) : isDesktop = false;

  const LogsListAppBar.desktop({
    super.key,
    this.hasBottom = false,
    required this.infospect,
    required this.notifier,
  }) : isDesktop = true;

  final bool hasBottom;
  final Infospect infospect;
  final LogsListNotifier notifier;
  final bool isDesktop;

  static const double _mobileToolbarHeight = 40;

  @override
  State<LogsListAppBar> createState() => _LogsListAppBarState();

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

class _LogsListAppBarState extends State<LogsListAppBar> {
  late final TextEditingController _controller = TextEditingController();
  late final FocusNode _focusNode = FocusNode();

  @override
  Widget build(BuildContext context) {
    final logsNotifier = widget.notifier;
    final theme = Theme.of(context);

    if (!widget.isDesktop) {
      return Material(
        color: theme.colorScheme.surface,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: LogsListAppBar._mobileToolbarHeight,
              child: Padding(
                padding: const EdgeInsets.only(left: 10, right: 4),
                child: Row(
                  children: [
                    Expanded(
                      child: AppSearchBar(
                        controller: _controller,
                        focusNode: _focusNode,
                        isDesktop: false,
                        onChanged: logsNotifier.searchText,
                      ),
                    ),
                    AppBarActionWidget(
                      actionModel: LogsAction.filterModel,
                      selectedActions: logsNotifier.filters,
                      tooltip: 'Filter',
                      onItemSelected: logsNotifier.addFilter,
                      selected: logsNotifier.filters.isNotEmpty,
                    ),
                    AppBarActionWidget<LogsActionType>(
                      actionModel: LogsAction.menuModel,
                      tooltip: 'More',
                      onItemSelected: (value) {
                        if (value.id == LogsActionType.share) {
                          logsNotifier.shareAllLogs();
                        } else if (value.id == LogsActionType.clear) {
                          AppAdaptiveDialog.show(
                            context,
                            tag: 'logs',
                            title: 'Clear Logs?',
                            body:
                                'Are you sure you want to clear all logs? This will clear up the list.',
                            onPositiveActionClick: logsNotifier.clearAllLogs,
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
                filters: logsNotifier.filters,
                onDeleted: logsNotifier.removeFilter,
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
        onChanged: logsNotifier.searchText,
      ),
      actions: [
        AppBarActionWidget(
          actionModel: LogsAction.filterModel,
          selectedActions: logsNotifier.filters,
          tooltip: 'Filter',
          onItemSelected: logsNotifier.addFilter,
          selected: logsNotifier.filters.isNotEmpty,
        ),
        AppBarActionWidget<LogsActionType>(
          actionModel: LogsAction.menuModel,
          tooltip: 'More',
          onItemSelected: (value) {
            if (value.id == LogsActionType.share) {
              logsNotifier.shareAllLogs();
            } else if (value.id == LogsActionType.clear) {
              AppAdaptiveDialog.show(
                context,
                tag: 'logs',
                title: 'Clear Logs?',
                body:
                    'Are you sure you want to clear all logs? This will clear up the list.',
                onPositiveActionClick: logsNotifier.clearAllLogs,
              );
            }
          },
        ),
        const SizedBox(width: 4),
      ],
      bottom: widget.hasBottom
          ? FilterChipBar(
              filters: logsNotifier.filters,
              isDesktop: true,
              onDeleted: logsNotifier.removeFilter,
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
