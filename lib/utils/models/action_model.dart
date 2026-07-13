import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

class ActionModel<T> {
  final IconData icon;
  final List<PopupAction<T>> actions;
  final String? title;

  ActionModel({
    required this.icon,
    required this.actions,
    this.title,
  });
}

class PopupAction<T> extends Equatable {
  final T id;
  final T? parentId;
  final String name;
  final List<PopupAction<T>> subActions;
  final bool isSelected;
  final IconData? icon;
  final bool isDestructive;

  const PopupAction({
    required this.name,
    required this.id,
    this.isSelected = false,
    this.subActions = const [],
    this.parentId,
    this.icon,
    this.isDestructive = false,
  });

  PopupAction<T> setParentId(T parentId) => PopupAction<T>(
        id: id,
        name: name,
        isSelected: isSelected,
        subActions: subActions,
        parentId: parentId ?? this.parentId,
        icon: icon,
        isDestructive: isDestructive,
      );

  bool get hasSubActions => subActions.isNotEmpty;

  @override
  List<Object?> get props =>
      [id, parentId, name, isSelected, subActions, icon, isDestructive];
}
