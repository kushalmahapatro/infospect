import 'package:infospect/network/models/infospect_network_error.dart';
import 'package:infospect/network/models/infospect_network_request.dart';
import 'package:infospect/network/models/infospect_network_response.dart';

/// Represents an Network call data for the Infospect application.
class InfospectNetworkCall {
  // The unique identifier for the Network call.
  final int id;
  // The timestamp when the Network call was created.
  DateTime createdTime = DateTime.now();
  // The client information associated with the Network call.
  String client = "";
  // A flag indicating if the call is still in progress (loading) or completed.
  bool loading = true;
  // A flag indicating if the call is made over a secure (NetworkS) connection.
  bool secure = false;
  // The Network method used in the call (e.g., GET, POST, etc.).
  String method = "";
  // The endpoint (URL path) used in the Network call.
  String endpoint = "";
  // The server URL (domain) to which the call is made.
  String server = "";
  // The full URI (server + endpoint) used in the Network call.
  String uri = "";
  // The duration of the Network call in milliseconds.
  int duration = 0;
  // The Network request data associated with the call.
  InfospectNetworkRequest? request;
  // The Network response data associated with the call.
  InfospectNetworkResponse? response;
  // The Network error data associated with the call (if any).
  InfospectNetworkError? error;

  /// Creates an instance of the `InfospectNetworkCall` class.
  ///
  /// Parameters:
  /// - [id]: The unique identifier for the Network call.
  /// - [time]: The timestamp when the Network call was created (default is the current time).
  InfospectNetworkCall(this.id, {DateTime? time}) {
    loading = true;
    createdTime = time ?? DateTime.now();
  }

  /// Sets the Network response for the call and marks the call as completed.
  ///
  /// Parameters:
  /// - [response]: The Network response data to set for the call.
  void setResponse(InfospectNetworkResponse response) {
    this.response = response;
    loading = false;
  }

  /// Generates a cURL command string based on the Network request data associated with the call.
  ///
  /// The generated cURL command includes the Network method, headers, request body (if applicable),
  /// query parameters, and server URL. It also handles cases with or without NetworkS and compression.
  ///
  /// Returns:
  /// - A cURL command string representing the Network request of the call.
  String get cURL {
    bool compressed =
        false; // A flag indicating if the request is compressed using gzip.
    String curlCmd = "curl"; // The base cURL command string.
    curlCmd += " -X $method"; // Add the Network method to the cURL command.

    if (request != null) {
      // Get the headers from the Network request.
      final Map<String, dynamic> headers = request!.headers;
      // Check if the request is compressed with gzip.
      compressed = headers['Accept-Encoding'] == 'gzip';
      // Add each header to the cURL command.
      headers.forEach((key, dynamic value) {
        curlCmd += " -H '$key: $value'";
      });

      // Get the request body as a string.
      final String requestBody = request!.body.toString();
      // If the request body is not empty, add it to the cURL command.
      if (requestBody != '') {
        curlCmd += " --data \$'${requestBody.replaceAll("\n", "\\n")}'";
      }

      // Get the query parameters from the Net request.
      final Map<String, dynamic> queryParamMap = request!.queryParameters;
      int paramCount = queryParamMap.keys.length;
      String queryParams = "";
      // If there are query parameters, add them to the cURL command.
      if (paramCount > 0) {
        queryParams += "?";
        queryParamMap.forEach((key, dynamic value) {
          queryParams += '$key=$value';
          paramCount -= 1;
          if (paramCount > 0) {
            queryParams += "&";
          }
        });
      }

      // If the server URL already has http(s), don't add it again.
      if (server.contains("http://") || server.contains("https://")) {
        curlCmd +=
            "${compressed ? " --compressed " : " "}${"'$server$endpoint$queryParams'"}";
      } else {
        curlCmd +=
            "${compressed ? " --compressed " : " "}${"'${secure ? 'https://' : 'http://'}$server$endpoint$queryParams'"}";
      }
    }

    return curlCmd;
  }

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
      'createdTime': createdTime.microsecondsSinceEpoch,
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
    };
  }

  /// Creates an instance of the `InfospectNetworkCall` class from a Map representation.
  ///
  /// Parameters:
  /// - [map]: A Map containing the key-value pairs representing the `InfospectNetworkCall` object.
  ///
  /// Returns an instance of the `InfospectNetworkCall` class with the data populated from the provided Map.
  factory InfospectNetworkCall.fromMap(Map map) {
    InfospectNetworkCall call = InfospectNetworkCall(map['id']);
    call.createdTime = DateTime.fromMicrosecondsSinceEpoch(map['createdTime']);
    call.client = map['client'];
    call.loading = map['loading'];
    call.secure = map['secure'];
    call.method = map['method'];
    call.endpoint = map['endpoint'];
    call.server = map['server'];
    call.uri = map['uri'];
    call.duration = map['duration'];
    call.request = map['request'] != null
        ? InfospectNetworkRequest.fromMap(map['request'])
        : null;
    call.response = map['response'] != null
        ? InfospectNetworkResponse.fromMap(map['response'])
        : null;
    call.error = map['error'] != null
        ? InfospectNetworkError.fromMap(map['error'])
        : null;

    return call;
  }
}
