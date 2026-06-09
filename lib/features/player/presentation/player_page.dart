import 'package:app_multitracks/core/audio/daw_platform.dart';
import 'package:app_multitracks/features/songs/domain/song_asset_type.dart';
import 'package:flutter/material.dart';

import '../../../core/session/session_instance.dart';
import '../../player/domain/track_player.dart';

class PlayerPage extends StatefulWidget {
  const PlayerPage({super.key});

  @override
  State<PlayerPage> createState() => _PlayerPageState();
}

class _PlayerPageState extends State<PlayerPage> {
  bool loaded = false;
  List<double> volumes = [];
  List<TrackModel> tracks = [];
  List<bool> muted = [];

  @override
  void initState() {
    super.initState();


    final song = songSession.currentSong;

    if (song == null) return;

    tracks = song.audioTracks.map((asset) {
      return TrackModel(
        name: asset.name,
        path: asset.path,
      );
    }).toList();

    muted = List.generate(
      tracks.length,
      (_) => false,
    );

    final paths = song.assets
      .where((a) => a.type == SongAssetType.audio)
      .map((a) => a.path)
      .toList();

    DAWPlatform.instance.loadTracks(paths);
    setState(() {
      volumes = List.generate(
        tracks.length,
        (_) => 1.0,
      );
    });
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
      ),
      body: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: () async {
                  await DAWPlatform.instance.play();
                },
                child: const Icon(Icons.play_arrow),
              ),
              ElevatedButton(
                onPressed: () async {
                  await DAWPlatform.instance.stop();
                },
                child: const Icon(Icons.stop),
              ),
            ],
          ),
          Expanded(
            child: ListView.builder(
              itemCount: tracks.length,
              itemBuilder: (_, index) {
                return Column(
                  children: [

                    Text(tracks[index].name),

                    Slider(
                      min: 0,
                      max: 1,
                      value: tracks[index].volume,
                      onChanged: (value) async {

                        setState(() {
                          tracks[index].volume = value;
                        });

                        await DAWPlatform.instance.setVolume(
                          index,
                          value
                        );
                      },
                    ),
                    ElevatedButton(
                      onPressed: () async {

                        final value = !muted[index];

                        setState(() {
                          muted[index] = value;
                        });

                        await DAWPlatform.instance.mute(
                          index,
                          value,
                        );
                      },
                      child: Text(
                        muted[index]
                          ? 'UNMUTE'
                          : 'MUTE',
                      ),
                    )
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}