part of 'search_bloc.dart';

class SearchState extends Equatable {
  const SearchState({
    this.hasFocus = false,
    this.text = '',
  });

  final bool hasFocus;
  final String text;

  @override
  List<Object> get props => [hasFocus, text];

  SearchState copyWith({
    bool? hasFocus,
    String? text,
  }) {
    return SearchState(
      hasFocus: hasFocus ?? this.hasFocus,
      text: text ?? this.text,
    );
  }
}
