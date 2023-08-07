import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:infospect/features/launch/bloc/launch_bloc.dart';
import 'package:infospect/features/logger/ui/logs_list/bloc/logs_list_bloc.dart';
import 'package:infospect/features/network/ui/list/bloc/networks_list_bloc.dart';
import 'package:infospect/features/search/bloc/search_bloc.dart';

class SearchBarWidget extends StatefulWidget implements PreferredSizeWidget {
  const SearchBarWidget({
    super.key,
  });

  @override
  State<SearchBarWidget> createState() => _SearchBarWidgetState();

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class _SearchBarWidgetState extends State<SearchBarWidget> {
  late final TextEditingController _controller = TextEditingController();
  late final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    _focusNode.addListener(
      () {
        context.read<SearchBloc>().add(
              SearchBarFocusChanged(focued: _focusNode.hasFocus),
            );
      },
    );

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final index = context.watch<LaunchBloc>().state.selectedTab;

    return BlocConsumer<SearchBloc, SearchState>(
      listenWhen: (previous, current) => current.text != previous.text,
      listener: (context, state) {
        _controller.text = state.text;
        _controller.selection = TextSelection.fromPosition(
          TextPosition(offset: state.text.length),
        );
      },
      builder: (context, state) {
        return AppBar(
          elevation: 0,
          backgroundColor: Colors.white,
          iconTheme: const IconThemeData(color: Colors.black),
          title: CupertinoSearchTextField(
            controller: _controller,
            focusNode: _focusNode,
            onChanged: (value) {
              if (index == 0) {
                context.read<NetworksListBloc>().add(
                      NetworkLogsSearched(text: value),
                    );
              } else {
                context.read<LogsListBloc>().add(
                      TextSearched(text: value),
                    );
              }
            },
          ),
          actions: [
            if (state.hasFocus) ...[
              TextButton(
                onPressed: () {
                  _controller.text = '';
                  _focusNode.unfocus();
                  context.read<SearchBloc>().add(
                        const SearchBarFocusChanged(
                          focued: false,
                        ),
                      );
                },
                child: const Text('Cancel'),
              )
            ],
            const AppBarActionWidget(),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();

    super.dispose();
  }
}

class AppBarActionWidget extends StatelessWidget {
  const AppBarActionWidget({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      itemBuilder: (_) {
        return [
          PopupMenuItem<String>(
            child: PopupMenuButton<String>(
              enableFeedback: true,
              itemBuilder: (_) {
                return [
                  PopupMenuItem<String>(
                    child: const Text('GET'),
                    onTap: () {},
                  ),
                  PopupMenuItem<String>(
                    child: const Text('PUT'),
                    onTap: () {},
                  ),
                  const PopupMenuItem<String>(
                    child: Text('POST'),
                    value: 'post',
                  )
                ];
              },
              onSelected: (value) {
                print(value);
              },
              onOpened: () {
                print('opened');
              },
              padding: EdgeInsets.zero,
              child: Row(
                children: [
                  const Icon(Icons.circle, color: Colors.red, size: 10),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      color: Colors.transparent,
                      child: const Text('Method'),
                    ),
                  ),
                ],
              ),
            ),
          )
        ];
      },
      onSelected: (value) {},
      icon: const Icon(Icons.filter_alt_outlined),
    );
  }
}
