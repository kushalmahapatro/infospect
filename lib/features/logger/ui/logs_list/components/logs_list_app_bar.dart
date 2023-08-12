import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:infospect/features/logger/ui/logs_list/bloc/logs_list_bloc.dart';
import 'package:infospect/features/logger/ui/logs_list/models/logs_action.dart';
import 'package:infospect/helpers/infospect_helper.dart';
import 'package:infospect/utils/common_widgets/action_widget.dart';
import 'package:infospect/utils/models/action_model.dart';

class LogsListAppBar extends StatefulWidget implements PreferredSizeWidget {
  const LogsListAppBar(
      {super.key, this.hasBottom = false, required this.infospect});

  final bool hasBottom;
  final Infospect infospect;

  @override
  State<LogsListAppBar> createState() => _LogsListAppBarState();

  @override
  Size get preferredSize => hasBottom
      ? const Size.fromHeight(kToolbarHeight + 40)
      : const Size.fromHeight(kTextTabBarHeight);
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
    final logsBloc = context.read<LogsListBloc>();

    return AppBar(
      elevation: 0,
      leading: BackButton(
        onPressed: () => Navigator.of(widget.infospect.context!).pop(),
      ),
      title: CupertinoSearchTextField(
        controller: _controller,
        focusNode: _focusNode,
        onChanged: (value) {
          logsBloc.add(TextSearched(text: value));
        },
      ),
      actions: [
        AppBarActionWidget(
          actionModel: LogsAction.filterModel,
          selectedActions: logsBloc.state.filters,
          onItemSelected: (value) {
            logsBloc.add(LogsFilterAdded(action: value));
          },
          selected: logsBloc.state.filters.isNotEmpty,
        ),
        AppBarActionWidget(
          actionModel: LogsAction.menuModel,
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
    return BlocSelector<LogsListBloc, LogsListState, List<PopupAction>>(
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
                          context.read<LogsListBloc>().add(
                                LogsFilterRemoved(action: e),
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
