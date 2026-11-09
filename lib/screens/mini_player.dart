import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../player/player_controller.dart';
import '../widgets/track_tile.dart';
import 'now_playing_screen.dart';

class MiniPlayer extends StatelessWidget {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.watch<PlayerController>();
    final track = p.current;
    if (track == null) return const SizedBox.shrink();

    return Material(
      color: const Color(0xFF1B1B24),
      child: InkWell(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(fullscreenDialog: true, builder: (_) => const NowPlayingScreen()),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            StreamBuilder<Duration>(
              stream: p.positionStream,
              builder: (_, snap) {
                final pos = snap.data?.inMilliseconds ?? 0;
                final total = track.durationSec * 1000;
                return LinearProgressIndicator(
                  value: total > 0 ? (pos / total).clamp(0.0, 1.0) : null,
                  minHeight: 2,
                );
              },
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  Artwork(url: track.artworkUrl, size: 44),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(track.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                        Text(
                          p.error ?? track.artist,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            color: p.error != null ? Colors.redAccent : Colors.white60,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(p.playing ? Icons.pause : Icons.play_arrow),
                    onPressed: p.togglePlay,
                  ),
                  IconButton(icon: const Icon(Icons.skip_next), onPressed: p.hasNext ? p.next : null),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
