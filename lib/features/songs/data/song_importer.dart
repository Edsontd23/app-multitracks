
import 'dart:io';

import 'package:path/path.dart' as p;

import '../domain/song.dart';
import '../domain/song_asset.dart';

import 'song_asset_classifier.dart';
import 'song_marker_storage.dart';

class SongImporter {
  final SongMarkerStorage _markerStorage;

  SongImporter({
    SongMarkerStorage? markerStorage,
  }) : _markerStorage = markerStorage ?? SongMarkerStorage();

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

    final song = Song(
      title: p.basename(folderPath),
      folderPath: directory.absolute.path,
      assets: assets,
    );

    // Recuperar marcadores guardados.
    final markers = await _markerStorage.loadMarkers(song);
    song.markers.addAll(markers);

    // Recuperar configuración musical.
    await _markerStorage.loadSongConfiguration(song);

    return song;
  }
}
