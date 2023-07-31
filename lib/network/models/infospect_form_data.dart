/// Represents a file attachment for the Infospect application.
class InfospectFormDataFile {
  final String? fileName; // The name of the file.
  final String contentType; // The content type (MIME type) of the file.
  final int length; // The length (size) of the file in bytes.

  /// Creates an instance of the `InfospectFormDataFile` class with the provided [fileName], [contentType], and [length].
  ///
  /// Parameters:
  /// - [fileName]: The name of the file (optional). Can be null if the file is not available or has no name.
  /// - [contentType]: The content type (MIME type) of the file.
  /// - [length]: The length (size) of the file in bytes.
  InfospectFormDataFile(this.fileName, this.contentType, this.length);

  /// Converts the `InfospectFormDataFile` object into a Map representation.
  ///
  /// Returns a Map with the following key-value pairs:
  /// - 'fileName': The name of the file.
  /// - 'contentType': The content type (MIME type) of the file.
  /// - 'length': The length (size) of the file in bytes.
  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'fileName': fileName,
      'contentType': contentType,
      'length': length,
    };
  }

  /// Creates an instance of the `InfospectFormDataFile` class from a Map representation.
  ///
  /// Parameters:
  /// - [map]: A Map containing the key-value pairs representing the `InfospectFormDataFile` object.
  ///
  /// Returns an instance of the `InfospectFormDataFile` class with the data populated from the provided Map.
  factory InfospectFormDataFile.fromMap(Map map) {
    return InfospectFormDataFile(
      map['fileName'] as String?,
      map['contentType'] as String,
      map['length'] as int,
    );
  }
}

/// Represents a data field for the Infospect application.
class InfospectFormDataField {
  final String name; // The name of the data field.
  final String value; // The value of the data field.

  /// Creates an instance of the `InfospectFormDataField` class with the provided [name] and [value].
  InfospectFormDataField(this.name, this.value);

  /// Converts the `InfospectFormDataField` object into a Map representation.
  ///
  /// Returns a Map with the following key-value pairs:
  /// - 'name': The name of the data field.
  /// - 'value': The value of the data field.
  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'name': name,
      'value': value,
    };
  }

  /// Creates an instance of the `InfospectFormDataField` class from a Map representation.
  ///
  /// Parameters:
  /// - [map]: A Map containing the key-value pairs representing the `InfospectFormDataField` object.
  ///
  /// Returns an instance of the `InfospectFormDataField` class with the data populated from the provided Map.
  factory InfospectFormDataField.fromMap(Map map) {
    return InfospectFormDataField(
      map['name'] as String,
      map['value'] as String,
    );
  }
}
