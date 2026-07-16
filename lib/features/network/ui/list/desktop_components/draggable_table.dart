import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:infospect/features/network/models/infospect_network_call.dart';
import 'package:infospect/features/network/ui/details/screen/network_body_window_screen.dart';
import 'package:infospect/features/network/ui/list/components/infospect_endpoint_label.dart';
import 'package:infospect/features/network/ui/list/desktop_components/desktop_call_list_states.dart';
import 'package:infospect/features/network/ui/list/desktop_components/draggable_cell.dart';
import 'package:infospect/features/network/ui/list/desktop_components/state_helpers.dart';
import 'package:infospect/features/network/ui/list/notifier/networks_list_notifier.dart';
import 'package:infospect/helpers/infospect_helper.dart';
import 'package:infospect/utils/common_widgets/infospect_toast.dart';
import 'package:infospect/utils/common_widgets/live_edge_scroll_view.dart';
import 'package:infospect/utils/extensions/date_time_extension.dart';
import 'package:infospect/utils/extensions/infospect_network/network_request_extension.dart';
import 'package:infospect/utils/extensions/infospect_network/network_response_extension.dart';
import 'package:infospect/utils/extensions/int_extension.dart';
import 'package:infospect/utils/infospect_util.dart';

class DraggableTable extends StatefulWidget {
  const DraggableTable({
    super.key,
    required this.infospect,
    required this.onCallSelected,
    this.selectedCall,
    required this.constraints,
    required this.notifier,
  });

  final Infospect infospect;
  final ValueChanged<InfospectNetworkCall> onCallSelected;
  final InfospectNetworkCall? selectedCall;
  final BoxConstraints constraints;
  final NetworksListNotifier notifier;

  @override
  State<DraggableTable> createState() => _DraggableTableState();
}

class _DraggableTableState extends DesktopCallListStates<DraggableTable> {
  static const double _rowHeight = 28;
  static const double _headerHeight = 30;

  final verticalScrollController = ScrollController();
  final headerHorizontalController = ScrollController();
  final bodyHorizontalController = ScrollController();
  bool _syncingHorizontal = false;

  @override
  void initState() {
    super.initState();
    headerHorizontalController.addListener(_onHeaderHorizontalScroll);
    bodyHorizontalController.addListener(_onBodyHorizontalScroll);
  }

  @override
  void dispose() {
    headerHorizontalController.removeListener(_onHeaderHorizontalScroll);
    bodyHorizontalController.removeListener(_onBodyHorizontalScroll);
    verticalScrollController.dispose();
    headerHorizontalController.dispose();
    bodyHorizontalController.dispose();
    super.dispose();
  }

  void _onHeaderHorizontalScroll() {
    _syncHorizontal(
      source: headerHorizontalController,
      target: bodyHorizontalController,
    );
  }

  void _onBodyHorizontalScroll() {
    _syncHorizontal(
      source: bodyHorizontalController,
      target: headerHorizontalController,
    );
  }

  void _syncHorizontal({
    required ScrollController source,
    required ScrollController target,
  }) {
    if (_syncingHorizontal || !source.hasClients || !target.hasClients) return;
    if (source.offset == target.offset) return;
    _syncingHorizontal = true;
    target.jumpTo(
      source.offset.clamp(
        target.position.minScrollExtent,
        target.position.maxScrollExtent,
      ),
    );
    _syncingHorizontal = false;
  }

