import '../models/track.dart';

/// Any music source implements this. Today: Audius. Later: a licensed
/// provider (7digital, MediaNet, etc.) can be dropped in without touching the UI.
abstract class CatalogProvider {
  String get name;

  /// Genres this source supports for browsing (empty = no genre filter).
  List<String> get genres;

  Future<List<Track>> trending({String? genre, int limit = 25});

  Future<List<Track>> search(String query, {int limit = 25});
}

class CatalogException implements Exception {
  final String message;
  CatalogException(this.message);
  @override
  String toString() => message;
}
