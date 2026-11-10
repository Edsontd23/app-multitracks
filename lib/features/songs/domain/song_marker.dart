enum SongMarkerType {
  marker,
  section,
}

class SongMarker {
  final String id;

  String name;
  Duration position;
  int beat;
  int measure;
  int tick;
  String? notes;
  int colorValue;
  SongMarkerType type;

  SongMarker({
    required this.id,
    required this.name,
    required this.position,
    required this.beat,
    required this.measure,
    this.tick = 0,
    this.notes,
    this.colorValue = 0xFF64748B,
    this.type = SongMarkerType.section,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'position': position.inMicroseconds,
      'beat': beat,
      'measure': measure,
      'tick': tick,
      'notes': notes,
      'colorValue': colorValue,
      'type': type.name,
    };
  }

  factory SongMarker.fromJson(Map<String, dynamic> json) {
    return SongMarker(
      id: json['id'] as String,
      name: json['name'] as String,
      position: Duration(
        microseconds: json['position'] as int,
      ),
      beat: json['beat'] as int,
      measure: json['measure'] as int,
      tick: json['tick'] as int? ?? 0,
      notes: json['notes'] as String?,
      colorValue: json['colorValue'] as int? ?? 0xFF64748B,
      type: json['type'] == 'marker'
          ? SongMarkerType.marker
          : SongMarkerType.section,
    );
  }
}

