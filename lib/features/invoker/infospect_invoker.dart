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

/// Screen edge the invoker can dock to.
enum InvokerEdge { left, right, top, bottom }

/// Floating Infospect entry point overlaid on [child].
///
/// Drag to move; release to snap to the nearest edge. Long-press to hide.
/// When hidden, a thin edge nub remains so it can be shown again.
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

  /// Edge the invoker docks to initially.
  final InvokerEdge initialEdge;

  /// Position along the docked edge from `0` (start) to `1` (end).
  /// For left/right edges this is vertical; for top/bottom horizontal.
  final double initialAlign;

  @override
  State<InfospectInvoker> createState() => _InfospectInvokerState();
}

class _InfospectInvokerState extends State<InfospectInvoker> {
  static const double _bubbleSize = 48;
  static const double _collapsedThickness = 6;
  static const double _hiddenThickness = 4;
  static const double _hiddenLength = 28;
  static const double _margin = 8;

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
    _edge = widget.initialEdge;
    _align = widget.initialAlign.clamp(0.0, 1.0);
    _expanded = widget.state == InvokerState.alwaysOpened;
  }

  @override
  void didUpdateWidget(covariant InfospectInvoker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.state != widget.state &&
        widget.state == InvokerState.alwaysOpened) {
      _expanded = true;
    }
  }

  @override
  void dispose() {
    _autoCollapseTimer?.cancel();
    _autoHideTimer?.cancel();
    super.dispose();
  }

  bool get _isCollapsible =>
      widget.state == InvokerState.collapsible ||
      widget.state == InvokerState.autoCollapse;

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

  Size _handleSize() {
    if (_hidden) {
      return switch (_edge) {
        InvokerEdge.left || InvokerEdge.right =>
          const Size(_hiddenThickness, _hiddenLength),
        InvokerEdge.top || InvokerEdge.bottom =>
          const Size(_hiddenLength, _hiddenThickness),
      };
    }
    if (!_expanded && _isCollapsible) {
      return switch (_edge) {
        InvokerEdge.left || InvokerEdge.right =>
          const Size(_collapsedThickness, _bubbleSize),
        InvokerEdge.top || InvokerEdge.bottom =>
          const Size(_bubbleSize, _collapsedThickness),
      };
    }
    return const Size(_bubbleSize, _bubbleSize);
  }

  BorderRadius _borderRadiusFor(InvokerEdge edge, {required bool docked}) {
    if (!docked || (_expanded && !_hidden)) {
      return BorderRadius.circular(_bubbleSize / 2);
    }
    return switch (edge) {
      InvokerEdge.left => const BorderRadius.horizontal(
          right: Radius.circular(6),
        ),
      InvokerEdge.right => const BorderRadius.horizontal(
          left: Radius.circular(6),
        ),
      InvokerEdge.top => const BorderRadius.vertical(
          bottom: Radius.circular(6),
        ),
      InvokerEdge.bottom => const BorderRadius.vertical(
          top: Radius.circular(6),
        ),
    };
  }

  EdgeInsets _safeInsets(BuildContext context) => MediaQuery.paddingOf(context);

  Offset _dockedTopLeft({
    required Size viewport,
    required Size handle,
    required EdgeInsets safe,
  }) {
    final left = safe.left + _margin;
    final top = safe.top + _margin;
    final right = viewport.width - safe.right - handle.width - _margin;
    final bottom = viewport.height - safe.bottom - handle.height - _margin;
    final verticalRange = math.max(0.0, bottom - top);
    final horizontalRange = math.max(0.0, right - left);

    return switch (_edge) {
      InvokerEdge.left => Offset(left, top + _align * verticalRange),
      InvokerEdge.right => Offset(right, top + _align * verticalRange),
      InvokerEdge.top => Offset(left + _align * horizontalRange, top),
      InvokerEdge.bottom => Offset(left + _align * horizontalRange, bottom),
    };
  }

  InvokerEdge _nearestEdge(Offset center, Size viewport, EdgeInsets safe) {
    final distances = <InvokerEdge, double>{
      InvokerEdge.left: center.dx - safe.left,
      InvokerEdge.right: viewport.width - safe.right - center.dx,
      InvokerEdge.top: center.dy - safe.top,
      InvokerEdge.bottom: viewport.height - safe.bottom - center.dy,
    };
    return distances.entries.reduce((a, b) => a.value <= b.value ? a : b).key;
  }

  void _snapToNearestEdge({
    required Offset topLeft,
    required Size handle,
    required Size viewport,
    required EdgeInsets safe,
  }) {
    final center = topLeft + Offset(handle.width / 2, handle.height / 2);
    final edge = _nearestEdge(center, viewport, safe);

    final minAlong = switch (edge) {
      InvokerEdge.left || InvokerEdge.right => safe.top + _margin,
      InvokerEdge.top || InvokerEdge.bottom => safe.left + _margin,
    };
    final maxAlong = switch (edge) {
      InvokerEdge.left || InvokerEdge.right =>
        viewport.height - safe.bottom - handle.height - _margin,
      InvokerEdge.top || InvokerEdge.bottom =>
        viewport.width - safe.right - handle.width - _margin,
    };
    final range = math.max(1.0, maxAlong - minAlong);
    final along = switch (edge) {
      InvokerEdge.left || InvokerEdge.right =>
        (topLeft.dy).clamp(minAlong, maxAlong),
      InvokerEdge.top || InvokerEdge.bottom =>
        (topLeft.dx).clamp(minAlong, maxAlong),
    };

    setState(() {
      _edge = edge;
      _align = (along - minAlong) / range;
      _dragging = false;
      _dragOffset = null;
    });
  }

  void _onPanStart({
    required Size viewport,
    required EdgeInsets safe,
  }) {
    if (_hidden) return;
    _cancelAutoCollapse();
    _cancelAutoHide();
    final handle = _handleSize();
    final origin = _dragOffset ??
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

  void _onPanEnd({
    required Size viewport,
    required EdgeInsets safe,
  }) {
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
                        onPanStart: (_) => _onPanStart(
                          viewport: viewport,
                          safe: safe,
                        ),
                        onPanUpdate: (details) =>
                            _onPanUpdate(details, viewport),
                        onPanEnd: (_) => _onPanEnd(
                          viewport: viewport,
                          safe: safe,
                        ),
                        onTap: _onTap,
                        onLongPress: _onLongPress,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          curve: Curves.easeOutCubic,
                          width: handle.width,
                          height: handle.height,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: bg.withValues(alpha: _hidden ? 0.55 : 0.92),
                            borderRadius: _borderRadiusFor(
                              _edge,
                              docked: !_dragging,
                            ),
                            boxShadow: _hidden ||
                                    (!_expanded && _isCollapsible)
                                ? null
                                : [
                                    BoxShadow(
                                      color: Colors.black
                                          .withValues(alpha: 0.22),
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
