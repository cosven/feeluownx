import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';

import '../bean/player_state.dart';
import '../client.dart';
import '../global.dart';
import '../player.dart';
import 'fullscreen_player.dart';

class PlayerControlPage extends StatefulWidget {
  const PlayerControlPage({super.key});

  @override
  State<PlayerControlPage> createState() => _PlayerControlPageState();
}

class _PlayerControlPageState extends State<PlayerControlPage>
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
            artwork = playerState.metadata?['artwork'] ?? '';
          }
          if (_isPlaying()) {
            controller.forward();
          } else {
            controller.reverse();
          }
          return ConstrainedBox(
              constraints: const BoxConstraints.expand(),
              child: Stack(alignment: Alignment.topCenter, children: [
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    artwork.isNotEmpty
                        ? Image.network(
                            width: 200,
                            height: 200,
                            artwork,
                            errorBuilder: (context, exception, stackTrack) =>
                                SvgPicture.asset('assets/music-square.svg',
                                    semanticsLabel: 'Fetch artwork error',
                                    alignment: Alignment.topCenter,
                                    width: 200,
                                    height: 200))
                        : SvgPicture.asset('assets/music-square.svg',
                            semanticsLabel: 'No artwork',
                            alignment: Alignment.topCenter,
                            width: 200,
                            height: 200),
                    Text(playerState.metadata?['title'] ?? ''),
                    Text(playerState.metadata?['artists_name'] ?? ''),
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
                                icon: AnimatedIcons.play_pause,
                                progress: controller),
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
                    ),
                    MaterialButton(
                        onPressed: () {
                          showModalBottomSheet(
                              isScrollControlled: false,
                              isDismissible: false,
                              enableDrag: false,
                              showDragHandle: false,
                              context: context,
                              constraints: const BoxConstraints.expand(),
                              builder: (context) {
                                return const FullscreenPlayerPage();
                              });
                        },
                        child: const Text("Test 全屏播放器"))
                  ],
                ),
                Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: Container(
                        height: 38,
                        alignment: Alignment.bottomCenter,
                        padding: const EdgeInsets.symmetric(
                            vertical: 10, horizontal: 15),
                        decoration: const BoxDecoration(boxShadow: [
                          BoxShadow(
                              blurStyle: BlurStyle.outer,
                              blurRadius: 4.0,
                              offset: Offset(0, 4),
                              color: Colors.black38)
                        ]),
                        child: Text(playerState.currentLyricsLine)))
              ]));
        }));
  }
}
