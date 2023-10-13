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
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 4),
        ],
        SelectableText(
          value,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        if (other != null) ...[
          const SizedBox(height: 4),
          SelectableText(
            other ?? '',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
        const SizedBox(height: 8),
        Container(
          height: 1,
          width: double.maxFinite,
          color: showDivider
              ? Theme.of(context).colorScheme.outline
              : Colors.transparent,
        ),
      ],
    );
  }
}
