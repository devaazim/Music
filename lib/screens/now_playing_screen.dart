import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:provider/provider.dart';

import '../library/library_store.dart';
import '../player/player_controller.dart';
import '../widgets/track_tile.dart';

class NowPlayingScreen extends StatelessWidget {
  const NowPlayingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.watch<PlayerController>();
    final lib = context.watch<LibraryStore>();
    final track = p.current;
    if (track == null) {
      return const Scaffold(body: Center(child: Text('Nothing playing')));
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.keyboard_arrow_down),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Now playing'),
        centerTitle: true,
        actions: [
          IconButton(icon: const Icon(Icons.more_vert), onPressed: () => showTrackMenu(context, track)),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          children: [
            const Spacer(),
            LayoutBuilder(
              builder: (_, c) => Artwork(
                url: track.artworkUrl,
                size: c.maxWidth.clamp(0, 360).toDouble(),
                radius: 16,
              ),
            ),
            const Spacer(),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(track.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text(track.artist,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Colors.white70)),
                    ],
                  ),
                ),
                IconButton(
                  iconSize: 28,
                  icon: Icon(
                    lib.isLiked(track) ? Icons.favorite : Icons.favorite_border,
                    color: lib.isLiked(track) ? Colors.pinkAccent : null,
                  ),
                  onPressed: () => lib.toggleLike(track),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _SeekBar(controller: p, fallbackSeconds: track.durationSec),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(
                  icon: Icon(Icons.shuffle,
                      color: p.shuffle ? Theme.of(context).colorScheme.primary : null),
                  onPressed: p.toggleShuffle,
                ),
                IconButton(
                  iconSize: 40,
                  icon: const Icon(Icons.skip_previous),
                  onPressed: p.previous,
                ),
                StreamBuilder<PlayerState>(
                  stream: p.stateStream,
                  builder: (_, snap) {
                    final state = snap.data;
                    final loading = state?.processingState == ProcessingState.loading ||
                        state?.processingState == ProcessingState.buffering;
                    if (loading) {
                      return const SizedBox(
                        width: 64,
                        height: 64,
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: CircularProgressIndicator(),
                        ),
                      );
                    }
                    return IconButton.filled(
                      iconSize: 40,
                      icon: Icon(p.playing ? Icons.pause : Icons.play_arrow),
                      onPressed: p.togglePlay,
                    );
                  },
                ),
                IconButton(
                  iconSize: 40,
                  icon: const Icon(Icons.skip_next),
                  onPressed: p.hasNext ? p.next : null,
                ),
                IconButton(
                  icon: Icon(
                    p.loopMode == LoopMode.one ? Icons.repeat_one : Icons.repeat,
                    color: p.loopMode == LoopMode.off ? null : Theme.of(context).colorScheme.primary,
                  ),
                  onPressed: p.cycleLoop,
                ),
              ],
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _SeekBar extends StatefulWidget {
  const _SeekBar({required this.controller, required this.fallbackSeconds});
  final PlayerController controller;
  final int fallbackSeconds;

  @override
  State<_SeekBar> createState() => _SeekBarState();
}

class _SeekBarState extends State<_SeekBar> {
  double? _drag;

  @override
  Widget build(BuildContext context) {
    final c = widget.controller;
    return StreamBuilder<Duration?>(
      stream: c.durationStream,
      builder: (_, dSnap) {
        final total = dSnap.data ?? Duration(seconds: widget.fallbackSeconds);
        return StreamBuilder<Duration>(
          stream: c.positionStream,
          builder: (_, pSnap) {
            final pos = pSnap.data ?? Duration.zero;
            final max = total.inMilliseconds.toDouble();
            final value = (_drag ?? pos.inMilliseconds.toDouble()).clamp(0.0, max > 0 ? max : 1.0);
            return Column(
              children: [
                Slider(
                  value: value,
                  max: max > 0 ? max : 1.0,
                  onChanged: max > 0 ? (v) => setState(() => _drag = v) : null,
                  onChangeEnd: (v) {
                    c.seek(Duration(milliseconds: v.round()));
                    setState(() => _drag = null);
                  },
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(formatDuration(Duration(milliseconds: value.round()).inSeconds),
                          style: const TextStyle(fontSize: 12, color: Colors.white60)),
                      Text(formatDuration(total.inSeconds),
                          style: const TextStyle(fontSize: 12, color: Colors.white60)),
                    ],
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
