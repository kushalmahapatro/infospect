import 'package:flutter/material.dart';

class DetailsRowWidget extends StatelessWidget {
  final String name;
  final String value;
  final bool nested;
  const DetailsRowWidget(this.name, this.value,
      {super.key, this.nested = false});

  @override
  Widget build(BuildContext context) {
    final Widget wrap = Wrap(
      crossAxisAlignment: WrapCrossAlignment.start,
      children: [
        SelectableText(
          name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        const Padding(
          padding: EdgeInsets.only(left: 5),
        ),
        SelectableText(value),
        const Padding(
          padding: EdgeInsets.only(bottom: 18),
        )
      ],
    );

    if (nested) {
      return Row(
        children: [
          const SizedBox(width: 16),
          Flexible(child: wrap),
        ],
      );
    }
    return wrap;
  }
}
