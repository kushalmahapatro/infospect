import 'package:flutter/material.dart';
import 'package:infospect/features/logger/models/infospect_log.dart';
import 'package:infospect/utils/common_widgets/live_edge_scroll_view.dart';

typedef LogItemBuilder =
    Widget Function(BuildContext context, int index, InfospectLog log);

/// Scrollable logs list with live-edge follow / scroll preservation.
class LogsScrollableList extends StatelessWidget {
  const LogsScrollableList({
    super.key,
    required this.logs,
    required this.itemBuilder,
    this.searchedText = '',
    this.filterSignature = '',
  });

  final List<InfospectLog> logs;
  final LogItemBuilder itemBuilder;
  final String searchedText;
  final String filterSignature;

  @override
  Widget build(BuildContext context) {
    return LiveEdgeScrollableList(
      itemCount: logs.length,
      newestItemKey: logs.isEmpty ? null : logs.first,
      newItemsLabel: 'New logs',
      edge: LiveListEdge.top,
      querySignature: '$searchedText|$filterSignature',
      itemBuilder: (context, index) {
        return itemBuilder(context, index, logs[index]);
      },
    );
  }
}
