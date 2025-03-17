import 'package:flutter/material.dart';
import 'package:feeluownx/client.dart';
import 'package:feeluownx/global.dart';
import 'package:logging/logging.dart';
import '../widgets/small_player.dart';

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
      body: Stack(
        children: [
          Scaffold(
            appBar: AppBar(
        title: Text(collectionName ?? '歌曲列表'),
        actions: [
          if (songs.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.play_arrow),
              tooltip: '播放全部',
              onPressed: _playAll,
            ),
        ],
      ),
            body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : songs.isEmpty
              ? const Center(child: Text('没有找到歌曲'))
              : RefreshIndicator(
                  onRefresh: _loadSongs,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: songs.length,
                    separatorBuilder: (context, index) => const Divider(height: 16),
                    itemBuilder: (context, index) {
                      final song = songs[index];
                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                        leading: const Icon(Icons.music_note),
                        title: Text(
                          song['title'] ?? '未知歌曲',
                          style: Theme.of(context).textTheme.titleMedium,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          '${song['artists_name'] ?? '未知歌手'} - ${song['album_name'] ?? '未知专辑'}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: Text(
                          song['duration_ms'] ?? '',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        onTap: () {
                          client.playSong(song);
                        },
                      );
                    },
                  ),
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
