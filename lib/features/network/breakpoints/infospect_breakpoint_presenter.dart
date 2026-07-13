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

/// Presents request/response breakpoint editors (dialog on mobile, window on desktop).
class InfospectBreakpointPresenter {
  InfospectBreakpointPresenter(this._infospect);

  final Infospect _infospect;

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

    final windowId = await openWindow(
      (context, id) => BreakpointInterceptScreen(
        phase: phase,
        initialPayload: payload,
        onContinue: (edited) async {
          _infospect.breakpointManager.completePending(
            sessionId,
            InfospectBreakpointResult.continueWith(edited),
          );
          await MultiViewDesktop.fromId(id).closeWindow();
        },
        onAbort: (edited) async {
          _infospect.breakpointManager.completePending(
            sessionId,
            InfospectBreakpointResult.abort(edited),
          );
          await MultiViewDesktop.fromId(id).closeWindow();
        },
      ),
      options: WindowOptions(
        title: '$title · ${payload.method} ${payload.endpoint}',
        size: const Size(920, 720),
        minimumSize: const Size(560, 420),
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
    final context = _infospect.context;
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

    final result = await showDialog<InfospectBreakpointResult>(
      context: context,
      barrierDismissible: false,
      useRootNavigator: true,
      builder: (dialogContext) {
        return Dialog.fullscreen(
          child: BreakpointInterceptScreen(
            phase: phase,
            initialPayload: payload,
            onContinue: (edited) {
              Navigator.of(dialogContext).pop(
                InfospectBreakpointResult.continueWith(edited),
              );
            },
            onAbort: (edited) {
              Navigator.of(dialogContext).pop(
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
