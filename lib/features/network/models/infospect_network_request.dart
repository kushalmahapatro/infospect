import 'dart:io';

import 'package:infospect/features/network/models/infospect_form_data.dart';
import 'package:infospect/utils/extensions/map_extension.dart';

/// Represents an Network request data for the Infospect application.
class InfospectNetworkRequest {
  int size = 0; // The size of the request data in bytes.

  DateTime time = DateTime.now(); // The timestamp when the request was made.
  Map<String, dynamic> headers =
      <String, dynamic>{}; // The headers of the Network request.
  dynamic body = ""; // The body of the Network request.
  String? contentType = ""; // The content type (MIME type) of the request.
  List<Cookie> cookies = []; // The cookies sent with the request.
  Map<String, dynamic> queryParameters =
      <String, dynamic>{}; // The query parameters of the request.
  List<InfospectFormDataFile>?
      formDataFiles; // List of file attachments (form data) if any.
  List<InfospectFormDataField>?
      formDataFields; // List of form data fields if any.

  /// Creates an instance of the `InfospectNetworkRequest` class.
  ///
  /// Parameters:
  /// - [size]: The size of the request data in bytes (default is 0).
  /// - [requestTime]: The timestamp when the request was made (default is the current time).
  /// - [headers]: The headers of the Network request (default is an empty map).
  /// - [body]: The body of the Network request (default is an empty string).
  /// - [contentType]: The content type (MIME type) of the request (default is an empty string).
  /// - [cookies]: The cookies sent with the request (default is an empty list).
  /// - [queryParameters]: The query parameters of the request (default is an empty map).
  /// - [formDataFiles]: List of file attachments (form data) if any (default is null).
  /// - [formDataFields]: List of form data fields if any (default is null).
  InfospectNetworkRequest({
    this.size = 0,
    DateTime? requestTime,
    this.headers = const <String, dynamic>{},
    this.body = "",
    this.contentType = "",
    this.cookies = const [],
    this.queryParameters = const <String, dynamic>{},
    this.formDataFiles,
    this.formDataFields,
  }) {
    time = requestTime ?? DateTime.now();
  }

  /// Converts the `InfospectNetworkRequest` object into a Map representation.
  ///
  /// Returns a Map with the following key-value pairs:
  /// - 'size': The size of the request data in bytes.
  /// - 'time': The timestamp when the request was made (in microseconds since epoch).
  /// - 'headers': The headers of the Network request.
  /// - 'body': The body of the Network request.
  /// - 'contentType': The content type (MIME type) of the request.
  /// - 'cookies': The cookies sent with the request (represented as a list of cookie names).
  /// - 'queryParameters': The query parameters of the request.
  /// - 'formDataFiles': List of file attachments (form data) if any, represented as a list of Maps.
  /// - 'formDataFields': List of form data fields if any, represented as a list of Maps.
  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'size': size,
      'time': time.microsecondsSinceEpoch,
      'headers': headers,
      'body': body,
      'contentType': contentType,
      'cookies': cookies.map((e) => e.name).toList(),
      'queryParameters': queryParameters,
      'formDataFiles':
          formDataFiles?.map((e) => e.toMap().getMap<dynamic>()).toList(),
      'formDataFields':
          formDataFields?.map((e) => e.toMap().getMap<dynamic>()).toList(),
    };
  }

  /// Creates an instance of the `InfospectNetworkRequest` class from a Map representation.
  ///
  /// Parameters:
  /// - [map]: A Map containing the key-value pairs representing the `InfospectNetworkRequest` object.
  ///
  /// Returns an instance of the `InfospectNetworkRequest` class with the data populated from the provided Map.
  factory InfospectNetworkRequest.fromMap(Map map) {
    List<T>? getList<T extends Object>(List<Map>? list) {
      if (list == null) return null;
      List<Object>? lists = [];
      if (T is InfospectFormDataFile) {
        if (list.isNotEmpty) {
          lists = list.map((e) => InfospectFormDataFile.fromMap(e)).toList();
        }
      }

      if (T is InfospectFormDataField) {
        if (list.isNotEmpty) {
          lists = list.map((e) => InfospectFormDataField.fromMap(e)).toList();
        }
      }

      return lists.cast<T>();
    }

    return InfospectNetworkRequest(
      size: map['size'] ?? 0,
      requestTime: DateTime.fromMicrosecondsSinceEpoch(map['time'] ?? 0),
      headers: (map['headers'] as Map).getMap<dynamic>(),
      body: map['body'] ?? "",
      contentType: map['contentType'] ?? "",
      cookies: (map['cookies'] as List<Object?>)
          .map<Cookie>((e) => Cookie.fromSetCookieValue(e.toString()))
          .toList(),
      queryParameters: (map['queryParameters'] as Map).getMap<dynamic>(),
      formDataFiles:
          map['formDataFiles'] != null && map['formDataFiles'] is List
              ? getList<InfospectFormDataFile>(
                  (map['formDataFiles'] as List).cast<Map>())
              : null,
      formDataFields:
          map['formDataFields'] != null && map['formDataFields'] is List
              ? getList<InfospectFormDataField>(
                  (map['formDataFields'] as List).cast<Map>())
              : null,
    );
  }
}
