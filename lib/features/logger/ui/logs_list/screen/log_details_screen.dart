import 'package:flutter/material.dart';
import 'package:infospect/features/logger/models/infospect_log.dart';
import 'package:infospect/features/logger/ui/logs_list/components/log_details_pane.dart';

class LogDetailsScreen extends StatelessWidget {
  const LogDetailsScreen({
    super.key,
    required this.log,
    this.searchedText = '',
  });

  final InfospectLog log;
  final String searchedText;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Log details')),
      body: LogDetailsContent(log: log, searchedText: searchedText),
    );
  }
}
