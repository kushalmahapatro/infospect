import 'package:flutter/material.dart';

enum RawDataView {
  beautified(value: 'Beautified', icon: Icons.code),
  treeView(value: 'Tree View', icon: Icons.list);

  final String value;
  final IconData icon;
  const RawDataView({required this.value, required this.icon});
}
