import 'package:infospect/utils/extensions/int_extension.dart';

extension DateTimeExtension on DateTime {
  /// Compact wall-clock time for network list rows: `HH:mm:ss.SSS`.
  String get formatTime {
    return '${hour.formatTimeUnit}:'
        '${minute.formatTimeUnit}:'
        '${second.formatTimeUnit}.'
        '${millisecond.toString().padLeft(3, '0')}';
  }

  /// Full local timestamp for tooltips: `yyyy-MM-dd HH:mm:ss.SSS`.
  String get formatTimestamp {
    final y = year.toString().padLeft(4, '0');
    final mo = month.formatTimeUnit;
    final d = day.formatTimeUnit;
    return '$y-$mo-$d $formatTime';
  }
}
