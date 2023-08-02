part of 'interceptor_bloc.dart';

@immutable
abstract class InterceptorEvent {
  const InterceptorEvent();
}

class TabChanged extends InterceptorEvent {
  final int selectedTab;

  const TabChanged({required this.selectedTab});
}

class CallsChanged extends InterceptorEvent {
  final List<InfospectNetworkCall> calls;

  const CallsChanged({required this.calls});
}
