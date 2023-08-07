import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:infospect/features/logger/ui/logs_list/bloc/logs_list_bloc.dart';
import 'package:infospect/features/logger/ui/logs_list/components/log_item_widget.dart';
import 'package:infospect/helpers/infospect_helper.dart';

class LogsListScreen extends StatelessWidget {
  const LogsListScreen(this.infospect, {super.key});

  final Infospect infospect;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LogsListBloc, LogsListState>(
      builder: (context, state) {
        return ListView.builder(
          itemCount: state.filteredLogs.length,
          itemBuilder: (context, index) {
            return LogItemWidget(
              log: state.filteredLogs[index],
              searchedText: state.searchedText,
            );
          },
        );
      },
    );
  }
}