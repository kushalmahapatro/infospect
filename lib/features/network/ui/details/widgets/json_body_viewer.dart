import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_json_view/flutter_json_view.dart';
import 'package:infospect/features/network/models/infospect_network_call.dart';
import 'package:infospect/features/network/ui/details/screen/network_body_window_screen.dart';
import 'package:infospect/features/network/ui/raw_data_viewer/models/raw_data_view.dart';
import 'package:infospect/features/network/ui/raw_data_viewer/widgets/json_viewer_desktop_toolbar.dart';
import 'package:infospect/helpers/infospect_helper.dart';
import 'package:infospect/utils/infospect_util.dart';

/// Renders JSON request/response bodies with beautify and foldable tree modes,
/// plus an option to open the content in a new desktop window.
class JsonBodyViewer extends StatefulWidget {
  const JsonBodyViewer({
    super.key,
    required this.data,
    this.windowTitle = 'Body',
    this.showOpenInWindow = true,
    this.initialView = RawDataView.beautified,
    this.call,
    this.kind,
  });

  final Map<String, dynamic> data;
  final String windowTitle;
  final bool showOpenInWindow;
  final RawDataView initialView;

  /// When set with [kind], popout opens a full call-details window.
  final InfospectNetworkCall? call;
  final NetworkBodyKind? kind;

  @override
  State<JsonBodyViewer> createState() => _JsonBodyViewerState();
}

class _JsonBodyViewerState extends State<JsonBodyViewer> {
  late RawDataView _view;
  String _searchValue = '';

  @override
  void initState() {
    super.initState();
    _view = widget.initialView;
  }

  bool get _canOpenInWindow =>
      widget.showOpenInWindow && !kIsWeb && InfospectUtil.isDesktop;

  void _openInWindow() {
    final call = widget.call;
    final kind = widget.kind;
    if (call != null && kind != null) {
      Infospect.instance.openNetworkBodyInNewWindow(
        call: call,
        kind: kind,
        detailsInitiallyExpanded: false,
      );
      return;
    }
    Infospect.instance.openRawDataInNewWindow(
      data: widget.data,
      title: widget.windowTitle,
    );
  }

  void _copyBody(BuildContext context) {
    final text = InfospectUtil.encoder.convert(widget.data);
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.maybeOf(context)?.showSnackBar(
      const SnackBar(
        content: Text('Body copied'),
        duration: Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final borderColor =
        theme.colorScheme.outlineVariant.withValues(alpha: 0.55);

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: borderColor),
        color: theme.colorScheme.surface,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            JsonViewerDesktopToolbar(
              view: _view,
              onViewChanged: (view) => setState(() => _view = view),
              showSearch: _view == RawDataView.beautified,
              searchValue: _searchValue,
              onSearchChanged: (value) => setState(() => _searchValue = value),
              showCopy: widget.data.isNotEmpty,
              onCopy: () => _copyBody(context),
              showOpenInWindow: _canOpenInWindow,
              onOpenInWindow: _openInWindow,
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                child: _view == RawDataView.beautified
                    ? SingleChildScrollView(
                        child: _BeautifiedBody(
                          data: widget.data,
                          searchValue: _searchValue,
                        ),
                      )
                    : JsonView.map(
                        widget.data,
                        theme: _jsonTheme(theme),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  JsonViewTheme _jsonTheme(ThemeData theme) {
    return JsonViewTheme(
      backgroundColor: theme.colorScheme.surface,
      defaultTextStyle: theme.textTheme.bodySmall!.copyWith(
        fontFamily: 'monospace',
        fontSize: 12,
      ),
      keyStyle: theme.textTheme.bodySmall!.copyWith(
        fontFamily: 'monospace',
        fontSize: 12,
        fontWeight: FontWeight.w600,
      ),
      stringStyle: theme.textTheme.bodySmall!.copyWith(
        fontFamily: 'monospace',
        fontSize: 12,
      ),
      boolStyle: theme.textTheme.bodySmall!.copyWith(
        fontFamily: 'monospace',
        fontSize: 12,
      ),
      closeIcon: Icon(
        Icons.keyboard_arrow_right,
        size: 16,
        color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
      ),
      openIcon: Icon(
        Icons.keyboard_arrow_down,
        size: 16,
        color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
      ),
      separator: Text(
        ' : ',
        style: theme.textTheme.bodySmall?.copyWith(
          fontFamily: 'monospace',
          fontSize: 12,
          color: theme.colorScheme.onSurface.withValues(alpha: 0.45),
        ),
      ),
    );
  }
}

class _BeautifiedBody extends StatelessWidget {
  const _BeautifiedBody({
    required this.data,
    required this.searchValue,
  });

  final Map<String, dynamic> data;
  final String searchValue;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final text = InfospectUtil.encoder.convert(data);
    final style = theme.textTheme.bodySmall?.copyWith(
      fontFamily: 'monospace',
      fontSize: 12,
      height: 1.45,
    );

    if (searchValue.isEmpty) {
      return SelectableText(text, style: style);
    }

    return SelectableText.rich(
      _highlightSpans(text, searchValue, style, theme),
      style: style,
    );
  }

  TextSpan _highlightSpans(
    String text,
    String query,
    TextStyle? style,
    ThemeData theme,
  ) {
    final lowerText = text.toLowerCase();
    final lowerQuery = query.toLowerCase();
    final spans = <TextSpan>[];
    var start = 0;

    while (true) {
      final index = lowerText.indexOf(lowerQuery, start);
      if (index < 0) {
        spans.add(TextSpan(text: text.substring(start)));
        break;
      }
      if (index > start) {
        spans.add(TextSpan(text: text.substring(start, index)));
      }
      spans.add(
        TextSpan(
          text: text.substring(index, index + query.length),
          style: style?.copyWith(
            backgroundColor:
                theme.colorScheme.primary.withValues(alpha: 0.25),
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
      start = index + query.length;
    }

    return TextSpan(style: style, children: spans);
  }
}
