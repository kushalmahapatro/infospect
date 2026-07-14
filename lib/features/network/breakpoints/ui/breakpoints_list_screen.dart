import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:infospect/features/network/breakpoints/infospect_breakpoint_manager.dart';
import 'package:infospect/features/network/breakpoints/models/infospect_network_breakpoint.dart';
import 'package:infospect/helpers/infospect_helper.dart';
import 'package:infospect/styling/themes/infospect_theme.dart';
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
      options: WindowOptions(
        title: 'Breakpoints · Infospect',
        size: const Size(560, 520),
        minimumSize: const Size(420, 360),
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
    final theme = Theme.of(context);
    final manager = Infospect.instance.breakpointManager;
    final border = theme.colorScheme.outlineVariant.withValues(alpha: 0.4);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: const Text('Breakpoints'),
        titleTextStyle: theme.textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w600,
          color: theme.colorScheme.onSurface,
        ),
        toolbarHeight: 44,
        automaticallyImplyLeading: !embedded,
        actions: [
          IconButton(
            tooltip: 'Add breakpoint',
            visualDensity: VisualDensity.compact,
            onPressed: () => _showEditor(context),
            icon: const Icon(Icons.add, size: 20),
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
                      color: theme.colorScheme.onSurface
                          .withValues(alpha: 0.35),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'No breakpoints yet',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontSize: 14,
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
                      onPressed: () => _showEditor(context),
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
                onTap: () => _showEditor(context, existing: rule),
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
                            _showEditor(context, existing: rule),
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

  Future<void> _showEditor(
    BuildContext context, {
    InfospectNetworkBreakpoint? existing,
  }) async {
    final theme = Theme.of(context);
    final useDesktopDialog = embedded ||
        (!kIsWeb &&
            InfospectUtil.isDesktop &&
            !Infospect.instance.preferInAppBreakpointDialogs);

    final InfospectNetworkBreakpoint? result;
    if (useDesktopDialog) {
      result = await showDialog<InfospectNetworkBreakpoint>(
        context: context,
        barrierDismissible: true,
        builder: (dialogContext) => Dialog(
          backgroundColor: theme.colorScheme.surface,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(4, 8, 4, 8),
              child: _BreakpointRuleSheet(existing: existing),
            ),
          ),
        ),
      );
    } else {
      result = await showModalBottomSheet<InfospectNetworkBreakpoint>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        showDragHandle: true,
        backgroundColor: theme.colorScheme.surface,
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
    }
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
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              isEdit ? 'Edit breakpoint' : 'Add breakpoint',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
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
