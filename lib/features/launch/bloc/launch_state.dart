part of 'launch_bloc.dart';

@immutable
class LaunchState extends Equatable {
  final int selectedTab;

  const LaunchState({this.selectedTab = 0});

  @override
  List<Object> get props => [
        selectedTab,
      ];

  LaunchState copyWith({
    int? selectedTab,
    List<InfospectNetworkCall>? networkCalls,
  }) {
    return LaunchState(
      selectedTab: selectedTab ?? this.selectedTab,
    );
  }
}
