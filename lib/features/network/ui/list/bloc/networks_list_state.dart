part of 'networks_list_bloc.dart';

class NetworksListState extends Equatable {
  const NetworksListState({
    this.calls = const [],
  });

  final List<InfospectNetworkCall> calls;

  @override
  List<Object> get props => [calls];

  NetworksListState copyWith({
    List<InfospectNetworkCall>? calls,
  }) {
    return NetworksListState(
      calls: calls ?? this.calls,
    );
  }
}
