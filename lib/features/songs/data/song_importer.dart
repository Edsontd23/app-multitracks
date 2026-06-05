import 'dart:io';

import 'package:path/path.dart' as p;

import '../domain/song.dart';
import '../domain/song_asset.dart';

import 'song_asset_classifier.dart';

class SongImporter {
  Future<Song> importFolder(String folderPath) async {
    final directory = Directory(folderPath);

    final entities = await directory.list().toList();

    final assets = <SongAsset>[];

    for (final entity in entities) {
      if (entity is! File) continue;

      final filename = p.basename(entity.path);

      assets.add(
        SongAsset(
          name: filename,
          path: entity.path,
          type: SongAssetClassifier.classify(filename),
        ),
      );
    }

    return Song(
      title: p.basename(folderPath),
      assets: assets,
    );
  }
}