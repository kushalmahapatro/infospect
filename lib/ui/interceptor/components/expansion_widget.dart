import 'package:flutter/material.dart';

class ExpansionWidget extends StatelessWidget {
  final String title;
  final List<Widget> children;
  final Widget? trailing;
  final bool initiallyExpanded;
  const ExpansionWidget({
    super.key,
    required this.title,
    required this.children,
    this.trailing,
    this.initiallyExpanded = true,
  });

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      initiallyExpanded: initiallyExpanded,
      tilePadding: const EdgeInsets.symmetric(horizontal: 8),
      childrenPadding: const EdgeInsets.symmetric(horizontal: 10),
      expandedAlignment: Alignment.center,
      controlAffinity: ListTileControlAffinity.platform,
      shape: Border.all(color: Colors.transparent),
      textColor: Colors.black,
      title: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
            ),
          ),
          trailing ?? const SizedBox.shrink(),
        ],
      ),
      children: children,
    );
  }
}
