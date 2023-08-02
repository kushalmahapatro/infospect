extension MapExtension on Map? {
  String get contentType {
    if (this != null &&
        (this!.containsKey('content-type') ||
            this!.containsKey('Content-Type'))) {
      return (this!['content-type'] ?? this!['Content-Type'] ?? 'unknown')
          .toString();
    }
    return 'unknown';
  }
}
