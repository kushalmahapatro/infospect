import 'package:flutter/material.dart';

class DetailsRowWidget extends StatelessWidget {
  final String name;
  final String value;
  final String? other;
  const DetailsRowWidget(this.name, this.value, {super.key, this.other});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        SelectableText(
          name,
          style: const TextStyle(
              fontWeight: FontWeight.w500, fontSize: 14, color: Colors.black),
        ),
        const SizedBox(height: 4),
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
          width: double.infinity,
          color: Colors.black12,
        ),
      ],
    );
  }
}
