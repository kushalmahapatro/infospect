import 'package:flutter/material.dart';
import 'package:infospect/features/logger/models/infospect_log.dart';
import 'package:infospect/features/logger/ui/logs_list/components/log_details_pane.dart';
import 'package:infospect/utils/common_widgets/infospect_mobile_chrome.dart';

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
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: const InfospectMobileToolbar(
        title: Text('Log details'),
      ),
      body: LogDetailsContent(log: log, searchedText: searchedText),
    );
  }
}
