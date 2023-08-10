import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:infospect/features/network/ui/list/bloc/networks_list_bloc.dart';
import 'package:infospect/features/network/ui/list/models/network_action.dart';
import 'package:infospect/utils/common_widgets/action_widget.dart';
import 'package:infospect/utils/models/action_model.dart';

class NetworkCallAppBar extends StatefulWidget implements PreferredSizeWidget {
  const NetworkCallAppBar({super.key, this.hasBottom = false});

  final bool hasBottom;

  @override
  State<NetworkCallAppBar> createState() => _NetworkCallAppBarState();

  @override
  Size get preferredSize => hasBottom
      ? const Size.fromHeight(kToolbarHeight + 40)
      : const Size.fromHeight(kTextTabBarHeight);
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
      backgroundColor: Colors.white,
      iconTheme: const IconThemeData(color: Colors.black),
      title: CupertinoSearchTextField(
        controller: _controller,
        focusNode: _focusNode,
        onChanged: (value) {
          networkListBloc.add(NetworkLogsSearched(text: value));
        },
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
      bottom: widget.hasBottom ? const _BottomWidget() : null,
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
  const _BottomWidget();

  @override
  Size get preferredSize => const Size.fromHeight(30);

  @override
  Widget build(BuildContext context) {
    return BlocSelector<NetworksListBloc, NetworksListState, List<PopupAction>>(
      selector: (state) {
        return state.filters;
      },
      builder: (context, filters) {
        return SizedBox(
          width: MediaQuery.sizeOf(context).width - 10,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: filters
                  .map(
                    (e) => Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Chip(
                        label: Text(e.name),
                        deleteIcon: Container(
                          height: 14,
                          width: 14,
                          decoration: BoxDecoration(
                              color: Colors.black,
                              border: Border.all(color: Colors.black),
                              shape: BoxShape.circle),
                          child: const Icon(
                            Icons.close_rounded,
                            size: 12,
                            color: Colors.white,
                          ),
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
                    ),
                  )
                  .toList(),
            ),
          ),
        );
      },
    );
  }
}
