
import 'dart:async';
import 'package:flutter/foundation.dart';

import '../data/song_marker_storage.dart';
import '../domain/song.dart';
import '../domain/song_marker.dart';

class SongMarkerController {
  final Song song;
  final SongMarkerStorage _storage;

  Timer? _saveTimer;

  Future<void> _writeQueue = Future<void>.value();

  bool _hasChanges = false;
  bool _disposed = false;

  SongMarkerController({
    required this.song,
    SongMarkerStorage? storage,
  }) : _storage = storage ?? SongMarkerStorage();

  List<SongMarker> get markers => song.markers;

  void addMarker(SongMarker marker) {
    _ensureActive();

    markers.add(marker);
    _sortMarkers();

    _hasChanges = true;
  }

  void renameMarker(SongMarker marker, String newName) {
    _ensureActive();

    marker.name = newName;
    _hasChanges = true;
  }

  void deleteMarker(SongMarker marker) {
    _ensureActive();

    markers.removeWhere((item) => item.id == marker.id);
    _hasChanges = true;
  }

  void moveMarker(SongMarker marker, Duration position) {
    _ensureActive();

    marker.position = position;
    _hasChanges = true;
  }

  void _sortMarkers() {
    markers.sort(
      (a, b) => a.position.compareTo(b.position),
    );
  }

  void scheduleSave({
    Duration delay = const Duration(milliseconds: 400),
  }) {
    _ensureActive();

    _saveTimer?.cancel();

    _saveTimer = Timer(delay, () {
      unawaited(
        saveNow().catchError((Object error, StackTrace stackTrace) {
          debugPrint('Error guardando marcadores: $error');
          debugPrintStack(stackTrace: stackTrace);
        }),
      );
    });
  }

  Future<void> saveNow() async {
    _saveTimer?.cancel();
    _saveTimer = null;

    if (!_hasChanges) return;

    _hasChanges = false;

    // Serializa las escrituras para evitar que se sobrescriban.
    _writeQueue = _writeQueue
        .catchError((Object _) {})
        .then((_) => _storage.saveMarkers(song));

    try {
      await _writeQueue;
      debugPrint('Marcadores guardados: ${markers.length}');
    } catch (error) {
      _hasChanges = true;
      rethrow;
    }
  }

  Future<void> dispose() async {
    if (_disposed) return;

    _saveTimer?.cancel();
    _saveTimer = null;

    await saveNow();

    _disposed = true;
  }

  void _ensureActive() {
    if (_disposed) {
      throw StateError(
        'SongMarkerController ya fue liberado.',
      );
    }
  }
}
