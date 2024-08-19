import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';

import '../global.dart';
import '../player.dart';

class SongCard extends StatelessWidget {
  final MediaItem mediaItem;

  SongCard({super.key, required this.mediaItem});

  final AudioPlayerHandler handler = Global.getIt<AudioPlayerHandler>();

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      child: InkWell(
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(mediaItem.title,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 16)),
              Text(mediaItem.artist ?? '',
                  style: const TextStyle(fontSize: 14)),
              const SizedBox(height: 10),
              Text(mediaItem.extras?['provider'] ?? '',
                  style: const TextStyle(fontSize: 10, color: Colors.grey)),
            ],
          ),
        ),
        onTap: () {
          String uri = mediaItem.extras?['uri'] ?? '';
          // Run the following command before using this feature.
          //   fuo exec "from feeluown.library import resolve"
          // TODO: implement deserialization in the feeluown daemon.
          handler.playFromUri(Uri.parse(uri));
        },
      ),
    );
  }
}
