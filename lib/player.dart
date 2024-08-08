import 'dart:convert';

import 'package:audio_service/audio_service.dart';
import 'package:feeluownx/main.dart';

class AudioPlayerHandler extends BaseAudioHandler {
  final Client client;

  AudioPlayerHandler(this.client) {
    initPlaybackState();
  }

  void initPlaybackState() {
    playbackState.add(PlaybackState(
      controls: [
        MediaControl.play,
        MediaControl.skipToNext,
        MediaControl.skipToPrevious,
        MediaControl.stop
      ],
      androidCompactActionIndices: const [0, 1, 2],
      processingState: AudioProcessingState.ready,
      playing: false,
      updatePosition: const Duration(milliseconds: 0),
      speed: 1.0,
      queueIndex: 0,
    ));
  }

  @override
  Future<void> play() {
    return client.jsonRpc('app.player.toggle');
  }

  @override
  Future<void> pause() {
    return client.jsonRpc('app.player.toggle');
  }

  @override
  Future<void> stop() {
    return client.jsonRpc('app.player.stop');
  }

  @override
  Future<void> skipToPrevious() {
    return client.jsonRpc('app.playlist.previous');
  }

  @override
  Future<void> skipToNext() {
    return client.jsonRpc('app.playlist.next');
  }

  Future<void> handleMessage(message) async {
    Map<String, dynamic> js = {};
    try {
      js = json.decode(message);
    } catch (e) {
      print('decode message failed: $e');
    }
    if (js.isNotEmpty) {
      try {
        String topic = js['topic'];
        String data = js['data']!;
        if (topic == 'player.state_changed') {
          print('pubsub: player state changed');
          List<dynamic> args = json.decode(data);
          int state = args[0];
          if (state == 1) {
            playbackState.add(playbackState.value.copyWith(playing: false));
          } else if (state == 2) {
            playbackState.add(playbackState.value.copyWith(playing: true));
          }
        } else if (topic == 'player.metadata_changed') {
          print('pubsub: player metadata changed');
          List<dynamic> args = json.decode(data);
          Map<String, dynamic> metadata = args[0];
          print(metadata);
          String artwork_ = metadata['artwork'];
          if (metadata['source'] == 'netease') {
            artwork_ = artwork_.replaceFirst('https', 'http');
          }
          print('artwork changed to: $artwork_');
          List<dynamic> artists = metadata['artists'];
          mediaItem.add(MediaItem(
              id: metadata['uri'],
              title: metadata['title'],
              artist: artists.join(","),
              album: metadata['album'],
              artUri: Uri.parse(artwork_)));
        }
      } catch (e) {
        print('handle message error: $e');
      }
    }
  }
}
