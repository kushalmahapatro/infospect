import 'package:flutter/material.dart';
import 'package:infospect/features/logger/models/infospect_log.dart';
import 'package:infospect/features/logger/ui/logs_list/utils/log_helper.dart';
import 'package:infospect/utils/common_widgets/highlight_text_widget.dart';

class LogItemWidget extends StatelessWidget {
  const LogItemWidget(
      {super.key, required this.log, required this.searchedText});

  final InfospectLog log;
  final String searchedText;

  @override
  Widget build(BuildContext context) {
    final logData = getIconAndColor(log.level);

    final style = TextStyle(color: logData.color, fontSize: 14, height: 1);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(logData.icon, color: logData.color, size: 16),
          const SizedBox(width: 4),
          Expanded(
              child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// Message
              _MessageWidget(
                style: style,
                log: log,
                searchedText: searchedText,
              ),

              /// Error
              _ErrorWidget(
                style: style,
                error: log.error,
                searchedText: searchedText,
              ),

              /// StackTrace
              _StackTraceWidget(
                style: style,
                stackTrace: log.stackTrace,
                searchedText: searchedText,
              ),
            ],
          )),
        ],
      ),
    );
  }
}

class _MessageWidget extends StatelessWidget {
  const _MessageWidget({
    required this.style,
    required this.log,
    required this.searchedText,
  });

  final TextStyle style;
  final InfospectLog log;
  final String searchedText;

  @override
  Widget build(BuildContext context) {
    final rawTimestamp = log.timestamp.toString();
    final timeStartIndex = rawTimestamp.indexOf(' ') + 1;
    final formattedTimestamp = '${rawTimestamp.substring(timeStartIndex)}:';
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        HighlightText(
          text: formattedTimestamp,
          style: style.copyWith(
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
        HighlightText(
          text: ' ${log.message}',
          highlight: searchedText,
          style: style,
          ignoreCase: true,
        ),
      ],
    );
  }
}

class _ErrorWidget extends StatelessWidget {
  const _ErrorWidget({
    required this.style,
    required this.error,
    required this.searchedText,
  });

  final TextStyle style;
  final dynamic error;
  final String searchedText;

  @override
  Widget build(BuildContext context) {
    final errorText = stringifiedLog(error);
    if (errorText == null) {
      return const SizedBox.shrink();
    }
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        HighlightText(
          text: 'Error: ',
          style: style.copyWith(fontWeight: FontWeight.bold),
        ),
        HighlightText(
          text: errorText,
          highlight: searchedText,
          style: style,
          ignoreCase: true,
        ),
      ],
    );
  }
}

class _StackTraceWidget extends StatelessWidget {
  const _StackTraceWidget({
    required this.style,
    required this.stackTrace,
    required this.searchedText,
  });

  final TextStyle style;
  final StackTrace? stackTrace;
  final String searchedText;

  @override
  Widget build(BuildContext context) {
    final stacktrace = stringifiedLog(stackTrace);

    if (stacktrace == null) {
      return const SizedBox.shrink();
    }
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.start,
      children: [
        HighlightText(
          text: 'Stack Trace:',
          style: style.copyWith(fontWeight: FontWeight.bold),
        ),
        HighlightText(
          text: stacktrace,
          highlight: searchedText,
          style: style,
          ignoreCase: true,
        ),
      ],
    );
  }
}
