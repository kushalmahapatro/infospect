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
}
