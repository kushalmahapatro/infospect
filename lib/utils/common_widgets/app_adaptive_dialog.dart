import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// A utility class that provides a static method to show platform-specific alert dialogs.
class AppAdaptiveDialog {
  static void show(
    BuildContext context, {
    required String tag,
    required String title,
    required String body,
    required VoidCallback onPositiveActionClick,
  }) {
    /// Displays a platform-specific alert dialog.
    ///
    /// - `context`: BuildContext required for showing the dialog.
    /// - `tag`: A unique identifier for the dialog.
    /// - `title`: The title of the dialog.
    /// - `body`: The body content of the dialog.
    /// - `onPositiveActionClick`: A callback that gets executed when the positive action button is clicked.
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
