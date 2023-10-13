import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';

part 'interceptor_details_event.dart';
part 'interceptor_details_state.dart';

class InterceptorDetailsBloc
    extends Bloc<InterceptorDetailsEvent, InterceptorDetailsState> {
  InterceptorDetailsBloc() : super(const InterceptorDetailsState()) {
    on<DetailsTabChanged>(_onTabChanged);
    on<RequestBodyTypeChanged>(_onRequestBodyTypeChanged);
  }

  FutureOr<void> _onTabChanged(
      DetailsTabChanged event, Emitter<InterceptorDetailsState> emit) {
    emit(state.copyWith(selectedTab: event.selectedTab));
  }

  FutureOr<void> _onRequestBodyTypeChanged(
      RequestBodyTypeChanged event, Emitter<InterceptorDetailsState> emit) {
    emit(state.copyWith(requestBodyType: event.index));
  }
}
