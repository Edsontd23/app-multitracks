import 'package:app_multitracks/features/songs/domain/song_marker.dart';

import 'song_asset.dart';
import 'song_asset_type.dart';

class Song {
  final String title;
  final List<SongAsset> assets;
  final List<SongMarker> markers;
  List<double>? waveform;
  Song({
    required this.title,
    required this.assets,
    this.markers = const []
  });

  List<SongAsset> byType(SongAssetType type) {
    return assets.where((asset) => asset.type == type).toList();
  }

  List<SongAsset> get audioTracks =>
      byType(SongAssetType.audio);

  List<SongAsset> get midiFiles =>
      byType(SongAssetType.midi);

  List<SongAsset> get lyricsFiles =>
      byType(SongAssetType.lyrics);

  List<SongAsset> get chordFiles =>
      byType(SongAssetType.chords);

  List<SongAsset> get artworkFiles =>
      byType(SongAssetType.artwork);

  List<SongAsset> get otherFiles =>
      byType(SongAssetType.other);

  int get audioCount => audioTracks.length;

  int get midiCount => midiFiles.length;

  int get lyricsCount => lyricsFiles.length;

  int get chordsCount => chordFiles.length;

  int get artworkCount => artworkFiles.length;

  int get otherCount => otherFiles.length;

  bool get hasAudio => audioCount > 0;

  bool get hasMidi => midiCount > 0;

  bool get hasLyrics => lyricsCount > 0;

  bool get hasChords => chordsCount > 0;

  bool get hasArtwork => artworkCount > 0;

  bool get hasMarkers => markers.isNotEmpty;

  int get markerCount => markers.length;

  SongAsset? get artwork {
    if (artworkFiles.isEmpty) return null;
    return artworkFiles.first;
  }

  SongAsset? get lyrics {
    if (lyricsFiles.isEmpty) return null;
    return lyricsFiles.first;
  }

  SongAsset? get midi {
    if (midiFiles.isEmpty) return null;
    return midiFiles.first;
  }

  int get totalAssets => assets.length;
}