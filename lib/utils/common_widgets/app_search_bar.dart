import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class AppSearchBar extends StatelessWidget {
  const AppSearchBar({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.onChanged,
    this.isDesktop = false,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;
  final bool isDesktop;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: isDesktop ? 28 : null,
      child: CupertinoSearchTextField(
        padding: isDesktop
            ? EdgeInsets.zero
            : const EdgeInsetsDirectional.fromSTEB(5.5, 8, 5.5, 8),
        style: isDesktop
            ? Theme.of(context).textTheme.labelSmall
            : Theme.of(context).textTheme.labelLarge,
        placeholderStyle: isDesktop
            ? Theme.of(context)
                .textTheme
                .labelSmall
                ?.copyWith(color: Colors.grey)
            : null,
        controller: controller,
        focusNode: focusNode,
        itemSize: isDesktop ? 16 : 20,
        prefixInsets: isDesktop
            ? const EdgeInsetsDirectional.only(start: 8, end: 4, bottom: 2)
            : const EdgeInsetsDirectional.fromSTEB(6, 0, 0, 3),
        onChanged: (value) {
          onChanged.call(value);
        },
      ),
    );
  }
}
