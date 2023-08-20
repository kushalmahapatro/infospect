part of 'infospect_helper.dart';

/// `InfospectNetworkCallHelper` is a utility class tailored to assist `Infospect` in handling
/// network-related tasks. It provides methods to log network calls, errors, responses and
/// facilitates integration with interceptors for networking libraries like Dio and HttpClient.
class InfospectNetworkCallHelper {
  /// Private constructor.
  ///
  /// - `infospect`: Reference to the main `Infospect` instance.
  const InfospectNetworkCallHelper._(Infospect infospect)
      : _infospect = infospect;

  final Infospect _infospect;

  /// Logs a new network call.
  ///
  /// - `call`: The network call to be logged.
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

  /// Logs an error associated with a specific network request.
  ///
  /// - `error`: The network error to be logged.
  /// - `requestId`: The unique identifier of the associated request.
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

  /// Logs a response associated with a specific network request.
  ///
  /// - `response`: The network response to be logged.
  /// - `requestId`: The unique identifier of the associated request.
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

  /// Logs an HTTP call which includes both the request and the response.
  ///
  /// - `httpCall`: The network call (including request and response) to be logged.
  void addHttpCall(InfospectNetworkCall httpCall) {
    assert(httpCall.request != null, "Http call request can't be null");
    assert(httpCall.response != null, "Http call response can't be null");
    _infospect.networkCallsSubject
        .add([..._infospect.networkCallsSubject.value, httpCall]);
    _infospect.sendNetworkCalls();
  }

  /// Clears all logged network calls.
  void clearAllNetworkCalls() {
    _infospect.networkCallsSubject.add([]);
  }

  /// Retrieves the index of a specific network call by its unique identifier.
  ///
  /// - `requestId`: The unique identifier of the network call.
  int _selectCall(int requestId) => _infospect.networkCallsSubject.value
      .indexWhere((call) => call.id == requestId);

  /// Provides an interceptor for Dio, which helps in logging network tasks when using the Dio library.
  InfospectDioInterceptor get dioInterceptor =>
      InfospectDioInterceptor(_infospect);

  /// Provides an interceptor for HttpClient, which assists in logging network activities when using HttpClient.
  ///
  /// - `client`: The HttpClient instance.
  InfospectHttpClientInterceptor httpClientInterceptor(
          {required Client client}) =>
      InfospectHttpClientInterceptor(
        client: client,
        infospect: _infospect,
      );
}
