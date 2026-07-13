import 'package:flutter/material.dart';
import 'package:infospect/features/logger/models/infospect_log.dart';
import 'package:infospect/features/logger/ui/logs_list/components/log_item_widget.dart';
import 'package:infospect/features/logger/ui/logs_list/components/logs_empty_state.dart';
import 'package:infospect/features/logger/ui/logs_list/components/logs_list_app_bar.dart';
import 'package:infospect/features/logger/ui/logs_list/components/logs_scrollable_list.dart';
import 'package:infospect/features/logger/ui/logs_list/notifier/logs_list_notifier.dart';
import 'package:infospect/helpers/infospect_helper.dart';
import 'package:infospect/utils/infospect_share.dart';
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
  InfospectLog? _selectedLog;

  @override
  void initState() {
    super.initState();
    widget.notifier.addListener(_onNotifierChanged);
    widget.notifier.onShareAllLogs = (sharableFile) {
      if (Infospect.instance.onShareAllLogs != null) {
        Infospect.instance.onShareAllLogs!(sharableFile.path);
      } else {
        final XFile file = XFile(sharableFile.path);
        InfospectShare.shareFiles([file], context: mounted ? context : null);
      }
    };
  }

  void _onNotifierChanged() {
    final logs = widget.notifier.filteredLogs;
    if (_selectedLog != null && !logs.contains(_selectedLog)) {
      _selectedLog = null;
    }
    setState(() {});
  }

  @override
  void didUpdateWidget(covariant DesktopLogsListScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.notifier != widget.notifier) {
      oldWidget.notifier.removeListener(_onNotifierChanged);
      widget.notifier.addListener(_onNotifierChanged);
    }
  }

  @override
  void dispose() {
    widget.notifier.removeListener(_onNotifierChanged);
    super.dispose();
  }

  String get _filterSignature =>
      widget.notifier.filters.map((e) => e.name).join('|');

  @override
  Widget build(BuildContext context) {
    final logs = widget.notifier.filteredLogs;
    final hasActiveQuery =
        widget.notifier.searchedText.isNotEmpty ||
        widget.notifier.filters.isNotEmpty;

    return Scaffold(
      appBar: LogsListAppBar.desktop(
        hasBottom: widget.notifier.filters.isNotEmpty,
        infospect: widget.infospect,
        notifier: widget.notifier,
      ),
      body: logs.isEmpty
          ? LogsEmptyState(hasActiveQuery: hasActiveQuery)
          : LogsScrollableList(
              logs: logs,
              searchedText: widget.notifier.searchedText,
              filterSignature: _filterSignature,
              itemBuilder: (context, index, log) {
                return LogItemWidget(
                  key: ValueKey(log),
                  log: log,
                  searchedText: widget.notifier.searchedText,
                  selected: _selectedLog == log,
                  onTap: () {
                    setState(() {
                      _selectedLog = log;
                    });
                  },
                );
              },
            ),
    );
  }
}
