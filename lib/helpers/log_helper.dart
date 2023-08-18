part of 'infospect_helper.dart';

class InfospectLogHelper {
  const InfospectLogHelper._(Infospect infospect) : _infospect = infospect;
  final Infospect _infospect;

  void addLog(InfospectLog log) {
    _infospect.infospectLogger.add(log);

    _infospect.sendLogs([log]);
  }

  void addLogs(List<InfospectLog> logs) {
    _infospect.infospectLogger.logs.addAll(logs);

    _infospect.sendLogs(logs);
  }
}
