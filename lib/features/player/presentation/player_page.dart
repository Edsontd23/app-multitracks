import 'dart:io';
import 'dart:async';
import 'package:app_multitracks/core/audio/daw_platform.dart';
import 'package:app_multitracks/core/theme/app_colors.dart';
import 'package:app_multitracks/core/tracks/track_mapper.dart';
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
  Timer? positionTimer;
  Duration currentPosition = Duration.zero;
  Duration totalDuration = Duration.zero;

  String formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');

    return '$minutes:$seconds';
  }

  void _startPositionTimer() {
    positionTimer?.cancel();

    positionTimer = Timer.periodic(
      const Duration(milliseconds: 50),
      (_) async {
        final pos = await DAWPlatform.instance.position();

        if (!mounted) return;

        setState(() {
          currentPosition = Duration(
            milliseconds: (pos * 1000).toInt(),
          );
        });
      },
    );
  }


  @override
  void initState() {
    super.initState();
    _initialize();
  }
  Future<void> _initialize() async {
    final song = songSession.currentSong;
    if (song == null) return;

    tracks = song.audioTracks.map((asset) {
      return TrackModel( name: asset.name, path: asset.path,  style: TrackMapper.fromName(asset.name), );
    }).toList();

    muted = List.generate(tracks.length, (_) => false);
    soloed = List.generate(tracks.length, (_) => false);
    volumes = List.generate(tracks.length, (_) => 1.0);

    final paths = song.assets.where((a) => a.type == SongAssetType.audio).map((a) => a.path).toList();

    await DAWPlatform.instance.loadTracks(paths);

    final seconds = await DAWPlatform.instance.duration();

    totalDuration = Duration(
      milliseconds: (seconds * 1000).toInt(),
    );

    setState(() { loaded = true; });
  }

  @override
  void dispose() {
    super.dispose();
    positionTimer?.cancel();
  }

  @override
  Widget build(BuildContext context) {
    final song = songSession.currentSong;
    if (song == null) {
      return const Scaffold(
        body: Center( child: Text('No song selected'), ),
      );
    }

    if (!loaded) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      body: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: <Widget>[
            SliverAppBar(
              pinned: true,
              expandedHeight: 150,
              collapsedHeight: 75,
              flexibleSpace: FlexibleSpaceBar(
                title: Padding(
                  padding: const EdgeInsets.only( left: 60, right: 16, bottom: 8),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        song.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Row(
                        spacing: 12,
                        children: [
                          Text(
                            formatDuration(currentPosition),
                            style: const TextStyle(fontSize: 10),
                          ),
                          Expanded(
                            child: Slider(
                              padding: EdgeInsets.zero,
                              value: currentPosition.inMilliseconds.toDouble().clamp(
                                0,
                                totalDuration.inMilliseconds.toDouble(),
                              ),
                              max: totalDuration.inMilliseconds <= 0 ? 1 : totalDuration.inMilliseconds.toDouble(),
                              onChanged: (value) async {
                                setState(() {
                                  currentPosition = Duration( milliseconds: value.toInt() );
                                });

                                await DAWPlatform.instance.seek(value / 1000,);
                              },
                            ),
                          ),
                          Text(
                            formatDuration(totalDuration),
                            style: const TextStyle(fontSize: 10),
                          ),
                          IconButton(
                            style: IconButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              shape: const CircleBorder(),
                              padding: EdgeInsets.zero,
                              minimumSize: const Size(24, 24),
                              maximumSize: const Size(24, 24),
                            ),
                            onPressed: () async {

                              if (isPlaying) {
                                await DAWPlatform.instance.stop();
                                positionTimer?.cancel();

                                setState(() {
                                  isPlaying = false;
                                  currentPosition = Duration.zero;
                                });

                                return;
                              }

                              await DAWPlatform.instance.play();

                              _startPositionTimer();

                              setState(() {
                                isPlaying = true;
                              });
                            },
                            icon: Icon( isPlaying ? Icons.stop : Icons.play_arrow, size: 18,),
                          )
                        ],
                      ),
                    ],
                  ),
                ),
                background: SizedBox(
                  width: .infinity,
                  child: Stack(
                    fit: StackFit.passthrough,
                    children: [
                      if (song.artwork != null)
                        Image.file(
                          File(song.artwork!.path),
                          fit: BoxFit.fitWidth,
                        ),                    
                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black87,
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              ),
            ),
            SliverList.builder(
              itemCount: tracks.length,
              itemBuilder: (BuildContext context, int index) {
                final track = tracks[index];
                return Card(
  margin: const EdgeInsets.symmetric(
    horizontal: 12,
    vertical: 4,
  ),
  child: Padding(
    padding: const EdgeInsets.all(12),
    child: Column(
      children: [

        Row(
          children: [

            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: track.style.color,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                track.style.icon,
                color: Colors.white,
              ),
            ),

            const SizedBox(width: 12),

            Expanded(
              child: Text(
                track.name.split('.').first,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),

            const SizedBox(width: 8),

            GestureDetector(
              onTap: () async {

                final value = !muted[index];

                setState(() {
                  muted[index] = value;
                });

                await DAWPlatform.instance.mute(
                  index,
                  value,
                );
              },
              child: Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: muted[index]
                      ? Colors.red
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: Colors.red,
                  ),
                ),
                child: const Text(
                  'M',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            const SizedBox(width: 8),

            GestureDetector(
              onTap: () async {

                final value = !soloed[index];

                setState(() {
                  soloed[index] = value;
                });

                await DAWPlatform.instance.solo(
                  index,
                  value,
                );
              },
              child: Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: soloed[index]
                      ? Colors.amber
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: Colors.amber,
                  ),
                ),
                child: const Text(
                  'S',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 8),

        Slider(
          min: 0,
          max: 1,
          value: track.volume,
          onChanged: (value) async {

            setState(() {
              track.volume = value;
            });

            await DAWPlatform.instance.setVolume(
              index,
              value,
            );
          },
        ),
      ],
    ),
  ),
);
}
            ),
          ],
        ),
    );
  }
}