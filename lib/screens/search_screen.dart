import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../catalog/catalog_provider.dart';
import '../models/track.dart';
import '../widgets/track_tile.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _controller = TextEditingController();
  Timer? _debounce;
  Future<List<Track>>? _future;
  String _query = '';

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      final q = value.trim();
      setState(() {
        _query = q;
        _future = q.isEmpty ? null : context.read<CatalogProvider>().search(q);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: SearchBar(
            controller: _controller,
            hintText: 'Songs, artists',
            leading: const Icon(Icons.search),
            onChanged: _onChanged,
            trailing: [
              if (_controller.text.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () {
                    _controller.clear();
                    _onChanged('');
                  },
                ),
            ],
          ),
        ),
        Expanded(
          child: _future == null
              ? const Center(child: Text('Search the catalog'))
              : FutureBuilder<List<Track>>(
                  future: _future,
                  builder: (context, snap) {
                    if (snap.connectionState != ConnectionState.done) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snap.hasError) {
                      return Center(child: Text('${snap.error}'));
                    }
                    final tracks = snap.data ?? const [];
                    if (tracks.isEmpty) {
                      return Center(child: Text('No results for "$_query"'));
                    }
                    return ListView.builder(
                      itemCount: tracks.length,
                      itemBuilder: (_, i) =>
                          TrackTile(track: tracks[i], queue: tracks, index: i),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
