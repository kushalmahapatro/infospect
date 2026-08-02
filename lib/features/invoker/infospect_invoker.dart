import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:infospect/features/launch/desktop/infospect_desktop_shortcuts.dart';
import 'package:infospect/helpers/infospect_helper.dart';
import 'package:infospect/utils/infospect_util.dart';

/// Expand / collapse behavior for the floating invoker.
///
/// `alwaysOpened`: always shows the full bubble (still draggable / hidable).
///
/// `collapsible`: starts collapsed as an edge peek; tap or drag outward to
/// expand; tap when expanded opens Infospect; swipe inward to collapse.
///
/// `autoCollapse`: like [collapsible], but auto-collapses 5 seconds after expand.
enum InvokerState { alwaysOpened, collapsible, autoCollapse }

/// Horizontal screen edge the invoker can dock to.
///
/// Only [left] and [right] are used. [top] and [bottom] remain for API
/// compatibility and are treated as [right].
enum InvokerEdge { left, right, top, bottom }

/// Floating Infospect entry point overlaid on [child].
///
/// Drag to move; release to snap to the nearer **left or right** edge
/// (vertical edges are not used). Long-press to hide. When hidden, a thin
/// edge nub remains so it can be shown again.
///
/// In collapsed / hidden modes the visual tab sits flush against the device
/// edge; the hit target extends inward (~44 logical px) so it stays easy to tap.
class InfospectInvoker extends StatefulWidget {
  const InfospectInvoker({
    super.key,
    required this.child,
    this.state = InvokerState.alwaysOpened,
    this.newWindowInDesktop = true,
    this.initialEdge = InvokerEdge.right,
    this.initialAlign = 0.85,
  });

  final Widget child;
  final InvokerState state;
  final bool newWindowInDesktop;

  /// Horizontal edge the invoker docks to initially ([left] or [right]).
  ///
  /// [InvokerEdge.top] / [InvokerEdge.bottom] are treated as [InvokerEdge.right].
  final InvokerEdge initialEdge;

  /// Vertical position along the docked side from `0` (top) to `1` (bottom).
  final double initialAlign;

  @override
  State<InfospectInvoker> createState() => _InfospectInvokerState();
}

class _InfospectInvokerState extends State<InfospectInvoker> {
  static const double _bubbleSize = 48;

  /// Visible thickness of the collapsed edge tab.
  static const double _collapsedVisualThickness = 8;

  /// Minimum inward hit extent when collapsed (Material / iOS touch target).
  static const double _collapsedHitThickness = 44;

  /// Visible length of the collapsed edge tab along the docked edge.
  static const double _collapsedLength = 56;

  static const double _hiddenVisualThickness = 5;
  static const double _hiddenHitThickness = 36;
  static const double _hiddenLength = 40;

  /// Gap from safe area when showing the expanded bubble.
  static const double _expandedMargin = 8;

  late InvokerEdge _edge;
  late double _align;
  bool _expanded = true;
  bool _hidden = false;
  bool _dragging = false;
  Offset? _dragOffset;
  Timer? _autoCollapseTimer;
  Timer? _autoHideTimer;

  static const Duration _autoHideDelay = Duration(seconds: 5);

  @override
  void initState() {
    super.initState();
    _edge = _horizontalEdge(widget.initialEdge);
    _align = widget.initialAlign.clamp(0.0, 1.0);
    _expanded = widget.state == InvokerState.alwaysOpened;
  }

