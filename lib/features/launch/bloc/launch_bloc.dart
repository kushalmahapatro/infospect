import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:infospect/features/network/models/infospect_network_call.dart';
import 'package:meta/meta.dart';

part 'launch_event.dart';
part 'launch_state.dart';

/// BLoC responsible for handling the state of the application's launch phase, especially related to tab changes.
class LaunchBloc extends Bloc<LaunchEvent, LaunchState> {
  LaunchBloc() : super(const LaunchState()) {
    /// Listen to tab changes.
    on<TabChanged>(_onTabChanged);
  }

  FutureOr<void> _onTabChanged(TabChanged event, Emitter<LaunchState> emit) {
    emit(state.copyWith(selectedTab: event.selectedTab));
  }
}
