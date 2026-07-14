import 'dart:convert';

import 'package:equatable/equatable.dart';
import 'package:infospect/features/network/models/infospect_network_error.dart';
import 'package:infospect/features/network/models/infospect_network_request.dart';
import 'package:infospect/features/network/models/infospect_network_response.dart';

/// Represents an Network call data for the Infospect application.
class InfospectNetworkCall extends Equatable {
  /// The unique identifier for the Network call.
  final int id;

  /// The timestamp when the Network call was created.
  final DateTime createdTime;

  /// The client information associated with the Network call.
  final String client;

  /// A flag indicating if the call is still in progress (loading) or completed.
  final bool loading;

  /// A flag indicating if the call is made over a secure (NetworkS) connection.
  final bool secure;

  /// The Network method used in the call (e.g., GET, POST, etc.).
  final String method;

  /// The endpoint (URL path) used in the Network call.
  final String endpoint;

  /// The server URL (domain) to which the call is made.
  final String server;

  /// The full URI (server + endpoint) used in the Network call.
  final String uri;

  /// The duration of the Network call in milliseconds.
  final int duration;

  /// The Network request data associated with the call.
  final InfospectNetworkRequest? request;

  /// The Network response data associated with the call.
  final InfospectNetworkResponse? response;

  /// The Network error data associated with the call (if any).
  final InfospectNetworkError? error;

  /// Whether a request breakpoint paused this call.
  final bool hadRequestBreakpoint;

  /// Whether a response breakpoint paused this call.
  final bool hadResponseBreakpoint;

  /// Whether the request was modified at a breakpoint before sending.
  final bool requestEditedAtBreakpoint;

  /// Whether the response was modified at a breakpoint before delivery.
  final bool responseEditedAtBreakpoint;

  /// Creates an instance of the `InfospectNetworkCall` class.
  ///
  /// Parameters:
  /// - [id]: The unique identifier for the Network call.
  /// - [time]: The timestamp when the Network call was created (default is the current time).
  InfospectNetworkCall(this.id,
      {DateTime? time,
      String endpoint = '',
      this.client = '',
      this.loading = true,
      this.secure = false,
      this.method = '',
      this.server = '',
      this.uri = '',
      this.duration = 0,
      this.request,
      this.response,
      this.error,
      this.hadRequestBreakpoint = false,
      this.hadResponseBreakpoint = false,
      this.requestEditedAtBreakpoint = false,
      this.responseEditedAtBreakpoint = false})
      : createdTime = time ?? DateTime.now(),
        endpoint = endpoint.isEmpty ? "/" : endpoint;

  /// True when any breakpoint interacted with this call.
  bool get hasBreakpointTrace =>
      hadRequestBreakpoint ||
      hadResponseBreakpoint ||
      requestEditedAtBreakpoint ||
      responseEditedAtBreakpoint;

