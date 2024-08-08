import 'dart:convert';

import 'package:audio_service/audio_service.dart';
import 'package:feeluownx/main.dart';

class AudioPlayerHandler extends BaseAudioHandler {
  final Client client;

  AudioPlayerHandler(this.client);

  @override
  Future<void> play() {
    return client.jsonRpc('app.player.play');
  }

  @override
  Future<void> pause() {
    return client.jsonRpc('app.player.pause');
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
          mediaItem.add(MediaItem(
              id: metadata['uri'],
              title: metadata['title'],
              artUri: Uri.parse(artwork_)));
        }
      } catch (e) {
        print('handle message error: $e');
      }
    }
  }
}
