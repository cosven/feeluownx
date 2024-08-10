import 'dart:ffi';

import 'package:audio_service/audio_service.dart';
import 'package:feeluownx/player.dart';
import 'package:feeluownx/settings.dart';
import 'package:flutter/material.dart';
import 'dart:convert';

import 'client.dart';
import 'global.dart';

late AudioHandler _audioHandler;

Future<void> main() async {
  await Global.init();
  runApp(const App());
}

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: DefaultTabController(
          length: 2,
          child: Scaffold(
            appBar: AppBar(
              title: const Text('FeelUOwn'),
              bottom: const TabBar(tabs: [
                Tab(icon: Icon(Icons.home)),
                Tab(icon: Icon(Icons.settings)),
              ]),
              bottomOpacity: .8,
            ),
            body: const TabBarView(children: [
              Center(
                child: PlayerControlPanel(),
              ),
              SettingPanel(),
            ]),
          )),
      // auto dark mode follows system settings
      themeMode: ThemeMode.system,
      theme: ThemeData.light(useMaterial3: true),
      darkTheme: ThemeData.dark(useMaterial3: true),
    );
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

  final Client client = Global.getIt<Client>();
  final PubsubClient pubsubClient = Global.getIt<PubsubClient>();
  late AudioPlayerHandler _handler;

  @override
  void initState() {
    super.initState();
    pubsubClient.connect().then((result) {
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
    });
  }

  Future<void> initAudioHandler() async {
    _handler = Global.getIt<AudioPlayerHandler>();
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
