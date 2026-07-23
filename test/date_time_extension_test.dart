import 'package:flutter_test/flutter_test.dart';
import 'package:infospect/utils/extensions/date_time_extension.dart';

void main() {
  test('formatTime uses HH:mm:ss.SSS', () {
    final time = DateTime(2026, 7, 17, 9, 5, 7, 42);
    expect(time.formatTime, '09:05:07.042');
  });

  test('formatTimestamp includes the local date', () {
    final time = DateTime(2026, 7, 17, 9, 5, 7, 42);
    expect(time.formatTimestamp, '2026-07-17 09:05:07.042');
  });
}
