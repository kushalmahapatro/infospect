import 'package:flutter/material.dart';
import 'package:infospect/utils/extensions/double_extension.dart';

extension IntExtension on int {
  String get toReadableTime {
    if (this < 0) {
      return "-1 ms";
    }
    if (this <= 1000) {
      return "$this ms";
    }
    if (this <= 60000) {
      return "${(this / 1000).formattedString} s";
    }

    final Duration duration = Duration(milliseconds: this);

    return "${duration.inMinutes} min ${duration.inSeconds.remainder(60)} s "
        "${duration.inMilliseconds.remainder(1000)} ms";
  }

  String get toReadableBytes {
    if (this < 0) {
      return "-1 B";
    }
    if (this <= 1000) {
      return "$this B";
    }
    if (this <= 1000000) {
      return "${(this / 1000).formattedString} kB";
    }

    return "${(this / 1000000).formattedString} MB";
  }

  String get formatTimeUnit {
    return (this < 10) ? "0$this" : "$this";
  }

  Color? getStatusTextColor(BuildContext context) {
    if (this == -1) {
      return Colors.red[400];
    } else if (this < 200) {
      return Theme.of(context).textTheme.bodyLarge!.color;
    } else if (this >= 200 && this < 300) {
      return Colors.green[400];
    } else if (this >= 300 && this < 400) {
      return Colors.orange[400];
    } else if (this >= 400 && this < 600) {
      return Colors.red[400];
    } else {
      return Theme.of(context).textTheme.bodyLarge!.color;
    }
  }
}
