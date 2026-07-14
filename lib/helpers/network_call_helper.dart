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
  }

  /// Logs an HTTP call which includes both the request and the response.
  ///
  /// - `httpCall`: The network call (including request and response) to be logged.
  void addHttpCall(InfospectNetworkCall httpCall) {
    assert(httpCall.request != null, "Http call request can't be null");
    assert(httpCall.response != null, "Http call response can't be null");
    _infospect.networkCallsSubject
        .add([..._infospect.networkCallsSubject.value, httpCall]);
  }

  /// Clears all logged network calls.
  void clearAllNetworkCalls() {
    _infospect.networkCallsSubject.add([]);
  }

  /// Marks breakpoint interaction flags on a logged call.
  void markBreakpointTrace({
    required int requestId,
    bool requestHit = false,
    bool responseHit = false,
    bool requestEdited = false,
    bool responseEdited = false,
  }) {
    final int index = _selectCall(requestId);
    if (index == -1) return;

    final selected = _infospect.networkCallsSubject.value[index];
    _infospect.networkCallsSubject.value[index] = selected.copyWith(
      hadRequestBreakpoint: requestHit || selected.hadRequestBreakpoint,
      hadResponseBreakpoint: responseHit || selected.hadResponseBreakpoint,
      requestEditedAtBreakpoint:
          requestEdited || selected.requestEditedAtBreakpoint,
      responseEditedAtBreakpoint:
          responseEdited || selected.responseEditedAtBreakpoint,
    );
    _infospect.networkCallsSubject
        .add([..._infospect.networkCallsSubject.value]);
  }

  /// Applies a request breakpoint edit: keeps original + edited, updates live request.
  void applyRequestBreakpointEdit({
    required int requestId,
    required InfospectBreakpointEdit edit,
  }) {
    final int index = _selectCall(requestId);
    if (index == -1) return;

    final selected = _infospect.networkCallsSubject.value[index];
    final edited = edit.edited;
    final request = selected.request?.copyWith(
          headers: edited.headers,
          queryParameters: edited.queryParameters,
          body: edited.body,
          size: utf8.encode(edited.body).length,
        ) ??
        InfospectNetworkRequest(
          headers: edited.headers,
          queryParameters: edited.queryParameters,
          body: edited.body,
          size: utf8.encode(edited.body).length,
        );

    _infospect.networkCallsSubject.value[index] = selected.copyWith(
      request: request,
      method: edited.method.isNotEmpty ? edited.method : selected.method,
      endpoint:
          edited.endpoint.isNotEmpty ? edited.endpoint : selected.endpoint,
      uri: edited.uri.isNotEmpty ? edited.uri : selected.uri,
      hadRequestBreakpoint: true,
      requestEditedAtBreakpoint: edit.hasChanges,
      requestBreakpointEdit: edit,
    );
    _infospect.networkCallsSubject
        .add([..._infospect.networkCallsSubject.value]);
  }

  /// Records a response breakpoint original/edited pair on the logged call.
  void applyResponseBreakpointEdit({
    required int requestId,
    required InfospectBreakpointEdit edit,
  }) {
    final int index = _selectCall(requestId);
    if (index == -1) return;

    final selected = _infospect.networkCallsSubject.value[index];
    _infospect.networkCallsSubject.value[index] = selected.copyWith(
      hadResponseBreakpoint: true,
      responseEditedAtBreakpoint: edit.hasChanges,
      responseBreakpointEdit: edit,
    );
    _infospect.networkCallsSubject
        .add([..._infospect.networkCallsSubject.value]);
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
