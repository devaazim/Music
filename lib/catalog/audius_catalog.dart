import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config.dart';
import '../models/track.dart';
import 'catalog_provider.dart';

class AudiusCatalog implements CatalogProvider {
  AudiusCatalog({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  @override
  String get name => 'Audius';

  @override
  List<String> get genres => const [
        'Electronic',
        'Hip-Hop/Rap',
        'Pop',
        'Rock',
        'Lo-Fi',
        'Ambient',
        'R&B/Soul',
        'Jazz',
        'Classical',
        'Latin',
      ];

  Uri _uri(String path, [Map<String, String> params = const {}]) {
    return Uri.parse('${AppConfig.audiusBaseUrl}$path').replace(
      queryParameters: {
        'app_name': AppConfig.appName,
        if (AppConfig.audiusApiKey.isNotEmpty) 'api_key': AppConfig.audiusApiKey,
        ...params,
      },
    );
  }

  Future<List<Track>> _fetchTracks(Uri uri) async {
    final http.Response res;
    try {
      res = await _client.get(uri).timeout(const Duration(seconds: 15));
    } catch (_) {
      throw CatalogException('Could not reach the music service. Check your connection.');
    }
    if (res.statusCode != 200) {
      throw CatalogException('Music service error (${res.statusCode}).');
    }
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    final data = (body['data'] as List?) ?? const [];
    return data
        .whereType<Map<String, dynamic>>()
        .where((t) => t['is_streamable'] != false)
        .map(_toTrack)
        .toList();
  }

  Track _toTrack(Map<String, dynamic> t) {
    final id = t['id'] as String;
    final artwork = (t['artwork'] as Map?)?.cast<String, dynamic>() ?? const {};
    final art = (artwork['480x480'] ?? artwork['150x150'] ?? artwork['1000x1000'] ?? '') as String;
    final user = (t['user'] as Map?)?.cast<String, dynamic>() ?? const {};
    return Track(
      id: id,
      title: (t['title'] ?? 'Untitled') as String,
      artist: (user['name'] ?? 'Unknown artist') as String,
      artworkUrl: art,
      streamUrl: _uri('/tracks/$id/stream').toString(),
      durationSec: (t['duration'] ?? 0) as int,
      genre: t['genre'] as String?,
    );
  }

  @override
  Future<List<Track>> trending({String? genre, int limit = 25}) {
    return _fetchTracks(_uri('/tracks/trending', {
      'limit': '$limit',
      'time': 'week',
      if (genre != null) 'genre': genre,
    }));
  }

  @override
  Future<List<Track>> search(String query, {int limit = 25}) {
    return _fetchTracks(_uri('/tracks/search', {
      'query': query,
      'limit': '$limit',
    }));
  }
}
