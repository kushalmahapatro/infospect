import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:infospect/utils/infospect_util.dart';
import 'package:infospect/utils/models/action_model.dart';

/// App-bar action that opens a native-feeling filter or overflow menu.
///
/// Desktop uses Material 3 cascading [MenuAnchor] menus.
/// Mobile uses a modal bottom sheet with grouped sections / action rows.
class AppBarActionWidget<T> extends StatelessWidget {
  const AppBarActionWidget({
    super.key,
    required this.actionModel,
    required this.onItemSelected,
    this.selected = false,
    this.selectedActions = const [],
    this.tooltip,
  });

  final ActionModel<T> actionModel;
  final ValueChanged<PopupAction<T>> onItemSelected;
  final bool selected;
  final List<PopupAction> selectedActions;
  final String? tooltip;

  bool get _isDesktop {
    try {
      return InfospectUtil.isDesktop;
    } catch (_) {
      return false;
    }
  }

  bool get _hasNestedActions =>
      actionModel.actions.any((action) => action.hasSubActions);

  @override
  Widget build(BuildContext context) {
    if (_isDesktop) {
      return _DesktopActionMenu<T>(
        actionModel: actionModel,
        onItemSelected: onItemSelected,
        selected: selected,
        selectedActions: selectedActions,
        tooltip: tooltip,
      );
    }

    return _MobileActionTrigger<T>(
      actionModel: actionModel,
      onItemSelected: onItemSelected,
      selected: selected,
      selectedActions: selectedActions,
      tooltip: tooltip,
      hasNestedActions: _hasNestedActions,
    );
  }
}

class _ActionIconButton extends StatelessWidget {
  const _ActionIconButton({
    required this.icon,
    required this.selected,
    required this.isDesktop,
    required this.onPressed,
    this.tooltip,
  });

  final IconData icon;
  final bool selected;
  final bool isDesktop;
  final VoidCallback onPressed;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final buttonSize = isDesktop ? 28.0 : 40.0;
    final iconSize = isDesktop ? 16.0 : 22.0;
    final iconColor = selected
        ? theme.colorScheme.primary
        : theme.colorScheme.onSurface.withValues(alpha: 0.72);

