import 'package:audio_service/audio_service.dart';
import 'package:feeluownx/player.dart';
import 'package:feeluownx/widgets/song_card.dart';
import 'package:feeluownx/widgets/playlist_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import 'client.dart';
import 'global.dart';

class SongSearchDelegate extends SearchDelegate<String> with TickerProviderStateMixin {
  final Client client = Global.getIt<Client>();
  final AudioPlayerHandler handler = Global.getIt<AudioPlayerHandler>();

  String searchType = "song";

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: Scaffold.of(context));
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        searchType = _tabController.index == 0 ? "song" : "playlist";
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      SizedBox(
        width: 200,
        child: TabBar(
          controller: _tabController,
          tabs: [
            Tab(
              icon: const Icon(Icons.music_note),
              text: AppLocalizations.of(context)!.song,
            ),
            Tab(
              icon: const Icon(Icons.playlist_play_sharp),
              text: AppLocalizations.of(context)!.playlist,
            ),
          ],
          isScrollable: true,
          labelColor: Theme.of(context).primaryColor,
          unselectedLabelColor: Colors.grey,
          indicatorSize: TabBarIndicatorSize.tab,
        ),
      ),
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      ),
    ];
  }

  Future<dynamic> search(String query, String searchType) {
    if (searchType == 'playlist') {
      return client.jsonRpc(
          "lambda: list(app.library.search('$query', type_in='$searchType'))");
    }
    return handler.search(query);
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
        future: search(query, searchType),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
                child: SizedBox(
                    width: 30, height: 30, child: CircularProgressIndicator()));
          }
          if (snapshot.data == null) {
            return ListView();
          }
          if (searchType == 'playlist') {
            // TODO: maybe we should define some Model (BriefPlaylistModel and PlaylistModel).
            List<Map<String, dynamic>> playlists = [];
            List<dynamic> dataList = snapshot.data!;
            for (dynamic data in dataList) {
              Map<String, dynamic> dataMap = data as Map<String, dynamic>;
              if (dataMap['playlists'] == null) {
                continue;
              }
              playlists.addAll((dataMap['playlists'] as List<dynamic>)
                  .cast<Map<String, dynamic>>());
            }
            return ListView.builder(
                itemCount: playlists.length,
                itemBuilder: (context, index) {
                  return PlaylistCard(model: playlists[index]);
                });
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
