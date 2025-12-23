part of 'infospect_helper.dart';

/// `InfospectMultiWindowHelper` aids the `Infospect` class in managing multi-window communication.
/// It provides functionalities for sending and receiving data between different windows,
/// especially in a desktop environment.
class InfospectMultiWindowHelper {
  /// The private constructor.
  ///
  /// - `infospect`: Reference to the main `Infospect` instance.
  const InfospectMultiWindowHelper._(Infospect infospect)
      : _infospect = infospect;

  final Infospect _infospect;

  /// Sends specified data to all sub windows.
  Future<void> _sendDataToSubWindow({required Map<String, List> data}) async {
    if (Platform.isAndroid || Platform.isIOS) return;
    List<WindowController> subWindows = [];

    try {
      subWindows = await WindowController.getAll();
      // Filter out the main window (id '0')
      subWindows = subWindows
          .where((w) => w.arguments == InfospectDataTransfer.windowName)
          .toList();
    } catch (_) {}

    /// Return if there's no sub windows
    if (subWindows.isEmpty) return;

    for (final window in subWindows) {
      try {
        await window.invokeMethod(InfospectDataTransfer.broadcast, data);
      } catch (_) {}
    }
  }

  /// Sends current network calls to all sub windows.
  void sendNetworkCalls() {
    final List data = (_infospect.networkCallsSubject.value)
        .map<Map<String, dynamic>>((e) => e.toMap())
        .toList();

    _sendDataToSubWindow(data: {'network': data});
  }

  /// Sends the provided logs or all logs to all sub windows.
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

  /// Sends the current theme mode to all sub windows.
  void sendThemeMode(bool isDarkTheme) {
    _sendDataToSubWindow(data: {
      'themeType': [isDarkTheme]
    });
  }

  /// Sets up the method handler to listen to data received by the main window.
  Future<void> handleMultiWindowReceivedData(BuildContext context) async {
    try {
      final controller = await WindowController.fromCurrentEngine();
      await controller.setWindowMethodHandler((call) async {
        return await _handleMethodCallback(context, call);
      });
    } catch (_) {}
  }

  /// Handles the data received from a sub window.
  Future<dynamic> _handleMethodCallback(
      BuildContext context, MethodCall call) async {
    _updateTheme(context, call);
    _updateLogs(call);
    _updateNetworkCalls(call);
  }

  /// Updates the network calls based on received data.
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

  /// Updates the logs based on received data.
  void _updateLogs(MethodCall call) {
    if (call.arguments is Map && (call.arguments as Map).containsKey('logs')) {
      for (final log in ((call.arguments as Map)['logs'] as List)) {
        Infospect.instance.infospectLogger.add(InfospectLog.fromMap(log));
      }
    }
  }

  /// Updates the theme based on received data.
  void _updateTheme(BuildContext context, MethodCall call) {
    if (call.arguments is Map &&
        (call.arguments as Map).containsKey('themeType')) {
      // Access the desktop theme notifier from navigation helper
      final themeNotifier =
          _infospect._infospectNavigationHelper.desktopThemeNotifier;
      if (themeNotifier != null) {
        themeNotifier.setTheme(
          ((call.arguments as Map)['themeType'] as List).firstOrNull ?? true,
        );
      }
    }
  }

  /// Sets up the method handler for the main window to process incoming data.
  Future<void> handleMainWindowReceiveData() async {
    if (Platform.isAndroid || Platform.isIOS) return;

    WindowMethodChannel channel =
        WindowMethodChannel(InfospectDataTransfer.channelName);
    channel.setMethodCallHandler(_handleMainWindowReceiveData);
  }

  /// Processes the incoming data for the main window.
  Future _handleMainWindowReceiveData(MethodCall call) async {
    if (call.method == InfospectDataTransfer.onSend) {
      if (call.arguments == MainWindowArguments.shareNetworkCallLogs) {
        final File? sharableFile = await InfospectUtil.shareNetworkCallLogs();
        if (sharableFile != null) {
          if (Infospect.instance.onShareAllNetworkCalls != null) {
            Infospect.instance.onShareAllNetworkCalls!(sharableFile.path);
            return;
          }
          final XFile file = XFile(sharableFile.path);
          SharePlus.instance.share(ShareParams(files: [file]));
        }
      } else if (call.arguments == MainWindowArguments.shareLogs) {
        final File? sharableFile = await InfospectUtil.shareLogs();
        if (sharableFile != null) {
          if (Infospect.instance.onShareAllLogs != null) {
            Infospect.instance.onShareAllLogs!(sharableFile.path);
            return;
          }
          final XFile file = XFile(sharableFile.path);
          SharePlus.instance.share(ShareParams(files: [file]));
        }
      } else if (call.arguments == MainWindowArguments.clearNetworkCallLogs) {
        Infospect.instance.clearAllNetworkCalls();
      } else if (call.arguments == MainWindowArguments.clearLogs) {
        Infospect.instance.clearAllLogs();
      }
    }
  }
}
