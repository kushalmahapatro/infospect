import 'package:flutter/material.dart';
import 'package:infospect/infospect.dart';
import 'package:infospect/routes/routes.dart';

class TrailingWidget extends StatelessWidget {
  final String text;
  final Infospect infospect;
  final Map<String, dynamic> data;
  final bool beautificationRequired;
  const TrailingWidget(
      {super.key,
      required this.text,
      required this.infospect,
      required this.data,
      this.beautificationRequired = false});

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: () => mobileRoutes.rawData(
        context,
        data,
        beautificationRequired,
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.labelSmall,
      ),
    );
  }
}
