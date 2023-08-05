import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:infospect/features/network/models/infospect_network_call.dart';
import 'package:meta/meta.dart';

part 'launch_event.dart';
part 'launch_state.dart';

class LaunchBloc extends Bloc<LaunchEvent, LaunchState> {
  LaunchBloc() : super(const LaunchState()) {
    on<TabChanged>(_onTabChanged);
  }

  FutureOr<void> _onTabChanged(TabChanged event, Emitter<LaunchState> emit) {
    emit(state.copyWith(selectedTab: event.selectedTab));
  }
}
