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
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceVariant,
                    boxShadow: [
                      BoxShadow(
                        color: Theme.of(context).colorScheme.shadow.withOpacity(0.1),
                        blurRadius: 4,
                        offset: const Offset(0, -1),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const SizedBox(width: 20),
                        Hero(
                            tag: "artworkImg",
                            child: artwork.isNotEmpty
                                ? Image.network(
                                    width: 48,
                                    height: 48,
                                    artwork,
                                    errorBuilder:
                                        (context, exception, stackTrack) =>
                                            SvgPicture.asset(
                                                'assets/music-square.svg',
                                                semanticsLabel:
                                                    'Fetch artwork error',
                                                alignment: Alignment.center,
                                                width: 48,
                                                height: 48))
                                : SvgPicture.asset('assets/music-square.svg',
                                    semanticsLabel: 'No artwork',
                                    alignment: Alignment.center,
                                    width: 48,
                                    height: 48)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Row(
                            children: [
                              Flexible(
                                child: Text(
                                  '${handler.playerState.metadata?['title'] ?? ''} • ${handler.playerState.getArtistsName()}',
                                  style: Theme.of(context).textTheme.titleSmall,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        IconButton(
                          icon: Icon(
                            playerState.isPlaying
                              ? Icons.pause
                              : Icons.play_arrow,
                          ),
                          onPressed: () {
                            if (playerState.isPlaying) {
                              handler.pause();
                            } else {
                              handler.play();
                            }
                          },
                        ),
                        const SizedBox(width: 4),
                        IconButton(
                          icon: const Icon(Icons.queue_music),
                          onPressed: () async {
                            final client = Global.getIt<Client>();
                            try {
                              final songs = await client.playlistList();
                              if (!mounted) return;
                              showModalBottomSheet(
                                context: context,
                                builder: (context) {
                                  return Column(
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.all(16.0),
                                        child: Text(
                                          '播放列表',
                                          style: Theme.of(context).textTheme.titleLarge,
                                        ),
                                      ),
                                      Expanded(
                                        child: ListView.builder(
                                          itemCount: songs.length,
                                          itemBuilder: (context, index) {
                                            final song = songs[index];
                                            return ListTile(
                                              leading: const Icon(Icons.music_note),
                                              title: Text(
                                                song['title'] ?? '未知歌曲',
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              subtitle: Text(
                                                '${song['artists_name'] ?? '未知歌手'} - ${song['album_name'] ?? '未知专辑'}',
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              onTap: () {
                                                client.playSong(song);
                                                Navigator.pop(context);
                                              },
                                            );
                                          },
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              );
                            } catch (e) {
                              if (!mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('获取播放列表失败: $e')),
                              );
                            }
                          },
                        ),
                        const SizedBox(width: 12),
                      ])));
        }));
  }
}
