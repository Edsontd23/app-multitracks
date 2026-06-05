import 'package:just_audio/just_audio.dart';

class PlayerController {
  final AudioPlayer player;

  PlayerController(this.player);

  Future<void> play(String path) async {
    await player.setFilePath(path);
    await player.play();
  }

  Future<void> pause() async {
    await player.pause();
  }

  Future<void> stop() async {
    await player.stop();
  }

  Stream<PlayerState> get stateStream => player.playerStateStream;
}