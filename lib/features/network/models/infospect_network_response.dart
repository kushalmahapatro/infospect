// ignore_for_file: must_be_immutable

import 'package:equatable/equatable.dart';
import 'package:infospect/utils/extensions/map_extension.dart';

/// Represents an Network response data for the Infospect application.
class InfospectNetworkResponse extends Equatable {
  int? status; // The Network status code of the response.
  int size = 0; // The size of the response data in bytes.
  DateTime time =
      DateTime.now(); // The timestamp when the response was received.
  dynamic body; // The body of the Network response.
  Map<String, String>? headers; // The headers of the Network response.

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
    this.body,
    this.headers,
  }) {
    responseTime ??= DateTime.now();
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
      'body': body,
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

  @override
  List<Object?> get props => [status, size, time, body, headers];
}
