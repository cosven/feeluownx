import 'package:flutter/material.dart';

import 'client.dart';
import 'global.dart';

class SongSearchDelegate extends SearchDelegate<String> {
  final Client client = Global.getIt<Client>();

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
          if (snapshot.data == null) {
            return ListView();
          }
          dynamic data = (snapshot.data! as List<dynamic>)[0];
          Map<String, dynamic> dataMap = data as Map<String, dynamic>;
          List<dynamic> songList = dataMap['songs'] as List<dynamic>;
          print("======== $songList");
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
                          Text(songList[index]['title'], style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                          Text(songList[index]['artists_name'], style: const TextStyle(fontSize: 14)),
                        ],
                      ),
                    ),
                    onTap: () {
                      String uri = songList[index]['uri'] as String;
                      // Run the following command before using this feature.
                      //   fuo exec "from feeluown.library import resolve"
                      // TODO: implement deserialization in the feeluown daemon.
                      client.jsonRpc(
                          'lambda: app.playlist.play_model(resolve("$uri"))');
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
