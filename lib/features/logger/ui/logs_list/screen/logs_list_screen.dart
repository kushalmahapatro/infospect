import 'package:flutter/material.dart';
import 'package:infospect/features/logger/ui/logs_list/notifier/logs_list_notifier.dart';
import 'package:infospect/features/logger/ui/logs_list/components/log_item_widget.dart';
import 'package:infospect/features/logger/ui/logs_list/components/logs_list_app_bar.dart';
import 'package:infospect/helpers/infospect_helper.dart';
import 'package:share_plus/share_plus.dart';

class LogsListScreen extends StatefulWidget {
  final Infospect infospect;
  final LogsListNotifier notifier;

  const LogsListScreen(
    this.infospect, {
    required this.notifier,
    super.key,
  });

  @override
  State<LogsListScreen> createState() => _LogsListScreenState();
}

class _LogsListScreenState extends State<LogsListScreen> {
  @override
  void initState() {
    super.initState();
    widget.notifier.addListener(_onNotifierChanged);
  }

  void _onNotifierChanged() {
    setState(() {});
  }

  @override
  void dispose() {
    widget.notifier.removeListener(_onNotifierChanged);
    // Don't dispose notifier here - it's managed by navigation_helper
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Handle share file
    if (widget.notifier.sharableFile != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (Infospect.instance.onShareAllLogs != null) {
          Infospect
              .instance.onShareAllLogs!(widget.notifier.sharableFile!.path);
        } else {
          final XFile file = XFile(widget.notifier.sharableFile!.path);
          SharePlus.instance.share(ShareParams(files: [file]));
        }
      });
    }

    return Scaffold(
      appBar: LogsListAppBar(
        hasBottom: widget.notifier.filters.isNotEmpty,
        infospect: widget.infospect,
        notifier: widget.notifier,
      ),
      body: ListView.builder(
        itemCount: widget.notifier.filteredLogs.length,
        itemBuilder: (context, index) {
          return LogItemWidget(
            log: widget.notifier.filteredLogs[index],
            searchedText: widget.notifier.searchedText,
          );
        },
      ),
    );
  }
}
