import 'package:flutter/material.dart';
import 'package:infospect/features/network/ui/raw_data_viewer/screen/raw_data_viewer_screen.dart';
import 'package:infospect/infospect.dart';

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
          infospect.context ?? context,
          MaterialPageRoute(
            builder: (_) {
              return RawDataViewerScreen(
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
