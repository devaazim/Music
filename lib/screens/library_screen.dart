import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../library/library_store.dart';
import '../models/track.dart';
import '../widgets/track_tile.dart';

class LibraryScreen extends StatelessWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final lib = context.watch<LibraryStore>();
    return DefaultTabController(
      length: 3,
      child: Column(
        children: [
          const TabBar(tabs: [Tab(text: 'Liked'), Tab(text: 'Playlists'), Tab(text: 'Recent')]),
          Expanded(
            child: TabBarView(
              children: [
                _TrackList(tracks: lib.liked, empty: 'Songs you like will show up here.'),
                _Playlists(lib: lib),
                _TrackList(tracks: lib.recent, empty: 'Nothing played yet.'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TrackList extends StatelessWidget {
  const _TrackList({required this.tracks, required this.empty});
  final List<Track> tracks;
  final String empty;

  @override
  Widget build(BuildContext context) {
    if (tracks.isEmpty) return Center(child: Text(empty));
    return ListView.builder(
      itemCount: tracks.length,
      itemBuilder: (_, i) => TrackTile(track: tracks[i], queue: tracks, index: i),
    );
  }
}

class _Playlists extends StatelessWidget {
  const _Playlists({required this.lib});
  final LibraryStore lib;

  @override
  Widget build(BuildContext context) {
    final names = lib.playlists.keys.toList();
    return Column(
      children: [
        ListTile(
          leading: const Icon(Icons.add),
          title: const Text('New playlist'),
          onTap: () => _newPlaylist(context),
        ),
        Expanded(
          child: names.isEmpty
              ? const Center(child: Text('No playlists yet.'))
              : ListView.builder(
                  itemCount: names.length,
                  itemBuilder: (_, i) {
                    final name = names[i];
                    final tracks = lib.playlists[name]!;
                    return ListTile(
                      leading: const Icon(Icons.queue_music),
                      title: Text(name),
                      subtitle: Text('${tracks.length} songs'),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () => lib.deletePlaylist(name),
                      ),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => _PlaylistPage(name: name)),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Future<void> _newPlaylist(BuildContext context) {
    final c = TextEditingController();
    return showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('New playlist'),
        content: TextField(controller: c, autofocus: true),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              lib.createPlaylist(c.text);
              Navigator.pop(ctx);
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }
}

class _PlaylistPage extends StatelessWidget {
  const _PlaylistPage({required this.name});
  final String name;

  @override
  Widget build(BuildContext context) {
    final lib = context.watch<LibraryStore>();
    final tracks = lib.playlists[name] ?? const <Track>[];
    return Scaffold(
      appBar: AppBar(title: Text(name)),
      body: tracks.isEmpty
          ? const Center(child: Text('Long-press any song to add it here.'))
          : ListView.builder(
              itemCount: tracks.length,
              itemBuilder: (_, i) => Dismissible(
                key: ValueKey(tracks[i].id),
                onDismissed: (_) => lib.removeFromPlaylist(name, tracks[i]),
                background: Container(color: Colors.red.shade900),
                child: TrackTile(track: tracks[i], queue: tracks, index: i),
              ),
            ),
    );
  }
}
