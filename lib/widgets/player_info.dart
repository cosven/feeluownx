import 'package:feeluownx/bean/player_state.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:share_plus/share_plus.dart';

import '../client.dart';
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

  final Client client = Global.getIt<Client>();

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

  Future<Object?> getCurrentSongLrc() async {
    String identify = handler.playerState.metadata?['uri'] ?? '';
    if (identify.isEmpty) {
      return null;
    }
    String uri = handler.playerState.metadata?['uri'] ?? '';
    Map<String, dynamic> params = {};
    params['__type__'] = 'feeluown.library.BriefSongModel';
    params['source'] = handler.playerState.metadata?['source'] ?? '';
    params['identifier'] = uri.split('/').last ?? '';
    Object? result =
        await client.jsonRpc("app.library.song_get_lyric", args: [params]);
    return result;
  }

  Future<Object?> getCurrentSongWebLink() async {
    String identify = handler.playerState.metadata?['uri'] ?? '';
    if (identify.isEmpty) {
      return null;
    }
    String uri = handler.playerState.metadata?['uri'] ?? '';
    Map<String, dynamic> params = {};
    params['__type__'] = 'feeluown.library.BriefSongModel';
    params['source'] = handler.playerState.metadata?['source'] ?? '';
    params['identifier'] = uri.split('/').last ?? '';
    Object? result =
        await client.jsonRpc("app.library.song_get_web_url", args: [params]);
    return result;
  }

  @override
  Widget build(BuildContext context) {
    TextStyle style =
        const TextStyle(color: Colors.white70, fontSize: 22, height: 1.2);

    String artwork = "";
    if (widget.playerState.metadata != null) {
      artwork = widget.playerState.metadata?['artwork'] ?? '';
    }

    if (isPlaying()) {
      controller.forward();
    } else {
      controller.reverse();
    }

    return Expanded(
        child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
          const SizedBox(height: 120),
          Hero(
              tag: "artworkImg",
              child: artwork.isNotEmpty
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
                      height: 200)),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              widget.playerState.metadata?['title'] ?? '',
              style: style,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 5),
          Text(widget.playerState.getArtistsName(),
              style: style.apply(fontSizeFactor: .8)),
          const SizedBox(height: 30),
          FutureBuilder(
              future: getCurrentSongLrc(),
              builder: (_, snapshot) {
                Map<String, dynamic>? data =
                    snapshot.data as Map<String, dynamic>?;
                return Expanded(
                    child: SingleChildScrollView(
                  scrollDirection: Axis.vertical,
                  reverse: false,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 60.0, vertical: 4.0),
                  physics: const BouncingScrollPhysics(),
                  child: Text(data?['content'] ?? '',
                      style:
                          style.apply(fontSizeFactor: .7, heightFactor: 1.6)),
                ));
              }),
          const SizedBox(height: 40),
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
          Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                IconButton(
                    tooltip: "Share URL",
                    onPressed: () async {
                      String uri = widget.playerState.metadata?['uri'] ?? '';
                      String title =
                          widget.playerState.metadata?['title'] ?? '';
                      if (uri != '') {
                        ShareResult result =
                            await Share.share(uri, subject: title);
                        if (ShareResultStatus.success == result.status) {
                          print("Share success");
                        }
                      }
                    },
                    icon: const Icon(Icons.share,
                        size: 30, color: Colors.white70)),
                IconButton(
                    tooltip: "Share Web URL",
                    onPressed: () async {
                      String title =
                          widget.playerState.metadata?['title'] ?? '';
                      Object? data = await getCurrentSongWebLink();
                      print(data);
                      if (data != null && data != '') {
                        ShareResult result =
                            await Share.share(data as String, subject: title);
                        if (ShareResultStatus.success == result.status) {
                          print("Share success");
                        }
                      }
                    },
                    icon: const Icon(Icons.link,
                        size: 30, color: Colors.white70)),
              ]),
          const SizedBox(height: 30),
        ]));
  }
}
