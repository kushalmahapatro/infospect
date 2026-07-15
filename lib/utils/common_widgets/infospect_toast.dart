import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:infospect/utils/infospect_util.dart';

/// Compact feedback toast.
///
/// On desktop, shows a top-right floating notification (native-app style).
/// On mobile / web, falls back to a short floating [SnackBar].
class InfospectToast {
  InfospectToast._();

  static OverlayEntry? _desktopEntry;
  static Timer? _desktopTimer;

  /// Shows [message] using a desktop toast or mobile snackbar.
  static void show(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 2),
    IconData? icon,
  }) {
    final useDesktop = !kIsWeb && InfospectUtil.isDesktop;
    if (useDesktop) {
      _showDesktop(context, message, duration: duration, icon: icon);
      return;
    }
    _showMobileSnackBar(context, message, duration: duration);
  }

  static void _showMobileSnackBar(
    BuildContext context,
    String message, {
    required Duration duration,
  }) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        duration: duration,
      ),
    );
  }

  static void _showDesktop(
    BuildContext context,
    String message, {
    required Duration duration,
    IconData? icon,
  }) {
    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    if (overlay == null) {
      _showMobileSnackBar(context, message, duration: duration);
      return;
    }

    _desktopTimer?.cancel();
    _desktopEntry?.remove();
    _desktopEntry = null;

    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (ctx) {
        final theme = Theme.of(context);
        final border = theme.colorScheme.outlineVariant.withValues(alpha: 0.55);
        return Positioned(
          top: 12,
          right: 12,
          child: _DesktopToastCard(
            message: message,
            icon: icon,
            borderColor: border,
            onDismiss: () {
              if (_desktopEntry == entry) {
                _dismissDesktop();
              }
            },
          ),
        );
      },
    );

    _desktopEntry = entry;
    overlay.insert(entry);
    _desktopTimer = Timer(duration, () {
      if (_desktopEntry == entry) {
        _dismissDesktop();
      }
    });
  }

  static void _dismissDesktop() {
    _desktopTimer?.cancel();
    _desktopTimer = null;
    _desktopEntry?.remove();
    _desktopEntry = null;
  }
}

class _DesktopToastCard extends StatefulWidget {
  const _DesktopToastCard({
    required this.message,
    required this.borderColor,
    required this.onDismiss,
    this.icon,
  });

  final String message;
  final Color borderColor;
  final VoidCallback onDismiss;
  final IconData? icon;

  @override
  State<_DesktopToastCard> createState() => _DesktopToastCardState();
}

class _DesktopToastCardState extends State<_DesktopToastCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Offset> _slide;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
      reverseDuration: const Duration(milliseconds: 120),
    );
    _slide = Tween<Offset>(
      begin: const Offset(0.12, -0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _close() async {
    if (!mounted) return;
    await _controller.reverse();
    widget.onDismiss();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: _close,
        child: FadeTransition(
          opacity: _fade,
          child: SlideTransition(
            position: _slide,
            child: Material(
              elevation: 6,
              shadowColor: Colors.black.withValues(alpha: 0.18),
              color: theme.colorScheme.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                constraints: const BoxConstraints(minWidth: 200, maxWidth: 360),
                padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: widget.borderColor),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      widget.icon ?? Icons.check_circle_outline_rounded,
                      size: 16,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        widget.message,
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontSize: 12,
                          height: 1.25,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    IconButton(
                      tooltip: 'Dismiss',
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 24,
                        minHeight: 24,
                      ),
                      iconSize: 14,
                      onPressed: _close,
                      icon: Icon(
                        Icons.close_rounded,
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.45),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
