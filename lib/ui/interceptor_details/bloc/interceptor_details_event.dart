part of 'interceptor_details_bloc.dart';

@immutable
abstract class InterceptorDetailsEvent {
  const InterceptorDetailsEvent();
}

class DetailsTabChanged extends InterceptorDetailsEvent {
  final int selectedTab;
  const DetailsTabChanged({required this.selectedTab});
}

class RequestBodyTypeChanged extends InterceptorDetailsEvent {
  final int index;
  const RequestBodyTypeChanged({required this.index});
}
