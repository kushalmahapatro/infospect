import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:infospect/features/network/breakpoints/models/infospect_breakpoint_session.dart';

/// Compact request / response breakpoint editor.
class BreakpointInterceptScreen extends StatefulWidget {
  const BreakpointInterceptScreen({
    super.key,
    required this.phase,
    required this.initialPayload,
    required this.onContinue,
    required this.onAbort,
    this.compact = true,
  });

  final InfospectBreakpointPhase phase;
  final InfospectBreakpointPayload initialPayload;
  final ValueChanged<InfospectBreakpointPayload> onContinue;
  final ValueChanged<InfospectBreakpointPayload> onAbort;
  final bool compact;

  @override
  State<BreakpointInterceptScreen> createState() =>
      _BreakpointInterceptScreenState();
}

class _BreakpointInterceptScreenState extends State<BreakpointInterceptScreen> {
  late final TextEditingController _bodyController;
  late final TextEditingController _statusController;
  late final List<_KvEntry> _headers;
  late final List<_KvEntry> _params;
  late final bool _isResponse;
  int _section = 0;

  @override
  void initState() {
    super.initState();
    _isResponse = widget.phase == InfospectBreakpointPhase.response;
    _bodyController =
        TextEditingController(text: widget.initialPayload.body);
    _statusController = TextEditingController(
      text: widget.initialPayload.statusCode?.toString() ?? '',
    );
    _headers = widget.initialPayload.headers.entries
        .map(
          (e) => _KvEntry(
            TextEditingController(text: e.key),
            TextEditingController(text: e.value),
          ),
        )
        .toList();
    _params = widget.initialPayload.queryParameters.entries
        .map(
          (e) => _KvEntry(
            TextEditingController(text: e.key),
            TextEditingController(text: e.value),
          ),
        )
        .toList();
    if (_headers.isEmpty) {
      _headers.add(_KvEntry(TextEditingController(), TextEditingController()));
    }
    if (_params.isEmpty) {
      _params.add(_KvEntry(TextEditingController(), TextEditingController()));
    }
  }

  @override
  void dispose() {
    _bodyController.dispose();
    _statusController.dispose();
    for (final entry in _headers) {
      entry.dispose();
    }
    for (final entry in _params) {
      entry.dispose();
    }
    super.dispose();
  }

  InfospectBreakpointPayload _buildPayload() {
    final headers = <String, String>{};
    for (final entry in _headers) {
      final key = entry.keyController.text.trim();
      if (key.isEmpty) continue;
      headers[key] = entry.valueController.text;
    }

    final params = <String, String>{};
    for (final entry in _params) {
      final key = entry.keyController.text.trim();
      if (key.isEmpty) continue;
      params[key] = entry.valueController.text;
    }

    int? status;
    final statusText = _statusController.text.trim();
    if (statusText.isNotEmpty) {
      status = int.tryParse(statusText);
    }

    return widget.initialPayload.copyWith(
      headers: headers,
      queryParameters: params,
      body: _bodyController.text,
      statusCode: status,
      clearStatusCode: statusText.isEmpty,
    );
  }

  List<String> get _sections => _isResponse
      ? const ['Headers', 'Body']
      : const ['Headers', 'Query', 'Body'];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final title =
        _isResponse ? 'Response Breakpoint' : 'Request Breakpoint';
    final border = theme.colorScheme.outlineVariant.withValues(alpha: 0.45);

