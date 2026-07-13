import 'package:flutter/material.dart';

/// Which end of the list receives new live items.
enum LiveListEdge { top, bottom }

/// Shared floating control used when newer items arrive off-screen.
class NewItemsFloatingButton extends StatelessWidget {
  const NewItemsFloatingButton({
    super.key,
    required this.visible,
    required this.label,
    required this.onPressed,
    required this.edge,
  });

  final bool visible;
  final String label;
  final VoidCallback onPressed;
  final LiveListEdge edge;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final icon = edge == LiveListEdge.top
        ? Icons.arrow_upward_rounded
        : Icons.arrow_downward_rounded;

    return Positioned(
      right: 16,
      bottom: 16,
      child: IgnorePointer(
        ignoring: !visible,
        child: AnimatedSlide(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          offset: visible ? Offset.zero : const Offset(0, 0.4),
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 180),
            opacity: visible ? 1 : 0,
            child: Material(
              elevation: 3,
              color: theme.colorScheme.secondaryContainer,
              shadowColor: theme.colorScheme.shadow.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(20),
              child: InkWell(
                onTap: onPressed,
                borderRadius: BorderRadius.circular(20),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        icon,
                        size: 16,
                        color: theme.colorScheme.onSecondaryContainer,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        label,
                        style: theme.textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onSecondaryContainer,
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
    );
  }
}

/// Scrollable list that follows the live edge while pinned, and preserves
/// scroll position when the user has moved away — showing [newItemsLabel]
/// when newer items arrive.
class LiveEdgeScrollableList extends StatefulWidget {
  const LiveEdgeScrollableList({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    required this.newestItemKey,
    required this.newItemsLabel,
    this.edge = LiveListEdge.top,
    this.querySignature = '',
    this.controller,
  });

  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;
  final Object? newestItemKey;
  final String newItemsLabel;
  final LiveListEdge edge;
  final String querySignature;
  final ScrollController? controller;

  @override
  State<LiveEdgeScrollableList> createState() => _LiveEdgeScrollableListState();
}

class _LiveEdgeScrollableListState extends State<LiveEdgeScrollableList> {
  static const double _edgeThreshold = 48;

  ScrollController? _ownedController;
  late ScrollController _controller;
  bool _pinnedToEdge = true;
  bool _hasNewItems = false;
  int _previousCount = 0;
  Object? _previousNewestKey;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? (_ownedController = ScrollController());
    _controller.addListener(_onScroll);
    _previousCount = widget.itemCount;
    _previousNewestKey = widget.newestItemKey;
  }

  @override
  void didUpdateWidget(covariant LiveEdgeScrollableList oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.controller != oldWidget.controller) {
      _controller.removeListener(_onScroll);
      _ownedController?.dispose();
      _ownedController = null;
      _controller =
          widget.controller ?? (_ownedController = ScrollController());
      _controller.addListener(_onScroll);
    }

    final queryChanged = widget.querySignature != oldWidget.querySignature;
    if (queryChanged) {
      _hasNewItems = false;
      _previousCount = widget.itemCount;
      _previousNewestKey = widget.newestItemKey;
      return;
    }

    final arrived = _didReceiveNewItems(
      previousCount: _previousCount,
      currentCount: widget.itemCount,
      previousNewestKey: _previousNewestKey,
      currentNewestKey: widget.newestItemKey,
    );

    _previousCount = widget.itemCount;
    _previousNewestKey = widget.newestItemKey;

    if (!arrived) {
      if (widget.itemCount == 0) {
        _hasNewItems = false;
      }
      return;
    }

    if (_pinnedToEdge) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _jumpToLiveEdge();
        if (_hasNewItems) {
          setState(() => _hasNewItems = false);
        }
      });
      return;
    }

    if (widget.edge == LiveListEdge.top) {
      final previousExtent = _controller.hasClients
          ? _controller.position.maxScrollExtent
          : 0.0;
      final previousOffset = _controller.hasClients ? _controller.offset : 0.0;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !_controller.hasClients) return;
        final delta = _controller.position.maxScrollExtent - previousExtent;
        if (delta > 0) {
          _controller.jumpTo(previousOffset + delta);
        }
        if (!_hasNewItems) {
          setState(() => _hasNewItems = true);
        }
      });
      return;
    }

    // Bottom edge: appending does not shift existing offsets.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (!_hasNewItems) {
        setState(() => _hasNewItems = true);
      }
    });
  }

  bool _didReceiveNewItems({
    required int previousCount,
    required int currentCount,
    required Object? previousNewestKey,
    required Object? currentNewestKey,
  }) {
    if (currentCount == 0) return false;
    if (previousCount == 0) return false;
    if (currentCount <= previousCount) return false;
    return currentNewestKey != previousNewestKey;
  }

  bool _isAtLiveEdge() {
    if (!_controller.hasClients) return true;
    final position = _controller.position;
    if (widget.edge == LiveListEdge.top) {
      return position.pixels <= _edgeThreshold;
    }
    return position.pixels >= position.maxScrollExtent - _edgeThreshold;
  }

  void _onScroll() {
    if (!_controller.hasClients) return;
    final atEdge = _isAtLiveEdge();
    if (atEdge == _pinnedToEdge && !(atEdge && _hasNewItems)) return;

    setState(() {
      _pinnedToEdge = atEdge;
      if (atEdge) {
        _hasNewItems = false;
      }
    });
  }

  void _jumpToLiveEdge() {
    if (!_controller.hasClients) return;
    if (widget.edge == LiveListEdge.top) {
      _controller.jumpTo(0);
    } else {
      _controller.jumpTo(_controller.position.maxScrollExtent);
    }
  }

  Future<void> _scrollToLiveEdge() async {
    if (!_controller.hasClients) return;
    final target = widget.edge == LiveListEdge.top
        ? 0.0
        : _controller.position.maxScrollExtent;
    await _controller.animateTo(
      target,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
    if (!mounted) return;
    setState(() {
      _pinnedToEdge = true;
      _hasNewItems = false;
    });
  }

  @override
  void dispose() {
    _controller.removeListener(_onScroll);
    _ownedController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ListView.builder(
          controller: _controller,
          padding: EdgeInsets.zero,
          itemCount: widget.itemCount,
          itemBuilder: widget.itemBuilder,
        ),
        NewItemsFloatingButton(
          visible: _hasNewItems,
          label: widget.newItemsLabel,
          edge: widget.edge,
          onPressed: _scrollToLiveEdge,
        ),
      ],
    );
  }
}