  @override
  Widget build(BuildContext context) {
    scheduleWidthCheck();

    final theme = Theme.of(context);
    final borderColor = theme.colorScheme.outlineVariant.withValues(
      alpha: 0.55,
    );
    final calls = widget.notifier.filteredCalls;
    final tableWidth = dataCellStates.totalWidth;
    final ascending = widget.notifier.isTimeSortAscending;
    final liveEdge = ascending ? LiveListEdge.bottom : LiveListEdge.top;
    final newestItemKey = calls.isEmpty
        ? null
        : (ascending ? calls.last.id : calls.first.id);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest.withValues(
              alpha: 0.32,
            ),
            border: Border(bottom: BorderSide(color: borderColor)),
          ),
          child: SizedBox(
            height: _headerHeight,
            child: SingleChildScrollView(
              controller: headerHorizontalController,
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: tableWidth,
                child: Row(
                  children: dataCellStates.mapIndexed((index, element) {
                    final isTimeColumn = element.id == CellType.columnTime.id;
                    return DraggableCell(
                      text: element.label,
                      minWidth: element.minWidth,
                      maxWidth: element.maxWidth,
                      width: element.width,
                      onColumnWidthChanged: (width) =>
                          updateDataCellStates(id: index, width: width),
                      onHeaderTap: isTimeColumn
                          ? widget.notifier.toggleTimeSort
                          : null,
                      timeSort:
                          isTimeColumn ? widget.notifier.timeSort : null,
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
        ),
        Expanded(
          child: calls.isEmpty
              ? _EmptyState()
              : LiveEdgeScrollAddon(
                  controller: verticalScrollController,
                  itemCount: calls.length,
                  newestItemKey: newestItemKey,
                  newItemsLabel: 'New calls',
                  edge: liveEdge,
                  querySignature:
                      '${widget.notifier.searchedText}|${widget.notifier.filters.map((e) => e.name).join('|')}|${widget.notifier.timeSort.name}',
                  child: Scrollbar(
                    thumbVisibility: true,
                    controller: verticalScrollController,
                    child: SingleChildScrollView(
                      controller: verticalScrollController,
                      child: Scrollbar(
                        thumbVisibility: true,
                        controller: bodyHorizontalController,
                        notificationPredicate: (notify) => notify.depth == 1,
                        child: SingleChildScrollView(
                          controller: bodyHorizontalController,
                          scrollDirection: Axis.horizontal,
                          child: SizedBox(
                            width: tableWidth,
                            child: Column(
                              children: [
                                for (
                                  var index = 0;
                                  index < calls.length;
                                  index++
                                )
                                  _CallRow(
                                    call: calls[index],
                                    index: index + 1,
                                    heights: _rowHeight,
                                    widths: dataCellStates,
                                    selected:
                                        widget.selectedCall?.id ==
                                        calls[index].id,
                                    zebra: calls[index].id.isOdd,
                                    searchedText: widget.notifier.searchedText,
                                    onSelected: () {
                                      if (calls[index].loading) return;
                                      widget.onCallSelected(calls[index]);
                                    },
                                    onContextMenu: (position) =>
                                        _showCallContextMenu(
                                          context,
                                          position,
                                          calls[index],
                                        ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
        ),
      ],
    );
  }

  Future<void> _showCallContextMenu(
    BuildContext context,
    Offset globalPosition,
    InfospectNetworkCall call,
  ) async {
    if (!InfospectUtil.isDesktop) return;

    final selected = await showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
        globalPosition.dx,
        globalPosition.dy,
        globalPosition.dx,
        globalPosition.dy,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(6),
        side: BorderSide(
          color: Theme.of(
            context,
          ).colorScheme.outlineVariant.withValues(alpha: 0.55),
        ),
      ),
      items: [
        const PopupMenuItem(
          value: 'breakpoint',
          height: 32,
          child: Text('Add breakpoint', style: TextStyle(fontSize: 12)),
        ),
        if (!call.loading) ...[
          const PopupMenuItem(
            value: 'open',
            height: 32,
            child: Text('Open in new window', style: TextStyle(fontSize: 12)),
          ),
          const PopupMenuItem(
            value: 'open_request',
            height: 32,
            child: Text('Open request body', style: TextStyle(fontSize: 12)),
          ),
          const PopupMenuItem(
            value: 'open_response',
            height: 32,
            child: Text('Open response body', style: TextStyle(fontSize: 12)),
          ),
        ],
      ],
    );

    if (selected == null) return;

    if (selected == 'breakpoint') {
      Infospect.instance.addEndpointBreakpoint(
        endpoint: call.endpoint,
        method: call.method,
      );
      if (context.mounted) {
        InfospectToast.show(
          context,
          'Breakpoint added for ${call.method} ${call.endpoint}',
          icon: Icons.crisis_alert_outlined,
        );
      }
      return;
    }

    if (call.loading) return;

    final kind = switch (selected) {
      'open_request' => NetworkBodyKind.request,
      'open_response' => NetworkBodyKind.response,
      _ => _preferredBodyKind(call),
    };

    await Infospect.instance.openNetworkBodyInNewWindow(
      call: call,
      kind: kind,
      detailsInitiallyExpanded: true,
    );
  }

  NetworkBodyKind _preferredBodyKind(InfospectNetworkCall call) {
    if ((call.response?.bodyMap ?? {}).isNotEmpty) {
      return NetworkBodyKind.response;
    }
    if ((call.request?.bodyMap ?? {}).isNotEmpty) {
      return NetworkBodyKind.request;
    }
    return NetworkBodyKind.response;
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Text(
        'No network calls',
        style: theme.textTheme.bodySmall?.copyWith(
          fontSize: 12,
          color: theme.colorScheme.onSurface.withValues(alpha: 0.45),
        ),
      ),
    );
  }
}

class _CallRow extends StatefulWidget {
  const _CallRow({
    required this.call,
    required this.index,
    required this.heights,
    required this.widths,
    required this.selected,
    required this.zebra,
    required this.searchedText,
    required this.onSelected,
    required this.onContextMenu,
  });

  final InfospectNetworkCall call;
  final int index;
  final double heights;
  final List<DataCellState> widths;
  final bool selected;
  final bool zebra;
  final String searchedText;
  final VoidCallback onSelected;
  final ValueChanged<Offset> onContextMenu;

  @override
  State<_CallRow> createState() => _CallRowState();
}

class _CallRowState extends State<_CallRow> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final borderColor = theme.colorScheme.outlineVariant.withValues(
      alpha: 0.35,
    );

    Color background;
    if (widget.selected) {
      background = theme.colorScheme.primary.withValues(alpha: 0.14);
    } else if (_hovering) {
      background = theme.colorScheme.onSurface.withValues(alpha: 0.06);
    } else if (widget.zebra) {
      background = theme.colorScheme.surfaceContainerHighest.withValues(
        alpha: 0.18,
      );
    } else {
      background = Colors.transparent;
    }

    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      cursor: widget.call.loading
          ? SystemMouseCursors.basic
          : SystemMouseCursors.click,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onSelected,
        onSecondaryTapDown: (details) {
          widget.onContextMenu(details.globalPosition);
        },
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: background,
            border: Border(bottom: BorderSide(color: borderColor, width: 1)),
          ),
          child: SizedBox(
            height: widget.heights,
            child: Row(
              children: [
                _Cell(
                  width: widget.widths.width(CellType.columnState),
                  child: _StatusDot(call: widget.call),
                ),
                _Cell(
                  width: widget.widths.width(CellType.columnId),
                  child: _PlainText(text: '${widget.index}', muted: true),
                ),
                _Cell(
                  width: widget.widths.width(CellType.columnUrl),
                  child: InfospectEndpointLabel(
                    text: widget.call.uri,
                    highlight: widget.searchedText,
                    mode: InfospectEndpointOverflowMode.scroll,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontSize: 11,
                      fontFamily: 'monospace',
                      height: 1.2,
                    ),
                  ),
                ),
                _Cell(
                  width: widget.widths.width(CellType.columnClient),
                  child: _PlainText(text: widget.call.client),
                ),
                _Cell(
                  width: widget.widths.width(CellType.columnMethod),
                  child: Row(
                    children: [
                      Flexible(
                        child: _MethodPill(method: widget.call.method),
                      ),
                      if (widget.call.hasBreakpointTrace) ...[
                        const SizedBox(width: 4),
                        Icon(
                          Icons.crisis_alert_outlined,
                          size: 11,
                          color: theme.colorScheme.tertiary,
                        ),
                      ],
                    ],
                  ),
                ),
                _Cell(
                  width: widget.widths.width(CellType.columnStatus),
                  child: _PlainText(
                    text: _shortStatus(widget.call),
                  ),
                ),
                _Cell(
                  width: widget.widths.width(CellType.columnCode),
                  child: _StatusCode(call: widget.call),
                ),
                _Cell(
                  width: widget.widths.width(CellType.columnTime),
                  child: _PlainText(
                    text: widget.call.createdTime.formatTime,
                    monospace: true,
                  ),
                ),
                _Cell(
                  width: widget.widths.width(CellType.columnDuration),
                  child: _PlainText(
                    text: widget.call.duration.toReadableTime,
                    monospace: true,
                  ),
                ),
                _Cell(
                  width: widget.widths.width(CellType.columnSecure),
                  child: _SecureIcon(secure: widget.call.secure),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _shortStatus(InfospectNetworkCall call) {
    final bp = call.requestEditedAtBreakpoint || call.responseEditedAtBreakpoint
        ? ' · BP✎'
        : (call.hasBreakpointTrace ? ' · BP' : '');
    if (call.loading) return 'Active$bp';
    final status = call.response?.status ?? -1;
    if (status >= 200 && status < 300) return 'OK$bp';
    if (status >= 300 && status < 400) return 'Redirect$bp';
    return 'Error$bp';
  }
}

class _Cell extends StatelessWidget {
  const _Cell({required this.width, required this.child});

  final double width;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Padding(
        padding: const EdgeInsetsDirectional.only(start: 8, end: 4),
        child: Align(alignment: AlignmentDirectional.centerStart, child: child),
      ),
    );
  }
}

class _PlainText extends StatelessWidget {
  const _PlainText({
    required this.text,
    this.muted = false,
    this.monospace = false,
  });

  final String text;
  final bool muted;
  final bool monospace;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      text,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: theme.textTheme.bodySmall?.copyWith(
        fontSize: 11,
        fontFamily: monospace ? 'monospace' : null,
        height: 1.2,
        color: muted
            ? theme.colorScheme.onSurface.withValues(alpha: 0.55)
            : theme.colorScheme.onSurface.withValues(alpha: 0.86),
      ),
    );
  }
}

class _StatusDot extends StatelessWidget {
  const _StatusDot({required this.call});

  final InfospectNetworkCall call;

  @override
  Widget build(BuildContext context) {
    if (call.loading) {
      return SizedBox(
        width: 12,
        height: 12,
        child: CircularProgressIndicator(
          strokeWidth: 1.5,
          color: Theme.of(context).colorScheme.primary,
        ),
      );
    }

    return Container(
      width: 7,
      height: 7,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color:
            call.response?.getStatusTextColor(context) ??
            Theme.of(context).colorScheme.outline,
      ),
    );
  }
}

class _MethodPill extends StatelessWidget {
  const _MethodPill({required this.method});

  final String method;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        color: theme.colorScheme.primary.withValues(alpha: 0.18),
      ),
      child: Text(
        method,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.2,
          color: theme.colorScheme.primary,
        ),
      ),
    );
  }
}

class _StatusCode extends StatelessWidget {
  const _StatusCode({required this.call});

  final InfospectNetworkCall call;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final status = call.response?.status;
    if (call.loading || status == null || status == -1) {
      return Text(
        call.loading ? '…' : '',
        style: theme.textTheme.bodySmall?.copyWith(
          fontSize: 11,
          fontFamily: 'monospace',
          color: theme.colorScheme.onSurface.withValues(alpha: 0.45),
        ),
      );
    }

    final color = call.response?.getStatusTextColor(context);
    return Text(
      '$status',
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: theme.textTheme.bodySmall?.copyWith(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        fontFamily: 'monospace',
        color: color,
      ),
    );
  }
}

class _SecureIcon extends StatelessWidget {
  const _SecureIcon({required this.secure});

  final bool secure;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Tooltip(
      message: secure ? 'HTTPS' : 'HTTP',
      waitDuration: const Duration(milliseconds: 400),
      child: Icon(
        secure ? Icons.lock_outline : Icons.lock_open_outlined,
        size: 13,
        color: secure
            ? theme.colorScheme.onSurface.withValues(alpha: 0.55)
            : theme.colorScheme.error.withValues(alpha: 0.75),
      ),
    );
  }
}
