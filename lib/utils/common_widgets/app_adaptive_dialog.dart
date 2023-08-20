import 'package:flutter/material.dart';

class AppAdaptiveDialog {
  static void show(
    BuildContext context, {
    required String tag,
    required String title,
    required String body,
    required VoidCallback onPositiveActionClick,
  }) {
    showAdaptiveDialog(
      context: context,
      builder: (context) {
        return AlertDialog.adaptive(
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
      },
    );
  }
}
