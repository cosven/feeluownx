import 'package:audio_service/audio_service.dart';
import 'package:feeluownx/player.dart';
import 'package:feeluownx/widgets/song_card.dart';
import 'package:flutter/material.dart';

import 'client.dart';
import 'global.dart';

class SongSearchDelegate extends SearchDelegate<String> {
  final Client client = Global.getIt<Client>();
  final AudioPlayerHandler handler = Global.getIt<AudioPlayerHandler>();

  String searchType = "song";

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      DropdownMenu(
          dropdownMenuEntries: const [
            DropdownMenuEntry(value: "song", label: "Song", leadingIcon: Icon(Icons.music_note)),
            DropdownMenuEntry(value: "playlist", label: "Playlist", leadingIcon: Icon(Icons.playlist_play_sharp)),
          ],
          initialSelection: searchType,
          enableSearch: false,
          enableFilter: false,
          requestFocusOnTap: false,
          leadingIcon: const Icon(Icons.filter_alt),
          label: const Text('Type'),
          inputDecorationTheme: const InputDecorationTheme(
            filled: true,
            contentPadding: EdgeInsets.symmetric(vertical: 5.0),
          ),
          onSelected: (value) {
            searchType = value ?? "song";
          }),
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
          if (snapshot.data == null) {
            return ListView();
          }
          List<MediaItem> songList = snapshot.data!;
          return ListView.builder(
              itemCount: songList.length,
              itemBuilder: (context, index) {
                return SongCard(mediaItem: songList[index]);
              });
        });
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return ListView();
  }
}
