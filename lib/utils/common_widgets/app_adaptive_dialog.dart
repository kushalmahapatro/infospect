import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class AppAdaptiveDialog {
  static void show(
    BuildContext context, {
    required String tag,
    required String title,
    required String body,
    required VoidCallback onPositiveActionClick,
  }) {
    showDialog(
      context: context,
      builder: (context) {
        if (Platform.isMacOS || Platform.isIOS) {
          return CupertinoAlertDialog(
            title: Text(title),
            content: Text(body),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.pop(context, '${tag}_cancel'),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  onPositiveActionClick.call();
                  Navigator.pop(context, '${tag}_clear');
                },
                child: const Text('Go ahead'),
              ),
            ],
          );
        } else {
          return AlertDialog(
            title: Text(title),
            content: Text(body),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.pop(context, '${tag}_cancel'),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  onPositiveActionClick.call();
                  Navigator.pop(context, '${tag}_clear');
                },
                child: const Text('Go ahead'),
              ),
            ],
          );
        }
      },
    );
  }
}

extension StringExtension on String {
  int get removeDotAndToInt => int.tryParse(replaceAll('.', '')) ?? 0;
}