    return Material(
      color: theme.colorScheme.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 8, 8),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${widget.initialPayload.method}  ${widget.initialPayload.endpoint}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontFamily: 'monospace',
                          fontSize: 11,
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.55),
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  key: const Key('breakpoint_abort'),
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    foregroundColor: theme.colorScheme.error,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                  onPressed: () => widget.onAbort(_buildPayload()),
                  child: const Text('Abort'),
                ),
                FilledButton(
                  key: const Key('breakpoint_continue'),
                  style: FilledButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    minimumSize: const Size(0, 32),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  onPressed: () => widget.onContinue(_buildPayload()),
                  child: const Text('Continue'),
                ),
                const SizedBox(width: 4),
              ],
            ),
          ),
          if (_isResponse)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
              child: Row(
                children: [
                  Text(
                    'Status',
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 72,
                    child: TextField(
                      key: const Key('breakpoint_status_field'),
                      controller: _statusController,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(fontSize: 13),
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      decoration: const InputDecoration(
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 8,
                        ),
                        border: OutlineInputBorder(),
                        hintText: '200',
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Edit then Continue to deliver to the client.',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurface
                            .withValues(alpha: 0.5),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
            child: SizedBox(
              width: double.infinity,
              child: SegmentedButton<int>(
                style: ButtonStyle(
                  visualDensity: VisualDensity.compact,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  textStyle: WidgetStatePropertyAll(
                    theme.textTheme.labelSmall?.copyWith(fontSize: 11),
                  ),
                ),
                segments: [
                  for (var i = 0; i < _sections.length; i++)
                    ButtonSegment<int>(value: i, label: Text(_sections[i])),
                ],
                selected: {_section},
                onSelectionChanged: (value) {
                  setState(() => _section = value.first);
                },
              ),
            ),
          ),
          Divider(height: 1, color: border),
          Expanded(
            child: switch (_sections[_section]) {
              'Headers' => _KvEditor(
                  entries: _headers,
                  keyHint: 'Header',
                  valueHint: 'Value',
                  onChanged: () => setState(() {}),
                ),
              'Query' => _KvEditor(
                  entries: _params,
                  keyHint: 'Param',
                  valueHint: 'Value',
                  onChanged: () => setState(() {}),
                ),
              _ => _BodyEditor(controller: _bodyController),
            },
          ),
        ],
      ),
    );
  }
}

class _KvEntry {
  _KvEntry(this.keyController, this.valueController);

  final TextEditingController keyController;
  final TextEditingController valueController;

  void dispose() {
    keyController.dispose();
    valueController.dispose();
  }
}

class _KvEditor extends StatelessWidget {
  const _KvEditor({
    required this.entries,
    required this.keyHint,
    required this.valueHint,
    required this.onChanged,
  });

  final List<_KvEntry> entries;
  final String keyHint;
  final String valueHint;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(10, 8, 6, 16),
      itemCount: entries.length + 1,
      itemBuilder: (context, index) {
        if (index == entries.length) {
          return Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              style: TextButton.styleFrom(
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(horizontal: 8),
              ),
              onPressed: () {
                entries.add(
                  _KvEntry(TextEditingController(), TextEditingController()),
                );
                onChanged();
              },
              icon: const Icon(Icons.add, size: 16),
              label: Text('Add $keyHint'),
            ),
          );
        }

        final entry = entries[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Row(
            children: [
              Expanded(
                flex: 2,
                child: TextField(
                  controller: entry.keyController,
                  style: const TextStyle(fontSize: 12),
                  decoration: InputDecoration(
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 8,
                    ),
                    border: const OutlineInputBorder(),
                    hintText: keyHint,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                flex: 3,
                child: TextField(
                  controller: entry.valueController,
                  style: const TextStyle(fontSize: 12),
                  decoration: InputDecoration(
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 8,
                    ),
                    border: const OutlineInputBorder(),
                    hintText: valueHint,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Remove',
                visualDensity: VisualDensity.compact,
                iconSize: 16,
                onPressed: () {
                  entry.dispose();
                  entries.removeAt(index);
                  onChanged();
                },
                icon: const Icon(Icons.close),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _BodyEditor extends StatelessWidget {
  const _BodyEditor({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
      child: TextField(
        key: const Key('breakpoint_body_field'),
        controller: controller,
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
          border: OutlineInputBorder(),
          hintText: 'Body',
          alignLabelWithHint: true,
          contentPadding: EdgeInsets.all(10),
        ),
      ),
    );
  }
}
