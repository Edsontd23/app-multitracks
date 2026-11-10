
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../domain/song.dart';
import '../domain/song_marker.dart';

class SongMarkerStorage {
  static const String _storageDirectory = 'multitracks';
  static const String _storageFile = 'markers.json';
  static const int _version = 2;

  Future<Directory> _getSongDirectory(Song song) async {
    final appSupport = await getApplicationSupportDirectory();

    final songId = sha256
        .convert(utf8.encode(p.normalize(song.folderPath)))
        .toString();

    return Directory(
      p.join(appSupport.path, _storageDirectory, songId),
    );
  }

  Future<File> _getFile(Song song) async {
    final directory = await _getSongDirectory(song);
    return File(p.join(directory.path, _storageFile));
  }

  Future<Map<String, dynamic>> _readData(Song song) async {
    final file = await _getFile(song);

    if (!await file.exists()) return {};

    final content = await file.readAsString();
    final decoded = jsonDecode(content);

    if (decoded is! Map) return {};

    return Map<String, dynamic>.from(decoded);
  }

  Future<void> _writeData(
    Song song,
    Map<String, dynamic> data,
  ) async {
    final file = await _getFile(song);

    await file.parent.create(recursive: true);

    data['version'] = _version;
    data['folderPath'] = song.folderPath;

    await file.writeAsString(
      jsonEncode(data),
      flush: true,
    );
  }

  // -----------------------------------------------
  // MARCADORES
  // -----------------------------------------------

  Future<void> saveMarkers(Song song) async {
    final data = await _readData(song);

    data['song'] = song.title;
    data['markers'] = song.markers.map((marker) {
      return marker.toJson();
    }).toList();

    await _writeData(song, data);
  }

  Future<List<SongMarker>> loadMarkers(Song song) async {
    final data = await _readData(song);

    final markers = data['markers'] as List<dynamic>? ?? [];

    return markers.map((marker) {
      return SongMarker.fromJson(
        Map<String, dynamic>.from(marker as Map),
      );
    }).toList();
  }

  // -----------------------------------------------
  // CONFIGURACIÓN MUSICAL
  // -----------------------------------------------

  Future<void> saveSongConfiguration(Song song) async {
    final data = await _readData(song);

    data['song'] = song.title;

    data['configuration'] = {
      'bpm': song.bpm,
      'timeSignature': song.timeSignature,
      'originalKey': song.originalKey,
    };

    data['trackNames'] = {
      for (final track in song.audioTracks)
        track.path: track.name,
    };

    await _writeData(song, data);
  }

  Future<void> loadSongConfiguration(Song song) async {
    final data = await _readData(song);

    final configuration =
        data['configuration'] as Map<String, dynamic>?;

    if (configuration == null) return;

    song.title = data['song'] as String? ?? song.title;

    final bpm = configuration['bpm'];

    if (bpm is num) {
      song.bpm = bpm.toDouble();
    }

    song.timeSignature =
        configuration['timeSignature'] as String?;

    song.originalKey =
        configuration['originalKey'] as String?;

    final trackNames =
        data['trackNames'] as Map<String, dynamic>? ?? {};

    for (final track in song.audioTracks) {
      final savedName = trackNames[track.path];

      if (savedName is String && savedName.isNotEmpty) {
        track.name = savedName;
      }
    }
  }

  // -----------------------------------------------
  // ELIMINAR
  // -----------------------------------------------

  Future<void> deleteMarkers(Song song) async {
    final file = await _getFile(song);

    if (!await file.exists()) return;

    await file.delete();

    final directory = file.parent;

    if (await directory.exists() &&
        await directory.list().isEmpty) {
      await directory.delete();
    }
  }
}
