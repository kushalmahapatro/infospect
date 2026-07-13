import 'package:flutter/material.dart';
import 'package:infospect/utils/models/action_model.dart';

/// Enum that lists the types of actions that can be performed related to logs.
enum LogsActionType { level, share, clear }

/// An abstract class that provides data models for actions related to logs.
abstract class LogsAction {
  static ActionModel get filterModel {
    return ActionModel(
      icon: Icons.filter_list_rounded,
      title: 'Filter',
      actions: [
        PopupAction(
          id: LogsActionType.level,
          name: 'Log Level',
          icon: Icons.layers_outlined,
          subActions: DiagnosticLevel.values
              .map(
                (e) => PopupAction<dynamic>(
                  id: e.name,
                  name: e.name.toUpperCase(),
                ),
              )
              .toList(),
        ),
      ],
    );
  }

  static ActionModel<LogsActionType> get menuModel {
    return ActionModel(
      icon: Icons.more_horiz_rounded,
      title: 'More',
      actions: const [
        PopupAction<LogsActionType>(
          id: LogsActionType.share,
          name: 'Share',
          icon: Icons.ios_share_rounded,
        ),
        PopupAction<LogsActionType>(
          id: LogsActionType.clear,
          name: 'Clear',
          icon: Icons.delete_outline_rounded,
          isDestructive: true,
        ),
      ],
    );
  }
}
