import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:infospect/features/network/models/infospect_network_call.dart';
import 'package:infospect/features/network/ui/list/bloc/networks_list_bloc.dart';
import 'package:infospect/features/network/ui/list/desktop_components/desktop_call_list_states.dart';
import 'package:infospect/features/network/ui/list/desktop_components/draggable_cell.dart';
import 'package:infospect/features/network/ui/list/desktop_components/state_helpers.dart';
import 'package:infospect/helpers/infospect_helper.dart';
import 'package:infospect/utils/common_widgets/highlight_text_widget.dart';
import 'package:infospect/utils/extensions/date_time_extension.dart';
import 'package:infospect/utils/extensions/infospect_network/network_response_extension.dart';
import 'package:infospect/utils/extensions/int_extension.dart';
import 'package:share_plus/share_plus.dart';

class DraggableTable extends StatefulWidget {
  const DraggableTable({
    super.key,
    required this.infospect,
    required this.onCallSelected,
    this.selectedCall,
    required this.constraints,
  });

  final Infospect infospect;

  final ValueChanged<InfospectNetworkCall> onCallSelected;
  final InfospectNetworkCall? selectedCall;
  final BoxConstraints constraints;

  @override
  State<DraggableTable> createState() => _DraggableTableState();
}

class _DraggableTableState extends DesktopCallListStates<DraggableTable> {
  final verticalScrollController = ScrollController();
  final horizontalScrollController = ScrollController();

  @override
  Widget build(BuildContext context) {
    checkWidth();
    return Scrollbar(
      thumbVisibility: true,
      trackVisibility: true,
      controller: verticalScrollController,
      child: Scrollbar(
        thumbVisibility: true,
        trackVisibility: true,
        controller: horizontalScrollController,
        notificationPredicate: (notify) => notify.depth == 1,
        child: SingleChildScrollView(
          controller: verticalScrollController,
          scrollDirection: Axis.vertical,
          child: SingleChildScrollView(
            controller: horizontalScrollController,
            scrollDirection: Axis.horizontal,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: _resizableColumnWidth(),
            ), // DataTable creation
          ),
        ),
      ),
    );
  }

  Widget _resizableColumnWidth() {
    return BlocConsumer<NetworksListBloc, NetworksListState>(
      listenWhen: (previous, current) =>
          current is CompressedNetworkCallLogsFile,
      listener: (context, state) {
        if (state is CompressedNetworkCallLogsFile) {
          if (Infospect.instance.onShareAllNetworkCalls != null) {
            Infospect.instance.onShareAllNetworkCalls!(state.sharableFile.path);
            return;
          }
          final XFile file = XFile(state.sharableFile.path);
          Share.shareXFiles([file]);
        }
      },
      builder: (context, state) {
        List<InfospectNetworkCall> calls = state.filteredCalls;
        final color = Theme.of(context).colorScheme.onBackground;

        return Row(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DataTable(
              headingRowHeight: 30,
              dataRowMinHeight: 20,
              dataRowMaxHeight: 26,
              columnSpacing: 4,
              horizontalMargin: 0,
              showCheckboxColumn: false,
              headingRowColor: MaterialStateProperty.all(
                color.withOpacity(0.2),
              ),
              headingTextStyle: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: color,
              ),
              border: const TableBorder(
                horizontalInside: BorderSide(
                  width: 0.1,
                ),
              ),
              dataTextStyle: TextStyle(
                fontSize: 12,
                color: color,
              ),
              columns: dataCellStates.mapIndexed(
                (index, element) {
                  return DataColumn(
                    label: DraggableCell(
                      text: element.label,
                      minWidth: element.minWidth,
                      maxWidth: element.maxWidth,
                      width: index == dataCellStates.length - 1
                          ? element.width
                          : null,
                      onColumnWidthChanged: (width) => updateDataCellStates(
                        id: index,
                        width: width,
                      ),
                    ),
                  );
                },
              ).toList(),
              rows: calls.reversed.mapIndexed((index, element) {
                return DataRow(
                  onSelectChanged: (value) {
                    if (element.loading) return;
                    widget.onCallSelected(element);
                  },
                  selected: widget.selectedCall?.id == element.id,
                  cells: [
                    /// State
                    dataCellWidget(
                      widget: element.loading
                          ? SizedBox(
                              width: 10,
                              height: 10,
                              child: CircularProgressIndicator(
                                color: Theme.of(context).colorScheme.error,
                                strokeWidth: 1,
                              ),
                            )
                          : _getStateColor(context, element),
                      data: '',
                      width: dataCellStates.width(CellType.columnState),
                    ),

                    /// Index
                    dataCellWidget(
                      data: '${index + 1}',
                      width: dataCellStates.width(CellType.columnId),
                    ),

                    /// url
                    dataCellWidget(
                      data: element.uri,
                      width: dataCellStates.width(CellType.columnUrl),
                      highlight: state.searchedText,
                    ),

                    /// Client name
                    dataCellWidget(
                      data: element.client,
                      width: dataCellStates.width(CellType.columnClient),
                    ),

                    /// Method
                    dataCellWidget(
                      data: element.method,
                      width: dataCellStates.width(CellType.columnMethod),
                    ),

                    /// status
                    dataCellWidget(
                      data: _getStatusText(element),
                      width: dataCellStates.width(CellType.columnStatus),
                    ),

                    /// code
                    dataCellWidget(
                      data: element.response?.status != -1
                          ? (element.response?.status ?? '').toString()
                          : '',
                      width: dataCellStates.width(CellType.columnCode),
                    ),

                    /// Time
                    dataCellWidget(
                      data: element.createdTime.formatTime,
                      width: dataCellStates.width(CellType.columnTime),
                    ),

                    /// duration
                    dataCellWidget(
                      data: element.duration.toReadableTime,
                      width: dataCellStates.width(CellType.columnDuration),
                    ),

                    /// is secure connection
                    dataCellWidget(
                      data: element.secure.toString(),
                      width: dataCellStates.width(CellType.columnSecure),
                    ),
                  ],
                );
              }).toList(),
            ),
          ],
        );
      },
    );
  }

  String _getStatusText(InfospectNetworkCall element) {
    return element.loading
        ? 'Active'
        : element.response?.status == 200
            ? 'Completed'
            : 'Error';
  }

  Container _getStateColor(BuildContext context, InfospectNetworkCall element) {
    return Container(
      width: 8,
      height: 8,
      margin: const EdgeInsetsDirectional.only(start: 4),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: element.response?.getStatusTextColor(context),
      ),
    );
  }
}

DataCell dataCellWidget(
    {required String data,
    required double width,
    Widget? widget,
    String? highlight}) {
  return DataCell(
    Container(
      padding: const EdgeInsetsDirectional.only(start: 2),
      child: widget ??
          HighlightText(
            text: data,
            highlight: highlight,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            softWrap: true,
            selectable: false,
          ),
    ),
  );
}
