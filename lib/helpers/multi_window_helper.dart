part of 'infospect_helper.dart';

class InfospectMultiWindowHelper {
  const InfospectMultiWindowHelper._(Infospect infospect)
      : _infospect = infospect;

  final Infospect _infospect;

  Future<void> _sendDataToSubWindow({required Map<String, List> data}) async {
    if (Platform.isAndroid || Platform.isIOS) return;
    List<int> subWindowIds = [];

    try {
      subWindowIds = await DesktopMultiWindow.getAllSubWindowIds();
    } catch (_) {}

    /// Return if there's no sub windows
    if (subWindowIds.isEmpty) return;

    for (final windowId in subWindowIds) {
      DesktopMultiWindow.invokeMethod(windowId, 'broadcast', data);
    }
  }

  void sendNetworkCalls() {
    final List data = (_infospect.networkCallsSubject.value)
        .map<Map<String, dynamic>>((e) => e.toMap())
        .toList();

    _sendDataToSubWindow(data: {'network': data});
  }

  void sendLogs([List<InfospectLog>? logs]) {
    if (logs == null) {
      _sendDataToSubWindow(data: _infospect.infospectLogger.logsMap);
    } else {
      _sendDataToSubWindow(
        data: {
          'logs': logs.map<Map<String, dynamic>>((e) => e.toMap()).toList()
        },
      );
    }
  }

  void sendThemeMode(bool isDarkTheme) {
    _sendDataToSubWindow(data: {
      'themeType': [isDarkTheme]
    });
  }

  void handleMultiWindowReceivedData(BuildContext context) {
    DesktopMultiWindow.setMethodHandler((call, fromWindowId) =>
        _handleMethodCallback(context, call, fromWindowId));
  }

  Future<dynamic> _handleMethodCallback(
      BuildContext context, MethodCall call, int fromWindowId) async {
    _updateTheme(context, call);
    _updateLogs(call);
    _updateNetworkCalls(call);
  }

  void _updateNetworkCalls(MethodCall call) {
    if (call.arguments is Map &&
        (call.arguments as Map).containsKey('network')) {
      if ((call.arguments as Map)['network'] is List &&
          ((call.arguments as Map)['network'] as List).isNotEmpty) {
        List<InfospectNetworkCall>? events = [];
        for (final log in ((call.arguments as Map)['network'] as List)) {
          try {
            final InfospectNetworkCall call = InfospectNetworkCall.fromMap(log);
            events.add(call);
          } catch (e, st) {
            debugPrint('Error while adding call: $e, stack: $st');
            Infospect.instance.infospectLogger.add(
              InfospectLog(
                level: DiagnosticLevel.error,
                message: 'Error while adding call: $e',
                stackTrace: st,
                error: e,
                timestamp: DateTime.now(),
              ),
            );
          }
        }
        if (events.isNotEmpty) {
          Infospect.instance.clearAllNetworkCalls();
          Infospect.instance.networkCallsSubject.add(events.reversed.toList());
        }
      }
    }
  }

  void _updateLogs(MethodCall call) {
    if (call.arguments is Map && (call.arguments as Map).containsKey('logs')) {
      for (final log in ((call.arguments as Map)['logs'] as List)) {
        Infospect.instance.infospectLogger.add(InfospectLog.fromMap(log));
      }
    }
  }

  void _updateTheme(BuildContext context, MethodCall call) {
    if (call.arguments is Map &&
        (call.arguments as Map).containsKey('themeType')) {
      context.read<DesktopThemeCubit>().setTheme(
            ((call.arguments as Map)['themeType'] as List).firstOrNull ?? true,
          );
    }
  }

  void handleMainWindowReceiveData() {
    DesktopMultiWindow.setMethodHandler(_handleMainWindowReceiveData);
  }

  Future _handleMainWindowReceiveData(MethodCall call, int fromWindowId) async {
    if (call.method == 'onSend') {
      if (call.arguments == MainWindowArguments.shareNetworkCallLogs.name) {
        final File? sharableFile = await InfospectUtil.shareNetworkCallLogs();
        if (sharableFile != null) {
          if (Infospect.instance.onShareAllNetworkCalls != null) {
            Infospect.instance.onShareAllNetworkCalls!(sharableFile.path);
            return;
          }
          final XFile file = XFile(sharableFile.path);
          Share.shareXFiles([file]);
        }
      } else if (call.arguments == MainWindowArguments.shareLogs.name) {
        final File? sharableFile = await InfospectUtil.shareLogs();
        if (sharableFile != null) {
          if (Infospect.instance.onShareAllLogs != null) {
            Infospect.instance.onShareAllLogs!(sharableFile.path);
            return;
          }
          final XFile file = XFile(sharableFile.path);
          Share.shareXFiles([file]);
        }
      } else if (call.arguments ==
          MainWindowArguments.clearNetworkCallLogs.name) {
        Infospect.instance.clearAllNetworkCalls();
      } else if (call.arguments == MainWindowArguments.clearLogs.name) {
        Infospect.instance.clearAllLogs();
      }
    }
  }
}
