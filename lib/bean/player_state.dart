import 'package:flutter/foundation.dart';

class PlayerState with ChangeNotifier {
  /// Corresponding to player.metadata
  Map<String, dynamic>? metadata;

  /// 当前播放状态  0: stopped, 1:paused, 2:playing
  int playState = 0;

  /// 当前歌词行
  String currentLyricsLine = "";

  void setPlayState(int value) {
    playState = value;
    notifyListeners();
  }

  void setMetadata(Map<String, dynamic> value) {
    metadata = value;
    notifyListeners();
  }

  void setCurrentLyricsLine(String value) {
    currentLyricsLine = value;
    notifyListeners();
  }

  bool get isPlaying => playState == 2;

  String getArtistsName() {
    return (metadata?['artists'] ?? []).join('/');
  }

  bool sameAsCurrentSong(Map<String, dynamic> song) {
    if (metadata == null) return false;
    return song['uri'] == metadata!['uri'];
  }
}
