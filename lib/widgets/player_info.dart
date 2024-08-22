import 'package:feeluownx/bean/player_state.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

import '../global.dart';
import '../player.dart';

class PlayerInfo extends StatefulWidget {
  final PlayerState playerState;

  const PlayerInfo({super.key, required this.playerState});

  @override
  State<StatefulWidget> createState() => PlayerInfoState();
}

class PlayerInfoState extends State<PlayerInfo>
    with SingleTickerProviderStateMixin {
  final AudioPlayerHandler handler = Global.getIt<AudioPlayerHandler>();

  late AnimationController controller;

  @override
  void initState() {
    super.initState();
    controller = AnimationController(vsync: this)
      ..drive(Tween(begin: 0, end: 1))
      ..duration = const Duration(milliseconds: 500);
  }

  bool isPlaying() {
    return handler.playerState.playState == 2;
  }

  @override
  Widget build(BuildContext context) {
    TextStyle style = const TextStyle(color: Colors.white70, fontSize: 22);

    String artwork = "";
    if (widget.playerState.metadata != null) {
      artwork = widget.playerState.metadata?['artwork'] ?? '';
    }

    if (isPlaying()) {
      controller.forward();
    } else {
      controller.reverse();
    }

    return Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 120),
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
          const SizedBox(height: 20),
          Text(widget.playerState.metadata?['title'] ?? '', style: style),
          Text(widget.playerState.metadata?['artists_name'] ?? '',
              style: style.apply(fontSizeFactor: .8)),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              IconButton(
                iconSize: 40,
                color: Colors.white60,
                icon: const Icon(Icons.skip_previous_rounded),
                onPressed: () async {
                  await handler.skipToPrevious();
                },
              ),
              IconButton(
                iconSize: 60,
                color: Colors.white60,
                icon: AnimatedIcon(
                    icon: AnimatedIcons.play_pause, progress: controller),
                onPressed: () async {
                  await handler.play();
                },
              ),
              IconButton(
                iconSize: 40,
                color: Colors.white60,
                icon: const Icon(Icons.skip_next_rounded),
                onPressed: () async {
                  await handler.skipToNext();
                },
              ),
            ],
          ),
        ]);
  }
}
