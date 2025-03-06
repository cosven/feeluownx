import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:feeluownx/client.dart';
import 'package:feeluownx/global.dart';
import 'package:feeluownx/pages/album_detail_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final Client client = Global.getIt<Client>();
  List<Map<String, dynamic>> albums = [];
  bool isLoading = true;
  final Map<String, String?> albumCovers = {};  // 用于缓存专辑封面 URL

  @override
  void initState() {
    super.initState();
    _loadAlbums();
  }

  Future<void> _loadAlbums() async {
    try {
      final loadedAlbums = await client.listLibraryAlbums();
      setState(() {
        albums = loadedAlbums;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load albums: $e')),
        );
      }
    }
  }

  Future<void> _loadAlbumCover(Map<String, dynamic> album) async {
    if (albumCovers.containsKey(album['identifier'])) return;

    try {
      final coverUrl = await client.getAlbumCover(album);
      if (mounted) {
        setState(() {
          albumCovers[album['identifier']] = coverUrl;
        });
      }
    } catch (e) {
      debugPrint('Failed to load album cover: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (albums.isEmpty) {
      return const Center(child: Text('No albums found'));
    }

    return RefreshIndicator(
      onRefresh: _loadAlbums,
      child: ListView(
        children: [
          const SizedBox(height: 48),  // 添加顶部间距
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Albums',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ),
          SizedBox(
            height: 220,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: albums.length,
              itemBuilder: (context, index) {
                final album = albums[index];
                _loadAlbumCover(album);
                final coverUrl = albumCovers[album['identifier']];

                return Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: SizedBox(
                    width: 160, // 固定宽度
                    child: InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AlbumDetailPage(
                              album: album,
                              coverUrl: coverUrl,
                            ),
                          ),
                        );
                      },
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 专辑封面
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: AspectRatio(
                              aspectRatio: 1,
                              child: coverUrl != null
                                  ? Image.network(
                                      coverUrl,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) {
                                        return Container(
                                          color: Colors.grey[300],
                                          child: const Center(
                                            child: Icon(Icons.error_outline,
                                                size: 48, color: Colors.grey),
                                          ),
                                        );
                                      },
                                      loadingBuilder:
                                          (context, child, loadingProgress) {
                                        if (loadingProgress == null) return child;
                                        return Container(
                                          color: Colors.grey[300],
                                          child: const Center(
                                            child: CircularProgressIndicator(),
                                          ),
                                        );
                                      },
                                    )
                                  : Container(
                                      color: Colors.grey[300],
                                      child: const Center(
                                        child: Icon(Icons.album,
                                            size: 48, color: Colors.grey),
                                      ),
                                    ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          // 专辑名称
                          Text(
                            album['name'] ?? 'Unknown Album',
                            style: Theme.of(context).textTheme.titleMedium,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          // 艺术家名称
                          Text(
                            album['artists_name'] ?? 'Unknown Artist',
                            style: Theme.of(context).textTheme.bodySmall,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}
