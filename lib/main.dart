import 'dart:ffi';

import 'package:animations/animations.dart';
import 'package:audio_service/audio_service.dart';
import 'package:feeluownx/player.dart';
import 'package:feeluownx/playlist_ui.dart';
import 'package:feeluownx/search.dart';
import 'package:feeluownx/settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'dart:convert';

import 'bean/player_state.dart';
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
        body: PageTransitionSwitcher(
            duration: const Duration(milliseconds: 500),
            transitionBuilder: (child, animation, secondaryAnimation) =>
                SharedAxisTransition(
                    animation: animation,
                    secondaryAnimation: secondaryAnimation,
                    transitionType: SharedAxisTransitionType.horizontal,
                    child: child),
            child: children[currentIndex]),
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

class _PlayerControlPanelState extends State<PlayerControlPanel>
    with SingleTickerProviderStateMixin {
  final Client client = Global.getIt<Client>();
  late final AudioPlayerHandler _handler = Global.getIt<AudioPlayerHandler>();

  late AnimationController controller;

  @override
  void initState() {
    super.initState();
    controller = AnimationController(vsync: this)
      ..drive(Tween(begin: 0, end: 1))
      ..duration = const Duration(milliseconds: 500);
  }

  @override
  void dispose() {
    super.dispose();
  }

  bool _isPlaying() {
    return _handler.playerState.playState == 2;
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
        value: _handler.playerState,
        child: Consumer<PlayerState>(builder: (_, playerState, __) {
          String artwork = "";
          if (playerState.metadata != null) {
            artwork = playerState.metadata?['artwork'];
          }
          if (_isPlaying()) {
            controller.forward();
          } else {
            controller.reverse();
          }
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              artwork.isNotEmpty
                  ? Image.network(artwork,
                      errorBuilder: (context, exception, stackTrack) =>
                          const Text("fetch artwork failed"))
                  : const Text('No artwork'),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.max,
                children: [
                  IconButton(
                    icon: const Icon(Icons.skip_previous_rounded),
                    onPressed: () async {
                      await _handler.skipToPrevious();
                    },
                  ),
                  IconButton(
                      icon: AnimatedIcon(
                          icon: AnimatedIcons.play_pause, progress: controller),
                      tooltip: 'Toggle',
                      onPressed: () async {
                        await _handler.play();
                      }),
                  IconButton(
                    icon: const Icon(Icons.skip_next_rounded),
                    onPressed: () async {
                      await _handler.skipToNext();
                    },
                  ),
                ],
              )
            ],
          );
        }));
  }
}