    final button = SizedBox(
      width: buttonSize,
      height: buttonSize,
      child: Material(
        color: selected
            ? theme.colorScheme.primary.withValues(alpha: 0.14)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(isDesktop ? 5 : 8),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(isDesktop ? 5 : 8),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Icon(icon, size: iconSize, color: iconColor),
              if (selected)
                Positioned(
                  right: isDesktop ? 3 : 6,
                  top: isDesktop ? 3 : 6,
                  child: Container(
                    width: isDesktop ? 5 : 7,
                    height: isDesktop ? 5 : 7,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );

    if (tooltip == null || tooltip!.isEmpty) return button;
    return Tooltip(
      message: tooltip!,
      waitDuration: const Duration(milliseconds: 400),
      child: button,
    );
  }
}

// ─── Desktop: cascading MenuAnchor ───────────────────────────────────────────

class _DesktopActionMenu<T> extends StatefulWidget {
  const _DesktopActionMenu({
    required this.actionModel,
    required this.onItemSelected,
    required this.selected,
    required this.selectedActions,
    this.tooltip,
  });

  final ActionModel<T> actionModel;
  final ValueChanged<PopupAction<T>> onItemSelected;
  final bool selected;
  final List<PopupAction> selectedActions;
  final String? tooltip;

  @override
  State<_DesktopActionMenu<T>> createState() => _DesktopActionMenuState<T>();
}

class _DesktopActionMenuState<T> extends State<_DesktopActionMenu<T>> {
  final MenuController _controller = MenuController();

  bool _isChecked(PopupAction action, {required bool isLeaf}) {
    return widget.selectedActions.firstWhereOrNull(
          (element) => isLeaf
              ? element.id == action.id
              : element.parentId == action.id,
        ) !=
        null;
  }

  MenuStyle get _menuStyle {
    final theme = Theme.of(context);
    return MenuStyle(
      backgroundColor: WidgetStatePropertyAll(theme.colorScheme.surface),
      surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
      elevation: const WidgetStatePropertyAll(6),
      shadowColor: WidgetStatePropertyAll(
        theme.colorScheme.shadow.withValues(alpha: 0.18),
      ),
      shape: WidgetStatePropertyAll(
        RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.55),
          ),
        ),
      ),
      padding: const WidgetStatePropertyAll(
        EdgeInsets.symmetric(vertical: 4),
      ),
    );
  }

  ButtonStyle get _itemStyle {
    final theme = Theme.of(context);
    return ButtonStyle(
      visualDensity: VisualDensity.compact,
      minimumSize: const WidgetStatePropertyAll(Size(168, 30)),
      maximumSize: const WidgetStatePropertyAll(Size(260, 30)),
      padding: const WidgetStatePropertyAll(
        EdgeInsets.symmetric(horizontal: 10),
      ),
      textStyle: WidgetStatePropertyAll(
        theme.textTheme.bodySmall?.copyWith(fontSize: 12, height: 1.2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return MenuAnchor(
      controller: _controller,
      consumeOutsideTap: true,
      style: _menuStyle,
      alignmentOffset: const Offset(0, 4),
      builder: (context, controller, child) {
        return _ActionIconButton(
          icon: widget.actionModel.icon,
          selected: widget.selected,
          isDesktop: true,
          tooltip: widget.tooltip,
          onPressed: () {
            if (controller.isOpen) {
              controller.close();
            } else {
              controller.open();
            }
          },
        );
      },
      menuChildren: widget.actionModel.actions.map((action) {
        if (action.hasSubActions) {
          return SubmenuButton(
            style: _itemStyle,
            menuStyle: _menuStyle,
            alignmentOffset: const Offset(4, -4),
            leadingIcon: SizedBox(
              width: 16,
              child: action.icon != null
                  ? Icon(
                      action.icon,
                      size: 14,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    )
                  : (_isChecked(action, isLeaf: false)
                      ? Icon(
                          Icons.check_rounded,
                          size: 14,
                          color: theme.colorScheme.primary,
                        )
                      : null),
            ),
            menuChildren: action.subActions.map((subAction) {
              final checked = _isChecked(subAction, isLeaf: true);
              return MenuItemButton(
                style: _itemStyle,
                leadingIcon: SizedBox(
                  width: 16,
                  child: checked
                      ? Icon(
                          Icons.check_rounded,
                          size: 14,
                          color: theme.colorScheme.primary,
                        )
                      : (subAction.icon != null
                          ? Icon(
                              subAction.icon,
                              size: 14,
                              color: theme.colorScheme.onSurface
                                  .withValues(alpha: 0.65),
                            )
                          : null),
                ),
                onPressed: () {
                  widget.onItemSelected(subAction.setParentId(action.id));
                  _controller.close();
                },
                child: Text(
                  subAction.name,
                  style: TextStyle(
                    fontWeight: checked ? FontWeight.w600 : FontWeight.w400,
                    color: checked
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurface,
                  ),
                ),
              );
            }).toList(),
            child: Text(action.name),
          );
        }

        final checked = _isChecked(action, isLeaf: true);
        final destructive = action.isDestructive;
        final foreground = destructive
            ? theme.colorScheme.error
            : (checked
                ? theme.colorScheme.primary
                : theme.colorScheme.onSurface);

        return MenuItemButton(
          style: _itemStyle.copyWith(
            foregroundColor: WidgetStatePropertyAll(foreground),
          ),
          leadingIcon: SizedBox(
            width: 16,
            child: action.icon != null
                ? Icon(action.icon, size: 14, color: foreground)
                : (checked
                    ? Icon(
                        Icons.check_rounded,
                        size: 14,
                        color: theme.colorScheme.primary,
                      )
                    : null),
          ),
          onPressed: () {
            widget.onItemSelected(action);
            _controller.close();
          },
          child: Text(
            action.name,
            style: TextStyle(
              fontWeight: checked ? FontWeight.w600 : FontWeight.w400,
              color: foreground,
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ─── Mobile: bottom sheet ────────────────────────────────────────────────────

class _MobileActionTrigger<T> extends StatelessWidget {
  const _MobileActionTrigger({
    required this.actionModel,
    required this.onItemSelected,
    required this.selected,
    required this.selectedActions,
    required this.hasNestedActions,
    this.tooltip,
  });

  final ActionModel<T> actionModel;
  final ValueChanged<PopupAction<T>> onItemSelected;
  final bool selected;
  final List<PopupAction> selectedActions;
  final bool hasNestedActions;
  final String? tooltip;

  Future<void> _openSheet(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      showDragHandle: true,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) {
        if (hasNestedActions) {
          return _FilterBottomSheet<T>(
            actionModel: actionModel,
            selectedActions: selectedActions,
            onItemSelected: (action) {
              // Pop the sheet first so a follow-up push is not immediately popped.
              Navigator.of(sheetContext).pop();
              WidgetsBinding.instance.addPostFrameCallback((_) {
                onItemSelected(action);
              });
            },
          );
        }

        return _OverflowBottomSheet<T>(
          actionModel: actionModel,
          onItemSelected: (action) {
            // Pop the sheet first so a follow-up push is not immediately popped.
            Navigator.of(sheetContext).pop();
            WidgetsBinding.instance.addPostFrameCallback((_) {
              onItemSelected(action);
            });
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return _ActionIconButton(
      icon: actionModel.icon,
      selected: selected,
      isDesktop: false,
      tooltip: tooltip,
      onPressed: () => _openSheet(context),
    );
  }
}

class _FilterBottomSheet<T> extends StatelessWidget {
  const _FilterBottomSheet({
    required this.actionModel,
    required this.selectedActions,
    required this.onItemSelected,
  });

  final ActionModel<T> actionModel;
  final List<PopupAction> selectedActions;
  final ValueChanged<PopupAction<T>> onItemSelected;

  bool _isChecked(PopupAction action) {
    return selectedActions.firstWhereOrNull(
          (element) => element.id == action.id,
        ) !=
        null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final maxHeight = MediaQuery.sizeOf(context).height * 0.72;

    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: maxHeight),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
            child: Text(
              actionModel.title ?? 'Filter',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Flexible(
            child: ListView(
              shrinkWrap: true,
              padding: const EdgeInsets.fromLTRB(8, 0, 8, 20),
              children: [
                for (final group in actionModel.actions) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
                    child: Row(
                      children: [
                        if (group.icon != null) ...[
                          Icon(
                            group.icon,
                            size: 14,
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.55),
                          ),
                          const SizedBox(width: 6),
                        ],
                        Text(
                          group.name.toUpperCase(),
                          style: theme.textTheme.labelSmall?.copyWith(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.6,
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.5),
                          ),
                        ),
                      ],
                    ),
                  ),
                  for (final option in group.subActions)
                    _SheetTile(
                      label: option.name,
                      icon: option.icon,
                      selected: _isChecked(option),
                      onTap: () =>
                          onItemSelected(option.setParentId(group.id)),
                    ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OverflowBottomSheet<T> extends StatelessWidget {
  const _OverflowBottomSheet({
    required this.actionModel,
    required this.onItemSelected,
  });

  final ActionModel<T> actionModel;
  final ValueChanged<PopupAction<T>> onItemSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 0, 8, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if ((actionModel.title ?? '').isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                child: Text(
                  actionModel.title!,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            for (final action in actionModel.actions)
              _SheetTile(
                label: action.name,
                icon: action.icon,
                destructive: action.isDestructive,
                onTap: () => onItemSelected(action),
              ),
            const SizedBox(height: 4),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
          ],
        ),
      ),
    );
  }
}

class _SheetTile extends StatelessWidget {
  const _SheetTile({
    required this.label,
    required this.onTap,
    this.icon,
    this.selected = false,
    this.destructive = false,
  });

  final String label;
  final IconData? icon;
  final bool selected;
  final bool destructive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = destructive
        ? theme.colorScheme.error
        : (selected
            ? theme.colorScheme.primary
            : theme.colorScheme.onSurface);

    return Material(
      color: selected
          ? theme.colorScheme.primary.withValues(alpha: 0.08)
          : Colors.transparent,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Row(
            children: [
              SizedBox(
                width: 24,
                child: selected
                    ? Icon(Icons.check_rounded, size: 18, color: color)
                    : (icon != null
                        ? Icon(icon, size: 18, color: color)
                        : null),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontSize: 16,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
