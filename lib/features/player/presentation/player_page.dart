import 'dart:io';
import 'dart:async';
import 'package:app_multitracks/core/audio/daw_platform.dart';
import 'package:app_multitracks/core/theme/app_colors.dart';
import 'package:app_multitracks/core/tracks/track_mapper.dart';
import 'package:app_multitracks/features/songs/domain/song_asset_type.dart';
import 'package:app_multitracks/features/songs/domain/song_marker.dart';
import 'package:flutter/material.dart';

import '../../../core/audio/master_mixer.dart';
import '../../../core/audio/waveform_service.dart';
import '../../../core/session/session_instance.dart';
import '../../player/domain/track_player.dart';
import 'widgets/arrangement/arrangement_view.dart';
import 'widgets/timeline/timeline.dart';
import 'widgets/waveform/waveform.dart';

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
  late final List<SongMarker> markers;
  final ScrollController timelineController = ScrollController();
  double get playheadX {
    if (totalDuration.inMilliseconds == 0) {
      return 0;
    }
    return ( currentPosition.inMilliseconds / totalDuration.inMilliseconds ) *
    ( totalDuration.inMilliseconds / 1000 * 100 );

  }
  

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
        _followPlayhead();

      },
    );
  }

  void _followPlayhead(){

    if(!timelineController.hasClients) {
      return;
    }


    final seconds =
        currentPosition.inMilliseconds /
        1000;


    final offset =
        seconds *
        100;


    timelineController.animateTo(
      offset - 200,
      duration:
        const Duration(
          milliseconds:200,
        ),
      curve:
        Curves.easeOut,
    );

  }
  Future<void> loadMasterWaveform() async {


final song =
    songSession.currentSong;


if(song == null) {
  return;
}



final waveformService =
    WaveformService();



final master =
await waveformService.generate(
  song.audioTracks.first.path,
);



song.waveform =
    master;



setState((){});


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

    markers = List.from(song.markers);
    muted = List.generate(tracks.length, (_) => false);
    soloed = List.generate(tracks.length, (_) => false);
    volumes = List.generate(tracks.length, (_) => 1.0);

    final paths = song.assets.where((a) => a.type == SongAssetType.audio).map((a) => a.path).toList();

    await DAWPlatform.instance.loadTracks(paths);
    
    final masterPath =
        await MasterMixer()
            .mix(paths);


    song.waveform =
        await WaveformService()
            .generate(masterPath);
    final seconds = await DAWPlatform.instance.duration();

    totalDuration = Duration(
      milliseconds: (seconds * 1000).toInt(),
    );

    setState(() { loaded = true; });
  }

  @override
  void dispose() {
    positionTimer?.cancel();
    timelineController.dispose();
    super.dispose();
  }

  void _addMarker() {
    final marker = SongMarker(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: "Marker ${markers.length + 1}",
      position: currentPosition,
      beat: 0,
      measure: 0,
      tick: 0,
    );

    setState(() {
      markers.add(marker);
      markers.sort(
        (a, b) => a.position.compareTo(b.position),
      );
    });
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
              background: Stack(
                fit: StackFit.expand,
                children: [
                  if (song.artwork != null)
                    Image.file(
                      File(song.artwork!.path),
                      fit: BoxFit.cover,
                    ),

                  Container(
                    decoration: const BoxDecoration(
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

                  Positioned(
                    left: 60,
                    right: 16,
                    bottom: 10,
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
                            color: Colors.white,
                          ),
                        ),

                        const SizedBox(height: 4),

                        Row(
                          children: [

                            Text(
                              formatDuration(currentPosition),
                              style: const TextStyle(
                                fontSize: 10,
                                color: Colors.white,
                              ),
                            ),

                            Expanded(
                              child: Slider(
                                padding: EdgeInsets.zero,
                                value: currentPosition.inMilliseconds
                                    .toDouble()
                                    .clamp(
                                      0,
                                      totalDuration.inMilliseconds.toDouble(),
                                    ),
                                max: totalDuration.inMilliseconds <= 0
                                    ? 1
                                    : totalDuration.inMilliseconds.toDouble(),

                                onChanged: (value) async {

                                  setState(() {
                                    currentPosition = Duration(
                                      milliseconds: value.toInt(),
                                    );
                                  });

                                  await DAWPlatform.instance.seek(
                                    value / 1000,
                                  );
                                },
                              ),
                            ),

                            IconButton(
                              icon: const Icon(
                                Icons.flag,
                                color: Colors.white,
                              ),
                              onPressed: _addMarker,
                            ),

                            Text(
                              formatDuration(totalDuration),
                              style: const TextStyle(
                                fontSize: 10,
                                color: Colors.white,
                              ),
                            ),

                            IconButton(
                              style: IconButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                shape: const CircleBorder(),
                                padding: EdgeInsets.zero,
                                minimumSize: const Size(24,24),
                                maximumSize: const Size(24,24),
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

                              icon: Icon(
                                isPlaying
                                    ? Icons.stop
                                    : Icons.play_arrow,
                                size: 18,
                              ),
                            ),
                          ],
                        ),

                        SizedBox(
                          height: 36,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,

                            itemCount: markers.length,

                            separatorBuilder: (_, _) =>
                                const SizedBox(width: 8),

                            itemBuilder: (_, index) {

                              final marker = markers[index];

                              return FilledButton(
                                onPressed: () async {

                                  await DAWPlatform.instance.seek(
                                    marker.position.inMilliseconds / 1000,
                                  );

                                  setState(() {
                                    currentPosition = marker.position;
                                  });

                                },

                                child: Text(
                                  marker.name,
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ), 
          ),
          SliverToBoxAdapter(
            child: SizedBox(
              height: 80,
              child:Timeline(
                duration: totalDuration,
                position: currentPosition,
                markers: markers,
                scrollController: timelineController,
                waveform: song.waveform,
              ),
            ),
          ),
          SliverToBoxAdapter(
          child: SizedBox(
            height: tracks.length * 80.0,

            child: ArrangementView(
              tracks: tracks,
              duration: totalDuration,
              position: currentPosition,
              pixelsPerSecond:100,
              scrollController: timelineController,
            ),
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
        const SizedBox(
 height:60,
),


SizedBox(
 height:60,

 child:Waveform(

   samples:track.waveform ?? [],

 ),

),
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