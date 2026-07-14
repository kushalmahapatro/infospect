import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:infospect/features/network/breakpoints/infospect_breakpoint_manager.dart';
import 'package:infospect/features/network/breakpoints/models/infospect_breakpoint_session.dart';
import 'package:infospect/features/network/breakpoints/ui/breakpoint_intercept_screen.dart';
import 'package:infospect/helpers/infospect_helper.dart';
import 'package:infospect/styling/themes/infospect_theme.dart';
import 'package:infospect/utils/infospect_util.dart';
import 'package:multiview_desktop/multiview_desktop.dart';

/// Presents request/response breakpoint editors (compact sheet on mobile,
/// native desktop window on desktop).
///
/// Desktop intercept windows are cached by session id so opening another
/// window (which rebuilds every multiview builder) does not wipe in-progress
/// edits. Multiple concurrent intercept windows are supported.
class InfospectBreakpointPresenter {
  InfospectBreakpointPresenter(this._infospect);

  final Infospect _infospect;

  /// Keeps intercept screen [Element]/s alive across multiview rebuilds.
  final Map<String, GlobalKey> _desktopScreenKeys = <String, GlobalKey>{};

  Future<InfospectBreakpointResult> present({
    required InfospectBreakpointPhase phase,
    required InfospectBreakpointPayload payload,
  }) async {
    final sessionId = InfospectBreakpointManager.newId();
    final completer =
        _infospect.breakpointManager.registerPending(sessionId);

    if (!kIsWeb &&
        InfospectUtil.isDesktop &&
        !_infospect.preferInAppBreakpointDialogs) {
      await _presentDesktop(
        sessionId: sessionId,
        phase: phase,
        payload: payload,
        completer: completer,
      );
    } else {
      await _presentMobile(
        sessionId: sessionId,
        phase: phase,
        payload: payload,
      );
    }

    return completer.future;
  }

  Future<void> _presentDesktop({
    required String sessionId,
    required InfospectBreakpointPhase phase,
    required InfospectBreakpointPayload payload,
    required Completer<InfospectBreakpointResult> completer,
  }) async {
    final darkTheme = _infospect.context != null
        ? Theme.of(_infospect.context!).brightness == Brightness.dark
        : true;

    final title = phase == InfospectBreakpointPhase.request
        ? 'Request Breakpoint'
        : 'Response Breakpoint';

    final screenKey = _desktopScreenKeys.putIfAbsent(
      sessionId,
      GlobalKey.new,
    );

    Future<void> finish(InfospectBreakpointResult result, int id) async {
      _desktopScreenKeys.remove(sessionId);
      _infospect.breakpointManager.completePending(sessionId, result);
      try {
        await MultiViewDesktop.fromId(id).closeWindow();
      } catch (_) {}
    }

    final windowId = await openWindow(
      (context, id) => BreakpointInterceptScreen(
        key: screenKey,
        phase: phase,
        initialPayload: payload,
        compact: true,
        desktop: true,
        onContinue: (edited) {
          unawaited(
            finish(
              InfospectBreakpointResult.continueWith(edited),
              id,
            ),
          );
        },
        onAbort: (edited) {
          unawaited(
            finish(
              InfospectBreakpointResult.abort(edited),
              id,
            ),
          );
        },
      ),
      options: WindowOptions(
        title: '$title · ${payload.method} ${payload.endpoint}',
        size: const Size(720, 580),
        minimumSize: const Size(520, 420),
        alignment: Alignment.center,
        shellOverrides: ViewShellOverrides(
          appearance: AppShellPatch(
            theme: InfospectTheme.lightTheme,
            darkTheme: InfospectTheme.darkTheme,
            themeMode: darkTheme ? ThemeMode.dark : ThemeMode.light,
          ),
        ),
      ),
    );

    void onWindowsChanged() {
      if (!MultiViewDesktop.allWindowViewIds.contains(windowId)) {
        MultiViewDesktop.allWindowIdsNotifier.removeListener(onWindowsChanged);
        _desktopScreenKeys.remove(sessionId);
        if (!completer.isCompleted) {
          _infospect.breakpointManager.completePending(
            sessionId,
            InfospectBreakpointResult.continueWith(payload),
          );
        }
      }
    }

    MultiViewDesktop.allWindowIdsNotifier.addListener(onWindowsChanged);
  }

  Future<void> _presentMobile({
    required String sessionId,
    required InfospectBreakpointPhase phase,
    required InfospectBreakpointPayload payload,
  }) async {
    // Prefer Infospect's own navigator when the inspector is open; otherwise
    // fall back to the host app navigator key.
    BuildContext? context = _infospect.context;
    if (context == null || !context.mounted) {
      InfospectUtil.log(
        'Breakpoint hit but no NavigatorKey context is available; '
        'continuing without edits.',
      );
      _infospect.breakpointManager.completePending(
        sessionId,
        InfospectBreakpointResult.continueWith(payload),
      );
      return;
    }

    final result = await showModalBottomSheet<InfospectBreakpointResult>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      enableDrag: false,
      isDismissible: false,
      useRootNavigator: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
      ),
      builder: (sheetContext) {
        final height = MediaQuery.sizeOf(sheetContext).height;
        return SizedBox(
          height: height * 0.72,
          child: BreakpointInterceptScreen(
            phase: phase,
            initialPayload: payload,
            compact: true,
            onContinue: (edited) {
              Navigator.of(sheetContext).pop(
                InfospectBreakpointResult.continueWith(edited),
              );
            },
            onAbort: (edited) {
              Navigator.of(sheetContext).pop(
                InfospectBreakpointResult.abort(edited),
              );
            },
          ),
        );
      },
    );

    _infospect.breakpointManager.completePending(
      sessionId,
      result ?? InfospectBreakpointResult.continueWith(payload),
    );
  }
}
