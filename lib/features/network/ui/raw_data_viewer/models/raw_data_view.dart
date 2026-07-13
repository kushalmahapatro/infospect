import 'package:flutter/material.dart';

enum RawDataView {
  beautified(value: 'Beautified', icon: Icons.data_object),
  treeView(value: 'Tree View', icon: Icons.account_tree_outlined);

  final String value;
  final IconData icon;
  const RawDataView({required this.value, required this.icon});
}
