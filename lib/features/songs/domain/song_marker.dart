class SongMarker {
  final String id;

  String name;

  Duration position;

  int beat;

  int measure;

  int tick;

  String? notes;

  SongMarker({
    required this.id,
    required this.name,
    required this.position,
    required this.beat,
    required this.measure,
    this.tick = 0,
    this.notes,
  });
}