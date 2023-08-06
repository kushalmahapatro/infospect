part of 'networks_list_bloc.dart';

sealed class NetworksListEvent extends Equatable {
  const NetworksListEvent();

  @override
  List<Object> get props => [];
}

final class CallsChanged extends NetworksListEvent {
  final List<InfospectNetworkCall> calls;

  const CallsChanged({required this.calls});
}

final class NetworkLogsSearched extends NetworksListEvent {
  final String text;

  const NetworkLogsSearched({required this.text});
}
