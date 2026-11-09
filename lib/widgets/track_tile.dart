import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../library/library_store.dart';
import '../models/track.dart';
import '../player/player_controller.dart';

class Artwork extends StatelessWidget {
  const Artwork({super.key, required this.url, this.size = 52, this.radius = 8});
  final String url;
  final double size;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final placeholder = Container(
      width: size,
      height: size,
      color: Colors.white10,
      child: Icon(Icons.music_note, size: size * 0.45, color: Colors.white38),
    );
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: url.isEmpty
          ? placeholder
          : CachedNetworkImage(
              imageUrl: url,
              width: size,
              height: size,
              fit: BoxFit.cover,
              placeholder: (_, __) => placeholder,
              errorWidget: (_, __, ___) => placeholder,
            ),
    );
  }
}

String formatDuration(int seconds) {
  final m = seconds ~/ 60;
  final s = (seconds % 60).toString().padLeft(2, '0');
  return '$m:$s';
}

/// One row in any track list. Tapping plays the whole [queue] from this track.
class TrackTile extends StatelessWidget {
  const TrackTile({super.key, required this.track, required this.queue, required this.index});

  final Track track;
  final List<Track> queue;
  final int index;

  @override
  Widget build(BuildContext context) {
    final player = context.watch<PlayerController>();
    final library = context.watch<LibraryStore>();
    final isCurrent = player.current == track;

    return ListTile(
      leading: Artwork(url: track.artworkUrl),
      title: Text(
        track.title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: isCurrent ? Theme.of(context).colorScheme.primary : null,
          fontWeight: isCurrent ? FontWeight.w600 : null,
        ),
      ),
      subtitle: Text(
        track.durationSec > 0
            ? '${track.artist} • ${formatDuration(track.durationSec)}'
            : track.artist,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: IconButton(
        icon: Icon(
          library.isLiked(track) ? Icons.favorite : Icons.favorite_border,
          color: library.isLiked(track) ? Colors.pinkAccent : null,
        ),
        onPressed: () => library.toggleLike(track),
      ),
      onTap: () {
        library.addRecent(track);
        player.playQueue(queue, index);
      },
      onLongPress: () => showTrackMenu(context, track),
    );
  }
}

Future<void> showTrackMenu(BuildContext context, Track track) {
  final player = context.read<PlayerController>();
  final library = context.read<LibraryStore>();
  return showModalBottomSheet(
    context: context,
    builder: (ctx) => SafeArea(
      child: Wrap(
        children: [
          ListTile(
            leading: const Icon(Icons.queue_music),
            title: const Text('Add to queue'),
            onTap: () {
              player.addToQueue(track);
              Navigator.pop(ctx);
            },
          ),
          ListTile(
            leading: const Icon(Icons.playlist_add),
            title: const Text('Add to playlist'),
            onTap: () {
              Navigator.pop(ctx);
              _pickPlaylist(context, library, track);
            },
          ),
        ],
      ),
    ),
  );
}

Future<void> _pickPlaylist(BuildContext context, LibraryStore library, Track track) {
  final controller = TextEditingController();
  return showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Add to playlist'),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView(
          shrinkWrap: true,
          children: [
            for (final name in library.playlists.keys)
              ListTile(
                title: Text(name),
                onTap: () {
                  library.addToPlaylist(name, track);
                  Navigator.pop(ctx);
                },
              ),
            TextField(
              controller: controller,
              decoration: const InputDecoration(hintText: 'New playlist name'),
              onSubmitted: (v) {
                library.createPlaylist(v);
                library.addToPlaylist(v.trim(), track);
                Navigator.pop(ctx);
              },
            ),
          ],
        ),
      ),
    ),
  );
}
