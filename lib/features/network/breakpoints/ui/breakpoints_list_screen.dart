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

  static Future<void> open(BuildContext context) async {
    if (!kIsWeb && InfospectUtil.isDesktop) {
      final darkTheme =
          Theme.of(context).brightness == Brightness.dark;
      await openWindow(
        (ctx, id) => const BreakpointsListScreen(embedded: true),
        options: WindowOptions(
          title: 'Breakpoints · Infospect',
          size: const Size(720, 560),
          minimumSize: const Size(480, 360),
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
      return;
    }

    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => const BreakpointsListScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final manager = Infospect.instance.breakpointManager;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: const Text('Breakpoints'),
        automaticallyImplyLeading: !embedded,
        actions: [
          IconButton(
            tooltip: 'Add breakpoint',
            onPressed: () => _showEditor(context),
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: ValueListenableBuilder<List<InfospectNetworkBreakpoint>>(
        valueListenable: manager.breakpoints,
        builder: (context, rules, _) {
          if (rules.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.crisis_alert_outlined,
                      size: 40,
                      color: theme.colorScheme.onSurface
                          .withValues(alpha: 0.35),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'No breakpoints yet',
                      style: theme.textTheme.titleSmall,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Add an endpoint to pause matching requests and responses,\n'
                      'then edit body, params, or headers before continuing.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface
                            .withValues(alpha: 0.55),
                      ),
                    ),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: () => _showEditor(context),
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Add breakpoint'),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: rules.length,
            separatorBuilder: (_, _) => Divider(
              height: 1,
              color: theme.colorScheme.outlineVariant.withValues(alpha: 0.45),
            ),
            itemBuilder: (context, index) {
              final rule = rules[index];
              final methodLabel =
                  (rule.method == null || rule.method!.trim().isEmpty)
                      ? 'ANY'
                      : rule.method!.toUpperCase();
              final phases = <String>[
                if (rule.breakOnRequest) 'Request',
                if (rule.breakOnResponse) 'Response',
              ].join(' · ');

              return ListTile(
                dense: true,
                leading: Switch.adaptive(
                  value: rule.enabled,
                  onChanged: (value) =>
                      manager.setEnabled(rule.id, value),
                ),
                title: Text(
                  '$methodLabel  ${rule.endpoint}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontFamily: 'monospace',
                  ),
                ),
                subtitle: Text(
                  phases.isEmpty ? 'Disabled phases' : phases,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurface
                        .withValues(alpha: 0.55),
                  ),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      tooltip: 'Edit',
                      onPressed: () => _showEditor(context, existing: rule),
                      icon: const Icon(Icons.edit_outlined, size: 20),
                    ),
                    IconButton(
                      tooltip: 'Delete',
                      onPressed: () => manager.removeBreakpoint(rule.id),
                      icon: Icon(
                        Icons.delete_outline,
                        size: 20,
                        color: theme.colorScheme.error,
                      ),
                    ),
                  ],
                ),
                onTap: () => _showEditor(context, existing: rule),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showEditor(context),
        icon: const Icon(Icons.add),
        label: const Text('Add'),
      ),
    );
  }

  Future<void> _showEditor(
    BuildContext context, {
    InfospectNetworkBreakpoint? existing,
  }) async {
    final result = await showDialog<InfospectNetworkBreakpoint>(
      context: context,
      builder: (dialogContext) => _BreakpointRuleDialog(existing: existing),
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

class _BreakpointRuleDialog extends StatefulWidget {
  const _BreakpointRuleDialog({this.existing});

  final InfospectNetworkBreakpoint? existing;

  @override
  State<_BreakpointRuleDialog> createState() => _BreakpointRuleDialogState();
}

class _BreakpointRuleDialogState extends State<_BreakpointRuleDialog> {
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
    final isEdit = widget.existing != null;

    return AlertDialog(
      title: Text(isEdit ? 'Edit breakpoint' : 'Add breakpoint'),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _endpointController,
              decoration: const InputDecoration(
                labelText: 'Endpoint',
                hintText: '/api/users or /api/users*',
                border: OutlineInputBorder(),
                helperText: 'Trailing * matches a path prefix',
              ),
            ),
            const SizedBox(height: 12),
            InputDecorator(
              decoration: const InputDecoration(
                labelText: 'Method',
                border: OutlineInputBorder(),
                helperText: 'ANY stops every method for this endpoint',
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _method,
                  isExpanded: true,
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
            const SizedBox(height: 8),
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              title: const Text('Enabled'),
              value: _enabled,
              onChanged: (value) => setState(() => _enabled = value),
            ),
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              title: const Text('Break on request'),
              value: _breakOnRequest,
              onChanged: (value) => setState(() => _breakOnRequest = value),
            ),
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              title: const Text('Break on response'),
              value: _breakOnResponse,
              onChanged: (value) => setState(() => _breakOnResponse = value),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
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
      ],
    );
  }
}
