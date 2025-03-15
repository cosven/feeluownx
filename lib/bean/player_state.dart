import 'package:flutter/foundation.dart';

class PlayerState with ChangeNotifier {
  /// 当前歌曲信息
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

  String getArtistsName() {
    return (metadata?['artists'] ?? []).join('/');
  }
}
