import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';

import '../models/track.dart';

/// Owns the audio player and the queue. Background playback and lock-screen
/// controls come from just_audio_background (initialised in main.dart).
class PlayerController extends ChangeNotifier {
  PlayerController() {
    _player.currentIndexStream.listen((i) {
      _index = i;
      notifyListeners();
    });
    _player.playerStateStream.listen((_) => notifyListeners());
    _player.playbackEventStream.listen((_) {}, onError: (Object e, StackTrace _) {
      error = 'Playback failed. Try another track.';
      notifyListeners();
    });
  }

  final AudioPlayer _player = AudioPlayer();
  List<Track> _queue = [];
  int? _index;
  String? error;

  List<Track> get queue => List.unmodifiable(_queue);
  Track? get current =>
      (_index != null && _index! >= 0 && _index! < _queue.length) ? _queue[_index!] : null;

  bool get playing => _player.playing;
  bool get hasPrevious => _player.hasPrevious;
  bool get hasNext => _player.hasNext;
  bool get shuffle => _player.shuffleModeEnabled;
  LoopMode get loopMode => _player.loopMode;

  Stream<Duration> get positionStream => _player.positionStream;
  Stream<Duration?> get durationStream => _player.durationStream;
  Stream<PlayerState> get stateStream => _player.playerStateStream;

  AudioSource _source(Track t) => AudioSource.uri(
        Uri.parse(t.streamUrl),
        tag: MediaItem(
          id: t.id,
          title: t.title,
          artist: t.artist,
          artUri: t.artworkUrl.isEmpty ? null : Uri.parse(t.artworkUrl),
          duration: t.durationSec > 0 ? Duration(seconds: t.durationSec) : null,
        ),
      );

  Future<void> playQueue(List<Track> tracks, int startIndex) async {
    error = null;
    _queue = List.of(tracks);
    _index = startIndex;
    notifyListeners();
    try {
      await _player.setAudioSources(
        _queue.map(_source).toList(),
        initialIndex: startIndex,
      );
      await _player.play();
    } catch (_) {
      error = 'Could not start playback.';
      notifyListeners();
    }
  }

  Future<void> addToQueue(Track t) async {
    if (_queue.isEmpty) {
      await playQueue([t], 0);
      return;
    }
    _queue.add(t);
    await _player.addAudioSource(_source(t));
    notifyListeners();
  }

  Future<void> togglePlay() => _player.playing ? _player.pause() : _player.play();
  Future<void> next() => _player.seekToNext();
  Future<void> previous() => _player.seekToPrevious();
  Future<void> seek(Duration d) => _player.seek(d);

  Future<void> toggleShuffle() async {
    await _player.setShuffleModeEnabled(!_player.shuffleModeEnabled);
    notifyListeners();
  }

  Future<void> cycleLoop() async {
    final next = switch (_player.loopMode) {
      LoopMode.off => LoopMode.all,
      LoopMode.all => LoopMode.one,
      LoopMode.one => LoopMode.off,
    };
    await _player.setLoopMode(next);
    notifyListeners();
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }
}
