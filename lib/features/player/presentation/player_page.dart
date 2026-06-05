import 'package:flutter/material.dart';

import '../../../core/session/session_instance.dart';
import '../../player/application/multitrack_controller.dart';
import '../../player/domain/track_player.dart';

class PlayerPage extends StatefulWidget {
  const PlayerPage({super.key});

  @override
  State<PlayerPage> createState() => _PlayerPageState();
}

class _PlayerPageState extends State<PlayerPage> {
  late MultitrackController controller;
  bool loaded = false;

  @override
  void initState() {
    super.initState();

    final song = songSession.currentSong;

    if (song == null) return;

    final tracks = song.audioTracks.map((asset) {
      return TrackPlayer(
        name: asset.name,
        path: asset.path,
      );
    }).toList();

    controller = MultitrackController(tracks);

    _load();
  }

  Future<void> _load() async {
    await controller.loadAll();
    setState(() => loaded = true);
  }

  @override
  void dispose() {
    if (loaded) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final song = songSession.currentSong;

    if (song == null) {
      return const Scaffold(
        body: Center(
          child: Text('No song selected'),
        ),
      );
    }

    if (!loaded) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Player - ${song.title}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.play_arrow),
            onPressed: controller.playAll,
          ),
          IconButton(
            icon: const Icon(Icons.pause),
            onPressed: controller.pauseAll,
          ),
          IconButton(
            icon: const Icon(Icons.stop),
            onPressed: controller.stopAll,
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: controller.tracks.length,
        itemBuilder: (context, index) {
          final track = controller.tracks[index];

          return ListTile(
            title: Text(track.name),
            subtitle: StreamBuilder<double>(
              stream: track.player.volumeStream,
              initialData: 1.0,
              builder: (context, snapshot) {
                final value = snapshot.data ?? 1.0;

                return Slider(
                  value: value,
                  min: 0,
                  max: 1,
                  onChanged: (v) async {
                    await track.setVolume(v);
                    setState(() {});
                  },
                );
              },
            ),
            trailing: IconButton(
              icon: const Icon(Icons.volume_off),
              onPressed: () async {
                final newValue = track.volume > 0 ? 0.0 : 1.0;
                await track.setVolume(newValue);
                setState(() {});
              },
            ),
          );
        },
      ),
    );
  }
}