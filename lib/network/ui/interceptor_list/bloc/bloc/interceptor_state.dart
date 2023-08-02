part of 'interceptor_bloc.dart';

@immutable
class InterceptorState extends Equatable {
  final int selectedTab;
  final List<InfospectNetworkCall> networkCalls;

  const InterceptorState({
    this.selectedTab = 0,
    this.networkCalls = const [],
  });

  @override
  List<Object> get props => [selectedTab, ...networkCalls];

  InterceptorState copyWith({
    int? selectedTab,
    List<InfospectNetworkCall>? networkCalls,
  }) {
    return InterceptorState(
      selectedTab: selectedTab ?? this.selectedTab,
      networkCalls: networkCalls ?? this.networkCalls,
    );
  }
}
