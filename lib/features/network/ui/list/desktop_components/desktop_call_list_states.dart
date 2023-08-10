import 'package:flutter/material.dart';
import 'package:infospect/features/network/models/infospect_network_call.dart';
import 'package:infospect/features/network/ui/list/desktop_components/draggable_cell.dart';
import 'package:infospect/features/network/ui/list/desktop_components/draggable_table.dart';
import 'package:infospect/features/network/ui/list/desktop_components/state_helpers.dart';
import 'package:infospect/features/network/ui/list/screen/desktop_networks_list_screen.dart';

abstract class DesktopCallListStates<T extends DraggableTable>
    extends State<T> {
  List<DataCellState> dataCellStates = [];

  @override
  void initState() {
    init();
    super.initState();
  }

  @override
  void dispose() {
    dataCellStates.clear();
    super.dispose();
  }

  void updateDataCellStates({required int id, required double width}) {
    /// return if width is not changed
    if (dataCellStates[id].width == width) return;

    dataCellStates[id] = dataCellStates[id].copyWith(width: width);
    setState(() {});
  }

  void init() {
    for (var element in CellId.values) {
      dataCellStates.add(
        DataCellState(
          id: element.id,
          label: element.label,
          minWidth: element.minWidth,
          maxWidth: element.maxWidth,
        ),
      );
    }
  }
}

abstract class DesktopNetworksListScreenState<
    T extends DesktopNetworksListScreen> extends State<T> {
  InfospectNetworkCall? _selectedCall;

  InfospectNetworkCall? get selectedCall => _selectedCall;

  void updateSelectedCall(InfospectNetworkCall? value) {
    /// return if selected call is not changed
    if (_selectedCall == value) return;

    _selectedCall = value;
    setState(() {});
  }

  @override
  void dispose() {
    _selectedCall = null;
    super.dispose();
  }
}

abstract class DraggableCellState<T extends DraggableCell> extends State<T> {
  double initX = 0;
  late double columnWidth;
  late double minimumColumnWidth;
  late double maximumColumnWidth;

  @override
  void initState() {
    minimumColumnWidth = widget.minWidth;
    maximumColumnWidth = widget.maxWidth;
    columnWidth = (minimumColumnWidth + maximumColumnWidth) / 2;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onColumnWidthChanged(columnWidth);
    });
    super.initState();
  }

  void updateInitX(double value) {
    /// return if initX is not changed
    if (initX == value) return;

    initX = value;
    setState(() {});
  }

  void updateColumnWidth(DragUpdateDetails details) {
    final double oldColumnWidth = columnWidth;
    final double increment = details.globalPosition.dx - initX;
    final double newWidth = columnWidth + increment;

    updateInitX(details.globalPosition.dx);

    if (newWidth > minimumColumnWidth) {
      if (newWidth < maximumColumnWidth) {
        columnWidth = newWidth;
      } else {
        columnWidth = maximumColumnWidth;
      }
    } else {
      columnWidth = minimumColumnWidth;
    }

    /// return if column width is not changed
    if (oldColumnWidth == columnWidth) return;

    widget.onColumnWidthChanged(columnWidth);
    setState(() {});
  }
}
