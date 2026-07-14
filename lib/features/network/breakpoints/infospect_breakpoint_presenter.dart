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
/// compact window on desktop).
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
        compact: true,
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
        size: const Size(640, 520),
        minimumSize: const Size(480, 360),
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
