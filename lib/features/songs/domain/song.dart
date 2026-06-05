import 'song_asset.dart';

class Song {
  final String title;

  final List<SongAsset> assets;

  const Song({
    required this.title,
    required this.assets,
  });

  List<SongAsset> byType(dynamic type) {
    return assets.where((e) => e.type == type).toList();
  }
}