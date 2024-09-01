import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

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
        onLongPress: () async {
          await showModalBottomSheet(
              isScrollControlled: false,
              context: context,
              builder: (context) {
                return SizedBox(height: 200, child: ListView(children: [
                  const SizedBox(height: 10),
                  ListTile(
                      title: Text(AppLocalizations.of(context)!.copyUri),
                      leading: const Icon(Icons.copy),
                      onTap: () async {
                        await Clipboard.setData(ClipboardData(
                            text: mediaItem.extras?['uri'] ?? ''));
                        if (context.mounted) {
                          Navigator.of(context).pop();
                        }
                      }),
                  ListTile(
                      title: Text(AppLocalizations.of(context)!.copyTitleArtist),
                      leading: const Icon(Icons.copy),
                      onTap: () async {
                        await Clipboard.setData(ClipboardData(
                            text: "${mediaItem.title} - ${mediaItem.artist ?? ''}"));
                        if (context.mounted) {
                          Navigator.of(context).pop();
                        }
                      }),
                ]));
              });
        },
      ),
    );
  }
}
