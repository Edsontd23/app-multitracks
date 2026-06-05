import 'package:just_audio/just_audio.dart';

class TrackPlayer {
  final String name;
  final String path;

  final AudioPlayer player = AudioPlayer();

  double volume = 1.0;

  TrackPlayer({
    required this.name,
    required this.path,
  });

  Future<void> load() async {
    await player.setFilePath(path);
    await player.setVolume(volume);
  }

  Future<void> play() async => player.play();

  Future<void> pause() async => player.pause();

  Future<void> stop() async => player.stop();

  Future<void> setVolume(double value) async {
    volume = value;
    await player.setVolume(value);
  }

  double get currentVolume => volume;

  void dispose() {
    player.dispose();
  }
}