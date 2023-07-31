extension MapExtension on Map? {
  Map<String, T> getMap<T>() {
    return this != null ? this!.cast<String, T>() : <String, T>{};
  }
}
