import 'dart:ffi';

import 'package:audio_service/audio_service.dart';
import 'package:feeluownx/player.dart';
import 'package:feeluownx/playlist_ui.dart';
import 'package:feeluownx/search.dart';
import 'package:feeluownx/settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'dart:convert';

import 'client.dart';
import 'global.dart';

AudioHandler? _audioHandler;

Future<void> main() async {
  await Global.init();
  runApp(const App());
}

class App extends StatefulWidget {
  const App({super.key});

  @override
  State<StatefulWidget> createState() => AppState();
}

class AppState extends State<App> {
  int currentIndex = 0;
  final List<Widget> children = [
    const PlayerControlPanel(),
    const PlaylistView(),
    const SettingPanel(),
  ];

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        appBar: AppBar(
          title: const Text('FeelUOwn'),
        ),
        body: children[currentIndex],
        bottomNavigationBar: BottomNavigationBar(items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.list), label: "Playing"),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: "Settings")
        ], currentIndex: currentIndex, onTap: onTabChange),
        floatingActionButton: Builder(
            builder: (context) => FloatingActionButton(
                onPressed: () async {
                  await showSearch(
                      context: context,
                      delegate: Global.getIt<SongSearchDelegate>());
                },
                child: const Icon(Icons.search))),
      ),
      // auto dark mode follows system settings
      themeMode: ThemeMode.system,
      theme: ThemeData.light(useMaterial3: true),
      darkTheme: ThemeData.dark(useMaterial3: true),
    );
  }

  void onTabChange(int index) {
    setState(() {
      currentIndex = index;
    });
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
  late final AudioPlayerHandler _handler = Global.getIt<AudioPlayerHandler>();

  @override
  void initState() {
    super.initState();
    _handler.listen(handleWebsocketMsg);
  }

  void handleWebsocketMsg(dynamic message) {
    print("listen ===== $message");
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
  }

  @override
  void dispose() {
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
