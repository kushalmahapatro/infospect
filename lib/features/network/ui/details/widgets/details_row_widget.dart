import 'package:flutter/material.dart';

class DetailsRowWidget extends StatelessWidget {
  final String name;
  final String value;
  final String? other;
  final bool showDivider;

  const DetailsRowWidget(this.name, this.value,
      {super.key, this.other, this.showDivider = true});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        if (name.isNotEmpty) ...[
          SelectableText(
            name,
            style: const TextStyle(
                fontWeight: FontWeight.w500, fontSize: 14, color: Colors.black),
          ),
          const SizedBox(height: 4),
        ],
        SelectableText(
          value,
          style: const TextStyle(fontSize: 12, color: Colors.black87),
        ),
        if (other != null) ...[
          const SizedBox(height: 4),
          SelectableText(
            other ?? '',
            style: const TextStyle(fontSize: 12, color: Colors.black87),
          ),
        ],
        const SizedBox(height: 8),
        Container(
          height: 1,
          width: double.maxFinite,
          color: showDivider ? Colors.black12 : Colors.transparent,
        ),
      ],
    );
  }
}
