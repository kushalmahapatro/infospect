import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:infospect/utils/models/action_model.dart';

class AppBarActionWidget<T> extends StatelessWidget {
  const AppBarActionWidget({
    super.key,
    required this.actionModel,
    required this.onItemSelected,
    this.selected = false,
    this.selectedActions = const [],
  });

  final ActionModel<T> actionModel;
  final ValueChanged<PopupAction<T>> onItemSelected;
  final bool selected;
  final List<PopupAction> selectedActions;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<PopupAction<T>>(
      itemBuilder: (_) {
        return actionModel.actions.map((action) {
          if (action.subActions.isEmpty) {
            return PopupMenuItem<PopupAction<T>>(
              value: action,
              child: _MenuItem(
                action: action,
                isSubAction: true,
                selectedActions: selectedActions,
              ),
            );
          }

          return PopupMenuItem<PopupAction<T>>(
            value: action,
            child: PopupMenuButton<PopupAction<T>>(
              itemBuilder: (_) {
                return action.subActions.map(
                  (subAction) {
                    return PopupMenuItem<PopupAction<T>>(
                      value: subAction,
                      child: _MenuItem(
                        action: subAction,
                        isSubAction: true,
                        selectedActions: selectedActions,
                      ),
                    );
                  },
                ).toList();
              },
              onSelected: (value) {
                onItemSelected.call(value.setParentId(action.id));
                Navigator.of(context).pop();
              },
              padding: EdgeInsets.zero,
              tooltip: '',
              child: _MenuItem(
                action: action,
                selectedActions: selectedActions,
              ),
            ),
          );
        }).toList();
      },
      onSelected: (value) {
        final selectedAction = actionModel.actions
            .firstWhereOrNull((element) => element.name == value.name);
        if (selectedAction != null && selectedAction.subActions.isEmpty) {
          onItemSelected.call(value);
        }
      },
      tooltip: '',
      child: Container(
        width: 40,
        height: 40,
        padding: const EdgeInsets.all(8.0),
        child: Stack(
          alignment: Alignment.center,
          children: [
            PositionedDirectional(
              end: 0,
              top: 0,
              child: Icon(
                Icons.circle,
                color: selected ? Colors.red : Colors.transparent,
                size: 10,
              ),
            ),
            Icon(actionModel.icon),
          ],
        ),
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  const _MenuItem({
    required this.action,
    this.isSubAction = false,
    this.selectedActions = const [],
  });

  final PopupAction action;
  final bool isSubAction;
  final List<PopupAction> selectedActions;

  @override
  Widget build(BuildContext context) {
    bool selected = selectedActions.firstWhereOrNull(
          (element) => isSubAction
              ? element.id == action.id
              : element.parentId == action.id,
        ) !=
        null;
    Widget widget = SizedBox(
      height: 50,
      child: Row(
        children: [
          Icon(
            Icons.circle,
            color: selected ? Colors.red : Colors.transparent,
            size: 10,
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 4),
              color: Colors.transparent,
              child: Text(action.name),
            ),
          ),
          if (action.subActions.isNotEmpty) const Icon(Icons.arrow_right)
        ],
      ),
    );

    if (action.subActions.isEmpty && !isSubAction) {
      return GestureDetector(
        onTap: () {
          if (action.subActions.isEmpty) {
            Navigator.of(context).pop();
          }
        },
        child: widget,
      );
    }

    return widget;
  }
}
