part of 'networks_list_bloc.dart';

sealed class NetworksListEvent extends Equatable {
  const NetworksListEvent();
}

final class CallsChanged extends NetworksListEvent {
  final List<InfospectNetworkCall> calls;

  const CallsChanged({required this.calls});

  @override
  List<Object?> get props => [calls];
}

final class NetworkLogsSearched extends NetworksListEvent {
  final String text;

  const NetworkLogsSearched({required this.text});

  @override
  List<Object?> get props => [text];
}

final class NetworkLogsFilterAdded extends NetworksListEvent {
  final PopupAction action;

  const NetworkLogsFilterAdded({required this.action});

  @override
  List<Object?> get props => [action];
}

final class NetworkLogsFilterRemoved extends NetworksListEvent {
  final PopupAction action;

  const NetworkLogsFilterRemoved({required this.action});

  @override
  List<Object?> get props => [action];
}

final class ShareNetworkLogsClicked extends NetworksListEvent {
  const ShareNetworkLogsClicked();

  @override
  List<Object?> get props => [];
}

final class ClearNetworkLogsClicked extends NetworksListEvent {
  const ClearNetworkLogsClicked();

  @override
  List<Object?> get props => [];
}
