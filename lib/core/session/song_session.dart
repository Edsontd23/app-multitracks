import '../../features/songs/domain/song.dart';

class SongSession {
  Song? currentSong;

  void setSong(Song song) {
    currentSong = song;
  }

  void clear() {
    currentSong = null;
  }

  bool get hasSong => currentSong != null;
}