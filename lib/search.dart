import 'package:audio_service/audio_service.dart';
import 'package:feeluownx/player.dart';
import 'package:flutter/material.dart';

import 'client.dart';
import 'global.dart';

class SongSearchDelegate extends SearchDelegate<String> {
  final Client client = Global.getIt<Client>();
  final AudioPlayerHandler handler = Global.getIt<AudioPlayerHandler>();

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          query = '';
          // When pressed here the query will be cleared from the search bar.
        },
      ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () => Navigator.of(context).pop(),
      // Exit from the search screen.
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return FutureBuilder(
        future: handler.search(query),
        builder: (context, snapshot) {
          print(snapshot.data);
          if (snapshot.data == null) {
            return ListView();
          }
          List<MediaItem> songList = snapshot.data!;
          return ListView.builder(
              itemCount: songList.length,
              itemBuilder: (context, index) {
                return Card(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  child: InkWell(
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(songList[index].title,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600, fontSize: 16)),
                          Text(songList[index].artist ?? '',
                              style: const TextStyle(fontSize: 14)),
                          Text(songList[index].extras?['provider'] ?? '',
                              style: const TextStyle(
                                  fontSize: 10, color: Colors.grey)),
                        ],
                      ),
                    ),
                    onTap: () {
                      String uri = songList[index].extras?['uri'] ?? '';
                      // Run the following command before using this feature.
                      //   fuo exec "from feeluown.library import resolve"
                      // TODO: implement deserialization in the feeluown daemon.
                      handler.playFromUri(Uri.parse(uri));
                    },
                  ),
                );
              });
        });
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return ListView();
  }
}
