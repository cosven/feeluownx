import 'package:audio_service/audio_service.dart';
import 'package:feeluownx/widgets/song_card.dart';
import 'package:flutter/material.dart';
import 'package:feeluownx/global.dart';
import 'package:feeluownx/client.dart';

class PlaylistView extends StatefulWidget {
  const PlaylistView({super.key});

  @override
  State<StatefulWidget> createState() => _PlaylistState();
}

class _PlaylistState extends State<PlaylistView> {
  final Client client = Global.getIt<Client>();

  @override
  void initState() {
    super.initState();
  }

  List<MediaItem> mapSongToMediaItem(List<dynamic> dataList) {
    List<MediaItem> items = [];
    for (dynamic value in dataList) {
      items.add(MediaItem(
          id: value['uri'] ?? '',
          title: value['title'] ?? '',
          artist: value['artists_name'] ?? '',
          extras: {
            'provider': value['provider'] ?? '',
            'uri': value['uri'] ?? ''
          }));
    }
    return items;
  }

  Future<List<MediaItem>> _fetchPlaylist() async {
    List<dynamic>? songs1 =
        (await client.jsonRpc('app.playlist.list')) as List<dynamic>?;
    if (songs1 == null) {
      return [];
    }
    return mapSongToMediaItem(songs1);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
        future: _fetchPlaylist(),
        builder: (context, snapshot) {
          dynamic songs = snapshot.data;
          if (songs == null) {
            return ListView();
          }
          return ListView.builder(
              itemCount: songs.length,
              itemBuilder: (BuildContext context, int index) {
                return SongCard(mediaItem: songs[index]);
              });
        });
  }
}
