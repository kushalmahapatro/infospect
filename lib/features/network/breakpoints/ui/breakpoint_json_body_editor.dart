import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:infospect/features/network/breakpoints/infospect_breakpoint_manager.dart';
import 'package:infospect/features/network/breakpoints/ui/breakpoint_json_tree_editor.dart';
import 'package:infospect/features/network/breakpoints/ui/json_editing_controller.dart';
import 'package:infospect/utils/common_widgets/infospect_toast.dart';

enum BreakpointJsonEditorMode { text, tree }

/// Dual-mode JSON body editor: syntax-highlighted text + editable tree.
class BreakpointJsonBodyEditor extends StatefulWidget {
  const BreakpointJsonBodyEditor({
    super.key,
    required this.controller,
    this.initialMode,
  });

  final TextEditingController controller;

  /// Defaults to [BreakpointJsonEditorMode.tree] when the body is valid JSON.
  final BreakpointJsonEditorMode? initialMode;

  @override
  State<BreakpointJsonBodyEditor> createState() =>
      _BreakpointJsonBodyEditorState();
}

class _BreakpointJsonBodyEditorState extends State<BreakpointJsonBodyEditor> {
  BreakpointJsonEditorMode _mode = BreakpointJsonEditorMode.text;
  String? _error;
  int? _errorLine;
  bool? _isJson;
  dynamic _treeData;
  int _treeSession = 0;
  final ScrollController _textScroll = ScrollController();
  final ScrollController _gutterScroll = ScrollController();
  bool _syncingScroll = false;

  @override
  void initState() {
    super.initState();
    // Validate before attaching the listener so the first parse cannot race
    // with an uninitialized mode (e.g. non-JSON response bodies).
    _revalidate(notify: false);
    _mode = widget.initialMode ??
        (_isJson == true
            ? BreakpointJsonEditorMode.tree
            : BreakpointJsonEditorMode.text);
    if (_mode == BreakpointJsonEditorMode.tree && _treeData == null) {
      _mode = BreakpointJsonEditorMode.text;
    }
    widget.controller.addListener(_revalidate);
    _textScroll.addListener(_syncGutterToText);
  }

