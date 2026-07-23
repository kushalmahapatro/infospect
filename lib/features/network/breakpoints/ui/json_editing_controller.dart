import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Location of a JSON syntax problem inside editor text.
class JsonParseIssue {
  const JsonParseIssue({
    required this.offset,
    required this.length,
    required this.message,
  });

  final int offset;
  final int length;
  final String message;

  int get end => offset + length;
}

/// Matching brace/bracket pair indexes (inclusive character positions).
class JsonBracketMatch {
  const JsonBracketMatch({required this.open, required this.close});

  final int open;
  final int close;
}

/// [TextEditingController] with JSON syntax colors, error underlines, and
/// bracket-pair highlighting at the caret.
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

    final issue = findJsonParseIssue(text);
    final match = findMatchingBracket(text, value.selection.baseOffset);
    final errorColor = theme.colorScheme.error;
    final matchColor = theme.colorScheme.primary.withValues(alpha: 0.22);

    final spans = <InlineSpan>[];
    var start = 0;

    void emit(int from, int to, TextStyle tokenStyle) {
      if (from >= to) return;
      var cursor = from;
      while (cursor < to) {
        var next = to;
        TextStyle styleForRun = tokenStyle;

        if (issue != null) {
          final errStart = issue.offset.clamp(0, text.length);
          final errEnd = issue.end.clamp(0, text.length);
          if (cursor < errEnd && next > errStart) {
            if (cursor < errStart) {
              next = errStart;
            } else {
              next = math.min(next, errEnd);
              styleForRun = tokenStyle.copyWith(
                decoration: TextDecoration.underline,
                decorationColor: errorColor,
                decorationStyle: TextDecorationStyle.wavy,
                decorationThickness: 1.6,
                color: errorColor,
              );
            }
          }
        }

        if (match != null) {
          for (final index in [match.open, match.close]) {
            if (cursor <= index && index < next) {
              if (cursor < index) {
                next = index;
              } else {
                next = index + 1;
                styleForRun = styleForRun.copyWith(
                  backgroundColor: matchColor,
                  fontWeight: FontWeight.w800,
                  color: theme.colorScheme.primary,
                );
              }
              break;
            }
          }
        }

        spans.add(
          TextSpan(
            text: text.substring(cursor, next),
            style: styleForRun,
          ),
        );
        cursor = next;
      }
    }

    for (final tokenMatch in _tokenPattern.allMatches(text)) {
      if (tokenMatch.start > start) {
        emit(start, tokenMatch.start, base);
      }
      final token = tokenMatch.group(0)!;
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
      emit(tokenMatch.start, tokenMatch.end, tokenStyle);
      start = tokenMatch.end;
    }
    if (start < text.length) {
      emit(start, text.length, base);
    }

    return TextSpan(style: base, children: spans);
  }
}

/// Parses [text] and returns a [JsonParseIssue] when `jsonDecode` fails.
JsonParseIssue? findJsonParseIssue(String text) {
  final trimmed = text.trim();
  if (trimmed.isEmpty) return null;
  try {
    jsonDecode(text);
    return null;
  } on FormatException catch (e) {
    final rawOffset = e.offset;
    final offset = (rawOffset ?? _fallbackErrorOffset(text)).clamp(0, text.length);
    // Underline a short window around the failure point.
    final length = _errorUnderlineLength(text, offset);
    return JsonParseIssue(
      offset: offset,
      length: length,
      message: e.message,
    );
  } catch (e) {
    return JsonParseIssue(
      offset: 0,
      length: math.min(1, text.length),
      message: e.toString(),
    );
  }
}

/// Finds the matching `{}` / `[]` pair for the caret at [cursor].
///
/// Looks at the character under the caret, or the one immediately before it
/// (so a caret after `{` still matches). Brackets inside JSON strings are
/// ignored.
JsonBracketMatch? findMatchingBracket(String text, int cursor) {
  if (text.isEmpty) return null;
  final positions = <int>[];
  if (cursor >= 0 && cursor < text.length) positions.add(cursor);
  if (cursor > 0 && cursor <= text.length) positions.add(cursor - 1);

  for (final pos in positions) {
    if (pos < 0 || pos >= text.length) continue;
    if (_isInsideJsonString(text, pos)) continue;
    final ch = text[pos];
    if (ch == '{' || ch == '[') {
      final close = _scanForward(text, pos, ch, ch == '{' ? '}' : ']');
      if (close != null) return JsonBracketMatch(open: pos, close: close);
    } else if (ch == '}' || ch == ']') {
      final open = _scanBackward(text, pos, ch == '}' ? '{' : '[', ch);
      if (open != null) return JsonBracketMatch(open: open, close: pos);
    }
  }
  return null;
}

/// 1-based line number for [offset], or `null` when unknown.
int? lineNumberForOffset(String text, int? offset) {
  if (offset == null || offset < 0) return null;
  final clamped = offset.clamp(0, text.length);
  return '\n'.allMatches(text.substring(0, clamped)).length + 1;
}

int _fallbackErrorOffset(String text) {
  // Prefer the first clearly broken structural char near the end.
  for (var i = text.length - 1; i >= 0; i--) {
    final ch = text[i];
    if (ch == ',' || ch == ':' || ch == '{' || ch == '[' || ch == '"') {
      return i;
    }
  }
  return math.max(0, text.length - 1);
}

bool _isInsideJsonString(String text, int index) {
  var inString = false;
  var escape = false;
  for (var i = 0; i < index; i++) {
    final ch = text[i];
    if (!inString) {
      if (ch == '"') inString = true;
      continue;
    }
    if (escape) {
      escape = false;
      continue;
    }
    if (ch == '\\') {
      escape = true;
      continue;
    }
    if (ch == '"') inString = false;
  }
  return inString;
}

int _errorUnderlineLength(String text, int offset) {
  if (text.isEmpty) return 0;
  if (offset >= text.length) return 1;
  // Stretch across a token-ish run so the wavy underline is visible.
  var end = offset + 1;
  while (end < text.length && end - offset < 24) {
    final ch = text[end];
    if (ch == '\n' || ch == ',' || ch == '}' || ch == ']') break;
    end++;
  }
  return math.max(1, end - offset);
}

int? _scanForward(String text, int openIndex, String open, String close) {
  var depth = 0;
  var inString = false;
  var escape = false;
  for (var i = openIndex; i < text.length; i++) {
    final ch = text[i];
    if (inString) {
      if (escape) {
        escape = false;
      } else if (ch == '\\') {
        escape = true;
      } else if (ch == '"') {
        inString = false;
      }
      continue;
    }
    if (ch == '"') {
      inString = true;
      continue;
    }
    if (ch == open) {
      depth++;
    } else if (ch == close) {
      depth--;
      if (depth == 0) return i;
    }
  }
  return null;
}

int? _scanBackward(String text, int closeIndex, String open, String close) {
  var depth = 0;
  var inString = false;
  // Scan backward; string handling is approximate but good enough for JSON.
  for (var i = closeIndex; i >= 0; i--) {
    final ch = text[i];
    if (inString) {
      if (ch == '"') {
        // Count preceding backslashes.
        var slashes = 0;
        var j = i - 1;
        while (j >= 0 && text[j] == '\\') {
          slashes++;
          j--;
        }
        if (slashes.isEven) inString = false;
      }
      continue;
    }
    if (ch == '"') {
      inString = true;
      continue;
    }
    if (ch == close) {
      depth++;
    } else if (ch == open) {
      depth--;
      if (depth == 0) return i;
    }
  }
  return null;
}
