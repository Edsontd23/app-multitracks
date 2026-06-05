import 'dart:io';

import '../domain/song.dart';
import 'song_importer.dart';

class SongLibraryImporter {
  final SongImporter importer = SongImporter();

  Future<List<Song>> importLibrary(
    String libraryPath,
  ) async {
    final root = Directory(libraryPath);

    final entities = await root.list().toList();

    final songs = <Song>[];

    for (final entity in entities) {
      if (entity is! Directory) continue;

      final song =
          await importer.importFolder(entity.path);

      songs.add(song);
    }

    songs.sort(
      (a, b) => a.title.compareTo(b.title),
    );

    return songs;
  }
}