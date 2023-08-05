part of 'raw_data_viewer_bloc.dart';

class RawDataViewerState extends Equatable {
  const RawDataViewerState({
    this.view = RawDataView.beautified,
    this.searchValue = '',
  });

  final RawDataView view;
  final String searchValue;

  @override
  List<Object> get props => [view, searchValue];

  RawDataViewerState copyWith({
    RawDataView? view,
    String? searchValue,
  }) {
    return RawDataViewerState(
      view: view ?? this.view,
      searchValue: searchValue ?? this.searchValue,
    );
  }
}
