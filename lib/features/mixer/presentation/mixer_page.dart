import 'package:app_multitracks/features/player/application/multitrack_engine.dart';
import 'package:app_multitracks/features/player/domain/track_player.dart';
import 'package:flutter/material.dart';

import '../../../core/session/session_instance.dart';

class MixerPage extends StatefulWidget {
  const MixerPage({super.key});

  @override
  State<MixerPage> createState() => _MixerPageState();
}

class _MixerPageState extends State<MixerPage> {
  late MultitrackEngine engine;
  bool loaded = false;

  @override
  void initState() {
    super.initState();

    final song = songSession.currentSong;

    final tracks = song!.audioTracks.map((a) {
      return TrackPlayer(
        name: a.name,
        path: a.path,
      );
    }).toList();

    engine = MultitrackEngine(tracks);

    _load();
  }

  Future<void> _load() async {
    await engine.loadAll();
    setState(() => loaded = true);
  }

  @override
  void dispose() {
    engine.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!loaded) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Mixer - ${songSession.currentSong!.title}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.play_arrow),
            onPressed: engine.playAll,
          ),
          IconButton(
            icon: const Icon(Icons.pause),
            onPressed: engine.pauseAll,
          ),
          IconButton(
            icon: const Icon(Icons.stop),
            onPressed: engine.stopAll,
          ),
        ],
      ),
      body: const Center(
        child: Text('Audio listo 🎧'),
      ),
    );
  }
}