import '../domain/track_player.dart';

class MultitrackEngine {
  final List<TrackPlayer> tracks;

  MultitrackEngine(this.tracks);

  Future<void> loadAll() async {
    for (final t in tracks) {
      await t.load();
    }
  }

  Future<void> playAll() async {
    for (final t in tracks) {
      await t.play();
    }
  }

  Future<void> pauseAll() async {
    for (final t in tracks) {
      await t.pause();
    }
  }

  Future<void> stopAll() async {
    for (final t in tracks) {
      await t.stop();
    }
  }

  void dispose() {
    for (final t in tracks) {
      t.dispose();
    }
  }
}