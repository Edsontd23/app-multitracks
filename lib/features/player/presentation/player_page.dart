import 'package:app_multitracks/core/audio/daw_platform.dart';
import 'package:app_multitracks/core/theme/app_colors.dart';
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
  List<bool> soloed = [];
  bool isPlaying = false;

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

    muted = List.generate(tracks.length, (_) => false);
    soloed = List.generate(tracks.length, (_) => false);

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
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              '${songSession.currentSong!.title.toUpperCase().split('-')[0]}\n${songSession.currentSong!.title.toUpperCase().split('-')[1].trim()}',
              softWrap: true,
              textWidthBasis: TextWidthBasis.parent,
              style: const TextStyle(
                fontSize: 12,
              ),
            ),
            ElevatedButton(
              onPressed: () async {

                if (isPlaying) {

                  await DAWPlatform.instance.stop();

                } else {

                  await DAWPlatform.instance.play();

                }

                setState(() {
                  isPlaying = !isPlaying;
                });
              },
              child: Icon(
                isPlaying
                  ? Icons.stop
                  : Icons.play_arrow,
              ),
            ),
            Row(
              children: [
                Text('BPM: \n120', style: TextStyle(fontSize: 12),),
                Text('KEY: \nC', style: TextStyle(fontSize: 12),),
              ],
            )
          ],
        ),
        backgroundColor: Colors.transparent,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: tracks.length,
              itemBuilder: (_, index) {
                return Padding(
                  padding: const EdgeInsets.fromLTRB(16.0, 4.0, 16.0, 2.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                  
                      Text(tracks[index].name.split('.')[0]),
                  
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
                      Row(
                        children: [
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
                            child: Icon(
                              color: muted[index] ? AppColors.primary : AppColors.secondary,
                              muted[index]
                                ? Icons.volume_off
                                : Icons.volume_up,
                            ),
                          ),
                          ElevatedButton(
                            onPressed: () async {
                          
                              final value = !soloed[index];
                          
                              setState(() {
                                soloed[index] = value;
                              });
                          
                              await DAWPlatform.instance.solo(
                                index,
                                value,
                              );
                            },
                            child: Icon(
                              soloed[index]
                                ? Icons.do_disturb_on
                                : Icons.do_disturb_off,
                            ),
                          ),
                        ],
                      )
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}