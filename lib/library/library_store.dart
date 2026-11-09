import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/track.dart';

/// Liked songs, playlists and recently played, stored on-device.
/// (Swap for your backend API when you add accounts.)
class LibraryStore extends ChangeNotifier {
  static const _kLiked = 'liked_v1';
  static const _kPlaylists = 'playlists_v1';
  static const _kRecent = 'recent_v1';

  final List<Track> liked = [];
  final Map<String, List<Track>> playlists = {};
  final List<Track> recent = [];

  late SharedPreferences _prefs;

  Future<void> load() async {
    _prefs = await SharedPreferences.getInstance();
    List<Track> decode(String? raw) => raw == null
        ? []
        : (jsonDecode(raw) as List)
            .map((e) => Track.fromJson((e as Map).cast<String, dynamic>()))
            .toList();

    liked.addAll(decode(_prefs.getString(_kLiked)));
    recent.addAll(decode(_prefs.getString(_kRecent)));

    final rawPl = _prefs.getString(_kPlaylists);
    if (rawPl != null) {
      (jsonDecode(rawPl) as Map<String, dynamic>).forEach((name, list) {
        playlists[name] = (list as List)
            .map((e) => Track.fromJson((e as Map).cast<String, dynamic>()))
            .toList();
      });
    }
    notifyListeners();
  }

  bool isLiked(Track t) => liked.contains(t);

  void toggleLike(Track t) {
    isLiked(t) ? liked.remove(t) : liked.insert(0, t);
    _save();
  }

  void createPlaylist(String name) {
    final n = name.trim();
    if (n.isEmpty || playlists.containsKey(n)) return;
    playlists[n] = [];
    _save();
  }

  void deletePlaylist(String name) {
    playlists.remove(name);
    _save();
  }

  void addToPlaylist(String name, Track t) {
    final list = playlists[name];
    if (list == null || list.contains(t)) return;
    list.add(t);
    _save();
  }

  void removeFromPlaylist(String name, Track t) {
    playlists[name]?.remove(t);
    _save();
  }

  void addRecent(Track t) {
    recent.remove(t);
    recent.insert(0, t);
    if (recent.length > 30) recent.removeLast();
    _save();
  }

  void _save() {
    _prefs.setString(_kLiked, jsonEncode(liked.map((t) => t.toJson()).toList()));
    _prefs.setString(_kRecent, jsonEncode(recent.map((t) => t.toJson()).toList()));
    _prefs.setString(
      _kPlaylists,
      jsonEncode(playlists.map((k, v) => MapEntry(k, v.map((t) => t.toJson()).toList()))),
    );
    notifyListeners();
  }
}
