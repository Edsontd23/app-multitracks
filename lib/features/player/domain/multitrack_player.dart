import 'package:just_audio/just_audio.dart';

class TrackPlayer {
  final String name;
  final String path;

  final AudioPlayer player = AudioPlayer();

  double volume;

  TrackPlayer({
    required this.name,
    required this.path,
    this.volume = 1.0,
  });

  Future<void> load() async {
    await player.setFilePath(path);
    await player.setVolume(volume);
  }

  Future<void> play() async {
    await player.play();
  }

  Future<void> pause() async {
    await player.pause();
  }

  Future<void> stop() async {
    await player.stop();
  }

  Future<void> setVolume(double value) async {
    volume = value;
    await player.setVolume(value);
  }

  void dispose() {
    player.dispose();
  }
}