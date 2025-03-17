import 'package:flutter/material.dart';
import 'package:feeluownx/client.dart';
import 'package:feeluownx/global.dart';
import 'package:logging/logging.dart';

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
  final Logger _logger = Logger('_SongListPageState');

  String? get collectionIdentifier => widget.collectionIdentifier;

  @override
  void initState() {
    super.initState();
    _loadSongs();
  }

  Future<void> _loadSongs() async {
    _logger.info("Loading songs for collection: $collectionIdentifier");
    try {
      final loadedSongs = collectionIdentifier != null
          ? await client.listCollectionSongs(collectionIdentifier!)
          : await client.listLibrarySongs();
      setState(() {
        songs = loadedSongs;
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
        title: const Text('歌曲列表'),
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
    );
  }
}
