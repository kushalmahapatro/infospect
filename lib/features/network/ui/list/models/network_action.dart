import 'package:flutter/material.dart';
import 'package:infospect/utils/models/action_model.dart';

enum NetworkActionType { method, status, share, clear, breakpoints }

abstract class NetworkAction {
  static ActionModel get filterModel {
    return ActionModel(
      icon: Icons.filter_list_rounded,
      title: 'Filter',
      actions: const [
        PopupAction(
          id: NetworkActionType.method,
          name: 'Method',
          icon: Icons.http_rounded,
          subActions: [
            PopupAction(id: 'get', name: 'GET'),
            PopupAction(id: 'post', name: 'POST'),
            PopupAction(id: 'put', name: 'PUT'),
            PopupAction(id: 'delete', name: 'DELETE'),
            PopupAction(id: 'option', name: 'OPTION'),
          ],
        ),
        PopupAction(
          id: NetworkActionType.status,
          name: 'Status',
          icon: Icons.dns_outlined,
          subActions: [
            PopupAction(
              id: 'success',
              name: 'Success',
              icon: Icons.check_circle_outline_rounded,
            ),
            PopupAction(
              id: 'error',
              name: 'Error',
              icon: Icons.error_outline_rounded,
            ),
          ],
        ),
      ],
    );
  }

  static ActionModel<NetworkActionType> get menuModel {
    return ActionModel(
      icon: Icons.more_horiz_rounded,
      title: 'More',
      actions: const [
        PopupAction(
          id: NetworkActionType.breakpoints,
          name: 'Breakpoints',
          icon: Icons.crisis_alert_outlined,
        ),
        PopupAction(
          id: NetworkActionType.share,
          name: 'Share',
          icon: Icons.ios_share_rounded,
        ),
        PopupAction(
          id: NetworkActionType.clear,
          name: 'Clear',
          icon: Icons.delete_outline_rounded,
          isDestructive: true,
        ),
      ],
    );
  }
}
