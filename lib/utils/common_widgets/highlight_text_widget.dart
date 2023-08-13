import 'package:flutter/material.dart';
import 'package:infospect/utils/common_widgets/conditional_widget.dart';

class HighlightText extends StatelessWidget {
  final String text;
  final String? highlight;
  final TextStyle? style;
  final TextStyle? highlightStyle;
  final Color? highlightColor;
  final bool ignoreCase;
  final bool selectable;

  final int? maxLines;
  final TextOverflow? overflow;
  final bool? softWrap;

  const HighlightText({
    super.key,
    required this.text,
    this.highlight,
    this.style,
    this.highlightColor = const Color.fromRGBO(255, 255, 0, 0.3),
    this.highlightStyle,
    this.ignoreCase = false,
    this.selectable = true,
    this.maxLines,
    this.overflow,
    this.softWrap,
  });

  @override
  Widget build(BuildContext context) {
    if ((highlight?.isEmpty ?? true) || text.isEmpty) {
      return ConditionalWidget(
        condition: selectable,
        ifTrue: SelectableText(
          text,
          style: style,
          maxLines: maxLines,
        ),
        ifFalse: Text(
          text,
          style: style,
          maxLines: maxLines,
          overflow: overflow,
          softWrap: softWrap,
        ),
      );
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

    return ConditionalWidget(
      condition: selectable,
      ifTrue: SelectableText.rich(
        TextSpan(children: spans),
        maxLines: maxLines,
      ),
      ifFalse: Text.rich(
        TextSpan(children: spans),
        maxLines: maxLines,
        overflow: overflow,
        softWrap: softWrap,
      ),
    );
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
