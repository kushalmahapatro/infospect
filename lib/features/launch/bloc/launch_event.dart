part of 'launch_bloc.dart';

@immutable
abstract class LaunchEvent {
  const LaunchEvent();
}

class TabChanged extends LaunchEvent {
  final int selectedTab;

  const TabChanged({required this.selectedTab});
}
