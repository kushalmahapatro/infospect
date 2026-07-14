import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// Keyboard shortcuts used by the Infospect desktop layout and host invoker.
///
/// Activators use ⌘ on Apple platforms and Ctrl elsewhere. Host apps that open
/// Infospect use [openInspectorActivators] (⌘⌥I / Ctrl+Alt+I).
abstract final class InfospectDesktopShortcuts {
  static bool get isApple =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.macOS ||
          defaultTargetPlatform == TargetPlatform.iOS);

  /// Primary modifier activator (⌘ on macOS, Ctrl on Windows/Linux).
  static SingleActivator primary(
    LogicalKeyboardKey key, {
    bool shift = false,
    bool alt = false,
  }) {
    return SingleActivator(
      key,
      meta: isApple,
      control: !isApple,
      shift: shift,
      alt: alt,
    );
  }

  static String primaryLabel(
    String key, {
    bool shift = false,
    bool alt = false,
  }) {
    final mod = isApple ? '⌘' : 'Ctrl';
    final parts = <String>[
      mod,
      if (alt) isApple ? '⌥' : 'Alt',
      if (shift) isApple ? '⇧' : 'Shift',
      key,
    ];
    return isApple ? parts.join() : parts.join('+');
  }

  // --- Infospect window ---

  static SingleActivator get networkTab => primary(LogicalKeyboardKey.digit1);
  static SingleActivator get logsTab => primary(LogicalKeyboardKey.digit2);
  static SingleActivator get breakpoints => primary(LogicalKeyboardKey.keyB);

  static SingleActivator get clearNetwork =>
      primary(LogicalKeyboardKey.keyK, shift: true);
  static SingleActivator get shareNetwork =>
      primary(LogicalKeyboardKey.keyS, shift: true);
  static SingleActivator get popOutNetwork =>
      primary(LogicalKeyboardKey.keyN, shift: true);

  static SingleActivator get clearLogs =>
      primary(LogicalKeyboardKey.keyL, shift: true);
  static SingleActivator get shareLogs =>
      primary(LogicalKeyboardKey.keyE, shift: true);
  static SingleActivator get popOutLogs =>
      primary(LogicalKeyboardKey.keyG, shift: true);

  static SingleActivator get closeWindow => primary(LogicalKeyboardKey.keyW);

  // --- Host: open Infospect (both platforms registered) ---

  static const SingleActivator openInspectorMac = SingleActivator(
    LogicalKeyboardKey.keyI,
    meta: true,
    alt: true,
  );

  static const SingleActivator openInspectorOther = SingleActivator(
    LogicalKeyboardKey.keyI,
    control: true,
    alt: true,
  );

  static List<SingleActivator> get openInspectorActivators => const [
        openInspectorMac,
        openInspectorOther,
      ];

  static String get openInspectorLabel =>
      isApple ? '⌘⌥I' : 'Ctrl+Alt+I';
}