  @override
  void didUpdateWidget(covariant BreakpointJsonBodyEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_revalidate);
      widget.controller.addListener(_revalidate);
      _revalidate();
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_revalidate);
    _textScroll.removeListener(_syncGutterToText);
    _textScroll.dispose();
    _gutterScroll.dispose();
    super.dispose();
  }

  void _syncGutterToText() {
    if (_syncingScroll) return;
    if (!_gutterScroll.hasClients) return;
    _syncingScroll = true;
    _gutterScroll.jumpTo(
      _textScroll.offset.clamp(0.0, _gutterScroll.position.maxScrollExtent),
    );
    _syncingScroll = false;
  }

  void _revalidate({bool notify = true}) {
    final text = widget.controller.text;
    final trimmed = text.trim();
    if (trimmed.isEmpty) {
      _error = null;
      _errorLine = null;
      _isJson = null;
      _treeData = null;
      if (notify) setState(() {});
      return;
    }
    final issue = findJsonParseIssue(text);
    if (issue == null) {
      try {
        _treeData = jsonDecode(text);
      } catch (_) {
        _treeData = null;
      }
      _error = null;
      _errorLine = null;
      _isJson = true;
    } else {
      _error = issue.message;
      _errorLine = lineNumberForOffset(text, issue.offset);
      _isJson = false;
      _treeData = null;
      if (_mode == BreakpointJsonEditorMode.tree) {
        _mode = BreakpointJsonEditorMode.text;
      }
    }
    if (notify) setState(() {});
  }

  void _setMode(BreakpointJsonEditorMode mode) {
    if (mode == BreakpointJsonEditorMode.tree) {
      if (_isJson != true) {
        InfospectToast.show(
          context,
          'Fix JSON syntax to use the tree editor',
          icon: Icons.warning_amber_rounded,
        );
        return;
      }
      try {
        _treeData = jsonDecode(widget.controller.text);
      } catch (_) {
        return;
      }
      _treeSession++;
    } else if (_mode == BreakpointJsonEditorMode.tree && _treeData != null) {
      widget.controller.text =
          const JsonEncoder.withIndent('  ').convert(_treeData);
      widget.controller.selection =
          TextSelection.collapsed(offset: widget.controller.text.length);
    }
    setState(() => _mode = mode);
  }

  void _onTreeChanged(dynamic data) {
    _treeData = data;
    final encoded = const JsonEncoder.withIndent('  ').convert(data);
    if (widget.controller.text != encoded) {
      widget.controller.value = TextEditingValue(
        text: encoded,
        selection: TextSelection.collapsed(offset: encoded.length),
      );
    }
  }

  void _format() {
    final text = widget.controller.text.trim();
    if (text.isEmpty) return;
    try {
      final decoded = jsonDecode(text);
      widget.controller.text =
          const JsonEncoder.withIndent('  ').convert(decoded);
      widget.controller.selection =
          TextSelection.collapsed(offset: widget.controller.text.length);
      _revalidate();
    } catch (_) {
      _revalidate();
    }
  }

  void _minify() {
    final text = widget.controller.text.trim();
    if (text.isEmpty) return;
    try {
      final decoded = jsonDecode(text);
      widget.controller.text = jsonEncode(decoded);
      widget.controller.selection =
          TextSelection.collapsed(offset: widget.controller.text.length);
      _revalidate();
    } catch (_) {
      _revalidate();
    }
  }

  Future<void> _copy() async {
    final text = widget.controller.text;
    if (text.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    InfospectToast.show(
      context,
      'Body copied',
      duration: const Duration(seconds: 1),
      icon: Icons.copy_rounded,
    );
  }

  int get _lineCount {
    final text = widget.controller.text;
    if (text.isEmpty) return 1;
    return '\n'.allMatches(text).length + 1;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final border = theme.colorScheme.outlineVariant.withValues(alpha: 0.5);
    final statusColor = _isJson == null
        ? theme.colorScheme.onSurface.withValues(alpha: 0.45)
        : (_isJson!
            ? theme.colorScheme.primary
            : theme.colorScheme.error);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Material(
          color:
              theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
          child: SizedBox(
            height: 34,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Row(
                children: [
                  Flexible(
                    child: Text(
                      _isJson == null
                          ? 'Body'
                          : (_isJson! ? 'JSON' : 'Invalid JSON'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: statusColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    flex: 2,
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: SizedBox(
                          height: 26,
                          child: SegmentedButton<BreakpointJsonEditorMode>(
                            style: ButtonStyle(
                              visualDensity: VisualDensity.compact,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              textStyle: WidgetStatePropertyAll(
                                theme.textTheme.labelSmall
                                    ?.copyWith(fontSize: 10),
                              ),
                              padding: const WidgetStatePropertyAll(
                                EdgeInsets.symmetric(horizontal: 8),
                              ),
                            ),
                            segments: const [
                              ButtonSegment(
                                value: BreakpointJsonEditorMode.text,
                                label: Text('Text'),
                                icon: Icon(Icons.code_rounded, size: 14),
                              ),
                              ButtonSegment(
                                value: BreakpointJsonEditorMode.tree,
                                label: Text('Tree'),
                                icon: Icon(Icons.account_tree_outlined, size: 14),
                              ),
                            ],
                            selected: {_mode},
                            onSelectionChanged: (value) =>
                                _setMode(value.first),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const Spacer(),
                  if (_mode == BreakpointJsonEditorMode.text) ...[
                    _ToolButton(
                      tooltip: 'Format JSON',
                      icon: Icons.data_object_rounded,
                      onPressed: _isJson == true ? _format : null,
                    ),
                    _ToolButton(
                      tooltip: 'Minify JSON',
                      icon: Icons.compress_rounded,
                      onPressed: _isJson == true ? _minify : null,
                    ),
                  ],
                  _ToolButton(
                    tooltip: 'Copy',
                    icon: Icons.copy_rounded,
                    onPressed:
                        widget.controller.text.isEmpty ? null : _copy,
                  ),
                ],
              ),
            ),
          ),
        ),
        Divider(height: 1, color: border),
        if (_error != null && _isJson == false)
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 6, 10, 0),
            child: Text(
              _errorLine == null ? _error! : 'Line $_errorLine: $_error',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelSmall?.copyWith(
                fontSize: 10,
                color: theme.colorScheme.error,
              ),
            ),
          ),
        Expanded(
          child: _mode == BreakpointJsonEditorMode.tree && _treeData != null
              ? BreakpointJsonTreeEditor(
                  key: ValueKey(_treeSession),
                  data: _treeData,
                  onChanged: _onTreeChanged,
                )
              : _JsonTextPane(
                  controller: widget.controller,
                  textScroll: _textScroll,
                  gutterScroll: _gutterScroll,
                  lineCount: _lineCount,
                  isInvalid: _isJson == false,
                  errorLine: _errorLine,
                ),
        ),
      ],
    );
  }
}

class _JsonTextPane extends StatelessWidget {
  const _JsonTextPane({
    required this.controller,
    required this.textScroll,
    required this.gutterScroll,
    required this.lineCount,
    required this.isInvalid,
    this.errorLine,
  });

  final TextEditingController controller;
  final ScrollController textScroll;
  final ScrollController gutterScroll;
  final int lineCount;
  final bool isInvalid;
  final int? errorLine;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final gutterWidth = 12.0 + (math.max(2, '$lineCount'.length) * 7.0);
    const lineHeight = 12 * 1.35;

