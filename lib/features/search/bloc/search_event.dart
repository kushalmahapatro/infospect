part of 'search_bloc.dart';

sealed class SearchEvent {
  const SearchEvent();
}

final class SearchBarFocusChanged extends SearchEvent {
  const SearchBarFocusChanged({required this.focued});

  final bool focued;
}

final class SearchTextSet extends SearchEvent {
  const SearchTextSet({required this.text});

  final String text;
}
