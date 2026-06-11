import 'package:app_multitracks/core/tracks/track_style.dart';

class TrackModel {
  final String name;
  final String path;

  double volume;
  bool muted;
  bool solo;
  final TrackStyle style;

  TrackModel({
    required this.name,
    required this.path,
    required this.style,
    this.volume = 1.0,
    this.muted = false,
    this.solo = false,
  });
}