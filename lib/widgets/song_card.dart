import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../global.dart';
import '../player.dart';

class SongCard extends StatelessWidget {
  final MediaItem mediaItem;
  final bool isPlaying;
  final bool showIndex;
  final int? index;

  SongCard({
    super.key,
    required this.mediaItem,
    this.isPlaying = false,
    this.showIndex = false,
    this.index,
  });

  final AudioPlayerHandler handler = Global.getIt<AudioPlayerHandler>();

  String _formatDuration(Duration? duration) {
    if (duration == null) return '';
    final minutes = duration.inMinutes;
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: SizedBox(
        width: 32,
        child: showIndex
            ? Text(
                '${index != null ? index + 1 : ''}',
                style: Theme.of(context).textTheme.bodyLarge,
                textAlign: TextAlign.center,
              )
            : (isPlaying
                ? const Icon(Icons.play_arrow, color: Colors.blue)
                : const Icon(Icons.music_note)),
      ),
      title: Text(
        mediaItem.title,
        style: TextStyle(
          color: isPlaying ? Colors.blue : null,
          fontWeight: isPlaying ? FontWeight.bold : null,
        ),
      ),
      subtitle: Text(mediaItem.artist ?? 'Unknown Artist'),
      trailing: Text(_formatDuration(mediaItem.duration)),
      onTap: () {
        final uri = mediaItem.extras?['uri'] ?? '';
        handler.playFromUri(Uri.parse(uri));
      },
      onLongPress: () async {
        await showModalBottomSheet(
          context: context,
          builder: (context) {
            return SizedBox(
              height: 200,
              child: ListView(
                children: [
                  const SizedBox(height: 10),
                  ListTile(
                    title: Text(AppLocalizations.of(context)!.copyUri),
                    leading: const Icon(Icons.copy),
                    onTap: () async {
                      await Clipboard.setData(
                        ClipboardData(text: mediaItem.extras?['uri'] ?? ''),
                      );
                      if (context.mounted) Navigator.of(context).pop();
                    },
                  ),
                  ListTile(
                    title: Text(AppLocalizations.of(context)!.copyTitleArtist),
                    leading: const Icon(Icons.copy),
                    onTap: () async {
                      await Clipboard.setData(
                        ClipboardData(
                          text: "${mediaItem.title} - ${mediaItem.artist ?? ''}",
                        ),
                      );
                      if (context.mounted) Navigator.of(context).pop();
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
