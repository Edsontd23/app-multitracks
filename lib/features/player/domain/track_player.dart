class TrackModel {
  final String name;
  final String path;

  double volume;
  bool muted;
  bool solo;

  TrackModel({
    required this.name,
    required this.path,
    this.volume = 1.0,
    this.muted = false,
    this.solo = false,
  });
}