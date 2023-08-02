import 'package:flutter/material.dart';
import 'package:infospect/infospect.dart';
import 'package:infospect/network/ui/interceptor_details/components/raw_data_viewer.dart';

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
      onPressed: () {
        Navigator.push(
          infospect.context!,
          MaterialPageRoute(
            builder: (_) {
              return RawDataViewer(
                data: data,
                beautificationRequired: beautificationRequired,
              );
            },
          ),
        );
      },
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 12,
          color: Colors.blue,
        ),
      ),
    );
  }
}
