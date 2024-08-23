import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';

import '../bean/player_state.dart';
import '../global.dart';
import '../player.dart';
import '../widgets/player_info.dart';

class FullscreenPlayerPage extends StatefulWidget {
  const FullscreenPlayerPage({super.key});

  @override
  State<StatefulWidget> createState() => FullscreenPlayerPageState();
}

class FullscreenPlayerPageState extends State<FullscreenPlayerPage> {
  AudioPlayerHandler handler = Global.getIt<AudioPlayerHandler>();

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
        value: handler.playerState,
        child: Consumer<PlayerState>(builder: (_, playerState, __) {
          String artwork = "";
          if (playerState.metadata != null) {
            artwork = playerState.metadata?['artwork'] ?? '';
          }
          Map<String, String> artHeaders = {};
          artHeaders['user-agent'] =
              'Mozilla/5.0 (X11; Linux x86_64; rv:129.0) Gecko/20100101 Firefox/129.0';
          ImageProvider image;
          if (artwork != '') {
            image = NetworkImage(artwork, headers: artHeaders);
          } else {
            image = const AssetImage('assets/music-square.png');
          }
          return Container(
              constraints: const BoxConstraints.expand(),
              decoration: BoxDecoration(
                  image: DecorationImage(
                      image: image,
                      fit: BoxFit.fitHeight,
                      alignment: Alignment.center)),
              child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 80.0, sigmaY: 80.0),
                  child: Container(
                      constraints: const BoxConstraints.expand(),
                      decoration:
                          BoxDecoration(color: Colors.black87.withOpacity(.4)),
                      child: Column(children: [
                        PlayerInfo(playerState: playerState),
                        MaterialButton(
                            child: const Text("Back", style: TextStyle(color: Colors.white70)),
                            onPressed: () {
                              Navigator.pop(context);
                            })
                      ]))));
        }));
  }
}
