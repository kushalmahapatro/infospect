// ignore_for_file: must_be_immutable

import 'package:dio/dio.dart';
import 'package:infospect/utils/extensions/map_extension.dart';

/// Represents an Network response data for the Infospect application.
class InfospectNetworkResponse {
  final int? status; // The Network status code of the response.
  final int size; // The size of the response data in bytes.
  final DateTime time; // The timestamp when the response was received.
  final dynamic body; // The body of the Network response.
  final Map<String, String>? headers; // The headers of the Network response.

  /// Creates an instance of the `InfospectNetworkResponse` class.
  ///
  /// Parameters:
  /// - [status]: The Network status code of the response (optional).
  /// - [size]: The size of the response data in bytes (default is 0).
  /// - [responseTime]: The timestamp when the response was received (default is the current time).
  /// - [body]: The body of the Network response (can be of any type).
  /// - [headers]: The headers of the Network response (optional).
  InfospectNetworkResponse({
    this.status,
    this.size = 0,
    DateTime? responseTime,
    this.body = '',
    this.headers,
  }) : time = responseTime ?? DateTime.now();

  InfospectNetworkResponse copyWith({
    int? status,
    int? size,
    DateTime? time,
    dynamic body,
    Map<String, String>? headers,
  }) {
    return InfospectNetworkResponse(
      status: status ?? this.status,
      size: size ?? this.size,
      responseTime: time ?? this.time,
      body: body ?? this.body,
      headers: headers ?? this.headers,
    );
  }

  /// Converts the `InfospectNetworkResponse` object into a Map representation.
  ///
  /// Returns a Map with the following key-value pairs:
  /// - 'status': The Network status code of the response (can be null if not set).
  /// - 'size': The size of the response data in bytes.
  /// - 'time': The timestamp when the response was received (in microseconds since epoch).
  /// - 'body': The body of the Network response.
  /// - 'headers': The headers of the Network response (can be null if not set).
  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'status': status,
      'size': size,
      'time': time.microsecondsSinceEpoch,
      'body': body is ResponseBody ? body.runtimeType.toString() : body,
      'headers': headers,
    };
  }

  /// Creates an instance of the `InfospectNetworkResponse` class from a Map representation.
  ///
  /// Parameters:
  /// - [map]: A Map containing the key-value pairs representing the `InfospectNetworkResponse` object.
  ///
  /// Returns an instance of the `InfospectNetworkResponse` class with the data populated from the provided Map.
  factory InfospectNetworkResponse.fromMap(Map map) {
    return InfospectNetworkResponse(
      status: map['status'] != null ? map['status'] as int : null,
      size: map['size'] ?? 0,
      responseTime: DateTime.fromMicrosecondsSinceEpoch(map['time']),
      body: map['body'] as dynamic,
      headers: (map['headers'] as Map?)?.getMap<String>(),
    );
  }
}
