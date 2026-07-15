import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Editable foldable JSON tree. Mutates a deep copy and reports via [onChanged].
class BreakpointJsonTreeEditor extends StatefulWidget {
  const BreakpointJsonTreeEditor({
    super.key,
    required this.data,
    required this.onChanged,
  });

  final dynamic data;
  final ValueChanged<dynamic> onChanged;

  @override
  State<BreakpointJsonTreeEditor> createState() =>
      _BreakpointJsonTreeEditorState();
}

class _BreakpointJsonTreeEditorState extends State<BreakpointJsonTreeEditor> {
  late dynamic _root;
  final Set<String> _expanded = <String>{'/'};

  @override
  void initState() {
    super.initState();
    _root = _clone(widget.data);
    _expandShallow(_root, '/');
  }

  void _expandShallow(dynamic value, String path) {
    _expanded.add(path);
    if (value is Map && value.length <= 12) {
      for (final key in value.keys) {
        final child = value[key];
        if (child is Map || child is List) {
          _expanded.add('$path$key/');
        }
      }
    } else if (value is List && value.length <= 12) {
      for (var i = 0; i < value.length; i++) {
        final child = value[i];
        if (child is Map || child is List) {
          _expanded.add('$path$i/');
        }
      }
    }
  }

  void _commit(dynamic next) {
    setState(() => _root = next);
    widget.onChanged(_clone(next));
  }

  void _toggle(String path) {
    setState(() {
      if (_expanded.contains(path)) {
        _expanded.remove(path);
      } else {
        _expanded.add(path);
      }
    });
  }

  void _expandAll() {
    setState(() {
      _expanded
        ..clear()
        ..addAll(_collectContainerPaths(_root, '/'));
    });
  }

