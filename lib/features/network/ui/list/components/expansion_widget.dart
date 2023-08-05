import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:infospect/features/network/ui/details/widgets/details_row_widget.dart';

class ExpansionWidget extends StatelessWidget {
  final String title;
  final List<Widget> children;
  final Widget? trailing;
  final bool initiallyExpanded;

  factory ExpansionWidget.map({
    required Map<String, dynamic> map,
    required String title,
    Widget? trailing,
    bool initiallyExpanded = true,
    Key? key,
  }) {
    return ExpansionWidget(
      key: key,
      title: title,
      trailing: trailing,
      initiallyExpanded: initiallyExpanded,
      children: [
        ...map.entries
            .mapIndexed(
              (i, e) => DetailsRowWidget(
                e.key,
                e.value.toString(),
                showDivider: i != map.length - 1,
              ),
            )
            .toList()
      ],
    );
  }

  const ExpansionWidget({
    super.key,
    required this.title,
    required this.children,
    this.trailing,
    this.initiallyExpanded = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      margin: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.black, width: 1),
      ),
      child: ExpansionTile(
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
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
              ),
            ),
            trailing ?? const SizedBox.shrink(),
          ],
        ),
        children: children,
      ),
    );
  }
}