/// Applies live-edge follow / preserve behavior to an existing
/// [ScrollController] (e.g. desktop table body scroll).
class LiveEdgeScrollAddon extends StatefulWidget {
  const LiveEdgeScrollAddon({
    super.key,
    required this.controller,
    required this.itemCount,
    required this.newestItemKey,
    required this.newItemsLabel,
    required this.child,
    this.edge = LiveListEdge.bottom,
    this.querySignature = '',
  });

  final ScrollController controller;
  final int itemCount;
  final Object? newestItemKey;
  final String newItemsLabel;
  final Widget child;
  final LiveListEdge edge;
  final String querySignature;

  @override
  State<LiveEdgeScrollAddon> createState() => _LiveEdgeScrollAddonState();
}

class _LiveEdgeScrollAddonState extends State<LiveEdgeScrollAddon> {
  static const double _edgeThreshold = 48;

  bool _pinnedToEdge = true;
  bool _hasNewItems = false;
  int _previousCount = 0;
  Object? _previousNewestKey;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onScroll);
    _previousCount = widget.itemCount;
    _previousNewestKey = widget.newestItemKey;
  }

  @override
  void didUpdateWidget(covariant LiveEdgeScrollAddon oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.controller != oldWidget.controller) {
      oldWidget.controller.removeListener(_onScroll);
      widget.controller.addListener(_onScroll);
    }

    final queryChanged = widget.querySignature != oldWidget.querySignature;
    if (queryChanged) {
      _hasNewItems = false;
      _previousCount = widget.itemCount;
      _previousNewestKey = widget.newestItemKey;
      return;
    }

    final arrived =
        widget.itemCount > _previousCount &&
        widget.itemCount > 0 &&
        _previousCount > 0 &&
        widget.newestItemKey != _previousNewestKey;

    _previousCount = widget.itemCount;
    _previousNewestKey = widget.newestItemKey;

    if (!arrived) {
      if (widget.itemCount == 0) {
        _hasNewItems = false;
      }
      return;
    }

    if (_pinnedToEdge) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !widget.controller.hasClients) return;
        _jumpToLiveEdge();
        if (_hasNewItems) {
          setState(() => _hasNewItems = false);
        }
      });
      return;
    }

    if (widget.edge == LiveListEdge.top) {
      final previousExtent = widget.controller.hasClients
          ? widget.controller.position.maxScrollExtent
          : 0.0;
      final previousOffset = widget.controller.hasClients
          ? widget.controller.offset
          : 0.0;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !widget.controller.hasClients) return;
        final delta =
            widget.controller.position.maxScrollExtent - previousExtent;
        if (delta > 0) {
          widget.controller.jumpTo(previousOffset + delta);
        }
        if (!_hasNewItems) {
          setState(() => _hasNewItems = true);
        }
      });
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (!_hasNewItems) {
        setState(() => _hasNewItems = true);
      }
    });
  }

  bool _isAtLiveEdge() {
    if (!widget.controller.hasClients) return true;
    final position = widget.controller.position;
    if (widget.edge == LiveListEdge.top) {
      return position.pixels <= _edgeThreshold;
    }
    return position.pixels >= position.maxScrollExtent - _edgeThreshold;
  }

  void _onScroll() {
    if (!widget.controller.hasClients) return;
    final atEdge = _isAtLiveEdge();
    if (atEdge == _pinnedToEdge && !(atEdge && _hasNewItems)) return;

    setState(() {
      _pinnedToEdge = atEdge;
      if (atEdge) {
        _hasNewItems = false;
      }
    });
  }

  void _jumpToLiveEdge() {
    if (!widget.controller.hasClients) return;
    if (widget.edge == LiveListEdge.top) {
      widget.controller.jumpTo(0);
    } else {
      widget.controller.jumpTo(widget.controller.position.maxScrollExtent);
    }
  }

  Future<void> _scrollToLiveEdge() async {
    if (!widget.controller.hasClients) return;
    final target = widget.edge == LiveListEdge.top
        ? 0.0
        : widget.controller.position.maxScrollExtent;
    await widget.controller.animateTo(
      target,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
    if (!mounted) return;
    setState(() {
      _pinnedToEdge = true;
      _hasNewItems = false;
    });
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onScroll);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        NewItemsFloatingButton(
          visible: _hasNewItems,
          label: widget.newItemsLabel,
          edge: widget.edge,
          onPressed: _scrollToLiveEdge,
        ),
      ],
    );
  }
}
