import 'package:flutter/material.dart';

class AppSearchBar extends StatelessWidget {
  const AppSearchBar({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.onChanged,
    this.isDesktop = false,
    this.hintText = 'Search',
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;
  final bool isDesktop;
  final String hintText;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final borderColor =
        theme.colorScheme.outlineVariant.withValues(alpha: 0.7);
    final iconColor = theme.colorScheme.onSurface.withValues(alpha: 0.55);
    final height = isDesktop ? 28.0 : 34.0;
    final fontSize = isDesktop ? 12.0 : 13.0;

    return SizedBox(
      height: height,
      child: ValueListenableBuilder<TextEditingValue>(
        valueListenable: controller,
        builder: (context, value, _) {
          return TextField(
            controller: controller,
            focusNode: focusNode,
            onChanged: onChanged,
            style: theme.textTheme.bodySmall?.copyWith(fontSize: fontSize),
            cursorHeight: isDesktop ? 14 : 16,
            textAlignVertical: TextAlignVertical.center,
            decoration: InputDecoration(
              isDense: true,
              hintText: hintText,
              hintStyle: theme.textTheme.bodySmall?.copyWith(
                fontSize: fontSize,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.45),
              ),
              prefixIcon: Icon(
                Icons.search,
                size: isDesktop ? 16 : 20,
                color: iconColor,
              ),
              prefixIconConstraints: BoxConstraints(
                minWidth: isDesktop ? 32 : 40,
                minHeight: height,
              ),
              suffixIcon: value.text.isEmpty
                  ? null
                  : IconButton(
                      tooltip: 'Clear',
                      padding: EdgeInsets.zero,
                      visualDensity: VisualDensity.compact,
                      constraints: BoxConstraints(
                        minWidth: isDesktop ? 28 : 36,
                        minHeight: isDesktop ? 28 : 36,
                      ),
                      icon: Icon(
                        Icons.close,
                        size: isDesktop ? 14 : 18,
                        color: iconColor,
                      ),
                      onPressed: () {
                        controller.clear();
                        onChanged('');
                        focusNode.requestFocus();
                      },
                    ),
              suffixIconConstraints: BoxConstraints(
                minWidth: isDesktop ? 28 : 36,
                minHeight: height,
              ),
              contentPadding: EdgeInsets.symmetric(
                horizontal: isDesktop ? 8 : 12,
                vertical: 0,
              ),
              filled: true,
              fillColor: theme.colorScheme.surface.withValues(alpha: 0.75),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(isDesktop ? 6 : 8),
                borderSide: BorderSide(color: borderColor),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(isDesktop ? 6 : 8),
                borderSide: BorderSide(color: borderColor),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(isDesktop ? 6 : 8),
                borderSide: BorderSide(
                  color: theme.colorScheme.primary.withValues(alpha: 0.7),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
