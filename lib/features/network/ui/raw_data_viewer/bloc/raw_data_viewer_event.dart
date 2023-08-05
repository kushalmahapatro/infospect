part of 'raw_data_viewer_bloc.dart';

abstract class RawDataViewerEvent extends Equatable {
  const RawDataViewerEvent();
}

class SearchValueChanged extends RawDataViewerEvent {
  final String value;

  const SearchValueChanged(this.value);

  @override
  List<Object> get props => [value];
}

class RawDataViewChanged extends RawDataViewerEvent {
  final RawDataView view;

  const RawDataViewChanged(this.view);

  @override
  List<Object> get props => [view];
}
