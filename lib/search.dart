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
        future: client.jsonRpc("lambda: list(app.library.search('$query'))"),
        builder: (context, snapshot) {
          print(snapshot.data);
          if (snapshot.data == null) {
            return ListView();
          }
          List<dynamic> songListMerged = [];
          List<dynamic> dataList = snapshot.data! as List<dynamic>;
          for (dynamic data in dataList) {
            Map<String, dynamic> dataMap = data as Map<String, dynamic>;
            if (dataMap['songs'] == null) {
              continue;
            }
            List<dynamic> songList = dataMap['songs'] as List<dynamic>;
            songListMerged.addAll(songList);
          }
          print("======== $songListMerged");
          return ListView.builder(
              itemCount: songListMerged.length,
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
                          Text(songListMerged[index]['title'],
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600, fontSize: 16)),
                          Text(songListMerged[index]['artists_name'],
                              style: const TextStyle(fontSize: 14)),
                          Text(songListMerged[index]['provider'],
                              style: const TextStyle(fontSize: 10, color: Colors.grey)),
                        ],
                      ),
                    ),
                    onTap: () {
                      String uri = songListMerged[index]['uri'] as String;
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
