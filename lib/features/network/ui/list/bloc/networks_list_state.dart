part of 'networks_list_bloc.dart';

final class NetworksListState extends Equatable {
  const NetworksListState({
    this.calls = const [],
    this.filteredCalls = const [],
    this.searchedText = '',
    this.filters = const [],
  });

  final List<InfospectNetworkCall> calls;
  final List<InfospectNetworkCall> filteredCalls;
  final String searchedText;
  final List<PopupAction> filters;

  @override
  List<Object> get props => [calls, searchedText, filteredCalls, filters];

  NetworksListState copyWith({
    List<InfospectNetworkCall>? calls,
    List<InfospectNetworkCall>? filteredCalls,
    String? searchedText,
    List<PopupAction>? filters,
  }) {
    return NetworksListState(
      calls: calls ?? this.calls,
      filteredCalls: filteredCalls ?? this.filteredCalls,
      searchedText: searchedText ?? this.searchedText,
      filters: filters ?? this.filters,
    );
  }
}

final class CompressedNetworkCallLogsFile extends NetworksListState {
  const CompressedNetworkCallLogsFile({
    super.calls,
    super.filteredCalls,
    super.searchedText,
    super.filters,
    required this.sharableFile,
  });

  final File sharableFile;

  @override
  List<Object> get props => super.props..add(sharableFile);
}
