import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:infospect/features/network/models/infospect_network_call.dart';
import 'package:infospect/features/network/ui/details/models/details_topic_data.dart';
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

  void checkWidth() {
    double width = 0;
    for (int i = 0; i < dataCellStates.length; i++) {
      final element = dataCellStates[i];

      double w = widget.constraints.maxWidth - width;

      if (i == dataCellStates.length - 1 && w > 75) {
        if (dataCellStates[i].width == w) return;
        double maxWidth = (2 * w) - 50;

        dataCellStates[i] =
            dataCellStates[i].copyWith(width: w, maxWidth: maxWidth);
        setState(() {});
      } else {
        width = width + element.width;
      }
    }
  }

  void init() {
    double width = 0;
    for (int i = 0; i < CellId.values.length; i++) {
      final element = CellId.values[i];
      var cellState = DataCellState(
        id: element.id,
        label: element.label,
        minWidth: element.minWidth,
        maxWidth: element.maxWidth,
      );
      width = width + cellState.width;
      double w = widget.constraints.maxWidth - width;

      if (i == CellId.values.length - 1 && w > 75) {
        double maxWidth = (2 * w) - 50;
        cellState = cellState.copyWith(width: w, maxWidth: maxWidth);
      }
      dataCellStates.add(cellState);
    }
  }
}

abstract class DesktopNetworksListScreenState<
    T extends DesktopNetworksListScreen> extends State<T> {
  InfospectNetworkCall? _selectedCall;

  RequestDetailsTopicHelper? _topicHelper;
  ResponseDetailsTopicHelper? _responseTopicHelper;

  TopicData? _selectedTopic;
  TopicData? _selectedResponseTopic;

  InfospectNetworkCall? get selectedCall => _selectedCall;

  RequestDetailsTopicHelper? get topicHelper => _topicHelper;

  ResponseDetailsTopicHelper? get responseTopicHelper => _responseTopicHelper;

  TopicData? get selectedTopic => _selectedTopic;

  TopicData? get selectedResponseTopic => _selectedResponseTopic;

  void updateSelectedCall(InfospectNetworkCall? value) {
    /// return if selected call is not changed
    if (_selectedCall == value) return;

    _selectedCall = value;
    if (value != null) {
      _topicHelper = RequestDetailsTopicHelper(value);
      _selectedTopic = _topicHelper?.topics.firstWhereOrNull(
        (element) => element.topic == _selectedTopic?.topic,
      );
      _responseTopicHelper = ResponseDetailsTopicHelper(value);
      _selectedResponseTopic = _responseTopicHelper?.topics.firstWhereOrNull(
        (element) => element.topic == _selectedResponseTopic?.topic,
      );
    }
    setState(() {});
  }

  void updateSelectedTopic(TopicData? value) {
    /// return if selected topic is not changed
    if (_selectedTopic == value) return;

    _selectedTopic = value;
    setState(() {});
  }

  void updateSelectedResponseTopic(TopicData? value) {
    /// return if selected topic is not changed
    if (_selectedResponseTopic == value) return;

    _selectedResponseTopic = value;
    setState(() {});
  }

  @override
  void dispose() {
    _selectedCall = null;
    _selectedTopic = null;
    _selectedResponseTopic = null;
    _topicHelper = null;
    _responseTopicHelper = null;
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
