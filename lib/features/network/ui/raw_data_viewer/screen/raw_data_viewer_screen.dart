import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_json_view/flutter_json_view.dart';
import 'package:infospect/features/network/ui/raw_data_viewer/notifier/raw_data_viewer_notifier.dart';
import 'package:infospect/features/network/ui/raw_data_viewer/models/raw_data_view.dart';
import 'package:infospect/features/network/ui/raw_data_viewer/widgets/json_viewer_desktop_toolbar.dart';
import 'package:infospect/infospect.dart';
import 'package:infospect/utils/infospect_util.dart';

class RawDataViewerScreen extends StatefulWidget {
  final Map<String, dynamic> data;
  final bool beautificationRequired;
  final RawDataViewerNotifier notifier;
  final String title;

  /// When true, this screen is hosted in its own desktop window — hide
  /// navigation chrome and the open-in-new-window action.
  final bool standaloneWindow;

  const RawDataViewerScreen({
    super.key,
    required this.data,
    this.beautificationRequired = false,
    required this.notifier,
    this.title = 'Raw Data',
    this.standaloneWindow = false,
  });

  @override
  State<RawDataViewerScreen> createState() => _RawDataViewerScreenState();
}

class _RawDataViewerScreenState extends State<RawDataViewerScreen> {
  @override
  void initState() {
    super.initState();
    widget.notifier.addListener(_onNotifierChanged);
  }

  void _onNotifierChanged() {
    setState(() {});
  }

  @override
  void dispose() {
    widget.notifier.removeListener(_onNotifierChanged);
    widget.notifier.dispose();
    super.dispose();
  }

  bool get _isDesktop => !kIsWeb && InfospectUtil.isDesktop;

  bool get _canOpenInWindow =>
      _isDesktop && !widget.standaloneWindow;

  bool get _useDesktopChrome => _isDesktop || widget.standaloneWindow;

  @override
  Widget build(BuildContext context) {
    if (_useDesktopChrome) {
      return _buildDesktop(context);
    }
    return _buildMobile(context);
  }

  Widget _buildDesktop(BuildContext context) {
    final theme = Theme.of(context);
    final canToggle = widget.beautificationRequired;
    final showSearch =
        canToggle && widget.notifier.view == RawDataView.beautified;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          JsonViewerDesktopToolbar(
            title: widget.standaloneWindow ? null : widget.title,
            view: widget.notifier.view,
            onViewChanged: widget.notifier.changeView,
            showViewToggle: canToggle,
            showSearch: showSearch,
            searchValue: widget.notifier.searchValue,
            onSearchChanged: widget.notifier.changeSearchValue,
            showOpenInWindow: _canOpenInWindow,
            onOpenInWindow: () => Infospect.instance.openRawDataInNewWindow(
              data: widget.data,
              title: widget.title,
              beautificationRequired: widget.beautificationRequired,
            ),
          ),
          Expanded(child: _buildBody(context)),
        ],
      ),
    );
  }

  Widget _buildMobile(BuildContext context) {
    final canToggle = widget.beautificationRequired;
    final showSearch =
        canToggle && widget.notifier.view == RawDataView.beautified;

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: Text(widget.title),
      ),
      body: Column(
        children: [
          if (canToggle || showSearch)
            JsonViewerDesktopToolbar(
              view: widget.notifier.view,
              onViewChanged: widget.notifier.changeView,
              showViewToggle: canToggle,
              showSearch: showSearch,
              searchValue: widget.notifier.searchValue,
              onSearchChanged: widget.notifier.changeSearchValue,
            ),
          Expanded(child: _buildBody(context)),
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    final theme = Theme.of(context);

    if (widget.notifier.view == RawDataView.beautified) {
      if (widget.beautificationRequired) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          child: HighlightText(
            style: theme.textTheme.bodySmall?.copyWith(
              fontFamily: 'monospace',
              fontSize: 12,
              height: 1.45,
            ),
            text: InfospectUtil.encoder.convert(widget.data),
            highlight: widget.notifier.searchValue,
            ignoreCase: true,
            highlightColor:
                theme.colorScheme.primary.withValues(alpha: 0.22),
          ),
        );
      }

      return ListView(
        padding: const EdgeInsets.all(12),
        children: widget.data.entries
            .map(
              (e) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      e.key,
                      style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    SelectableText(
                      e.value.toString(),
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontFamily: 'monospace',
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            )
            .toList(),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
      child: JsonView.map(
        widget.data,
        theme: JsonViewTheme(
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
        ),
      ),
    );
  }
}
