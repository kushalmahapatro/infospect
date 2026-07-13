import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:infospect/features/network/breakpoints/models/infospect_breakpoint_session.dart';

/// Full-screen (mobile) / window (desktop) editor for a paused request or response.
class BreakpointInterceptScreen extends StatefulWidget {
  const BreakpointInterceptScreen({
    super.key,
    required this.phase,
    required this.initialPayload,
    required this.onContinue,
    required this.onAbort,
  });

  final InfospectBreakpointPhase phase;
  final InfospectBreakpointPayload initialPayload;
  final ValueChanged<InfospectBreakpointPayload> onContinue;
  final ValueChanged<InfospectBreakpointPayload> onAbort;

  @override
  State<BreakpointInterceptScreen> createState() =>
      _BreakpointInterceptScreenState();
}

class _BreakpointInterceptScreenState extends State<BreakpointInterceptScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  late final TextEditingController _bodyController;
  late final TextEditingController _statusController;
  late final List<_KvEntry> _headers;
  late final List<_KvEntry> _params;
  late final bool _isResponse;

  @override
  void initState() {
    super.initState();
    _isResponse = widget.phase == InfospectBreakpointPhase.response;
    _tabController = TabController(
      length: _isResponse ? 2 : 3,
      vsync: this,
    );
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
    _tabController.dispose();
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final title =
        _isResponse ? 'Response Breakpoint' : 'Request Breakpoint';
    final subtitle =
        '${widget.initialPayload.method}  ${widget.initialPayload.uri}';
    final borderColor =
        theme.colorScheme.outlineVariant.withValues(alpha: 0.55);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        titleSpacing: 12,
        automaticallyImplyLeading: false,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: theme.textTheme.titleSmall),
            Text(
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelSmall?.copyWith(
                fontFamily: 'monospace',
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => widget.onAbort(_buildPayload()),
            child: Text(
              'Abort',
              style: TextStyle(color: theme.colorScheme.error),
            ),
          ),
          const SizedBox(width: 4),
          FilledButton(
            onPressed: () => widget.onContinue(_buildPayload()),
            child: const Text('Continue'),
          ),
          const SizedBox(width: 12),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            const Tab(text: 'Headers'),
            if (!_isResponse) const Tab(text: 'Query'),
            const Tab(text: 'Body'),
          ],
        ),
      ),
      body: Column(
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: borderColor)),
              color: theme.colorScheme.surfaceContainerHighest
                  .withValues(alpha: 0.35),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
              child: _isResponse
                  ? Row(
                      children: [
                        Text('Status', style: theme.textTheme.labelMedium),
                        const SizedBox(width: 12),
                        SizedBox(
                          width: 96,
                          child: TextField(
                            controller: _statusController,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            decoration: const InputDecoration(
                              isDense: true,
                              border: OutlineInputBorder(),
                              hintText: '200',
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            'Edit the response, then Continue to deliver it to the client.',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface
                                  .withValues(alpha: 0.6),
                            ),
                          ),
                        ),
                      ],
                    )
                  : Text(
                      'Edit headers, query params, or body, then Continue to send the request.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface
                            .withValues(alpha: 0.6),
                      ),
                    ),
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _KvEditor(
                  entries: _headers,
                  keyHint: 'Header',
                  valueHint: 'Value',
                  onChanged: () => setState(() {}),
                ),
                if (!_isResponse)
                  _KvEditor(
                    entries: _params,
                    keyHint: 'Param',
                    valueHint: 'Value',
                    onChanged: () => setState(() {}),
                  ),
                _BodyEditor(controller: _bodyController),
              ],
            ),
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
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
      itemCount: entries.length + 1,
      itemBuilder: (context, index) {
        if (index == entries.length) {
          return Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () {
                entries.add(
                  _KvEntry(TextEditingController(), TextEditingController()),
                );
                onChanged();
              },
              icon: const Icon(Icons.add, size: 18),
              label: Text('Add $keyHint'),
            ),
          );
        }

        final entry = entries[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              Expanded(
                flex: 2,
                child: TextField(
                  controller: entry.keyController,
                  decoration: InputDecoration(
                    isDense: true,
                    border: const OutlineInputBorder(),
                    hintText: keyHint,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 3,
                child: TextField(
                  controller: entry.valueController,
                  decoration: InputDecoration(
                    isDense: true,
                    border: const OutlineInputBorder(),
                    hintText: valueHint,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Remove',
                onPressed: () {
                  entry.dispose();
                  entries.removeAt(index);
                  onChanged();
                },
                icon: const Icon(Icons.close, size: 18),
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
      padding: const EdgeInsets.all(12),
      child: TextField(
        controller: controller,
        maxLines: null,
        expands: true,
        textAlignVertical: TextAlignVertical.top,
        style: theme.textTheme.bodySmall?.copyWith(
          fontFamily: 'monospace',
          height: 1.35,
        ),
        decoration: const InputDecoration(
          border: OutlineInputBorder(),
          hintText: 'Body',
          alignLabelWithHint: true,
        ),
      ),
    );
  }
}
