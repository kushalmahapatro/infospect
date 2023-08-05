import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:infospect/features/logger/models/infospect_log.dart';
import 'package:infospect/features/logger/ui/logs_list/bloc/logs_list_bloc.dart';
import 'package:infospect/helpers/infospect_helper.dart';

class LogsListScreen extends StatelessWidget {
  const LogsListScreen(this.infospect, {super.key});

  final Infospect infospect;

  @override
  Widget build(BuildContext context) {
    return BlocSelector<LogsListBloc, LogsListState, List<InfospectLog>>(
      selector: (state) => state.logs,
      builder: (context, state) {
        return ListView.builder(
          itemCount: state.length,
          itemBuilder: (context, index) {
            return ListTile(
              title: Text(state[index].message),
              subtitle: Text(state[index].error),
            );
          },
        );
      },
    );
  }
}
