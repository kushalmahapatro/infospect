part of 'networks_list_bloc.dart';

class NetworksListState extends Equatable {
  const NetworksListState({
    this.calls = const [],
    this.filteredCalls = const [],
    this.searchedText = '',
  });

  final List<InfospectNetworkCall> calls;
  final List<InfospectNetworkCall> filteredCalls;
  final String searchedText;

  @override
  List<Object> get props => [calls, filteredCalls, searchedText];

  NetworksListState copyWith({
    List<InfospectNetworkCall>? calls,
    List<InfospectNetworkCall>? filteredCalls,
    String? searchedText,
  }) {
    return NetworksListState(
      calls: calls ?? this.calls,
      filteredCalls: filteredCalls ?? this.filteredCalls,
      searchedText: searchedText ?? this.searchedText,
    );
  }
}
