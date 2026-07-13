import 'package:flutter/material.dart';
import 'package:infospect/features/logger/ui/logs_list/components/log_item_widget.dart';
import 'package:infospect/features/logger/ui/logs_list/components/logs_empty_state.dart';
import 'package:infospect/features/logger/ui/logs_list/components/logs_list_app_bar.dart';
import 'package:infospect/features/logger/ui/logs_list/components/logs_scrollable_list.dart';
import 'package:infospect/features/logger/ui/logs_list/notifier/logs_list_notifier.dart';
import 'package:infospect/features/logger/ui/logs_list/screen/log_details_screen.dart';
import 'package:infospect/helpers/infospect_helper.dart';
import 'package:infospect/utils/infospect_share.dart';
import 'package:share_plus/share_plus.dart';

class LogsListScreen extends StatefulWidget {
  final Infospect infospect;
  final LogsListNotifier notifier;

  const LogsListScreen(this.infospect, {required this.notifier, super.key});

  @override
  State<LogsListScreen> createState() => _LogsListScreenState();
}

class _LogsListScreenState extends State<LogsListScreen> {
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
    setState(() {});
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
      appBar: LogsListAppBar(
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
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => LogDetailsScreen(
                          log: log,
                          searchedText: widget.notifier.searchedText,
                        ),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}
