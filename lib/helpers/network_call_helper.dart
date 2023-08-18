part of 'infospect_helper.dart';

class InfospectNetworkCallHelper {
  const InfospectNetworkCallHelper._(Infospect infospect)
      : _infospect = infospect;

  final Infospect _infospect;

  void addCall(InfospectNetworkCall call) {
    final callsCount = _infospect.networkCallsSubject.value.length;
    if (callsCount >= _infospect.maxCallsCount) {
      final originalCalls = _infospect.networkCallsSubject.value;
      final calls = List<InfospectNetworkCall>.from(originalCalls);
      calls.sort(
        (call1, call2) => call1.createdTime.compareTo(call2.createdTime),
      );
      final indexToReplace = originalCalls.indexOf(calls.first);
      originalCalls[indexToReplace] = call;

      _infospect.networkCallsSubject.add(originalCalls);
    } else {
      _infospect.networkCallsSubject
          .add([..._infospect.networkCallsSubject.value, call]);
    }
    _infospect.sendNetworkCalls();
  }

  void addError(InfospectNetworkError error, int requestId) {
    final int index = _selectCall(requestId);

    if (index == -1) {
      InfospectUtil.log("Selected call is null");
      return;
    }

    final InfospectNetworkCall selectedCall =
        _infospect.networkCallsSubject.value[index];
    _infospect.networkCallsSubject.value[index] =
        selectedCall.copyWith(error: error, loading: false);
    _infospect.networkCallsSubject
        .add([..._infospect.networkCallsSubject.value]);
    _infospect.sendNetworkCalls();
  }

  void addResponse(InfospectNetworkResponse response, int requestId) {
    final int index = _selectCall(requestId);

    if (index == -1) {
      InfospectUtil.log("Selected call is null");
      return;
    }

    final InfospectNetworkCall selectedCall =
        _infospect.networkCallsSubject.value[index];

    _infospect.networkCallsSubject.value[index] = selectedCall.copyWith(
      loading: false,
      response: response,
      duration: response.time.millisecondsSinceEpoch -
          (selectedCall.request!.time).millisecondsSinceEpoch,
    );

    _infospect.networkCallsSubject
        .add([..._infospect.networkCallsSubject.value]);
    _infospect.sendNetworkCalls();
  }

  void addHttpCall(InfospectNetworkCall httpCall) {
    assert(httpCall.request != null, "Http call request can't be null");
    assert(httpCall.response != null, "Http call response can't be null");
    _infospect.networkCallsSubject
        .add([..._infospect.networkCallsSubject.value, httpCall]);
    _infospect.sendNetworkCalls();
  }

  void removeCalls() {
    _infospect.networkCallsSubject.add([]);
    _infospect.sendNetworkCalls();
  }

  int _selectCall(int requestId) => _infospect.networkCallsSubject.value
      .indexWhere((call) => call.id == requestId);

  /// dio interceptor
  InfospectDioInterceptor get dioInterceptor =>
      InfospectDioInterceptor(_infospect);

  /// http client interceptor
  InfospectHttpClientInterceptor httpClientInterceptor(
          {required Client client}) =>
      InfospectHttpClientInterceptor(
        client: client,
        infospect: _infospect,
      );
}
