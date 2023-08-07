import 'package:flutter/material.dart';

class HighlightText extends StatelessWidget {
  final String text;
  final String? highlight;
  final TextStyle? style;
  final TextStyle? highlightStyle;
  final Color? highlightColor;
  final bool ignoreCase;
  final bool selectable;

  const HighlightText({
    super.key,
    required this.text,
    this.highlight,
    this.style,
    this.highlightColor = Colors.yellow,
    this.highlightStyle,
    this.ignoreCase = false,
    this.selectable = true,
  });

  @override
  Widget build(BuildContext context) {
    if ((highlight?.isEmpty ?? true) || text.isEmpty) {
      return selectable
          ? SelectableText(text, style: style)
          : Text(text, style: style);
    }

    final String sourceText = ignoreCase ? text.toLowerCase() : text;
    final String targetHighlight =
        ignoreCase ? highlight!.toLowerCase() : highlight!;

    List<TextSpan> spans = [];
    int start = 0;
    int indexOfHighlight;
    do {
      indexOfHighlight = sourceText.indexOf(targetHighlight, start);
      if (indexOfHighlight < 0) {
        // no highlight
        spans.add(_normalSpan(text.substring(start)));
        break;
      }
      if (indexOfHighlight > start) {
        spans.add(_normalSpan(text.substring(start, indexOfHighlight)));
      }
      start = indexOfHighlight + highlight!.length;
      spans.add(_highlightSpan(text.substring(indexOfHighlight, start)));
    } while (true);

    return selectable
        ? SelectableText.rich(TextSpan(children: spans))
        : Text.rich(TextSpan(children: spans));
  }

  TextSpan _highlightSpan(String content) {
    return TextSpan(
      text: content,
      style: highlightStyle ??
          style?.copyWith(backgroundColor: highlightColor) ??
          TextStyle(backgroundColor: highlightColor),
    );
  }

  TextSpan _normalSpan(String content) {
    return TextSpan(text: content, style: style);
  }
}
