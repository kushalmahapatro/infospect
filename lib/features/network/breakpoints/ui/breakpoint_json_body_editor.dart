import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:infospect/features/network/breakpoints/infospect_breakpoint_manager.dart';

/// Monospace body editor with Format / Minify / Validate for JSON payloads.
class BreakpointJsonBodyEditor extends StatefulWidget {
  const BreakpointJsonBodyEditor({
    super.key,
    required this.controller,
  });

  final TextEditingController controller;

  @override
  State<BreakpointJsonBodyEditor> createState() =>
      _BreakpointJsonBodyEditorState();
}

class _BreakpointJsonBodyEditorState extends State<BreakpointJsonBodyEditor> {
  String? _error;
  bool? _isJson;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_revalidate);
    _revalidate();
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
    super.dispose();
  }

  void _revalidate() {
    final text = widget.controller.text.trim();
    if (text.isEmpty) {
      setState(() {
        _error = null;
        _isJson = null;
      });
      return;
    }
    try {
      jsonDecode(text);
      setState(() {
        _error = null;
        _isJson = true;
      });
    } catch (e) {
      setState(() {
        _error = e.toString().replaceFirst('FormatException: ', '');
        _isJson = false;
      });
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
    ScaffoldMessenger.maybeOf(context)?.showSnackBar(
      const SnackBar(
        content: Text('Body copied'),
        duration: Duration(seconds: 1),
      ),
    );
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
          color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
          child: SizedBox(
            height: 32,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Row(
                children: [
                  Text(
                    _isJson == null
                        ? 'Body'
                        : (_isJson! ? 'JSON' : 'Invalid JSON'),
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: statusColor,
                    ),
                  ),
                  const Spacer(),
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
                  _ToolButton(
                    tooltip: 'Copy',
                    icon: Icons.copy_rounded,
                    onPressed: widget.controller.text.isEmpty ? null : _copy,
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
              _error!,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelSmall?.copyWith(
                fontSize: 10,
                color: theme.colorScheme.error,
              ),
            ),
          ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
            child: TextField(
              key: const Key('breakpoint_body_field'),
              controller: widget.controller,
              maxLines: null,
              expands: true,
              textAlignVertical: TextAlignVertical.top,
              style: theme.textTheme.bodySmall?.copyWith(
                fontFamily: 'monospace',
                fontSize: 12,
                height: 1.35,
              ),
              decoration: InputDecoration(
                isDense: true,
                border: const OutlineInputBorder(),
                hintText: 'JSON or raw body',
                alignLabelWithHint: true,
                contentPadding: const EdgeInsets.all(10),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                    color: _isJson == false
                        ? theme.colorScheme.error
                        : theme.colorScheme.primary,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
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
