import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../catalog/catalog_provider.dart';
import '../models/track.dart';
import '../widgets/track_tile.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? _genre; // null = all genres
  Future<List<Track>>? _future;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _future ??= _load();
  }

  Future<List<Track>> _load() => context.read<CatalogProvider>().trending(genre: _genre);

  void _setGenre(String? g) {
    setState(() {
      _genre = g;
      _future = _load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final genres = context.read<CatalogProvider>().genres;
    return RefreshIndicator(
      onRefresh: () async {
        setState(() => _future = _load());
        await _future;
      },
      child: CustomScrollView(
        slivers: [
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(16, 16, 16, 4),
              child: Text('Trending this week',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            ),
          ),
          SliverToBoxAdapter(
            child: SizedBox(
              height: 56,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                children: [
                  _chip('All', _genre == null, () => _setGenre(null)),
                  for (final g in genres) _chip(g, _genre == g, () => _setGenre(g)),
                ],
              ),
            ),
          ),
          FutureBuilder<List<Track>>(
            future: _future,
            builder: (context, snap) {
              if (snap.connectionState != ConnectionState.done) {
                return const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              if (snap.hasError) {
                return SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('${snap.error}', textAlign: TextAlign.center),
                          const SizedBox(height: 12),
                          FilledButton(
                            onPressed: () => setState(() => _future = _load()),
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }
              final tracks = snap.data ?? const [];
              if (tracks.isEmpty) {
                return const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(child: Text('Nothing here yet.')),
                );
              }
              return SliverList.builder(
                itemCount: tracks.length,
                itemBuilder: (_, i) => TrackTile(track: tracks[i], queue: tracks, index: i),
              );
            },
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 16)),
        ],
      ),
    );
  }

  Widget _chip(String label, bool selected, VoidCallback onTap) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
        child: ChoiceChip(label: Text(label), selected: selected, onSelected: (_) => onTap()),
      );
}
