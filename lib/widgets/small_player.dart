import 'dart:ui';

import 'package:feeluownx/bean/player_state.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';

import '../global.dart';
import '../pages/fullscreen_player.dart';
import '../player.dart';

class SmallPlayerWidget extends StatefulWidget {
  const SmallPlayerWidget({super.key});

  @override
  State<StatefulWidget> createState() => SmallPlayerState();
}

class SmallPlayerState extends State<StatefulWidget> {
  final AudioPlayerHandler handler = Global.getIt<AudioPlayerHandler>();

  Route slideFromBottom(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(0.0, 1.0);
        const end = Offset.zero;
        const curve = Curves.easeInOut;
        var tween =
            Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
        return SlideTransition(
          position: animation.drive(tween),
          child: child,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
        value: handler.playerState,
        child: Consumer<PlayerState>(builder: (_, playerState, __) {
          String artwork = "";
          if (playerState.metadata != null) {
            artwork = playerState.metadata?['artwork'] ?? '';
          }
          return InkWell(
              onTap: () {
                Navigator.of(context)
                    .push(slideFromBottom(const FullscreenPlayerPage()));
              },
              child: Container(
                  decoration:
                      BoxDecoration(color: Colors.black87.withOpacity(0)),
                  child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(width: 20),
                        Hero(
                            tag: "artworkImg",
                            child: artwork.isNotEmpty
                                ? Image.network(
                                    width: 60,
                                    height: 60,
                                    artwork,
                                    errorBuilder:
                                        (context, exception, stackTrack) =>
                                            SvgPicture.asset(
                                                'assets/music-square.svg',
                                                semanticsLabel:
                                                    'Fetch artwork error',
                                                alignment: Alignment.center,
                                                width: 60,
                                                height: 60))
                                : SvgPicture.asset('assets/music-square.svg',
                                    semanticsLabel: 'No artwork',
                                    alignment: Alignment.center,
                                    width: 60,
                                    height: 60)),
                        const SizedBox(width: 10),
                        Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                  handler.playerState.metadata?['title'] ?? ''),
                              Text(handler
                                      .playerState.metadata?['artists_name'] ??
                                  ''),
                            ])
                      ])));
        }));
  }
}
