import 'package:flutter/material.dart';

/// [TextEditingController] that paints JSON with light syntax highlighting.
class JsonEditingController extends TextEditingController {
  JsonEditingController({super.text});

  static final RegExp _tokenPattern = RegExp(
    r'"(?:\\.|[^"\\])*"\s*:|' // key
    r'"(?:\\.|[^"\\])*"|' // string
    r'\btrue\b|\bfalse\b|\bnull\b|' // keywords
    r'-?\d+(?:\.\d+)?(?:[eE][+-]?\d+)?|' // number
    r'[{}\[\],:]', // punctuation
  );

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    final theme = Theme.of(context);
    final base = (style ?? const TextStyle()).copyWith(
      fontFamily: 'monospace',
      fontSize: style?.fontSize ?? 12,
      height: style?.height ?? 1.35,
      color: style?.color ?? theme.colorScheme.onSurface,
    );

    final keyStyle = base.copyWith(
      color: theme.colorScheme.primary,
      fontWeight: FontWeight.w600,
    );
    final stringStyle = base.copyWith(
      color: theme.brightness == Brightness.dark
          ? const Color(0xFFCE9178)
          : const Color(0xFFA31515),
    );
    final numberStyle = base.copyWith(
      color: theme.brightness == Brightness.dark
          ? const Color(0xFFB5CEA8)
          : const Color(0xFF098658),
    );
    final keywordStyle = base.copyWith(
      color: theme.brightness == Brightness.dark
          ? const Color(0xFF569CD6)
          : const Color(0xFF0000FF),
      fontWeight: FontWeight.w600,
    );
    final punctStyle = base.copyWith(
      color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
    );

    final text = value.text;
    if (text.isEmpty) {
      return TextSpan(style: base, text: '');
    }

    final spans = <InlineSpan>[];
    var start = 0;
    for (final match in _tokenPattern.allMatches(text)) {
      if (match.start > start) {
        spans.add(TextSpan(text: text.substring(start, match.start), style: base));
      }
      final token = match.group(0)!;
      final TextStyle tokenStyle;
      if (token.endsWith(':')) {
        tokenStyle = keyStyle;
      } else if (token.startsWith('"')) {
        tokenStyle = stringStyle;
      } else if (token == 'true' || token == 'false' || token == 'null') {
        tokenStyle = keywordStyle;
      } else if (RegExp(r'^-?\d').hasMatch(token)) {
        tokenStyle = numberStyle;
      } else {
        tokenStyle = punctStyle;
      }
      spans.add(TextSpan(text: token, style: tokenStyle));
      start = match.end;
    }
    if (start < text.length) {
      spans.add(TextSpan(text: text.substring(start), style: base));
    }

    return TextSpan(style: base, children: spans);
  }
}
