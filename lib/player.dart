import 'dart:convert';

import 'package:audio_service/audio_service.dart';
import 'package:feeluownx/bean/player_state.dart';
import 'package:feeluownx/global.dart';

import 'client.dart';

class AudioPlayerHandler extends BaseAudioHandler with SeekHandler {
  final Client client = Global.getIt<Client>();
  final PubsubClient pubsubClient = Global.getIt<PubsubClient>();

  PlayerState playerState = PlayerState();

  final Map<int, String> connectionStatusMap = {0: "已断开", 1: "已连接", 2: "异常"};

  /// 0: 断开 1: 已连接 2: 错误
  int connectionStatus = 0;
  String connectionMsg = "";

  String getConnectionStatusMsg() {
    return connectionStatusMap[connectionStatus] ?? "";
  }

  AudioPlayerHandler() {
    init();
  }

  void init() {
    pubsubClient
        .connect(onMessage: onWebsocketData, onError: onWebsocketError)
        .then((result) {
      connectionStatus = 1;
      connectionMsg = "";
      initPlaybackState();
      initFuoCurrentPlayingInfo();
    });
  }

  void initPlaybackState() {
    playbackState.add(PlaybackState(
      controls: [
        MediaControl.play,
        MediaControl.skipToNext,
        MediaControl.skipToPrevious,
        MediaControl.stop
      ],
      systemActions: const {MediaAction.seek},
      androidCompactActionIndices: const [0, 1, 2],
      processingState: AudioProcessingState.idle,
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

  @override
  Future<void> playFromUri(Uri uri, [Map<String, dynamic>? extras]) {
    return client.jsonRpc('lambda: app.playlist.play_model(resolve("$uri"))');
  }

  @override
  Future<void> seek(Duration position) async {
    int mills = position.inSeconds;
    client.jsonRpc("lambda: setattr(app.player, 'position', $mills)");
  }

  @override
  Future<List<MediaItem>> search(String query,
      [Map<String, dynamic>? extras]) async {
    Object? data =
        await client.jsonRpc("lambda: list(app.library.search('$query'))");
    if (data == null) {
      return [];
    }
    List<MediaItem> songListMerged = [];
    List<dynamic> dataList = data as List<dynamic>;
    for (dynamic data in dataList) {
      Map<String, dynamic> dataMap = data as Map<String, dynamic>;
      if (dataMap['songs'] == null) {
        continue;
      }
      List<MediaItem> songList =
          mapSongToMediaItem(dataMap['songs'] as List<dynamic>);
      songListMerged.addAll(songList);
    }
    return songListMerged;
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
          List<dynamic> args = json.decode(data);
          int state = args[0];
          playerState.setPlayState(state);
          if (state == 1) {
            playbackState.add(playbackState.value.copyWith(playing: false));
          } else if (state == 2) {
            // currently there is no buffering state change event, so we assume media is ready when player state changed to playing.
            playbackState.add(playbackState.value.copyWith(
                playing: true, processingState: AudioProcessingState.ready));
          }
        } else if (topic == 'player.metadata_changed') {
          print('pubsub: player metadata changed');
          List<dynamic> args = json.decode(data);
          Map<String, dynamic> metadata = args[0];
          playerState.setMetadata(metadata);
          String artwork_ = metadata['artwork'];
          Map<String, String> artHeaders = {};
          if (metadata['source'] == 'netease') {
            artHeaders['user-agent'] =
                'Mozilla/5.0 (X11; Linux x86_64; rv:129.0) Gecko/20100101 Firefox/129.0';
          }
          print('artwork changed to: $artwork_');
          List<dynamic> artists = metadata['artists'];
          mediaItem.add(MediaItem(
            id: metadata['uri'],
            title: metadata['title'],
            artist: artists.join(","),
            album: metadata['album'],
            artUri: Uri.parse(artwork_),
            artHeaders: artHeaders,
          ));
          // currently there is no buffering state change event, so we assume media is ready when metadata is changed until player state changed to playing.
          playbackState.add(playbackState.value
              .copyWith(processingState: AudioProcessingState.ready));
        } else if (topic == 'player.duration_changed') {
          List<dynamic> args = json.decode(data);
          dynamic durationSeconds = args[0];
          mediaItem.add(mediaItem.value?.copyWith(
              duration:
                  Duration(milliseconds: (durationSeconds * 1000).round())));
        } else if (topic == 'player.seeked') {
          print("seeked ====== $data");
          List<dynamic> args = json.decode(data);
          int positionSeconds = args[0];
          playbackState.add(playbackState.value.copyWith(
              updatePosition:
                  Duration(milliseconds: (positionSeconds * 1000).round())));
        } else if (topic == 'live_lyric') {
          playerState.setCurrentLyricsLine(data);
        } else {
          print("Unhandled topic: $topic => $data");
        }
      } catch (e) {
        print('handle message error: $e');
      }
    }
  }

  /// 接收 WebSocket 消息
  Future<void> onWebsocketData(event) async {
    return await handleMessage(event);
  }

  onWebsocketError(Object o, StackTrace trace) {
    connectionStatus = 2;
    connectionMsg = trace.toString();
    print(trace);
  }

  void onWebsocketDone() {
    connectionStatus = 0;
    connectionMsg = "";
    print("Websocket closed.");
  }

  List<MediaItem> mapSongToMediaItem(List<dynamic> dataList) {
    List<MediaItem> items = [];
    for (dynamic value in dataList) {
      items.add(MediaItem(
          id: value['uri'] ?? '',
          title: value['title'] ?? '',
          artist: value['artists_name'] ?? '',
          extras: {
            'provider': value['provider'] ?? '',
            'uri': value['uri'] ?? ''
          }));
    }
    return items;
  }

  Future<void> initFuoCurrentPlayingInfo() async {
    Object? obj = await client.jsonRpc("lambda: app.playlist.current_song");
    if (obj != null) {
      playerState.metadata = obj as Map<String, dynamic>;
      print(playerState.metadata);
    } else {
      print("get current song failed");
    }
  }
}
