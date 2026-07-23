import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:infospect/features/network/breakpoints/models/infospect_breakpoint_session.dart';
import 'package:infospect/features/network/breakpoints/ui/breakpoint_json_body_editor.dart';
import 'package:infospect/features/network/breakpoints/ui/json_editing_controller.dart';

/// Compact request / response breakpoint editor.
///
/// On desktop (`desktop: true`) uses a Scaffold + summary bar so the window
/// matches other Infospect popouts. Mobile keeps the denser sheet layout.
class BreakpointInterceptScreen extends StatefulWidget {
  const BreakpointInterceptScreen({
    super.key,
    required this.phase,
    required this.initialPayload,
    required this.onContinue,
    required this.onAbort,
    this.compact = true,
    this.desktop = false,
  });

  final InfospectBreakpointPhase phase;
  final InfospectBreakpointPayload initialPayload;
  final ValueChanged<InfospectBreakpointPayload> onContinue;
  final ValueChanged<InfospectBreakpointPayload> onAbort;
  final bool compact;
  final bool desktop;

  @override
  State<BreakpointInterceptScreen> createState() =>
      _BreakpointInterceptScreenState();
}

class _BreakpointInterceptScreenState extends State<BreakpointInterceptScreen> {
  late final JsonEditingController _bodyController;
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
        JsonEditingController(text: widget.initialPayload.body);
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
    if (widget.desktop) {
      return _buildDesktop(context);
    }
    return _buildMobile(context);
  }

  Widget _buildDesktop(BuildContext context) {
    final theme = Theme.of(context);
    final border = theme.colorScheme.outlineVariant.withValues(alpha: 0.55);
    final title =
        _isResponse ? 'Response Breakpoint' : 'Request Breakpoint';

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        toolbarHeight: 40,
        automaticallyImplyLeading: false,
        titleSpacing: 12,
        title: Text(
          title,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            fontSize: 13,
            color: theme.colorScheme.onSurface,
          ),
        ),
        actions: [
          TextButton(
            key: const Key('breakpoint_abort'),
            style: TextButton.styleFrom(
              visualDensity: VisualDensity.compact,
              foregroundColor: theme.colorScheme.error,
              padding: const EdgeInsets.symmetric(horizontal: 10),
            ),
            onPressed: () => widget.onAbort(_buildPayload()),
            child: const Text('Abort'),
          ),
          const SizedBox(width: 4),
          Padding(
            padding: const EdgeInsets.only(right: 10),
            child: FilledButton(
              key: const Key('breakpoint_continue'),
              style: FilledButton.styleFrom(
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                minimumSize: const Size(0, 30),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              onPressed: () => widget.onContinue(_buildPayload()),
              child: const Text('Continue'),
            ),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _DesktopSummaryBar(
            payload: widget.initialPayload,
            isResponse: _isResponse,
            statusController: _isResponse ? _statusController : null,
          ),
          Divider(height: 1, thickness: 1, color: border),
          _DesktopSectionTabs(
            sections: _sections,
            selected: _section,
            onSelected: (index) => setState(() => _section = index),
          ),
          Divider(height: 1, thickness: 1, color: border),
          Expanded(child: _sectionBody()),
        ],
      ),
    );
  }

  Widget _buildMobile(BuildContext context) {
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
            padding: const EdgeInsets.fromLTRB(10, 6, 4, 6),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 1),
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
                    minimumSize: const Size(0, 30),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  onPressed: () => widget.onAbort(_buildPayload()),
                  child: const Text('Abort'),
                ),
                FilledButton(
                  key: const Key('breakpoint_continue'),
                  style: FilledButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    minimumSize: const Size(0, 30),
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
              padding: const EdgeInsets.fromLTRB(10, 0, 10, 6),
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
            padding: const EdgeInsets.fromLTRB(10, 0, 10, 6),
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
          Expanded(child: _sectionBody()),
        ],
      ),
    );
  }

  Widget _sectionBody() {
    return switch (_sections[_section]) {
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
      _ => BreakpointJsonBodyEditor(controller: _bodyController),
    };
  }
}

class _DesktopSummaryBar extends StatelessWidget {
  const _DesktopSummaryBar({
    required this.payload,
    required this.isResponse,
    this.statusController,
  });

  final InfospectBreakpointPayload payload;
  final bool isResponse;
  final TextEditingController? statusController;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      constraints: const BoxConstraints(minHeight: 40),
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
      child: Row(
        children: [
          _Chip(
            label: payload.method,
            background: theme.colorScheme.primary.withValues(alpha: 0.2),
            foreground: theme.colorScheme.primary,
          ),
          const SizedBox(width: 6),
          _Chip(
            label: isResponse ? 'Response' : 'Request',
            background: theme.colorScheme.tertiary.withValues(alpha: 0.18),
            foreground: theme.colorScheme.tertiary,
          ),
          if (isResponse && statusController != null) ...[
            const SizedBox(width: 10),
            Text(
              'Status',
              style: theme.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w600,
                fontSize: 11,
              ),
            ),
            const SizedBox(width: 6),
            SizedBox(
              width: 64,
              height: 28,
              child: TextField(
                key: const Key('breakpoint_status_field'),
                controller: statusController,
                keyboardType: TextInputType.number,
                style: const TextStyle(fontSize: 12),
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 6,
                  ),
                  border: OutlineInputBorder(),
                  hintText: '200',
                ),
              ),
            ),
          ],
          const SizedBox(width: 10),
          Expanded(
            child: SelectableText(
              payload.uri.isNotEmpty ? payload.uri : payload.endpoint,
              maxLines: 1,
              style: theme.textTheme.bodySmall?.copyWith(
                fontSize: 11,
                fontFamily: 'monospace',
                color: theme.colorScheme.onSurface.withValues(alpha: 0.75),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DesktopSectionTabs extends StatelessWidget {
  const _DesktopSectionTabs({
    required this.sections,
    required this.selected,
    required this.onSelected,
  });

  final List<String> sections;
  final int selected;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final border = theme.colorScheme.outlineVariant.withValues(alpha: 0.55);

    return Container(
      height: 34,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.22),
      child: Row(
        children: [
          for (var i = 0; i < sections.length; i++) ...[
            if (i > 0) const SizedBox(width: 4),
            _SectionTab(
              label: sections[i],
              selected: selected == i,
              onTap: () => onSelected(i),
              border: border,
            ),
          ],
          const Spacer(),
          Text(
            'Edit values, then Continue',
            style: theme.textTheme.labelSmall?.copyWith(
              fontSize: 10,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.45),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTab extends StatelessWidget {
  const _SectionTab({
    required this.label,
    required this.selected,
    required this.onTap,
    required this.border,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color border;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: selected
          ? theme.colorScheme.primary.withValues(alpha: 0.14)
          : Colors.transparent,
      borderRadius: BorderRadius.circular(5),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(5),
        child: Container(
          height: 24,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(5),
            border: Border.all(
              color: selected
                  ? theme.colorScheme.primary.withValues(alpha: 0.35)
                  : border.withValues(alpha: 0),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
              color: selected
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurface.withValues(alpha: 0.62),
            ),
          ),
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.background,
    required this.foreground,
  });

  final String label;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        color: background,
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: foreground,
        ),
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


