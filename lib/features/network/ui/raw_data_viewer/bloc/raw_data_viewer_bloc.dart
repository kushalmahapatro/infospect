import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:infospect/features/network/ui/raw_data_viewer/models/raw_data_view.dart';

part 'raw_data_viewer_event.dart';
part 'raw_data_viewer_state.dart';

typedef RawDataViewerSelector<T>
    = BlocSelector<RawDataViewerBloc, RawDataViewerState, T>;
typedef RawDataViewerBuilder
    = BlocBuilder<RawDataViewerBloc, RawDataViewerState>;

class RawDataViewerBloc extends Bloc<RawDataViewerEvent, RawDataViewerState> {
  RawDataViewerBloc() : super(const RawDataViewerState()) {
    on<SearchValueChanged>(_onSearchValueChanged);
    on<RawDataViewChanged>(_onRawDataViewChanged);
  }

  FutureOr<void> _onSearchValueChanged(
      SearchValueChanged event, Emitter<RawDataViewerState> emit) {
    emit(state.copyWith(searchValue: event.value));
  }

  FutureOr<void> _onRawDataViewChanged(
      RawDataViewChanged event, Emitter<RawDataViewerState> emit) {
    emit(state.copyWith(view: event.view));
  }
}
