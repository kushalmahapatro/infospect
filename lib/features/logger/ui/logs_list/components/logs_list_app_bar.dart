import 'package:flutter/material.dart';
import 'package:infospect/features/logger/ui/logs_list/notifier/logs_list_notifier.dart';
import 'package:infospect/features/logger/ui/logs_list/models/logs_action.dart';
import 'package:infospect/infospect.dart';
import 'package:infospect/utils/common_widgets/app_adaptive_dialog.dart';
import 'package:infospect/utils/models/action_model.dart';

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

  @override
  State<LogsListAppBar> createState() => _LogsListAppBarState();

  @override
  Size get preferredSize => hasBottom
      ? Size.fromHeight(isDesktop ? 74 : kToolbarHeight + 40)
      : Size.fromHeight(isDesktop ? 40 : kToolbarHeight);
}

class _LogsListAppBarState extends State<LogsListAppBar> {
  late final TextEditingController _controller = TextEditingController();
  late final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final logsNotifier = widget.notifier;

    return AppBar(
      automaticallyImplyLeading: false,
      elevation: 0,
      leading: widget.isDesktop
          ? null
          : BackButton(
              onPressed: () => Navigator.of(widget.infospect.context!).pop(),
            ),
      title: AppSearchBar(
        controller: _controller,
        focusNode: _focusNode,
        isDesktop: widget.isDesktop,
        onChanged: (value) => logsNotifier.searchText(value),
      ),
      actions: [
        AppBarActionWidget(
          actionModel: LogsAction.filterModel,
          selectedActions: logsNotifier.filters,
          onItemSelected: (value) {
            logsNotifier.addFilter(value);
          },
          selected: logsNotifier.filters.isNotEmpty,
        ),
        AppBarActionWidget<LogsActionType>(
          actionModel: LogsAction.menuModel,
          onItemSelected: (value) {
            if (value.id == LogsActionType.share) {
              logsNotifier.shareAllLogs();
            } else if (value.id == LogsActionType.clear) {
              AppAdaptiveDialog.show(
                context,
                tag: 'logs',
                title: 'Clear Network Logs?',
                body:
                    'Are you sure you want to clear all logs? This will clear up the list.',
                onPositiveActionClick: () {
                  logsNotifier.clearAllLogs();
                },
              );
            }
          },
        ),
      ],
      bottom: widget.hasBottom
          ? _BottomWidget(widget.isDesktop, widget.notifier)
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

class _BottomWidget extends StatelessWidget implements PreferredSizeWidget {
  const _BottomWidget(this.isDesktop, this.notifier);

  final bool isDesktop;
  final LogsListNotifier notifier;

  @override
  Size get preferredSize => const Size.fromHeight(30);

  @override
  Widget build(BuildContext context) {
    final filters = notifier.filters;
    return LayoutBuilder(
      builder: (context, constraints) {
        return SizedBox(
          width: constraints.maxWidth - 10,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: filters.map(
                (e) {
                  return ConditionalWidget(
                    condition: isDesktop,
                    ifTrue: Transform.scale(
                      scale: 0.8,
                      child: chipWidget(e, context),
                    ),
                    ifFalse: chipWidget(e, context),
                  );
                },
              ).toList(),
            ),
          ),
        );
      },
    );
  }

  Padding chipWidget(PopupAction<dynamic> e, BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: isDesktop ? 0 : 8),
      child: Chip(
        label: Text(e.name),
        deleteIcon: Container(
          height: 14,
          width: 14,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary,
            border: Border.all(color: Colors.black),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.close_rounded, size: 12),
        ),
        labelPadding: const EdgeInsetsDirectional.only(
          start: 4,
        ),
        onDeleted: () {
          notifier.removeFilter(e);
        },
      ),
    );
  }
}