  void _collapseAll() {
    setState(() {
      _expanded
        ..clear()
        ..add('/');
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
          child: Row(
            children: [
              Text(
                'Tree editor',
                style: theme.textTheme.labelSmall?.copyWith(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                ),
              ),
              const Spacer(),
              TextButton(
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  minimumSize: const Size(0, 28),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                onPressed: _expandAll,
                child: Text(
                  'Expand',
                  style: theme.textTheme.labelSmall?.copyWith(fontSize: 10),
                ),
              ),
              TextButton(
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  minimumSize: const Size(0, 28),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                onPressed: _collapseAll,
                child: Text(
                  'Collapse',
                  style: theme.textTheme.labelSmall?.copyWith(fontSize: 10),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(6, 4, 6, 10),
            children: [
              _JsonNode(
                path: '/',
                label: _root is List ? 'root[]' : 'root',
                value: _root,
                expanded: _expanded,
                isRoot: true,
                onToggle: _toggle,
                onReplace: (next) => _commit(next),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _JsonNode extends StatelessWidget {
  const _JsonNode({
    required this.path,
    required this.label,
    required this.value,
    required this.expanded,
    required this.onToggle,
    required this.onReplace,
    this.onRename,
    this.onDelete,
    this.isRoot = false,
  });

  final String path;
  final String label;
  final dynamic value;
  final Set<String> expanded;
  final ValueChanged<String> onToggle;
  final ValueChanged<dynamic> onReplace;
  final ValueChanged<String>? onRename;
  final VoidCallback? onDelete;
  final bool isRoot;

  @override
  Widget build(BuildContext context) {
    if (value is Map) {
      return _MapNode(
        path: path,
        label: label,
        map: Map<String, dynamic>.from(value as Map),
        expanded: expanded,
        onToggle: onToggle,
        onReplace: onReplace,
        onRename: onRename,
        onDelete: onDelete,
        isRoot: isRoot,
      );
    }
    if (value is List) {
      return _ListNode(
        path: path,
        label: label,
        list: List<dynamic>.from(value as List),
        expanded: expanded,
        onToggle: onToggle,
        onReplace: onReplace,
        onRename: onRename,
        onDelete: onDelete,
        isRoot: isRoot,
      );
    }
    return _PrimitiveNode(
      label: label,
      value: value,
      onReplace: onReplace,
      onRename: onRename,
      onDelete: onDelete,
      isRoot: isRoot,
    );
  }
}

class _MapNode extends StatelessWidget {
  const _MapNode({
    required this.path,
    required this.label,
    required this.map,
    required this.expanded,
    required this.onToggle,
    required this.onReplace,
    this.onRename,
    this.onDelete,
    this.isRoot = false,
  });

  final String path;
  final String label;
  final Map<String, dynamic> map;
  final Set<String> expanded;
  final ValueChanged<String> onToggle;
  final ValueChanged<dynamic> onReplace;
  final ValueChanged<String>? onRename;
  final VoidCallback? onDelete;
  final bool isRoot;

  bool get _isOpen => expanded.contains(path);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final keys = map.keys.toList(growable: false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _NodeHeader(
          label: label,
          summary: '{${keys.length}}',
          expanded: _isOpen,
          onToggle: () => onToggle(path),
          onRename: onRename,
          onDelete: onDelete,
          trailing: IconButton(
            tooltip: 'Add field',
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 26, minHeight: 26),
            iconSize: 15,
            onPressed: () {
              final next = Map<String, dynamic>.from(map);
              var name = 'key';
              var i = 1;
              while (next.containsKey(name)) {
                name = 'key$i';
                i++;
              }
              next[name] = '';
              onReplace(next);
              if (!_isOpen) onToggle(path);
            },
            icon: Icon(
              Icons.add_rounded,
              color: theme.colorScheme.primary.withValues(alpha: 0.85),
            ),
          ),
        ),
        if (_isOpen)
          Padding(
            padding: const EdgeInsets.only(left: 12),
            child: DecoratedBox(
              decoration: BoxDecoration(
                border: Border(
                  left: BorderSide(
                    color: theme.colorScheme.outlineVariant.withValues(alpha: 0.55),
                  ),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.only(left: 8),
                child: Column(
                  children: [
                    for (final key in keys)
                      _JsonNode(
                        path: '$path$key/',
                        label: key,
                        value: map[key],
                        expanded: expanded,
                        onToggle: onToggle,
                        onReplace: (child) {
                          final next = Map<String, dynamic>.from(map);
                          next[key] = child;
                          onReplace(next);
                        },
                        onRename: (newKey) {
                          final trimmed = newKey.trim();
                          if (trimmed.isEmpty || trimmed == key) return;
                          if (map.containsKey(trimmed)) return;
                          final next = <String, dynamic>{};
                          for (final entry in map.entries) {
                            if (entry.key == key) {
                              next[trimmed] = entry.value;
                            } else {
                              next[entry.key] = entry.value;
                            }
                          }
                          onReplace(next);
                        },
                        onDelete: () {
                          final next = Map<String, dynamic>.from(map)..remove(key);
                          onReplace(next);
                        },
                      ),
                    if (keys.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Text(
                          'Empty object — tap + to add a field',
                          style: theme.textTheme.labelSmall?.copyWith(
                            fontSize: 10,
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
      ],
    );
  }
}

class _ListNode extends StatelessWidget {
  const _ListNode({
    required this.path,
    required this.label,
    required this.list,
    required this.expanded,
    required this.onToggle,
    required this.onReplace,
    this.onRename,
    this.onDelete,
    this.isRoot = false,
  });

  final String path;
  final String label;
  final List<dynamic> list;
  final Set<String> expanded;
  final ValueChanged<String> onToggle;
  final ValueChanged<dynamic> onReplace;
  final ValueChanged<String>? onRename;
  final VoidCallback? onDelete;
  final bool isRoot;

  bool get _isOpen => expanded.contains(path);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _NodeHeader(
          label: label,
          summary: '[${list.length}]',
          expanded: _isOpen,
          onToggle: () => onToggle(path),
          onRename: onRename,
          onDelete: onDelete,
          trailing: IconButton(
            tooltip: 'Add item',
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 26, minHeight: 26),
            iconSize: 15,
            onPressed: () {
              final next = List<dynamic>.from(list)..add('');
              onReplace(next);
              if (!_isOpen) onToggle(path);
            },
            icon: Icon(
              Icons.add_rounded,
              color: theme.colorScheme.primary.withValues(alpha: 0.85),
            ),
          ),
        ),
        if (_isOpen)
          Padding(
            padding: const EdgeInsets.only(left: 12),
            child: DecoratedBox(
              decoration: BoxDecoration(
                border: Border(
                  left: BorderSide(
                    color: theme.colorScheme.outlineVariant.withValues(alpha: 0.55),
                  ),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.only(left: 8),
                child: Column(
                  children: [
                    for (var i = 0; i < list.length; i++)
                      _JsonNode(
                        path: '$path$i/',
                        label: '[$i]',
                        value: list[i],
                        expanded: expanded,
                        onToggle: onToggle,
                        onReplace: (child) {
                          final next = List<dynamic>.from(list);
                          next[i] = child;
                          onReplace(next);
                        },
                        onDelete: () {
                          final next = List<dynamic>.from(list)..removeAt(i);
                          onReplace(next);
                        },
                      ),
                    if (list.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Text(
                          'Empty array — tap + to add an item',
                          style: theme.textTheme.labelSmall?.copyWith(
                            fontSize: 10,
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
      ],
    );
  }
}

enum _JsonValueType { string, number, boolean, nil, object, array }

class _PrimitiveNode extends StatefulWidget {
  const _PrimitiveNode({
    required this.label,
    required this.value,
    required this.onReplace,
    this.onRename,
    this.onDelete,
    this.isRoot = false,
  });

  final String label;
  final dynamic value;
  final ValueChanged<dynamic> onReplace;
  final ValueChanged<String>? onRename;
  final VoidCallback? onDelete;
  final bool isRoot;

  @override
  State<_PrimitiveNode> createState() => _PrimitiveNodeState();
}

class _PrimitiveNodeState extends State<_PrimitiveNode> {
  late TextEditingController _valueController;
  TextEditingController? _keyController;
  late _JsonValueType _type;

  @override
  void initState() {
    super.initState();
    _type = _typeOf(widget.value);
    _valueController = TextEditingController(text: _display(widget.value));
    if (widget.onRename != null) {
      _keyController = TextEditingController(text: widget.label);
    }
  }

  @override
  void didUpdateWidget(covariant _PrimitiveNode oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _type = _typeOf(widget.value);
      final next = _display(widget.value);
      if (_valueController.text != next) {
        _valueController.text = next;
      }
    }
    if (oldWidget.label != widget.label && _keyController != null) {
      _keyController!.text = widget.label;
    }
  }

  @override
  void dispose() {
    _valueController.dispose();
    _keyController?.dispose();
    super.dispose();
  }

  void _applyValue(String raw) {
    widget.onReplace(_parse(_type, raw));
  }

  void _changeType(_JsonValueType type) {
    setState(() => _type = type);
    final next = switch (type) {
      _JsonValueType.string => '',
      _JsonValueType.number => 0,
      _JsonValueType.boolean => false,
      _JsonValueType.nil => null,
      _JsonValueType.object => <String, dynamic>{},
      _JsonValueType.array => <dynamic>[],
    };
    if (type == _JsonValueType.string ||
        type == _JsonValueType.number ||
        type == _JsonValueType.boolean) {
      _valueController.text = _display(next);
    }
    widget.onReplace(next);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isContainer =
        _type == _JsonValueType.object || _type == _JsonValueType.array;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (_keyController != null)
            SizedBox(
              width: 96,
              child: TextField(
                controller: _keyController,
                style: theme.textTheme.labelSmall?.copyWith(
                  fontSize: 11,
                  fontFamily: 'monospace',
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.primary,
                ),
                decoration: const InputDecoration(
                  isDense: true,
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 6, vertical: 7),
                ),
                onSubmitted: widget.onRename,
                onEditingComplete: () =>
                    widget.onRename?.call(_keyController!.text),
              ),
            )
          else
            SizedBox(
              width: 72,
              child: Text(
                widget.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelSmall?.copyWith(
                  fontSize: 11,
                  fontFamily: 'monospace',
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
          const SizedBox(width: 6),
          SizedBox(
            width: 78,
            child: DropdownButtonHideUnderline(
              child: InputDecorator(
                decoration: const InputDecoration(
                  isDense: true,
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                ),
                child: DropdownButton<_JsonValueType>(
                  value: _type,
                  isDense: true,
                  isExpanded: true,
                  style: theme.textTheme.labelSmall?.copyWith(fontSize: 10),
                  items: const [
                    DropdownMenuItem(
                      value: _JsonValueType.string,
                      child: Text('string'),
                    ),
                    DropdownMenuItem(
                      value: _JsonValueType.number,
                      child: Text('number'),
                    ),
                    DropdownMenuItem(
                      value: _JsonValueType.boolean,
                      child: Text('bool'),
                    ),
                    DropdownMenuItem(
                      value: _JsonValueType.nil,
                      child: Text('null'),
                    ),
                    DropdownMenuItem(
                      value: _JsonValueType.object,
                      child: Text('object'),
                    ),
                    DropdownMenuItem(
                      value: _JsonValueType.array,
                      child: Text('array'),
                    ),
                  ],
                  onChanged: (type) {
                    if (type == null) return;
                    _changeType(type);
                  },
                ),
              ),
            ),
          ),
          const SizedBox(width: 6),
          if (!isContainer && _type != _JsonValueType.nil)
            Expanded(
              child: _type == _JsonValueType.boolean
                  ? Align(
                      alignment: Alignment.centerLeft,
                      child: Switch.adaptive(
                        value: widget.value == true,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        onChanged: (v) => widget.onReplace(v),
                      ),
                    )
                  : TextField(
                      controller: _valueController,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontSize: 11,
                        fontFamily: 'monospace',
                      ),
                      keyboardType: _type == _JsonValueType.number
                          ? const TextInputType.numberWithOptions(
                              decimal: true,
                              signed: true,
                            )
                          : TextInputType.text,
                      inputFormatters: _type == _JsonValueType.number
                          ? [
                              FilteringTextInputFormatter.allow(
                                RegExp(r'[0-9eE+\-.]'),
                              ),
                            ]
                          : null,
                      decoration: const InputDecoration(
                        isDense: true,
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 7,
                        ),
                      ),
                      onChanged: _applyValue,
                    ),
            )
          else if (_type == _JsonValueType.nil)
            Expanded(
              child: Text(
                'null',
                style: theme.textTheme.labelSmall?.copyWith(
                  fontSize: 11,
                  fontFamily: 'monospace',
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.45),
                ),
              ),
            )
          else
            const Spacer(),
          if (widget.onDelete != null)
            IconButton(
              tooltip: 'Remove',
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 26, minHeight: 26),
              iconSize: 15,
              onPressed: widget.onDelete,
              icon: Icon(
                Icons.close_rounded,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.45),
              ),
            ),
        ],
      ),
    );
  }
}

class _NodeHeader extends StatelessWidget {
  const _NodeHeader({
    required this.label,
    required this.summary,
    required this.expanded,
    required this.onToggle,
    this.onRename,
    this.onDelete,
    this.trailing,
  });

  final String label;
  final String summary;
  final bool expanded;
  final VoidCallback onToggle;
  final ValueChanged<String>? onRename;
  final VoidCallback? onDelete;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      height: 30,
      child: Row(
        children: [
          InkWell(
            onTap: onToggle,
            borderRadius: BorderRadius.circular(4),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
              child: Icon(
                expanded
                    ? Icons.expand_more_rounded
                    : Icons.chevron_right_rounded,
                size: 18,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
              ),
            ),
          ),
          if (onRename != null)
            SizedBox(
              width: 96,
              child: _InlineKeyField(initial: label, onSubmit: onRename!),
            )
          else
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                fontSize: 11,
                fontFamily: 'monospace',
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.primary,
              ),
            ),
          const SizedBox(width: 6),
          Text(
            summary,
            style: theme.textTheme.labelSmall?.copyWith(
              fontSize: 10,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.45),
            ),
          ),
          const Spacer(),
          ?trailing,
          if (onDelete != null)
            IconButton(
              tooltip: 'Remove',
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 26, minHeight: 26),
              iconSize: 15,
              onPressed: onDelete,
              icon: Icon(
                Icons.close_rounded,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.45),
              ),
            ),
        ],
      ),
    );
  }
}

class _InlineKeyField extends StatefulWidget {
  const _InlineKeyField({required this.initial, required this.onSubmit});

  final String initial;
  final ValueChanged<String> onSubmit;

  @override
  State<_InlineKeyField> createState() => _InlineKeyFieldState();
}

class _InlineKeyFieldState extends State<_InlineKeyField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initial);
  }

  @override
  void didUpdateWidget(covariant _InlineKeyField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initial != widget.initial &&
        _controller.text == oldWidget.initial) {
      _controller.text = widget.initial;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return TextField(
      controller: _controller,
      style: theme.textTheme.labelSmall?.copyWith(
        fontSize: 11,
        fontFamily: 'monospace',
        fontWeight: FontWeight.w700,
        color: theme.colorScheme.primary,
      ),
      decoration: const InputDecoration(
        isDense: true,
        border: OutlineInputBorder(),
        contentPadding: EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      ),
      onSubmitted: widget.onSubmit,
      onEditingComplete: () => widget.onSubmit(_controller.text),
    );
  }
}

_JsonValueType _typeOf(dynamic value) {
  if (value == null) return _JsonValueType.nil;
  if (value is bool) return _JsonValueType.boolean;
  if (value is num) return _JsonValueType.number;
  if (value is Map) return _JsonValueType.object;
  if (value is List) return _JsonValueType.array;
  return _JsonValueType.string;
}

String _display(dynamic value) {
  if (value == null) return '';
  if (value is String) return value;
  return value.toString();
}

dynamic _parse(_JsonValueType type, String raw) {
  return switch (type) {
    _JsonValueType.string => raw,
    _JsonValueType.number => num.tryParse(raw.trim()) ?? 0,
    _JsonValueType.boolean => raw.trim().toLowerCase() == 'true',
    _JsonValueType.nil => null,
    _JsonValueType.object => <String, dynamic>{},
    _JsonValueType.array => <dynamic>[],
  };
}

dynamic _clone(dynamic value) {
  if (value is Map) {
    return <String, dynamic>{
      for (final e in value.entries) e.key.toString(): _clone(e.value),
    };
  }
  if (value is List) {
    return <dynamic>[for (final e in value) _clone(e)];
  }
  return value;
}

Set<String> _collectContainerPaths(dynamic value, String path) {
  final paths = <String>{path};
  if (value is Map) {
    for (final entry in value.entries) {
      if (entry.value is Map || entry.value is List) {
        paths.addAll(_collectContainerPaths(entry.value, '$path${entry.key}/'));
      }
    }
  } else if (value is List) {
    for (var i = 0; i < value.length; i++) {
      final child = value[i];
      if (child is Map || child is List) {
        paths.addAll(_collectContainerPaths(child, '$path$i/'));
      }
    }
  }
  return paths;
}
