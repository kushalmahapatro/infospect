import 'package:flutter/material.dart';
import 'package:infospect/features/network/ui/list/desktop_components/desktop_call_list_states.dart';

class DraggableCell extends StatefulWidget {
  const DraggableCell({
    required this.text,
    required this.onColumnWidthChanged,
    this.maxWidth = 100,
    this.minWidth = 50,
    super.key,
  });

  final String text;
  final ValueChanged<double> onColumnWidthChanged;
  final double minWidth;
  final double maxWidth;

  @override
  State<DraggableCell> createState() => _DraggableCellState();
}

class _DraggableCellState extends DraggableCellState<DraggableCell> {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: columnWidth,
      child: Row(
        children: [
          Expanded(
            child: Container(
              margin: const EdgeInsetsDirectional.only(start: 4),
              alignment: AlignmentDirectional.centerStart,
              child: Text(
                widget.text,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ), // Header text
            ),
          ),
          if (minimumColumnWidth != maximumColumnWidth)
            GestureDetector(
              onPanStart: (details) => updateInitX(details.globalPosition.dx),
              onPanUpdate: updateColumnWidth,
              child: MouseRegion(
                cursor: columnWidth == minimumColumnWidth
                    ? SystemMouseCursors.resizeRight
                    : columnWidth == maximumColumnWidth
                        ? SystemMouseCursors.resizeLeft
                        : SystemMouseCursors.resizeLeftRight,
                child: Container(
                  color: Colors.black,
                  width: 1,
                  margin: const EdgeInsetsDirectional.only(
                    top: 4,
                    bottom: 4,
                    start: 8,
                  ),
                  height: double.infinity,
                ),
              ),
            )
        ],
      ),
    );
  }
}
