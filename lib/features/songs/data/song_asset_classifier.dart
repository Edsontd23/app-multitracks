import '../domain/song_asset_type.dart';

class SongAssetClassifier {
  static SongAssetType classify(String filename) {
    final lower = filename.toLowerCase();

    // AUDIO

    if (lower.endsWith('.wav') ||
        lower.endsWith('.mp3') ||
        lower.endsWith('.m4a') ||
        lower.endsWith('.aac') ||
        lower.endsWith('.flac')) {
      return SongAssetType.audio;
    }

    // MIDI

    if (lower.endsWith('.mid') ||
        lower.endsWith('.midi')) {
      return SongAssetType.midi;
    }

    // LYRICS

    if (lower.contains('lyrics') ||
        lower.contains('lyric') ||
        lower.contains('letra')) {
      return SongAssetType.lyrics;
    }

    // CHORDS

    if (lower.contains('chords') ||
        lower.contains('chord') ||
        lower.contains('acordes') ||
        lower.contains('leadsheet')) {
      return SongAssetType.chords;
    }

    // IMAGES

    if (lower.endsWith('.jpg') ||
        lower.endsWith('.jpeg') ||
        lower.endsWith('.png') ||
        lower.endsWith('.webp')) {
      return SongAssetType.artwork;
    }

    return SongAssetType.other;
  }
}