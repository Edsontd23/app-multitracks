import 'package:app_multitracks/core/tracks/track_mapper.dart';
import 'package:app_multitracks/features/player/domain/track_player.dart';
import 'package:flutter/material.dart';

import '../../../core/session/session_instance.dart';

class MixerPage extends StatefulWidget {
  const MixerPage({super.key});

  @override
  State<MixerPage> createState() => _MixerPageState();
}

class _MixerPageState extends State<MixerPage> {
  bool loaded = false;

  @override
  void initState() {
    super.initState();

    final song = songSession.currentSong;

    final tracks = song!.audioTracks.map((a) {
      return TrackModel(
        name: a.name,
        path: a.path,
        style: TrackMapper.fromName(a.name),
      );
    }).toList();

    _load();
  }

  Future<void> _load() async {
    setState(() => loaded = true);
  }

  @override
  void dispose() {
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
      ),
      body: const Center(
        child: Text('Audio listo 🎧'),
      ),
    );
  }
}