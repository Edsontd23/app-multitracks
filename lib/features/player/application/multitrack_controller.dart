import '../domain/multitrack_player.dart';

class MultitrackController {
  final List<TrackPlayer> tracks;

  MultitrackController(this.tracks);

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