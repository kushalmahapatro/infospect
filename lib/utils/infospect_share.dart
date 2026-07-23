import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:infospect/utils/common_widgets/infospect_toast.dart';
import 'package:share_plus/share_plus.dart';

/// Safe sharing for Infospect.
///
/// On macOS multi-view apps (`multiview_desktop`), `share_plus` force-unwraps
/// `registrar.view`, which is nil and crashes the process. Those platforms use
/// Finder / clipboard fallbacks instead.
class InfospectShare {
  const InfospectShare._();

  static bool get _useMacosFallback => !kIsWeb && Platform.isMacOS;

  static Future<void> shareFiles(
    List<XFile> files, {
    String? subject,
    Rect? sharePositionOrigin,
    BuildContext? context,
  }) async {
    if (_useMacosFallback) {
      for (final file in files) {
        await Process.run('open', ['-R', file.path]);
      }
      if (context != null && context.mounted) {
        InfospectToast.show(
          context,
          'Revealed in Finder',
          icon: Icons.folder_open_rounded,
        );
      }
      return;
    }

    await SharePlus.instance.share(
      ShareParams(
        files: files,
        subject: subject,
        sharePositionOrigin: sharePositionOrigin,
      ),
    );
  }

  static Future<void> shareText(
    String text, {
    String? subject,
    Rect? sharePositionOrigin,
    BuildContext? context,
  }) async {
    if (_useMacosFallback) {
      await Clipboard.setData(ClipboardData(text: text));
      if (context != null && context.mounted) {
        InfospectToast.show(
          context,
          'Copied to clipboard',
          icon: Icons.copy_rounded,
        );
      }
      return;
    }

    await SharePlus.instance.share(
      ShareParams(
        text: text,
        subject: subject,
        sharePositionOrigin: sharePositionOrigin,
      ),
    );
  }
}
