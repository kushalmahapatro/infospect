import 'package:flutter/material.dart';
import 'package:infospect/features/logger/ui/logs_list/notifier/logs_list_notifier.dart';
import 'package:infospect/features/logger/ui/logs_list/components/log_item_widget.dart';
import 'package:infospect/features/logger/ui/logs_list/components/logs_list_app_bar.dart';
import 'package:infospect/helpers/infospect_helper.dart';
import 'package:share_plus/share_plus.dart';

class DesktopLogsListScreen extends StatefulWidget {
  final Infospect infospect;
  final LogsListNotifier notifier;

  const DesktopLogsListScreen(
    this.infospect, {
    required this.notifier,
    super.key,
  });

  @override
  State<DesktopLogsListScreen> createState() => _DesktopLogsListScreenState();
}

class _DesktopLogsListScreenState extends State<DesktopLogsListScreen> {
  @override
  void initState() {
    super.initState();
    widget.notifier.addListener(_onNotifierChanged);
    widget.notifier.onShareAllLogs = (sharableFile) {
      if (Infospect.instance.onShareAllLogs != null) {
        Infospect.instance.onShareAllLogs!(sharableFile.path);
      } else {
        final XFile file = XFile(sharableFile.path);
        SharePlus.instance.share(ShareParams(files: [file]));
      }
    };
  }

  void _onNotifierChanged() {
    setState(() {});
  }

  @override
  void dispose() {
    widget.notifier.removeListener(_onNotifierChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: LogsListAppBar.desktop(
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
