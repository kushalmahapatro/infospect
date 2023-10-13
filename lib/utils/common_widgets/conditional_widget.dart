import 'package:flutter/material.dart';

class ConditionalWidget extends StatelessWidget {
  final bool condition;
  final Widget ifTrue;
  final Widget ifFalse;
  const ConditionalWidget({
    super.key,
    required this.condition,
    required this.ifTrue,
    required this.ifFalse,
  });

  @override
  Widget build(BuildContext context) {
    if (condition) {
      return ifTrue;
    } else {
      return ifFalse;
    }
  }
}
