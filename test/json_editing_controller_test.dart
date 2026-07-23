import 'package:flutter_test/flutter_test.dart';
import 'package:infospect/features/network/breakpoints/ui/json_editing_controller.dart';

void main() {
  group('findJsonParseIssue', () {
    test('returns null for valid JSON', () {
      expect(findJsonParseIssue('{"a":1}'), isNull);
      expect(findJsonParseIssue('[1, 2, 3]'), isNull);
    });

    test('returns an issue with offset for invalid JSON', () {
      const text = '{\n  "a": 1,\n}';
      final issue = findJsonParseIssue(text);
      expect(issue, isNotNull);
      expect(issue!.offset, greaterThanOrEqualTo(0));
      expect(issue.offset, lessThanOrEqualTo(text.length));
      expect(issue.length, greaterThan(0));
      expect(issue.message, isNotEmpty);
    });

    test('lineNumberForOffset maps offsets to 1-based lines', () {
      const text = '{\n  "a": 1\n}';
      expect(lineNumberForOffset(text, 0), 1);
      expect(lineNumberForOffset(text, 2), 2);
      expect(lineNumberForOffset(text, text.length - 1), 3);
    });
  });

  group('findMatchingBracket', () {
    test('matches object braces from an opening brace', () {
      const text = '{"a":[1,2]}';
      final match = findMatchingBracket(text, 0);
      expect(match, isNotNull);
      expect(match!.open, 0);
      expect(match.close, text.length - 1);
    });

    test('matches nested array brackets', () {
      const text = '{"a":[1,2]}';
      final openIndex = text.indexOf('[');
      final match = findMatchingBracket(text, openIndex);
      expect(match, isNotNull);
      expect(match!.open, openIndex);
      expect(match.close, text.indexOf(']'));
    });

    test('matches when caret is just after an opening brace', () {
      const text = '{ "x": 1 }';
      final match = findMatchingBracket(text, 1);
      expect(match, isNotNull);
      expect(match!.open, 0);
      expect(match.close, text.length - 1);
    });

    test('ignores brackets inside strings', () {
      const text = '{"a":"hello{world}"}';
      final match = findMatchingBracket(text, 0);
      expect(match, isNotNull);
      expect(match!.close, text.length - 1);
      // Cursor on the brace inside the string should not pair with root.
      final inside = text.indexOf('{', 1);
      expect(findMatchingBracket(text, inside), isNull);
    });
  });
}
