import 'dart:ffi';

import 'package:audio_service/audio_service.dart';
import 'package:feeluownx/player.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:web_socket_channel/web_socket_channel.dart';
import 'dart:convert';

late AudioHandler _audioHandler;

Future<void> main() async {
  runApp(const App());
}

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('FeelUOwn')),
        body: const Center(
          child: PlayerControlPanel(),
        ),
      ),
    );
  }
}

class Client {
  final String url = 'http://192.168.31.106:23332';
  int rpcRequestId = 0;

  Future<Map<String, dynamic>?> jsonRpc(String method,
      {List<dynamic>? args}) async {
    Map<String, dynamic> payload = {
      'jsonrpc': '2.0',
      'id': rpcRequestId,
      'method': method,
    };
    if (args != null && args.isNotEmpty) {
      payload['params'] = args;
    }
    String body = jsonEncode(payload);
    final response = await http.post(
      Uri.parse('$url/rpc/v1'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: body,
    );
    print('send rpc request: $body');
    if (response.statusCode == 200) {
      Map<String, dynamic> respBody = json.decode(response.body);
      return respBody['result'];
    } else {
      print('rpc failed, $response');
    }
    return null;
  }
}

class PubsubClient {
  final String url = 'ws://192.168.31.106:23332/signal/v1';
  WebSocketChannel? channel;

  void connect() {
    channel = WebSocketChannel.connect(Uri.parse(url));
  }

  void close() {
    channel?.sink.close();
  }

  Stream<dynamic>? get stream => channel?.stream;

  void send(String message) {
    channel?.sink.add(message);
  }
}

class PlayerControlPanel extends StatefulWidget {
  const PlayerControlPanel({super.key});

  @override
  State<PlayerControlPanel> createState() => _PlayerControlPanelState();
}

class _PlayerControlPanelState extends State<PlayerControlPanel> {
  int playerState = 1; // 2:playing, 1:paused
  String artwork = '';

  final Client client = Client();
  final PubsubClient pubsubClient = PubsubClient();
  late AudioPlayerHandler _handler;

  @override
  void initState() {
    super.initState();
    pubsubClient.connect();
    pubsubClient.stream?.listen(
      (message) {
        _handler.handleMessage(message);
        // print('recv pubsub msg: $message');
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
              setState(() {
                playerState = state;
              });
            } else if (topic == 'player.metadata_changed') {
              print('pubsub: player metadata changed');
              List<dynamic> args = json.decode(data);
              Map<String, dynamic> metadata = args[0];
              String artwork_ = metadata['artwork'];
              if (metadata['source'] == 'netease') {
                artwork_ = artwork_.replaceFirst('https', 'http');
              }
              print('artwork changed to: $artwork_');
              setState(() {
                artwork = artwork_;
              });
            }
          } catch (e) {
            print('handle message error: $e');
          }
        }
      },
      onDone: () {
        print('Websocket closed.');
      },
      onError: (error) {
        print('Websocket error: $error');
      },
    );
    initAudioHandler();
  }

  Future<void> initAudioHandler() async {
    _handler = AudioPlayerHandler(client);
    _audioHandler = await AudioService.init(
      builder: () => _handler,
      config: const AudioServiceConfig(
        androidNotificationChannelId: 'io.github.feeluown',
        androidNotificationChannelName: 'FeelUOwn',
        androidNotificationOngoing: true,
      ),
    );
  }

  @override
  void dispose() {
    pubsubClient.close();
    super.dispose();
  }

  bool _isPlaying() {
    return playerState == 2;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        artwork.isNotEmpty
            ? Image.network(artwork,
                errorBuilder: (context, exception, stackTrack) =>
                    Text("fetch artwork failed"))
            : Text('No artwork'),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.max,
          children: [
            IconButton(
              icon: const Icon(Icons.skip_previous_rounded),
              onPressed: () {
                client.jsonRpc('app.playlist.previous');
              },
            ),
            IconButton(
                icon: Icon(_isPlaying()
                    ? Icons.pause_rounded
                    : Icons.play_arrow_rounded),
                tooltip: 'Toggle',
                onPressed: () {
                  client.jsonRpc('app.player.toggle');
                }),
            IconButton(
              icon: const Icon(Icons.skip_next_rounded),
              onPressed: () {
                client.jsonRpc('app.playlist.next');
              },
            ),
          ],
        )
      ],
    );
  }
}
