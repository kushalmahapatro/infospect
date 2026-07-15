import 'package:flutter/material.dart';
import 'package:infospect/features/network/breakpoints/infospect_breakpoint_manager.dart';
import 'package:infospect/features/network/breakpoints/models/infospect_breakpoint_condition.dart';

/// Compact editor for AND-combined breakpoint conditions.
class BreakpointConditionsEditor extends StatelessWidget {
  const BreakpointConditionsEditor({
    super.key,
    required this.conditions,
    required this.onChanged,
    this.compact = false,
  });

  final List<InfospectBreakpointCondition> conditions;
  final ValueChanged<List<InfospectBreakpointCondition>> onChanged;
  final bool compact;

  void _add() {
    onChanged([
      ...conditions,
      InfospectBreakpointCondition(
        id: InfospectBreakpointManager.newId(),
        target: InfospectBreakpointMatchTarget.queryParam,
        op: InfospectBreakpointMatchOp.equals,
        key: '',
        value: '',
      ),
    ]);
  }

  void _update(int index, InfospectBreakpointCondition next) {
    final list = List<InfospectBreakpointCondition>.from(conditions);
    list[index] = next;
    onChanged(list);
  }

  void _remove(int index) {
    final list = List<InfospectBreakpointCondition>.from(conditions)
      ..removeAt(index);
    onChanged(list);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final labelStyle = theme.textTheme.labelSmall?.copyWith(
      fontSize: compact ? 10 : 11,
      fontWeight: FontWeight.w700,
      color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Text('Conditions', style: labelStyle),
            const SizedBox(width: 6),
            Text(
              'AND',
              style: theme.textTheme.labelSmall?.copyWith(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.primary.withValues(alpha: 0.8),
              ),
            ),
            const Spacer(),
            TextButton.icon(
              style: TextButton.styleFrom(
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(horizontal: 6),
                minimumSize: const Size(0, 28),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              onPressed: _add,
              icon: const Icon(Icons.add, size: 14),
              label: Text(
                'Add',
                style: theme.textTheme.labelSmall?.copyWith(fontSize: 11),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Optional filters: query params, headers, body text / JSON path, '
          'response status or body.',
          style: theme.textTheme.labelSmall?.copyWith(
            fontSize: 10,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.45),
          ),
        ),
        const SizedBox(height: 8),
        if (conditions.isEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
              ),
            ),
            child: Text(
              'No extra conditions — matches endpoint / method only.',
              style: theme.textTheme.bodySmall?.copyWith(
                fontSize: 11,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
          )
        else
          for (var i = 0; i < conditions.length; i++) ...[
            if (i > 0) const SizedBox(height: 8),
            _ConditionCard(
              key: ValueKey(conditions[i].id),
              condition: conditions[i],
              compact: compact,
              onChanged: (next) => _update(i, next),
              onRemove: () => _remove(i),
            ),
          ],
      ],
    );
  }
}

class _ConditionCard extends StatelessWidget {
  const _ConditionCard({
    super.key,
    required this.condition,
    required this.onChanged,
    required this.onRemove,
    required this.compact,
  });

  final InfospectBreakpointCondition condition;
  final ValueChanged<InfospectBreakpointCondition> onChanged;
  final VoidCallback onRemove;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ops = operatorsForTarget(condition.target);
    final op = ops.contains(condition.op) ? condition.op : ops.first;
    final needsKey = matchTargetNeedsKey(condition.target);
    final needsValue = matchOpNeedsValue(op);

    InputDecoration denseDecoration(String hint) => InputDecoration(
          isDense: true,
          hintText: hint,
          border: const OutlineInputBorder(),
          contentPadding: EdgeInsets.symmetric(
            horizontal: 8,
            vertical: compact ? 8 : 10,
          ),
        );

    return Container(
      padding: EdgeInsets.all(compact ? 8 : 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.55),
        ),
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: _DenseDropdown<InfospectBreakpointMatchTarget>(
                  value: condition.target,
                  items: InfospectBreakpointMatchTarget.values,
                  labelBuilder: labelForMatchTarget,
                  onChanged: (target) {
                    final nextOps = operatorsForTarget(target);
                    onChanged(
                      condition.copyWith(
                        target: target,
                        op: nextOps.contains(condition.op)
                            ? condition.op
                            : nextOps.first,
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 6),
              IconButton(
                tooltip: 'Remove',
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                iconSize: 16,
                onPressed: onRemove,
                icon: Icon(
                  Icons.close_rounded,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          _DenseDropdown<InfospectBreakpointMatchOp>(
            value: op,
            items: ops,
            labelBuilder: labelForMatchOp,
            onChanged: (nextOp) => onChanged(condition.copyWith(op: nextOp)),
          ),
          if (needsKey) ...[
            const SizedBox(height: 6),
            TextFormField<String>(
              initialValue: condition.key ?? '',
              style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
              decoration: denseDecoration(
                condition.target == InfospectBreakpointMatchTarget.requestBodyJson ||
                        condition.target ==
                            InfospectBreakpointMatchTarget.responseBodyJson
                    ? 'JSON path (e.g. user.id)'
                    : 'Key',
              ),
              onChanged: (value) => onChanged(condition.copyWith(key: value)),
            ),
          ],
          if (needsValue) ...[
            const SizedBox(height: 6),
            TextFormField<String>(
              initialValue: condition.value ?? '',
              style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
              decoration: denseDecoration(
                condition.target == InfospectBreakpointMatchTarget.responseStatus
                    ? (op == InfospectBreakpointMatchOp.inRange
                        ? 'e.g. 200-299'
                        : 'e.g. 404')
                    : 'Value',
              ),
              onChanged: (value) => onChanged(condition.copyWith(value: value)),
            ),
          ],
        ],
      ),
    );
  }
}

class _DenseDropdown<T> extends StatelessWidget {
  const _DenseDropdown({
    required this.value,
    required this.items,
    required this.labelBuilder,
    required this.onChanged,
  });

  final T value;
  final List<T> items;
  final String Function(T) labelBuilder;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DropdownButtonHideUnderline(
      child: InputDecorator(
        decoration: const InputDecoration(
          isDense: true,
          border: OutlineInputBorder(),
          contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        ),
        child: DropdownButton<T>(
          value: value,
          isDense: true,
          isExpanded: true,
          style: theme.textTheme.bodySmall?.copyWith(fontSize: 12),
          items: items
              .map(
                (item) => DropdownMenuItem<T>(
                  value: item,
                  child: Text(
                    labelBuilder(item),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              )
              .toList(),
          onChanged: (next) {
            if (next == null) return;
            onChanged(next);
          },
        ),
      ),
    );
  }
}