    return Padding(
      padding: const EdgeInsets.fromLTRB(6, 6, 8, 8),
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border.all(
            color: isInvalid
                ? theme.colorScheme.error
                : theme.colorScheme.outlineVariant.withValues(alpha: 0.55),
          ),
          borderRadius: BorderRadius.circular(4),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ColoredBox(
                color: theme.colorScheme.surfaceContainerHighest
                    .withValues(alpha: 0.45),
                child: SizedBox(
                  width: gutterWidth,
                  child: ListView.builder(
                    controller: gutterScroll,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: const EdgeInsets.only(top: 8, bottom: 8),
                    itemCount: lineCount,
                    itemExtent: lineHeight,
                    itemBuilder: (context, index) {
                      final line = index + 1;
                      final isError = errorLine == line;
                      return ColoredBox(
                        color: isError
                            ? theme.colorScheme.error.withValues(alpha: 0.12)
                            : Colors.transparent,
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: Text(
                              '$line',
                              style: theme.textTheme.labelSmall?.copyWith(
                                fontSize: 10,
                                height: 1.35,
                                fontFamily: 'monospace',
                                fontWeight:
                                    isError ? FontWeight.w700 : FontWeight.w400,
                                color: isError
                                    ? theme.colorScheme.error
                                    : theme.colorScheme.onSurface
                                        .withValues(alpha: 0.35),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              VerticalDivider(
                width: 1,
                thickness: 1,
                color: theme.colorScheme.outlineVariant.withValues(alpha: 0.45),
              ),
              Expanded(
                child: Actions(
                  actions: <Type, Action<Intent>>{
                    _IndentIntent: CallbackAction<_IndentIntent>(
                      onInvoke: (_) {
                        _insertAtCursor(controller, '  ');
                        return null;
                      },
                    ),
                    _SmartNewlineIntent: CallbackAction<_SmartNewlineIntent>(
                      onInvoke: (_) {
                        _insertSmartNewline(controller);
                        return null;
                      },
                    ),
                  },
                  child: Shortcuts(
                    shortcuts: const <ShortcutActivator, Intent>{
                      SingleActivator(LogicalKeyboardKey.tab): _IndentIntent(),
                      SingleActivator(LogicalKeyboardKey.enter):
                          _SmartNewlineIntent(),
                    },
                    child: TextField(
                      key: const Key('breakpoint_body_field'),
                      controller: controller,
                      scrollController: textScroll,
                      maxLines: null,
                      expands: true,
                      textAlignVertical: TextAlignVertical.top,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontFamily: 'monospace',
                        fontSize: 12,
                        height: 1.35,
                      ),
                      decoration: const InputDecoration(
                        isDense: true,
                        border: InputBorder.none,
                        hintText: 'JSON or raw body',
                        contentPadding: EdgeInsets.fromLTRB(8, 8, 8, 8),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _IndentIntent extends Intent {
  const _IndentIntent();
}

class _SmartNewlineIntent extends Intent {
  const _SmartNewlineIntent();
}

void _insertAtCursor(TextEditingController controller, String text) {
  final value = controller.value;
  final selection = value.selection;
  if (!selection.isValid) {
    controller.text = '${value.text}$text';
    controller.selection =
        TextSelection.collapsed(offset: controller.text.length);
    return;
  }
  final start = selection.start;
  final end = selection.end;
  final next = value.text.replaceRange(start, end, text);
  controller.value = TextEditingValue(
    text: next,
    selection: TextSelection.collapsed(offset: start + text.length),
  );
}

void _insertSmartNewline(TextEditingController controller) {
  final value = controller.value;
  final selection = value.selection;
  if (!selection.isValid) {
    _insertAtCursor(controller, '\n');
    return;
  }
  final text = value.text;
  final start = selection.start;
  final lineStart = text.lastIndexOf('\n', math.max(0, start - 1)) + 1;
  final linePrefix = text.substring(lineStart, start);
  final indentMatch = RegExp(r'^[ \t]*').firstMatch(linePrefix);
  var indent = indentMatch?.group(0) ?? '';
  final trimmedLeft = linePrefix.trimRight();
  if (trimmedLeft.endsWith('{') || trimmedLeft.endsWith('[')) {
    indent = '$indent  ';
  }
  _insertAtCursor(controller, '\n$indent');
}

class _ToolButton extends StatelessWidget {
  const _ToolButton({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      visualDensity: VisualDensity.compact,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
      iconSize: 16,
      onPressed: onPressed,
      icon: Icon(icon),
    );
  }
}

/// Pretty-prints [text] if it is JSON; otherwise returns [text] unchanged.
String tryFormatJsonBody(String text) {
  return InfospectBreakpointManager.stringifyBody(text);
}
