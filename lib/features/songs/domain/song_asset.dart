import 'song_asset_type.dart';

class SongAsset {
  String name;
  final String path;
  final SongAssetType type;

  SongAsset({
    required this.name,
    required this.path,
    required this.type,
  });
} 