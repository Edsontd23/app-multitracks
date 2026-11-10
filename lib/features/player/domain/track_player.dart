import 'package:app_multitracks/core/tracks/track_style.dart';
import 'audio_clip.dart';

class TrackModel {

  final String name;
  final String path;

  double volume;
  bool muted;
  bool solo;

  final TrackStyle style;
  List<double>? waveform;
  List<AudioClip> clips;


  TrackModel({
    required this.name,
    required this.path,
    required this.style,
    this.volume = 1.0,
    this.muted = false,
    this.solo = false,
    
    List<AudioClip>? clips,

  }) : clips = clips ?? [];

}