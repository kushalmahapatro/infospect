/// Represents an Network error for the Infospect application.
class InfospectNetworkError {
  dynamic error; // The error object.
  StackTrace?
      stackTrace; // The stack trace associated with the error, if available.

  /// Creates an instance of the `InfospectNetworkError` class.
  ///
  /// Parameters:
  /// - [error]: The error object (can be of any type).
  /// - [stackTrace]: The stack trace associated with the error (optional).
  InfospectNetworkError({
    this.error,
    this.stackTrace,
  });

  /// Converts the `InfospectNetworkError` object into a Map representation.
  ///
  /// Returns a Map with the following key-value pairs:
  /// - 'error': The string representation of the error object using the `toString()` method.
  /// - 'stackTrace': The string representation of the stack trace, if available, using `toString()`.
  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'error': error.toString(),
      'stackTrace': stackTrace?.toString(),
    };
  }

  /// Creates an instance of the `InfospectNetworkError` class from a Map representation.
  ///
  /// Parameters:
  /// - [map]: A Map containing the key-value pairs representing the `InfospectNetworkError` object.
  ///
  /// Returns an instance of the `InfospectNetworkError` class with the data populated from the provided Map.
  factory InfospectNetworkError.fromMap(Map map) {
    return InfospectNetworkError(
      error: map['error'] as dynamic,
      stackTrace: map['stackTrace'] != null
          ? StackTrace.fromString(map['stackTrace'])
          : null,
    );
  }
}
