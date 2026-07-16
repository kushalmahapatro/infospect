import 'package:flutter/material.dart';
import 'package:infospect/utils/common_widgets/highlight_text_widget.dart';

/// How an endpoint / URL should behave when it does not fit the available width.
enum InfospectEndpointOverflowMode {
  /// Grow to [maxLines] so the full path stays readable (mobile list rows).
  wrap,

  /// Keep a single compact line and allow horizontal scrubbing (desktop table).
  scroll,
}

/// Renders a network endpoint / URL without truncating with `…` when possible.
///
/// Short paths stay on one line. Longer ones either wrap (mobile) or scroll
/// horizontally (desktop) so the complete value remains reachable while the
/// surrounding list row stays compact.
class InfospectEndpointLabel extends StatelessWidget {
  const InfospectEndpointLabel({
    super.key,
    required this.text,
    this.highlight,
    this.style,
    this.mode = InfospectEndpointOverflowMode.wrap,
    this.maxLines = 2,
  });

  final String text;
  final String? highlight;
  final TextStyle? style;
  final InfospectEndpointOverflowMode mode;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    final label = HighlightText(
      text: text,
      highlight: (highlight == null || highlight!.isEmpty) ? null : highlight,
      ignoreCase: true,
      selectable: false,
      maxLines: mode == InfospectEndpointOverflowMode.wrap ? maxLines : 1,
      softWrap: mode == InfospectEndpointOverflowMode.wrap,
      overflow: mode == InfospectEndpointOverflowMode.wrap
          ? TextOverflow.fade
          : TextOverflow.visible,
      style: style,
    );

    final child = switch (mode) {
      InfospectEndpointOverflowMode.wrap => label,
      InfospectEndpointOverflowMode.scroll => SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: label,
        ),
    };

    return Tooltip(
      message: text,
      waitDuration: const Duration(milliseconds: 450),
      child: child,
    );
  }
}
