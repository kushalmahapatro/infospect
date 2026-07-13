import 'package:flutter/material.dart';
import 'package:infospect/features/network/ui/raw_data_viewer/models/raw_data_view.dart';

/// Compact desktop-style toolbar for JSON body viewing.
class JsonViewerDesktopToolbar extends StatelessWidget {
  const JsonViewerDesktopToolbar({
    super.key,
    required this.view,
    required this.onViewChanged,
    this.showViewToggle = true,
    this.showSearch = false,
    this.searchValue = '',
    this.onSearchChanged,
    this.showOpenInWindow = false,
    this.onOpenInWindow,
    this.showCopy = false,
    this.onCopy,
    this.title,
  });

  final RawDataView view;
  final ValueChanged<RawDataView> onViewChanged;
  final bool showViewToggle;
  final bool showSearch;
  final String searchValue;
  final ValueChanged<String>? onSearchChanged;
  final bool showOpenInWindow;
  final VoidCallback? onOpenInWindow;
  final bool showCopy;
  final VoidCallback? onCopy;
  final String? title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final borderColor =
        theme.colorScheme.outlineVariant.withValues(alpha: 0.55);

    return Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
        border: Border(bottom: BorderSide(color: borderColor)),
      ),
      child: Row(
        children: [
          if (title != null) ...[
            Text(
              title!,
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
            const SizedBox(width: 10),
            Container(width: 1, height: 16, color: borderColor),
            const SizedBox(width: 8),
          ],
          if (showViewToggle)
            _IconToggleGroup(
              view: view,
              onViewChanged: onViewChanged,
            ),
          if (showSearch) ...[
            const SizedBox(width: 10),
            Expanded(
              child: _CompactSearchField(
                value: searchValue,
                onChanged: onSearchChanged,
              ),
            ),
          ] else
            const Spacer(),
          if (showCopy && onCopy != null) ...[
            const SizedBox(width: 4),
            _ToolIconButton(
              icon: Icons.copy_rounded,
              tooltip: 'Copy body',
              onPressed: onCopy!,
            ),
          ],
          if (showOpenInWindow && onOpenInWindow != null) ...[
            const SizedBox(width: 4),
            _ToolIconButton(
              icon: Icons.open_in_new,
              tooltip: 'Open in new window',
              onPressed: onOpenInWindow!,
            ),
          ],
        ],
      ),
    );
  }
}

class _IconToggleGroup extends StatelessWidget {
  const _IconToggleGroup({
    required this.view,
    required this.onViewChanged,
  });

  final RawDataView view;
  final ValueChanged<RawDataView> onViewChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final borderColor =
        theme.colorScheme.outlineVariant.withValues(alpha: 0.7);

    return Container(
      height: 26,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: borderColor),
        color: theme.colorScheme.surface.withValues(alpha: 0.6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final option in RawDataView.values) ...[
            if (option != RawDataView.values.first)
              Container(width: 1, height: 14, color: borderColor),
            _ToolIconButton(
              icon: option.icon,
              tooltip: option.value,
              selected: view == option,
              onPressed: () => onViewChanged(option),
              dense: true,
            ),
          ],
        ],
      ),
    );
  }
}

class _ToolIconButton extends StatelessWidget {
  const _ToolIconButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.selected = false,
    this.dense = false,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;
  final bool selected;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final selectedColor = theme.colorScheme.primary.withValues(alpha: 0.14);
    final iconColor = selected
        ? theme.colorScheme.primary
        : theme.colorScheme.onSurface.withValues(alpha: 0.72);

    return Tooltip(
      message: tooltip,
      waitDuration: const Duration(milliseconds: 400),
      child: Material(
        color: selected ? selectedColor : Colors.transparent,
        borderRadius: BorderRadius.circular(dense ? 5 : 6),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(dense ? 5 : 6),
          child: SizedBox(
            width: dense ? 28 : 30,
            height: dense ? 24 : 28,
            child: Icon(icon, size: 15, color: iconColor),
          ),
        ),
      ),
    );
  }
}

class _CompactSearchField extends StatefulWidget {
  const _CompactSearchField({
    required this.value,
    this.onChanged,
  });

  final String value;
  final ValueChanged<String>? onChanged;

  @override
  State<_CompactSearchField> createState() => _CompactSearchFieldState();
}

class _CompactSearchFieldState extends State<_CompactSearchField> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value);
    _focusNode = FocusNode();
  }

  @override
  void didUpdateWidget(covariant _CompactSearchField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != _controller.text) {
      _controller.text = widget.value;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final borderColor =
        theme.colorScheme.outlineVariant.withValues(alpha: 0.7);

    return SizedBox(
      height: 26,
      child: TextField(
        controller: _controller,
        focusNode: _focusNode,
        onChanged: widget.onChanged,
        style: theme.textTheme.bodySmall?.copyWith(fontSize: 12),
        cursorHeight: 14,
        decoration: InputDecoration(
          isDense: true,
          hintText: 'Search',
          hintStyle: theme.textTheme.bodySmall?.copyWith(
            fontSize: 12,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.45),
          ),
          prefixIcon: Icon(
            Icons.search,
            size: 14,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
          ),
          prefixIconConstraints: const BoxConstraints(
            minWidth: 28,
            minHeight: 26,
          ),
          suffixIcon: widget.value.isEmpty
              ? null
              : IconButton(
                  tooltip: 'Clear',
                  padding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                  constraints: const BoxConstraints(
                    minWidth: 24,
                    minHeight: 24,
                  ),
                  icon: Icon(
                    Icons.close,
                    size: 13,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
                  ),
                  onPressed: () {
                    _controller.clear();
                    widget.onChanged?.call('');
                  },
                ),
          suffixIconConstraints: const BoxConstraints(
            minWidth: 24,
            minHeight: 24,
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 8),
          filled: true,
          fillColor: theme.colorScheme.surface.withValues(alpha: 0.75),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide: BorderSide(color: borderColor),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide: BorderSide(color: borderColor),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide: BorderSide(
              color: theme.colorScheme.primary.withValues(alpha: 0.7),
            ),
          ),
        ),
      ),
    );
  }
}
