part of 'interceptor_details_bloc.dart';

@immutable
class InterceptorDetailsState extends Equatable {
  final int selectedTab;
  final int requestBodyType;

  const InterceptorDetailsState({
    this.selectedTab = 0,
    this.requestBodyType = 0,
  });

  @override
  List<Object?> get props => [selectedTab, requestBodyType];

  InterceptorDetailsState copyWith({
    int? selectedTab,
    int? requestBodyType,
  }) {
    return InterceptorDetailsState(
      selectedTab: selectedTab ?? this.selectedTab,
      requestBodyType: requestBodyType ?? this.requestBodyType,
    );
  }
}
