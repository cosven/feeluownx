import 'package:flutter/material.dart';
import 'package:feeluownx/client.dart';
import 'package:feeluownx/global.dart';
import 'package:logging/logging.dart';
import '../widgets/small_player.dart';
import '../widgets/song_card.dart';
import '../bean/player_state.dart';

class SongListPage extends StatefulWidget {
  final String? collectionIdentifier;
  SongListPage({super.key, this.collectionIdentifier}) {
    _logger.info('Creating SongListPage for collection: $collectionIdentifier');
  }
  final Logger _logger = Logger('SongListPage');

  @override
  State<SongListPage> createState() => _SongListPageState();
}

class _SongListPageState extends State<SongListPage> {
  final Client client = Global.getIt<Client>();
  List<Map<String, dynamic>> songs = [];
  bool isLoading = true;
  String? collectionName;
  final Logger _logger = Logger('_SongListPageState');

  String? get collectionIdentifier => widget.collectionIdentifier;

  Future<void> _playAll() async {
    try {
      await client.playlistSetModels(songs);
      _logger.info('Played all ${songs.length} songs');
      await client.playerResume();
    } catch (e) {
      _logger.severe('Failed to play all songs', e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('播放全部失败: $e')),
        );
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _loadSongs();
  }

  Future<void> _loadSongs() async {
    _logger.info("Loading songs for collection: $collectionIdentifier");
    try {
      if (collectionIdentifier != null) {
        final collections = await client.listCollections();
        final collection = collections.firstWhere(
          (c) => c['identifier'].toString() == collectionIdentifier,
          orElse: () => {},
        );
        if (collection.isNotEmpty) {
          collectionName = collection['name'];
        }
        songs = await client.listCollectionSongs(collectionIdentifier!);
      } else {
        songs = await client.listLibrarySongs();
        collectionName = '我的音乐库';
      }
      setState(() {
        isLoading = false;
      });
      _logger.info('Loaded ${songs.length} songs');
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      if (mounted) {
        _logger.severe('Failed to load songs', e);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('加载歌曲失败: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(collectionName ?? '歌曲列表'),
        actions: [
          if (songs.isNotEmpty)
            TextButton.icon(
              icon: const Icon(Icons.play_arrow),
              label: const Text('播放全部'),
              onPressed: _playAll,
            ),
        ],
      ),
      body: Stack(
        children: [
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : songs.isEmpty
                  ? const Center(child: Text('没有找到歌曲'))
                  : RefreshIndicator(
                      onRefresh: _loadSongs,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: songs.length,
                        itemBuilder: (context, index) {
                          final song = songs[index];
                          return SongCard(
                            song: song,
                            showIndex: true,
                            index: index,
                          );
                        },
                      ),
                    ),
          const Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: SmallPlayerWidget(),
          ),
        ],
      ),
    );
  }
}
