import 'package:flutter/material.dart';
import 'package:feeluownx/global.dart';
import 'package:feeluownx/client.dart';

class PlaylistView extends StatefulWidget {
  const PlaylistView({super.key});

  @override
  State<StatefulWidget> createState() => _PlaylistState();
}

class _PlaylistState extends State<PlaylistView> {
  List<Map<String, dynamic>> songs = [];
  final Client client = Global.getIt<Client>();

  @override
  void initState() {
    super.initState();
    _fetchPlaylist();
  }

  Future<void> _fetchPlaylist() async {
    List<dynamic>? songs1 =
    (await client.jsonRpc('app.playlist.list')) as List<dynamic>?;
    if (songs1 == null) {
      return;
    }
    List<Map<String, dynamic>> songs2 = songs1.map((item) {
      return item as Map<String, dynamic>;
    }).toList();
    setState(() {
      songs = songs2;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
        itemCount: songs.length,
        itemBuilder: (BuildContext context, int index) {
          return InkWell(
              onTap: () {
                String uri = songs[index]['uri'] as String;
                // Run the following command before using this feature.
                //   fuo exec "from feeluown.library import resolve"
                // TODO: implement deserialization in the feeluown daemon.
                client.jsonRpc(
                    'lambda: app.playlist.play_model(resolve("$uri"))');
              },
              child: Card(
                margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Text('${songs[index]['title']}'),
                ),
              ));
        });
  }
}
