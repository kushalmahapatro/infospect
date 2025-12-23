import 'package:flutter/material.dart';
import 'package:infospect/features/network/ui/list/models/network_action.dart';
import 'package:infospect/features/network/ui/list/notifier/networks_list_notifier.dart';
import 'package:infospect/infospect.dart';
import 'package:infospect/utils/common_widgets/app_adaptive_dialog.dart';
import 'package:infospect/utils/models/action_model.dart';

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

  @override
  State<NetworkCallAppBar> createState() => _NetworkCallAppBarState();

  @override
  Size get preferredSize => hasBottom
      ? Size.fromHeight(isDesktop ? 74 : kToolbarHeight + 40)
      : Size.fromHeight(isDesktop ? 40 : kToolbarHeight);
}

class _NetworkCallAppBarState extends State<NetworkCallAppBar> {
  late final TextEditingController _controller = TextEditingController();
  late final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final networkNotifier = widget.notifier;

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
        onChanged: (value) => networkNotifier.searchNetworkLogs(value),
      ),
      actions: [
        AppBarActionWidget(
          actionModel: NetworkAction.filterModel,
          selectedActions: networkNotifier.filters,
          onItemSelected: (value) {
            networkNotifier.addFilter(value);
          },
          selected: networkNotifier.filters.isNotEmpty,
        ),
        AppBarActionWidget<NetworkActionType>(
          actionModel: NetworkAction.menuModel,
          onItemSelected: (value) {
            if (value.id == NetworkActionType.share) {
              networkNotifier.shareNetworkLogs();
            } else if (value.id == NetworkActionType.clear) {
              AppAdaptiveDialog.show(
                context,
                tag: 'network_calls',
                title: 'Clear Network Call Logs?',
                body:
                    'Are you sure you want to clear all network call logs? This will clear up the list.',
                onPositiveActionClick: () {
                  networkNotifier.clearNetworkLogs();
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
  final NetworksListNotifier notifier;

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
            border: Border.all(),
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
