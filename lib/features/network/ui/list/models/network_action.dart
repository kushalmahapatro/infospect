import 'package:flutter/material.dart';
import 'package:infospect/utils/models/action_model.dart';

enum NetworkActionType {
  method,
  status,
  share,
  clear,
}

abstract class NetworkAction {
  static ActionModel get filterModel {
    return ActionModel(
      icon: Icons.filter_alt_outlined,
      actions: const [
        PopupAction(
          id: NetworkActionType.method,
          name: "Method",
          subActions: [
            PopupAction(
              id: 'get',
              name: "GET",
            ),
            PopupAction(
              id: 'post',
              name: "POST",
            ),
            PopupAction(
              id: 'put',
              name: "PUT",
            ),
            PopupAction(
              id: 'delete',
              name: "DELETE",
            ),
            PopupAction(
              id: 'option',
              name: "OPTION",
            ),
          ],
        ),
        PopupAction(
          id: NetworkActionType.status,
          name: "Status",
          subActions: [
            PopupAction(
              id: 'success',
              name: "Success",
            ),
            PopupAction(
              id: 'error',
              name: "Error",
            ),
          ],
        ),
      ],
    );
  }

  static ActionModel<NetworkActionType> get menuModel {
    return ActionModel(
      icon: Icons.more_vert,
      actions: const [
        PopupAction(
          id: NetworkActionType.share,
          name: "Share",
        ),
        PopupAction(
          id: NetworkActionType.clear,
          name: "Clear",
        ),
      ],
    );
  }
}
