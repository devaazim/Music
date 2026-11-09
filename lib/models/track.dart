class Track {
  final String id;
  final String title;
  final String artist;
  final String artworkUrl;
  final String streamUrl;
  final int durationSec;
  final String? genre;

  const Track({
    required this.id,
    required this.title,
    required this.artist,
    required this.artworkUrl,
    required this.streamUrl,
    required this.durationSec,
    this.genre,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'artist': artist,
        'artworkUrl': artworkUrl,
        'streamUrl': streamUrl,
        'durationSec': durationSec,
        'genre': genre,
      };

  factory Track.fromJson(Map<String, dynamic> j) => Track(
        id: j['id'] as String,
        title: j['title'] as String,
        artist: j['artist'] as String,
        artworkUrl: (j['artworkUrl'] ?? '') as String,
        streamUrl: j['streamUrl'] as String,
        durationSec: (j['durationSec'] ?? 0) as int,
        genre: j['genre'] as String?,
      );

  @override
  bool operator ==(Object other) => other is Track && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
