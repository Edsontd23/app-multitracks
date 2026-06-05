import 'song_asset_type.dart';

class SongAsset {
  final String name;
  final String path;
  final SongAssetType type;

  const SongAsset({
    required this.name,
    required this.path,
    required this.type,
  });
}