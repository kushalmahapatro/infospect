import 'package:flutter/material.dart';
import 'package:infospect/features/network/ui/list/desktop_components/desktop_call_list_states.dart';
import 'package:infospect/features/network/ui/list/notifier/networks_list_notifier.dart';

class DraggableCell extends StatefulWidget {
  const DraggableCell({
    required this.text,
    required this.onColumnWidthChanged,
    this.maxWidth = 100,
    this.minWidth = 50,
    this.width,
    this.onHeaderTap,
    this.timeSort,
    super.key,
  });

  final String text;
  final ValueChanged<double> onColumnWidthChanged;
  final double minWidth;
  final double maxWidth;
  final double? width;
  final VoidCallback? onHeaderTap;
  final NetworkCallsTimeSort? timeSort;

  @override
  State<DraggableCell> createState() => _DraggableCellState();
}

class _DraggableCellState extends DraggableCellState<DraggableCell> {
  bool _hovering = false;
  bool _dragging = false;
  bool _headerHovering = false;

  bool get _canResize => minimumColumnWidth != maximumColumnWidth;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final borderColor = theme.colorScheme.outlineVariant.withValues(
      alpha: 0.55,
    );
    final active = _hovering || _dragging;
    final handleColor = active ? theme.colorScheme.primary : borderColor;
    final sortable = widget.onHeaderTap != null;
    final sortIcon = switch (widget.timeSort) {
      NetworkCallsTimeSort.ascending => Icons.arrow_upward_rounded,
      NetworkCallsTimeSort.descending => Icons.arrow_downward_rounded,
      null => null,
    };

    return SizedBox(
      width: columnWidth,
      height: 30,
      child: Row(
        children: [
          Expanded(
            child: MouseRegion(
              cursor: sortable
                  ? SystemMouseCursors.click
                  : SystemMouseCursors.basic,
              onEnter: sortable
                  ? (_) => setState(() => _headerHovering = true)
                  : null,
              onExit: sortable
                  ? (_) => setState(() => _headerHovering = false)
                  : null,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: widget.onHeaderTap,
                child: Padding(
                  padding: const EdgeInsetsDirectional.only(start: 8, end: 2),
                  child: Row(
                    children: [
                      Flexible(
                        child: Text(
                          widget.text,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.labelLarge?.copyWith(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.2,
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: sortable && _headerHovering ? 0.95 : 0.78,
                            ),
                          ),
                        ),
                      ),
                      if (sortIcon != null) ...[
                        const SizedBox(width: 2),
                        Icon(
                          sortIcon,
                          size: 12,
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.7,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (_canResize)
            MouseRegion(
              cursor: columnWidth == minimumColumnWidth
                  ? SystemMouseCursors.resizeRight
                  : columnWidth == maximumColumnWidth
                  ? SystemMouseCursors.resizeLeft
                  : SystemMouseCursors.resizeLeftRight,
              onEnter: (_) => setState(() => _hovering = true),
              onExit: (_) => setState(() => _hovering = false),
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onHorizontalDragStart: (details) {
                  setState(() => _dragging = true);
                  updateInitX(details.globalPosition.dx);
                },
                onHorizontalDragUpdate: updateColumnWidth,
                onHorizontalDragEnd: (_) => setState(() => _dragging = false),
                onHorizontalDragCancel: () => setState(() => _dragging = false),
                child: SizedBox(
                  width: 8,
                  height: double.infinity,
                  child: Center(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 100),
                      width: active ? 2 : 1,
                      height: 14,
                      color: handleColor,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
