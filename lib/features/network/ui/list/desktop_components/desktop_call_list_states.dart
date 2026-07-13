import 'package:flutter/material.dart';
import 'package:infospect/features/network/ui/list/desktop_components/draggable_cell.dart';
import 'package:infospect/features/network/ui/list/desktop_components/draggable_table.dart';
import 'package:infospect/features/network/ui/list/desktop_components/state_helpers.dart';

abstract class DesktopCallListStates<T extends DraggableTable>
    extends State<T> {
  List<DataCellState> dataCellStates = [];
  bool _widthCheckScheduled = false;

  @override
  void initState() {
    init();
    super.initState();
  }

  @override
  void didUpdateWidget(covariant T oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.constraints.maxWidth != widget.constraints.maxWidth) {
      scheduleWidthCheck();
    }
  }

  @override
  void dispose() {
    dataCellStates.clear();
    super.dispose();
  }

  void updateDataCellStates({required int id, required double width}) {
    if (dataCellStates[id].width == width) return;

    dataCellStates[id] = dataCellStates[id].copyWith(width: width);
    setState(() {});
  }

  /// Schedules a width pass after the current frame (never during build).
  void scheduleWidthCheck() {
    if (_widthCheckScheduled) return;
    _widthCheckScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _widthCheckScheduled = false;
      if (!mounted) return;
      _applyLastColumnWidth();
    });
  }

  void _applyLastColumnWidth() {
    if (dataCellStates.isEmpty) return;

    double used = 0;
    for (int i = 0; i < dataCellStates.length - 1; i++) {
      used += dataCellStates[i].width;
    }

    final remaining = widget.constraints.maxWidth - used;
    final last = dataCellStates.length - 1;

    if (remaining > 75) {
      final maxWidth = (2 * remaining) - 50;
      if (dataCellStates[last].width == remaining &&
          dataCellStates[last].maxWidth == maxWidth) {
        return;
      }
      dataCellStates[last] = dataCellStates[last].copyWith(
        width: remaining,
        maxWidth: maxWidth,
      );
      setState(() {});
    }
  }

  void init() {
    double width = 0;
    for (int i = 0; i < CellType.values.length; i++) {
      final element = CellType.values[i];
      var cellState = DataCellState(
        id: element.id,
        label: element.label,
        minWidth: element.minWidth,
        maxWidth: element.maxWidth,
        width: (element.minWidth + element.maxWidth) / 2,
      );
      width = width + cellState.width;
      final remaining = widget.constraints.maxWidth - width;

      if (i == CellType.values.length - 1 && remaining > 75) {
        final maxWidth = (2 * remaining) - 50;
        cellState = cellState.copyWith(width: remaining, maxWidth: maxWidth);
      }
      dataCellStates.add(cellState);
    }
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
    columnWidth = widget.width ?? (minimumColumnWidth + maximumColumnWidth) / 2;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      widget.onColumnWidthChanged(columnWidth);
    });
    super.initState();
  }

  @override
  void didUpdateWidget(covariant T oldWidget) {
    super.didUpdateWidget(oldWidget);
    minimumColumnWidth = widget.minWidth;
    maximumColumnWidth = widget.maxWidth;
    if (widget.width != null && widget.width != columnWidth) {
      columnWidth = widget.width!;
    }
  }

  void updateInitX(double value) {
    if (initX == value) return;
    initX = value;
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

    if (oldColumnWidth == columnWidth) return;

    widget.onColumnWidthChanged(columnWidth);
    setState(() {});
  }
}
