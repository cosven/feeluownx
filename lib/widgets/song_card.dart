import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../global.dart';
import '../player.dart';
import '../models.dart';

class SongCard extends StatelessWidget {
  final BriefSongModel song;
  final bool showIndex;
  final int? index;
  final AudioPlayerHandler handler = Global.getIt<AudioPlayerHandler>();
  final bool isPlaying;
  
  SongCard({
    super.key,
    required this.song,
    this.showIndex = false,
    this.index,
  }) : isPlaying = handler.playerState.sameAsCurrentSong(song);

  String _formatDuration(String durationStr) {
    // If already in mm:ss format, return as is
    if (durationStr.contains(':')) return durationStr;
    // Otherwise try to convert from milliseconds
    try {
      final duration = Duration(milliseconds: int.parse(durationStr));
      final minutes = duration.inMinutes;
      final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
      return '$minutes:$seconds';
    } catch (e) {
      return durationStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: SizedBox(
        width: 32,
        child: showIndex
            ? Text(
                '${index != null ? index! + 1 : ''}',
                style: Theme.of(context).textTheme.bodyLarge,
                textAlign: TextAlign.center,
              )
            : (isPlaying
                ? const Icon(Icons.play_arrow, color: Colors.blue)
                : const Icon(Icons.music_note)),
      ),
      title: Text(
        song['title'] ?? 'Unknown Title',
        style: TextStyle(
          color: isPlaying ? Colors.blue : null,
          fontWeight: isPlaying ? FontWeight.bold : null,
        ),
      ),
      subtitle: Text(song['artists_name'] ?? 'Unknown Artist'),
      trailing: Text(_formatDuration(song['duration_ms']?.toString() ?? '0')),
      onTap: () {
        final uri = song['uri']?.toString() ?? '';
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
                        ClipboardData(text: song['uri']?.toString() ?? ''),
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
                          text: "${song['title']} - ${song['artists_name'] ?? ''}",
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
