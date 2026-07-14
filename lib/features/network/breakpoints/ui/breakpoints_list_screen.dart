import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:infospect/features/network/breakpoints/infospect_breakpoint_manager.dart';
import 'package:infospect/features/network/breakpoints/models/infospect_network_breakpoint.dart';
import 'package:infospect/helpers/infospect_helper.dart';
import 'package:infospect/styling/themes/infospect_theme.dart';
import 'package:infospect/utils/common_widgets/infospect_mobile_chrome.dart';
import 'package:infospect/utils/infospect_desktop_window.dart';
import 'package:infospect/utils/infospect_util.dart';
import 'package:multiview_desktop/multiview_desktop.dart';

/// Lists and edits Proxyman-style network breakpoint rules.
class BreakpointsListScreen extends StatelessWidget {
  const BreakpointsListScreen({super.key, this.embedded = false});

  /// When true, omits close/back chrome (used inside a desktop window).
  final bool embedded;

  /// Singleton desktop management window — reopening focuses the existing one.
  static int? _desktopWindowId;
  static final GlobalKey _desktopScreenKey = GlobalKey();
  static bool _listeningForClose = false;

  static Future<void> open(BuildContext context) async {
    if (!kIsWeb &&
        InfospectUtil.isDesktop &&
        !Infospect.instance.preferInAppBreakpointDialogs) {
      await _openDesktop(context);
      return;
    }

    if (!context.mounted) return;
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => const BreakpointsListScreen(),
      ),
    );
  }

  static Future<void> _openDesktop(BuildContext context) async {
    final existing = _desktopWindowId;
    if (existing != null &&
        MultiViewDesktop.allWindowViewIds.contains(existing)) {
      final window = MultiViewDesktop.fromId(existing);
      await window.show();
      await window.focus();
      return;
    }

    final darkTheme = Theme.of(context).brightness == Brightness.dark;
    _ensureCloseListener();
    _desktopWindowId = await openWindow(
      (ctx, id) => BreakpointsListScreen(
        key: _desktopScreenKey,
        embedded: true,
      ),
      options: infospectDesktopWindowOptions(
        title: 'Breakpoints · Infospect',
        size: const Size(780, 560),
        minimumSize: const Size(640, 420),
        alignment: Alignment.center,
        shellOverrides: ViewShellOverrides(
          appearance: AppShellPatch(
            theme: InfospectTheme.lightTheme,
            darkTheme: InfospectTheme.darkTheme,
            themeMode: darkTheme ? ThemeMode.dark : ThemeMode.light,
          ),
        ),
      ),
    );
  }

  static void _ensureCloseListener() {
    if (_listeningForClose) return;
    _listeningForClose = true;
    MultiViewDesktop.allWindowIdsNotifier.addListener(() {
      final id = _desktopWindowId;
      if (id != null && !MultiViewDesktop.allWindowViewIds.contains(id)) {
        _desktopWindowId = null;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (embedded) {
      return const _BreakpointsDesktopScreen();
    }
    return const _BreakpointsMobileScreen();
  }
}

/// Desktop: table of rules + inspector/editor pane.
class _BreakpointsDesktopScreen extends StatefulWidget {
  const _BreakpointsDesktopScreen();

  @override
  State<_BreakpointsDesktopScreen> createState() =>
      _BreakpointsDesktopScreenState();
}

class _BreakpointsDesktopScreenState extends State<_BreakpointsDesktopScreen> {
  InfospectNetworkBreakpoint? _selected;
  bool _creating = false;

  InfospectBreakpointManager get _manager =>
      Infospect.instance.breakpointManager;

  void _select(InfospectNetworkBreakpoint rule) {
    setState(() {
      _selected = rule;
      _creating = false;
    });
  }

  void _startCreate() {
    setState(() {
      _creating = true;
      _selected = null;
    });
  }

  void _clearEditor() {
    setState(() {
      _creating = false;
      _selected = null;
    });
  }

  void _save(InfospectNetworkBreakpoint rule) {
    final existing = _manager.breakpoints.value
        .where((r) => r.id == rule.id)
        .isNotEmpty;
    if (existing) {
      _manager.updateBreakpoint(rule);
    } else {
      _manager.addBreakpoint(rule);
    }
    setState(() {
      _selected = rule;
      _creating = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final border = theme.colorScheme.outlineVariant.withValues(alpha: 0.55);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _DesktopToolbar(
            onAdd: _startCreate,
            onClearAll: () {
              _manager.clearBreakpoints();
              _clearEditor();
            },
          ),
          Divider(height: 1, thickness: 1, color: border),
          Expanded(
            child: ValueListenableBuilder<List<InfospectNetworkBreakpoint>>(
              valueListenable: _manager.breakpoints,
              builder: (context, rules, _) {
                // Keep selection in sync if the rule was deleted.
                final selected = _selected;
                final stillExists = selected != null &&
                    rules.any((r) => r.id == selected.id);
                final effectiveSelected = stillExists ? selected : null;

                return Row(
                  children: [
                    Expanded(
                      flex: 5,
                      child: rules.isEmpty
                          ? _DesktopEmptyState(onAdd: _startCreate)
                          : _BreakpointTable(
                              rules: rules,
                              selectedId: effectiveSelected?.id,
                              onSelect: _select,
                              onToggle: (id, enabled) =>
                                  _manager.setEnabled(id, enabled),
                              onDelete: (id) {
                                _manager.removeBreakpoint(id);
                                if (_selected?.id == id) _clearEditor();
                              },
                            ),
                    ),
                    VerticalDivider(width: 1, thickness: 1, color: border),
                    SizedBox(
                      width: 300,
                      child: _creating || effectiveSelected != null
                          ? _BreakpointEditorPanel(
                              key: ValueKey(
                                _creating
                                    ? 'new'
                                    : effectiveSelected!.id,
                              ),
                              existing: _creating ? null : effectiveSelected,
                              onCancel: _clearEditor,
                              onSave: _save,
                              onDelete: effectiveSelected == null
                                  ? null
                                  : () {
                                      _manager.removeBreakpoint(
                                        effectiveSelected.id,
                                      );
                                      _clearEditor();
                                    },
                            )
                          : const _EditorPlaceholder(),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _DesktopToolbar extends StatelessWidget {
  const _DesktopToolbar({
    required this.onAdd,
    required this.onClearAll,
  });

  final VoidCallback onAdd;
  final VoidCallback onClearAll;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final count = Infospect.instance.breakpointManager.breakpoints.value.length;

    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
      child: Row(
        children: [
          Text(
            'Breakpoints',
            style: theme.textTheme.titleSmall?.copyWith(
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '$count rule${count == 1 ? '' : 's'}',
            style: theme.textTheme.labelSmall?.copyWith(
              fontSize: 11,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
          const Spacer(),
          TextButton(
            style: TextButton.styleFrom(
              visualDensity: VisualDensity.compact,
              foregroundColor: theme.colorScheme.error,
              padding: const EdgeInsets.symmetric(horizontal: 8),
            ),
            onPressed: count == 0 ? null : onClearAll,
            child: const Text('Clear all'),
          ),
          const SizedBox(width: 4),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              visualDensity: VisualDensity.compact,
              minimumSize: const Size(0, 30),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            onPressed: onAdd,
            icon: const Icon(Icons.add, size: 16),
            label: const Text('Add'),
          ),
        ],
      ),
    );
  }
}

class _DesktopEmptyState extends StatelessWidget {
  const _DesktopEmptyState({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 320),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.crisis_alert_outlined,
              size: 32,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 12),
            Text(
              'No breakpoints',
              style: theme.textTheme.titleSmall?.copyWith(fontSize: 14),
            ),
            const SizedBox(height: 6),
            Text(
              'Match requests by endpoint and pause them to edit '
              'headers, query params, or body before continuing.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                fontSize: 12,
                height: 1.4,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.tonalIcon(
              style: FilledButton.styleFrom(
                visualDensity: VisualDensity.compact,
                minimumSize: const Size(0, 34),
              ),
              onPressed: onAdd,
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Add breakpoint'),
            ),
          ],
        ),
      ),
    );
  }
}

class _BreakpointTable extends StatelessWidget {
  const _BreakpointTable({
    required this.rules,
    required this.selectedId,
    required this.onSelect,
    required this.onToggle,
    required this.onDelete,
  });

  final List<InfospectNetworkBreakpoint> rules;
  final String? selectedId;
  final ValueChanged<InfospectNetworkBreakpoint> onSelect;
  final void Function(String id, bool enabled) onToggle;
  final ValueChanged<String> onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final border = theme.colorScheme.outlineVariant.withValues(alpha: 0.45);

    return Column(
      children: [
        Container(
          height: 28,
          color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            children: [
              const SizedBox(width: 36, child: _HeaderCell('On')),
              SizedBox(width: 1, height: 14, child: ColoredBox(color: border)),
              const SizedBox(width: 64, child: _HeaderCell('Method')),
              SizedBox(width: 1, height: 14, child: ColoredBox(color: border)),
              const Expanded(child: _HeaderCell('Endpoint')),
              SizedBox(width: 1, height: 14, child: ColoredBox(color: border)),
              const SizedBox(width: 72, child: _HeaderCell('Phases')),
              const SizedBox(width: 28),
            ],
          ),
        ),
        Divider(height: 1, thickness: 1, color: border),
        Expanded(
          child: ListView.separated(
            itemCount: rules.length,
            separatorBuilder: (_, _) =>
                Divider(height: 1, thickness: 1, color: border),
            itemBuilder: (context, index) {
              final rule = rules[index];
              final selected = rule.id == selectedId;
              final method =
                  (rule.method == null || rule.method!.trim().isEmpty)
                      ? 'ANY'
                      : rule.method!.toUpperCase();
              final phases = <String>[
                if (rule.breakOnRequest) 'Req',
                if (rule.breakOnResponse) 'Res',
              ].join(' · ');

              return Material(
                color: selected
                    ? theme.colorScheme.primary.withValues(alpha: 0.12)
                    : index.isEven
                        ? theme.colorScheme.surfaceContainerHighest
                            .withValues(alpha: 0.12)
                        : Colors.transparent,
                child: InkWell(
                  onTap: () => onSelect(rule),
                  child: SizedBox(
                    height: 32,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 36,
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: _CompactDesktopSwitch(
                                value: rule.enabled,
                                onChanged: (value) =>
                                    onToggle(rule.id, value),
                              ),
                            ),
                          ),
                          SizedBox(
                            width: 64,
                            child: Text(
                              method,
                              style: theme.textTheme.labelSmall?.copyWith(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                fontFamily: 'monospace',
                              ),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              rule.endpoint,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontSize: 12,
                                fontFamily: 'monospace',
                              ),
                            ),
                          ),
                          SizedBox(
                            width: 72,
                            child: Text(
                              phases.isEmpty ? '—' : phases,
                              style: theme.textTheme.labelSmall?.copyWith(
                                fontSize: 10,
                                color: theme.colorScheme.onSurface
                                    .withValues(alpha: 0.55),
                              ),
                            ),
                          ),
                          SizedBox(
                            width: 28,
                            child: IconButton(
                              tooltip: 'Delete',
                              visualDensity: VisualDensity.compact,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(
                                minWidth: 24,
                                minHeight: 24,
                              ),
                              iconSize: 14,
                              onPressed: () => onDelete(rule.id),
                              icon: Icon(
                                Icons.close,
                                color: theme.colorScheme.onSurface
                                    .withValues(alpha: 0.45),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _HeaderCell extends StatelessWidget {
  const _HeaderCell(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
        ),
      ),
    );
  }
}

class _EditorPlaceholder extends StatelessWidget {
  const _EditorPlaceholder();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Text(
          'Select a rule to edit,\nor click Add to create one.',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodySmall?.copyWith(
            fontSize: 12,
            height: 1.4,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.45),
          ),
        ),
      ),
    );
  }
}

class _BreakpointEditorPanel extends StatefulWidget {
  const _BreakpointEditorPanel({
    super.key,
    this.existing,
    required this.onSave,
    required this.onCancel,
    this.onDelete,
  });

  final InfospectNetworkBreakpoint? existing;
  final ValueChanged<InfospectNetworkBreakpoint> onSave;
  final VoidCallback onCancel;
  final VoidCallback? onDelete;

  @override
  State<_BreakpointEditorPanel> createState() => _BreakpointEditorPanelState();
}

class _BreakpointEditorPanelState extends State<_BreakpointEditorPanel> {
  static const _methods = <String>[
    'ANY',
    'GET',
    'POST',
    'PUT',
    'PATCH',
    'DELETE',
    'HEAD',
    'OPTIONS',
  ];

  late final TextEditingController _endpointController;
  late String _method;
  late bool _enabled;
  late bool _breakOnRequest;
  late bool _breakOnResponse;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _endpointController =
        TextEditingController(text: existing?.endpoint ?? '/');
    final method = existing?.method?.trim();
    _method = (method == null || method.isEmpty) ? 'ANY' : method.toUpperCase();
    if (!_methods.contains(_method)) _method = 'ANY';
    _enabled = existing?.enabled ?? true;
    _breakOnRequest = existing?.breakOnRequest ?? true;
    _breakOnResponse = existing?.breakOnResponse ?? true;
  }

  @override
  void dispose() {
    _endpointController.dispose();
    super.dispose();
  }

  void _submit() {
    final endpoint = _endpointController.text.trim();
    if (endpoint.isEmpty) return;
    widget.onSave(
      InfospectNetworkBreakpoint(
        id: widget.existing?.id ?? InfospectBreakpointManager.newId(),
        endpoint: endpoint,
        method: _method == 'ANY' ? null : _method,
        enabled: _enabled,
        breakOnRequest: _breakOnRequest,
        breakOnResponse: _breakOnResponse,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final border = theme.colorScheme.outlineVariant.withValues(alpha: 0.45);
    final isEdit = widget.existing != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          height: 34,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.28),
          child: Row(
            children: [
              Text(
                isEdit ? 'Edit rule' : 'New rule',
                style: theme.textTheme.labelLarge?.copyWith(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              if (widget.onDelete != null)
                IconButton(
                  tooltip: 'Delete',
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints:
                      const BoxConstraints(minWidth: 28, minHeight: 28),
                  iconSize: 16,
                  onPressed: widget.onDelete,
                  icon: Icon(Icons.delete_outline, color: theme.colorScheme.error),
                ),
            ],
          ),
        ),
        Divider(height: 1, thickness: 1, color: border),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
            children: [
              Text(
                'Endpoint',
                style: theme.textTheme.labelSmall?.copyWith(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
                ),
              ),
              const SizedBox(height: 4),
              TextField(
                controller: _endpointController,
                style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
                decoration: const InputDecoration(
                  isDense: true,
                  hintText: '/api/users or /api/users*',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 10,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Trailing * matches a path prefix',
                style: theme.textTheme.labelSmall?.copyWith(
                  fontSize: 10,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.45),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'Method',
                style: theme.textTheme.labelSmall?.copyWith(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
                ),
              ),
              const SizedBox(height: 4),
              DropdownButtonHideUnderline(
                child: InputDecorator(
                  decoration: const InputDecoration(
                    isDense: true,
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                  ),
                  child: DropdownButton<String>(
                    value: _method,
                    isDense: true,
                    isExpanded: true,
                    style: theme.textTheme.bodySmall?.copyWith(fontSize: 12),
                    items: _methods
                        .map(
                          (m) => DropdownMenuItem(value: m, child: Text(m)),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() => _method = value);
                    },
                  ),
                ),
              ),
              const SizedBox(height: 14),
              _DesktopToggle(
                label: 'Enabled',
                value: _enabled,
                onChanged: (v) => setState(() => _enabled = v),
              ),
              _DesktopToggle(
                label: 'Break on request',
                value: _breakOnRequest,
                onChanged: (v) => setState(() => _breakOnRequest = v),
              ),
              _DesktopToggle(
                label: 'Break on response',
                value: _breakOnResponse,
                onChanged: (v) => setState(() => _breakOnResponse = v),
              ),
            ],
          ),
        ),
        Divider(height: 1, thickness: 1, color: border),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
          child: Row(
            children: [
              TextButton(
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                ),
                onPressed: widget.onCancel,
                child: const Text('Cancel'),
              ),
              const Spacer(),
              FilledButton(
                style: FilledButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  minimumSize: const Size(0, 32),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                ),
                onPressed: _submit,
                child: Text(isEdit ? 'Save' : 'Add'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DesktopToggle extends StatelessWidget {
  const _DesktopToggle({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: SizedBox(
        height: 26,
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(fontSize: 12),
              ),
            ),
            _CompactDesktopSwitch(
              value: value,
              onChanged: onChanged,
            ),
          ],
        ),
      ),
    );
  }
}

/// Compact switch for desktop tables / inspector panes (~0.7× Material size).
class _CompactDesktopSwitch extends StatelessWidget {
  const _CompactDesktopSwitch({
    required this.value,
    required this.onChanged,
  });

  final bool value;
  final ValueChanged<bool>? onChanged;

  static const double _scale = 0.68;

  @override
  Widget build(BuildContext context) {
    return Transform.scale(
      scale: _scale,
      alignment: Alignment.centerLeft,
      child: SizedBox(
        height: 20,
        child: Switch.adaptive(
          value: value,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          onChanged: onChanged,
        ),
      ),
    );
  }
}

/// Mobile: list + bottom sheet editor (unchanged UX).
class _BreakpointsMobileScreen extends StatelessWidget {
  const _BreakpointsMobileScreen();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final manager = Infospect.instance.breakpointManager;
    final border = theme.colorScheme.outlineVariant.withValues(alpha: 0.4);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: InfospectMobileToolbar(
        title: const Text('Breakpoints'),
        actions: [
          IconButton(
            tooltip: 'Add breakpoint',
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            constraints: BoxConstraints.tight(InfospectMobileChrome.backTapTarget),
            onPressed: () => _showMobileEditor(context),
            icon: const Icon(Icons.add_rounded, size: 20),
          ),
        ],
      ),
      body: ValueListenableBuilder<List<InfospectNetworkBreakpoint>>(
        valueListenable: manager.breakpoints,
        builder: (context, rules, _) {
          if (rules.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.crisis_alert_outlined,
                      size: 28,
                      color:
                          theme.colorScheme.onSurface.withValues(alpha: 0.35),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'No breakpoints yet',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontSize: InfospectMobileChrome.titleFontSize,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Pause matching requests and responses to edit\n'
                      'headers, params, or body before continuing.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontSize: 12,
                        color: theme.colorScheme.onSurface
                            .withValues(alpha: 0.55),
                      ),
                    ),
                    const SizedBox(height: 14),
                    FilledButton.tonalIcon(
                      style: FilledButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        minimumSize: const Size(0, 34),
                      ),
                      onPressed: () => _showMobileEditor(context),
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('Add breakpoint'),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 4),
            itemCount: rules.length,
            separatorBuilder: (_, _) =>
                Divider(height: 1, thickness: 1, color: border),
            itemBuilder: (context, index) {
              final rule = rules[index];
              final methodLabel =
                  (rule.method == null || rule.method!.trim().isEmpty)
                      ? 'ANY'
                      : rule.method!.toUpperCase();
              final phases = <String>[
                if (rule.breakOnRequest) 'Req',
                if (rule.breakOnResponse) 'Res',
              ].join(' · ');

              return InkWell(
                onTap: () => _showMobileEditor(context, existing: rule),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(10, 6, 4, 6),
                  child: Row(
                    children: [
                      SizedBox(
                        height: 28,
                        child: Switch.adaptive(
                          value: rule.enabled,
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                          onChanged: (value) =>
                              manager.setEnabled(rule.id, value),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '$methodLabel  ${rule.endpoint}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontFamily: 'monospace',
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              phases.isEmpty ? 'No phases' : phases,
                              style: theme.textTheme.labelSmall?.copyWith(
                                fontSize: 10,
                                color: theme.colorScheme.onSurface
                                    .withValues(alpha: 0.5),
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: 'Edit',
                        visualDensity: VisualDensity.compact,
                        iconSize: 18,
                        onPressed: () =>
                            _showMobileEditor(context, existing: rule),
                        icon: const Icon(Icons.edit_outlined),
                      ),
                      IconButton(
                        tooltip: 'Delete',
                        visualDensity: VisualDensity.compact,
                        iconSize: 18,
                        onPressed: () => manager.removeBreakpoint(rule.id),
                        icon: Icon(
                          Icons.delete_outline,
                          color: theme.colorScheme.error,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _showMobileEditor(
    BuildContext context, {
    InfospectNetworkBreakpoint? existing,
  }) async {
    final result = await showModalBottomSheet<InfospectNetworkBreakpoint>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
      ),
      builder: (dialogContext) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(dialogContext).bottom,
        ),
        child: _BreakpointRuleSheet(existing: existing),
      ),
    );
    if (result == null) return;

    final manager = Infospect.instance.breakpointManager;
    if (existing == null) {
      manager.addBreakpoint(result);
    } else {
      manager.updateBreakpoint(result);
    }
  }
}

class _BreakpointRuleSheet extends StatefulWidget {
  const _BreakpointRuleSheet({this.existing});

  final InfospectNetworkBreakpoint? existing;

  @override
  State<_BreakpointRuleSheet> createState() => _BreakpointRuleSheetState();
}

class _BreakpointRuleSheetState extends State<_BreakpointRuleSheet> {
  static const _methods = <String>[
    'ANY',
    'GET',
    'POST',
    'PUT',
    'PATCH',
    'DELETE',
    'HEAD',
    'OPTIONS',
  ];

  late final TextEditingController _endpointController;
  late String _method;
  late bool _enabled;
  late bool _breakOnRequest;
  late bool _breakOnResponse;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _endpointController =
        TextEditingController(text: existing?.endpoint ?? '/');
    final method = existing?.method?.trim();
    _method = (method == null || method.isEmpty) ? 'ANY' : method.toUpperCase();
    if (!_methods.contains(_method)) {
      _method = 'ANY';
    }
    _enabled = existing?.enabled ?? true;
    _breakOnRequest = existing?.breakOnRequest ?? true;
    _breakOnResponse = existing?.breakOnResponse ?? true;
  }

  @override
  void dispose() {
    _endpointController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEdit = widget.existing != null;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 0, 10, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              isEdit ? 'Edit breakpoint' : 'Add breakpoint',
              style: theme.textTheme.titleSmall?.copyWith(
                fontSize: InfospectMobileChrome.titleFontSize,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _endpointController,
              style: const TextStyle(fontSize: 13),
              decoration: const InputDecoration(
                labelText: 'Endpoint',
                hintText: '/api/users or /api/users*',
                isDense: true,
                border: OutlineInputBorder(),
                helperText: 'Trailing * matches a path prefix',
              ),
            ),
            const SizedBox(height: 10),
            InputDecorator(
              decoration: const InputDecoration(
                labelText: 'Method',
                isDense: true,
                border: OutlineInputBorder(),
                helperText: 'ANY stops every method for this endpoint',
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _method,
                  isExpanded: true,
                  isDense: true,
                  style: theme.textTheme.bodyMedium?.copyWith(fontSize: 13),
                  items: _methods
                      .map(
                        (m) => DropdownMenuItem(value: m, child: Text(m)),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() => _method = value);
                  },
                ),
              ),
            ),
            const SizedBox(height: 4),
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              dense: true,
              title: const Text('Enabled', style: TextStyle(fontSize: 13)),
              value: _enabled,
              onChanged: (value) => setState(() => _enabled = value),
            ),
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              dense: true,
              title: const Text(
                'Break on request',
                style: TextStyle(fontSize: 13),
              ),
              value: _breakOnRequest,
              onChanged: (value) => setState(() => _breakOnRequest = value),
            ),
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              dense: true,
              title: const Text(
                'Break on response',
                style: TextStyle(fontSize: 13),
              ),
              value: _breakOnResponse,
              onChanged: (value) => setState(() => _breakOnResponse = value),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton(
                    onPressed: () {
                      final endpoint = _endpointController.text.trim();
                      if (endpoint.isEmpty) return;
                      final method = _method == 'ANY' ? null : _method;
                      Navigator.of(context).pop(
                        InfospectNetworkBreakpoint(
                          id: widget.existing?.id ??
                              InfospectBreakpointManager.newId(),
                          endpoint: endpoint,
                          method: method,
                          enabled: _enabled,
                          breakOnRequest: _breakOnRequest,
                          breakOnResponse: _breakOnResponse,
                        ),
                      );
                    },
                    child: Text(isEdit ? 'Save' : 'Add'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
