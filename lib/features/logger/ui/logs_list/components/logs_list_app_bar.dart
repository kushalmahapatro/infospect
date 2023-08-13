import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:infospect/features/logger/ui/logs_list/bloc/logs_list_bloc.dart';
import 'package:infospect/features/logger/ui/logs_list/models/logs_action.dart';
import 'package:infospect/infospect.dart';
import 'package:infospect/utils/models/action_model.dart';

class LogsListAppBar extends StatefulWidget implements PreferredSizeWidget {
  const LogsListAppBar(
      {super.key, this.hasBottom = false, required this.infospect})
      : isDesktop = false;

  const LogsListAppBar.desktop(
      {super.key, this.hasBottom = false, required this.infospect})
      : isDesktop = true;

  final bool hasBottom;
  final Infospect infospect;
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
    final logsBloc = context.read<LogsListBloc>();

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
        onChanged: (value) => logsBloc.add(
          TextSearched(text: value),
        ),
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
                    (e) => Transform(
                      transform: Matrix4.identity()..scale(isDesktop ? 0.8 : 1),
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: isDesktop ? 0 : 8,
                        ),
                        child: Padding(
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
