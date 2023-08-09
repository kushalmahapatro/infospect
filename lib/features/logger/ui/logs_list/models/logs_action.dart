import 'package:flutter/material.dart';
import 'package:infospect/utils/models/action_model.dart';

enum LogsActionType {
  level,
  share,
  clear,
}

abstract class LogsAction {
  static ActionModel get filterModel {
    return ActionModel(
      icon: Icons.filter_alt_outlined,
      actions: [
        PopupAction(
          id: LogsActionType.level,
          name: "Log Level",
          subActions: DiagnosticLevel.values
              .map(
                (e) => PopupAction<dynamic>(
                  id: e.name,
                  name: e.name.toUpperCase(),
                ),
              )
              .toList(),
        ),
        const PopupAction<LogsActionType>(
          id: LogsActionType.share,
          name: "Share",
        ),
        const PopupAction<LogsActionType>(
          id: LogsActionType.clear,
          name: "Clear",
        ),
      ],
    );
  }

  static ActionModel get menuModel {
    return ActionModel(
      icon: Icons.more_vert,
      actions: [
        const PopupAction<LogsActionType>(
          id: LogsActionType.share,
          name: "Share",
        ),
        const PopupAction<LogsActionType>(
          id: LogsActionType.clear,
          name: "Clear",
        ),
      ],
    );
  }
}
