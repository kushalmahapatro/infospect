import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

part 'search_event.dart';
part 'search_state.dart';

class SearchBloc extends Bloc<SearchEvent, SearchState> {
  SearchBloc() : super(const SearchState()) {
    on<SearchBarFocusChanged>(_onSearchBarFocusChanged);

    on<SearchTextSet>(_onSearchTextSet);
  }

  FutureOr<void> _onSearchBarFocusChanged(
      SearchBarFocusChanged event, Emitter<SearchState> emit) {
    emit(state.copyWith(hasFocus: event.focued));
  }

  FutureOr<void> _onSearchTextSet(
      SearchTextSet event, Emitter<SearchState> emit) {
    emit(state.copyWith(text: event.text));
  }
}
