import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

import '../global.dart';
import '../player.dart';

class PlaylistCard extends StatelessWidget {
  final Map<String, dynamic> model;

  PlaylistCard({super.key, required this.model});

  final AudioPlayerHandler handler = Global.getIt<AudioPlayerHandler>();

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      child: InkWell(
        child: Padding(
            padding: const EdgeInsets.all(10),
            child: Row(children: [
              ((model['cover'] ?? '') as String != '')
                  ? Image.network(model['cover'] as String,
                      width: 70,
                      height: 70,
                      errorBuilder: (context, exception, stackTrack) =>
                          SvgPicture.asset('assets/music-square.svg',
                              semanticsLabel: 'Fetch artwork error',
                              alignment: Alignment.topCenter,
                              width: 70,
                              height: 70))
                  : SvgPicture.asset('assets/music-square.svg',
                      semanticsLabel: 'Fetch artwork error',
                      alignment: Alignment.topCenter,
                      width: 70,
                      height: 70),
              const SizedBox(width: 10),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      model['name'],
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 16),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(model['creator_name'],
                        style: const TextStyle(fontSize: 14)),
                    const SizedBox(height: 10),
                    Text(model['provider'],
                        style:
                            const TextStyle(fontSize: 10, color: Colors.grey)),
                  ],
                ),
              ),
            ])),
      ),
    );
  }
}