  @override
  void didUpdateWidget(covariant InfospectInvoker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialEdge != widget.initialEdge) {
      _edge = _horizontalEdge(widget.initialEdge);
    }
    if (oldWidget.state != widget.state &&
        widget.state == InvokerState.alwaysOpened) {
      _expanded = true;
    }
  }

  /// Invoker only docks on the left/right sides.
  static InvokerEdge _horizontalEdge(InvokerEdge edge) => switch (edge) {
    InvokerEdge.left => InvokerEdge.left,
    InvokerEdge.right ||
    InvokerEdge.top ||
    InvokerEdge.bottom => InvokerEdge.right,
  };

  @override
  void dispose() {
    _autoCollapseTimer?.cancel();
    _autoHideTimer?.cancel();
    super.dispose();
  }

  bool get _isCollapsible =>
      widget.state == InvokerState.collapsible ||
      widget.state == InvokerState.autoCollapse;

  /// Collapsed peek or hidden nub — docked flush to the screen edge.
  bool get _isEdgePeek =>
      _hidden || (!_expanded && _isCollapsible && !_dragging);

  void _cancelAutoCollapse() {
    _autoCollapseTimer?.cancel();
    _autoCollapseTimer = null;
  }

  void _cancelAutoHide() {
    _autoHideTimer?.cancel();
    _autoHideTimer = null;
  }

  void _scheduleAutoCollapse() {
    _cancelAutoCollapse();
    if (widget.state != InvokerState.autoCollapse) return;
    _autoCollapseTimer = Timer(const Duration(seconds: 5), () {
      if (!mounted || _hidden || !_expanded) return;
      setState(() => _expanded = false);
    });
  }

  /// After revealing from the hidden nub, tuck away again if unused.
  void _scheduleAutoHide() {
    _cancelAutoHide();
    _autoHideTimer = Timer(_autoHideDelay, () {
      if (!mounted || _hidden || _dragging) return;
      _hide();
    });
  }

  void _expand() {
    if (_expanded) return;
    setState(() {
      _expanded = true;
      _hidden = false;
    });
    _scheduleAutoCollapse();
  }

  void _collapse() {
    if (!_isCollapsible || !_expanded) return;
    _cancelAutoCollapse();
    setState(() => _expanded = false);
  }

  void _hide() {
    _cancelAutoCollapse();
    _cancelAutoHide();
    setState(() {
      _hidden = true;
      _expanded = false;
      _dragging = false;
      _dragOffset = null;
    });
  }

  void _unhide({bool expand = true}) {
    setState(() {
      _hidden = false;
      _expanded = expand || widget.state == InvokerState.alwaysOpened;
    });
    if (_expanded) _scheduleAutoCollapse();
    _scheduleAutoHide();
  }

  /// Layout / gesture size (includes expanded hit area when edge-peeking).
  Size _handleSize() {
    if (_hidden) {
      return const Size(_hiddenHitThickness, _hiddenLength);
    }
    if (!_expanded && _isCollapsible) {
      return const Size(_collapsedHitThickness, _collapsedLength);
    }
    return const Size(_bubbleSize, _bubbleSize);
  }

  /// Painted tab size (thinner than the hit target when edge-peeking).
  Size _visualSize() {
    if (_hidden) {
      return const Size(_hiddenVisualThickness, _hiddenLength);
    }
    if (!_expanded && _isCollapsible && !_dragging) {
      return const Size(_collapsedVisualThickness, _collapsedLength);
    }
    return _handleSize();
  }

  Alignment _visualAlignment() {
    if (!_isEdgePeek) return Alignment.center;
    return _edge == InvokerEdge.left
        ? Alignment.centerLeft
        : Alignment.centerRight;
  }

  BorderRadius _borderRadiusFor(InvokerEdge edge, {required bool docked}) {
    if (!docked || (_expanded && !_hidden)) {
      return BorderRadius.circular(_bubbleSize / 2);
    }
    return switch (edge) {
      InvokerEdge.left => const BorderRadius.horizontal(
        right: Radius.circular(8),
      ),
      InvokerEdge.right || InvokerEdge.top || InvokerEdge.bottom =>
        const BorderRadius.horizontal(left: Radius.circular(8)),
    };
  }

  EdgeInsets _safeInsets(BuildContext context) => MediaQuery.paddingOf(context);

  Offset _dockedTopLeft({
    required Size viewport,
    required Size handle,
    required EdgeInsets safe,
  }) {
    // Expanded bubble: inset from safe area. Edge peeks: flush to the
    // physical screen edge on the docked side so there is no visible gap.
    final top = _isEdgePeek ? safe.top : safe.top + _expandedMargin;
    final bottom = _isEdgePeek
        ? viewport.height - safe.bottom - handle.height
        : viewport.height - safe.bottom - handle.height - _expandedMargin;
    final verticalRange = math.max(0.0, bottom - top);
    final y = top + _align * verticalRange;

    if (_isEdgePeek) {
      return _edge == InvokerEdge.left
          ? Offset(0, y)
          : Offset(viewport.width - handle.width, y);
    }

    final x = _edge == InvokerEdge.left
        ? safe.left + _expandedMargin
        : viewport.width - safe.right - handle.width - _expandedMargin;
    return Offset(x, y);
  }

  InvokerEdge _nearestHorizontalEdge(
    Offset center,
    Size viewport,
    EdgeInsets safe,
  ) {
    final leftDist = center.dx - safe.left;
    final rightDist = viewport.width - safe.right - center.dx;
    return leftDist <= rightDist ? InvokerEdge.left : InvokerEdge.right;
  }

  void _snapToNearestEdge({
    required Offset topLeft,
    required Size handle,
    required Size viewport,
    required EdgeInsets safe,
  }) {
    final center = topLeft + Offset(handle.width / 2, handle.height / 2);
    final edge = _nearestHorizontalEdge(center, viewport, safe);

    final minAlong = safe.top + _expandedMargin;
    final maxAlong =
        viewport.height - safe.bottom - handle.height - _expandedMargin;
    final range = math.max(1.0, maxAlong - minAlong);
    final along = topLeft.dy.clamp(minAlong, maxAlong);

    setState(() {
      _edge = edge;
      _align = (along - minAlong) / range;
      _dragging = false;
      _dragOffset = null;
    });
  }

  void _onPanStart({required Size viewport, required EdgeInsets safe}) {
    if (_hidden) return;
    _cancelAutoCollapse();
    _cancelAutoHide();
    final handle = _handleSize();
    final origin =
        _dragOffset ??
        _dockedTopLeft(viewport: viewport, handle: handle, safe: safe);
    setState(() {
      _dragging = true;
      _dragOffset = origin;
      if (_isCollapsible) _expanded = true;
    });
  }

  void _onPanUpdate(DragUpdateDetails details, Size viewport) {
    if (!_dragging || _dragOffset == null) return;
    final handle = _handleSize();
    final next = _dragOffset! + details.delta;
    setState(() {
      _dragOffset = Offset(
        next.dx.clamp(0.0, math.max(0.0, viewport.width - handle.width)),
        next.dy.clamp(0.0, math.max(0.0, viewport.height - handle.height)),
      );
    });
  }

  void _onPanEnd({required Size viewport, required EdgeInsets safe}) {
    if (!_dragging || _dragOffset == null) return;
    final handle = _handleSize();
    _snapToNearestEdge(
      topLeft: _dragOffset!,
      handle: handle,
      viewport: viewport,
      safe: safe,
    );
    if (_expanded) _scheduleAutoCollapse();
  }

  Future<void> _onLongPress() async {
    if (_hidden) return;
    _cancelAutoCollapse();
    _cancelAutoHide();
    final action = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.visibility_off_outlined),
                title: const Text('Hide invoker'),
                subtitle: const Text('Show again from the edge nub'),
                onTap: () => Navigator.pop(context, 'hide'),
              ),
              if (_isCollapsible && _expanded)
                ListTile(
                  leading: const Icon(Icons.compress_rounded),
                  title: const Text('Collapse'),
                  onTap: () => Navigator.pop(context, 'collapse'),
                ),
              ListTile(
                leading: const Icon(Icons.close_rounded),
                title: const Text('Cancel'),
                onTap: () => Navigator.pop(context),
              ),
            ],
          ),
        );
      },
    );

    if (!mounted) return;
    if (action == 'hide') {
      _hide();
    } else if (action == 'collapse') {
      _collapse();
    } else if (_expanded) {
      _scheduleAutoCollapse();
    }
  }

  void _onTap() {
    if (_hidden) {
      _unhide(expand: true);
      return;
    }

    _cancelAutoHide();

    if (!_expanded && _isCollapsible) {
      _expand();
      return;
    }

    _launchInfospect();
    if (_isCollapsible) {
      _collapse();
    }
  }

  void _launchInfospect() {
    if (InfospectUtil.isDesktop && widget.newWindowInDesktop) {
      Infospect.instance.openInspectorInNewWindow();
    } else {
      Infospect.instance.navigateToInterceptor();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) return widget.child;

    final safe = _safeInsets(context);

    return Directionality(
      textDirection: TextDirection.ltr,
      child: CallbackShortcuts(
        bindings: {
          for (final activator
              in InfospectDesktopShortcuts.openInspectorActivators)
            activator: () => Infospect.instance.openInspectorInNewWindow(),
        },
        child: LayoutBuilder(
          builder: (context, constraints) {
            final viewport = Size(constraints.maxWidth, constraints.maxHeight);
            final handle = _handleSize();
            final visual = _visualSize();
            final topLeft = _dragging && _dragOffset != null
                ? _dragOffset!
                : _dockedTopLeft(
                    viewport: viewport,
                    handle: handle,
                    safe: safe,
                  );
            final theme = Theme.of(context);
            final bg = theme.colorScheme.inverseSurface;
            final fg = theme.colorScheme.onInverseSurface;

            return Stack(
              fit: StackFit.expand,
              children: [
                widget.child,
                ValueListenableBuilder<bool>(
                  valueListenable: Infospect.instance.isInfospectOpened,
                  builder: (context, opened, _) {
                    if (opened) return const SizedBox.shrink();
                    return AnimatedPositioned(
                      duration: Duration(milliseconds: _dragging ? 0 : 220),
                      curve: Curves.easeOutCubic,
                      left: topLeft.dx,
                      top: topLeft.dy,
                      width: handle.width,
                      height: handle.height,
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onPanStart: (_) =>
                            _onPanStart(viewport: viewport, safe: safe),
                        onPanUpdate: (details) =>
                            _onPanUpdate(details, viewport),
                        onPanEnd: (_) =>
                            _onPanEnd(viewport: viewport, safe: safe),
                        onTap: _onTap,
                        onLongPress: _onLongPress,
                        child: SizedBox(
                          width: handle.width,
                          height: handle.height,
                          child: Align(
                            alignment: _visualAlignment(),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              curve: Curves.easeOutCubic,
                              width: visual.width,
                              height: visual.height,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: bg.withValues(
                                  alpha: _hidden ? 0.55 : 0.92,
                                ),
                                borderRadius: _borderRadiusFor(
                                  _edge,
                                  docked: !_dragging,
                                ),
                                boxShadow:
                                    _hidden || (!_expanded && _isCollapsible)
                                    ? null
                                    : [
                                        BoxShadow(
                                          color: Colors.black.withValues(
                                            alpha: 0.22,
                                          ),
                                          blurRadius: 10,
                                          offset: const Offset(0, 3),
                                        ),
                                      ],
                              ),
                              child: (_expanded && !_hidden)
                                  ? Icon(
                                      Icons.manage_search_rounded,
                                      color: fg,
                                      size: 22,
                                    )
                                  : null,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
