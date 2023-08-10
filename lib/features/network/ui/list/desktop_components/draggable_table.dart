import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:infospect/features/network/models/infospect_network_call.dart';
import 'package:infospect/features/network/ui/list/desktop_components/desktop_call_list_states.dart';
import 'package:infospect/features/network/ui/list/desktop_components/draggable_cell.dart';
import 'package:infospect/features/network/ui/list/desktop_components/state_helpers.dart';
import 'package:infospect/helpers/infospect_helper.dart';
import 'package:infospect/utils/extensions/date_time_extension.dart';
import 'package:infospect/utils/extensions/infospect_network/network_response_extension.dart';
import 'package:infospect/utils/extensions/int_extension.dart';

class DraggableTable extends StatefulWidget {
  const DraggableTable({
    super.key,
    required this.infospect,
    required this.onCallSelected,
    this.selectedCall,
  });

  final Infospect infospect;

  final ValueChanged<InfospectNetworkCall> onCallSelected;
  final InfospectNetworkCall? selectedCall;

  @override
  State<DraggableTable> createState() => _DraggableTableState();
}

class _DraggableTableState extends DesktopCallListStates<DraggableTable> {
  final verticalScrollController = ScrollController();
  final horizontalScrollController = ScrollController();

  @override
  Widget build(BuildContext context) {
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
    return StreamBuilder<List<InfospectNetworkCall>>(
      stream: widget.infospect.callsSubject,
      builder: (context, snapshot) {
        List<InfospectNetworkCall> calls = snapshot.data ?? [];

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
              headingRowColor:
                  MaterialStateProperty.all(Colors.black.withOpacity(0.2)),
              headingTextStyle: const TextStyle(
                  color: Colors.black,
                  fontSize: 12,
                  fontWeight: FontWeight.bold),
              border: const TableBorder(
                horizontalInside: BorderSide(
                  width: 0.1,
                  color: Colors.black,
                ),
              ),
              dataTextStyle: const TextStyle(
                fontSize: 12,
                color: Colors.black,
              ),
              columns: dataCellStates.mapIndexed(
                (index, element) {
                  return DataColumn(
                    label: DraggableCell(
                      text: element.label,
                      minWidth: element.minWidth,
                      maxWidth: element.maxWidth,
                      onColumnWidthChanged: (width) => updateDataCellStates(
                        id: index,
                        width: width,
                      ),
                    ),
                  );
                },
              ).toList(),
              rows: calls.reversed.mapIndexed((index, element) {
                CellId.Id;
                return DataRow(
                  onSelectChanged: (value) {
                    widget.onCallSelected(element);
                  },
                  selected: widget.selectedCall?.id == element.id,
                  cells: [
                    dataCellWidget(
                      widget: _getStateColor(context, element),
                      data: '',
                      width: dataCellStates.width(CellId.State),
                    ),
                    dataCellWidget(
                      data: '${index + 1}',
                      width: dataCellStates.width(CellId.Id),
                    ),
                    dataCellWidget(
                      data: element.uri,
                      width: dataCellStates.width(CellId.Url),
                    ),
                    dataCellWidget(
                      data: element.client,
                      width: dataCellStates.width(CellId.Client),
                    ),
                    dataCellWidget(
                      data: element.method,
                      width: dataCellStates.width(CellId.Method),
                    ),
                    dataCellWidget(
                      data: _getStatusText(element),
                      width: dataCellStates.width(CellId.Status),
                    ),
                    dataCellWidget(
                      data: element.response?.status != -1
                          ? (element.response?.status ?? '').toString()
                          : '',
                      width: dataCellStates.width(CellId.Status),
                    ),
                    dataCellWidget(
                      data: element.createdTime.formatTime,
                      width: dataCellStates.width(CellId.Time),
                    ),
                    dataCellWidget(
                      data: element.duration.toReadableTime,
                      width: dataCellStates.width(CellId.Duration),
                    ),
                    dataCellWidget(
                      data: element.secure.toString(),
                      width: dataCellStates.width(CellId.Secure),
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
    {required String data, required double width, Widget? widget}) {
  return DataCell(
    Container(
      constraints: BoxConstraints(maxWidth: width),
      padding: const EdgeInsetsDirectional.only(start: 2),
      child: widget ??
          Text(
            data,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            softWrap: true,
          ),
    ),
  );
}
