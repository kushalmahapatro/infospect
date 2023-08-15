import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:infospect/features/network/ui/list/bloc/networks_list_bloc.dart';
import 'package:infospect/features/network/ui/list/models/network_action.dart';
import 'package:infospect/infospect.dart';
import 'package:infospect/utils/models/action_model.dart';

class NetworkCallAppBar extends StatefulWidget implements PreferredSizeWidget {
  const NetworkCallAppBar(
      {super.key, this.hasBottom = false, required this.infospect})
      : isDesktop = false;

  const NetworkCallAppBar.desktop(
      {super.key, this.hasBottom = false, required this.infospect})
      : isDesktop = true;

  final bool hasBottom;
  final Infospect infospect;
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
    final networkListBloc = context.read<NetworksListBloc>();

    return AppBar(
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
        onChanged: (value) => networkListBloc.add(
          NetworkLogsSearched(text: value),
        ),
      ),
      actions: [
        AppBarActionWidget(
          actionModel: NetworkAction.filterModel,
          selectedActions: networkListBloc.state.filters,
          onItemSelected: (value) {
            networkListBloc.add(NetowrkLogsFilterAdded(action: value));
          },
          selected: networkListBloc.state.filters.isNotEmpty,
        ),
        AppBarActionWidget(
          actionModel: NetworkAction.menuModel,
          onItemSelected: (value) {},
        ),
      ],
      bottom: widget.hasBottom ? _BottomWidget(widget.isDesktop) : null,
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
  const _BottomWidget(this.isDesktop);

  final bool isDesktop;

  @override
  Size get preferredSize => const Size.fromHeight(30);

  @override
  Widget build(BuildContext context) {
    return BlocSelector<NetworksListBloc, NetworksListState, List<PopupAction>>(
      selector: (state) {
        return state.filters;
      },
      builder: (context, filters) {
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
                        ifTrue: Transform(
                          transform: Matrix4.identity()..scale(0.8),
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
          context.read<NetworksListBloc>().add(
                NetowrkLogsFilterRemoved(action: e),
              );
        },
      ),
    );
  }
}
