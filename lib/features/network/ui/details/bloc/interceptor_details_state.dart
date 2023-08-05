part of 'interceptor_details_bloc.dart';

@immutable
class InterceptorDetailsState extends Equatable {
  final int selectedTab;

  const InterceptorDetailsState({
    this.selectedTab = 0,
  });

  @override
  List<Object?> get props => [selectedTab];

  InterceptorDetailsState copyWith({
    int? selectedTab,
    int? requestBodyType,
  }) {
    return InterceptorDetailsState(
      selectedTab: selectedTab ?? this.selectedTab,
    );
  }
}