  /// Converts the `InfospectNetworkCall` object into a Map representation.
  ///
  /// Returns a Map with the following key-value pairs:
  /// - 'id': The unique identifier for the Network call.
  /// - 'createdTime': The timestamp when the Network call was created (in microseconds since epoch).
  /// - 'client': The client information associated with the Network call.
  /// - 'loading': A flag indicating if the call is still in progress (loading) or completed.
  /// - 'secure': A flag indicating if the call is made over a secure (NetworkS) connection.
  /// - 'method': The Network method used in the call.
  /// - 'endpoint': The endpoint (URL path) used in the Network call.
  /// - 'server': The server URL (domain) to which the call is made.
  /// - 'uri': The full URI (server + endpoint) used in the Network call.
  /// - 'duration': The duration of the Network call in milliseconds.
  /// - 'request': The Map representation of the Network request data associated with the call.
  /// - 'response': The Map representation of the Network response data associated with the call.
  /// - 'error': The Map representation of the Network error data associated with the call (if any).
  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'createdTime': createdTime.millisecondsSinceEpoch,
      'client': client,
      'loading': loading,
      'secure': secure,
      'method': method,
      'endpoint': endpoint,
      'server': server,
      'uri': uri,
      'duration': duration,
      'request': request?.toMap(),
      'response': response?.toMap(),
      'error': error?.toMap(),
      'hadRequestBreakpoint': hadRequestBreakpoint,
      'hadResponseBreakpoint': hadResponseBreakpoint,
      'requestEditedAtBreakpoint': requestEditedAtBreakpoint,
      'responseEditedAtBreakpoint': responseEditedAtBreakpoint,
    };
  }

  /// Creates an instance of the `InfospectNetworkCall` class from a Map representation.
  ///
  /// Parameters:
  /// - [map]: A Map containing the key-value pairs representing the `InfospectNetworkCall` object.
  ///
  /// Returns an instance of the `InfospectNetworkCall` class with the data populated from the provided Map.
  factory InfospectNetworkCall.fromMap(dynamic map) {
    return InfospectNetworkCall(
      map['id'] as int,
      time: DateTime.fromMillisecondsSinceEpoch(map['createdTime'] as int),
      client: map['client'] as String,
      loading: map['loading'] as bool,
      secure: map['secure'] as bool,
      method: map['method'] as String,
      endpoint: map['endpoint'] as String,
      server: map['server'] as String,
      uri: map['uri'] as String,
      duration: map['duration'] as int,
      request: map['request'] != null
          ? InfospectNetworkRequest.fromMap(map['request'])
          : null,
      response: map['response'] != null
          ? InfospectNetworkResponse.fromMap(map['response'])
          : null,
      error: map['error'] != null
          ? InfospectNetworkError.fromMap(map['error'])
          : null,
      hadRequestBreakpoint: map['hadRequestBreakpoint'] as bool? ?? false,
      hadResponseBreakpoint: map['hadResponseBreakpoint'] as bool? ?? false,
      requestEditedAtBreakpoint:
          map['requestEditedAtBreakpoint'] as bool? ?? false,
      responseEditedAtBreakpoint:
          map['responseEditedAtBreakpoint'] as bool? ?? false,
    );
  }

  @override
  List<Object?> get props {
    return [
      id,
      createdTime,
      client,
      loading,
      secure,
      method,
      endpoint,
      server,
      uri,
      duration,
      request,
      response,
      error,
      hadRequestBreakpoint,
      hadResponseBreakpoint,
      requestEditedAtBreakpoint,
      responseEditedAtBreakpoint,
    ];
  }

  InfospectNetworkCall copyWith({
    int? id,
    DateTime? createdTime,
    String? client,
    bool? loading,
    bool? secure,
    String? method,
    String? endpoint,
    String? server,
    String? uri,
    int? duration,
    InfospectNetworkRequest? request,
    InfospectNetworkResponse? response,
    InfospectNetworkError? error,
    bool? hadRequestBreakpoint,
    bool? hadResponseBreakpoint,
    bool? requestEditedAtBreakpoint,
    bool? responseEditedAtBreakpoint,
  }) {
    return InfospectNetworkCall(
      id ?? this.id,
      time: createdTime ?? this.createdTime,
      client: client ?? this.client,
      loading: loading ?? this.loading,
      secure: secure ?? this.secure,
      method: method ?? this.method,
      endpoint: endpoint ?? this.endpoint,
      server: server ?? this.server,
      uri: uri ?? this.uri,
      duration: duration ?? this.duration,
      request: request ?? this.request,
      response: response ?? this.response,
      error: error ?? this.error,
      hadRequestBreakpoint:
          hadRequestBreakpoint ?? this.hadRequestBreakpoint,
      hadResponseBreakpoint:
          hadResponseBreakpoint ?? this.hadResponseBreakpoint,
      requestEditedAtBreakpoint:
          requestEditedAtBreakpoint ?? this.requestEditedAtBreakpoint,
      responseEditedAtBreakpoint:
          responseEditedAtBreakpoint ?? this.responseEditedAtBreakpoint,
    );
  }

  String toJson() => json.encode(toMap());

  factory InfospectNetworkCall.fromJson(String source) =>
      InfospectNetworkCall.fromMap(json.decode(source) as Map<String, dynamic>);
}
