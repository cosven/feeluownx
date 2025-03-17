import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:feeluownx/client.dart';
import 'package:feeluownx/global.dart';
import 'package:feeluownx/pages/album_detail_page.dart';
import 'package:feeluownx/pages/song_list_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final Client client = Global.getIt<Client>();
  List<Map<String, dynamic>> albums = [];
  List<Map<String, dynamic>> collections = [];
  bool isLoading = true;
  bool isLoadingCollections = true;
  final Map<String, String?> albumCovers = {};  // 用于缓存专辑封面 URL

  @override
  void initState() {
    super.initState();
    _loadAlbums();
    _loadCollections();
  }

  Future<void> _loadCollections() async {
    try {
      final loadedCollections = await client.listCollections();
      setState(() {
        collections = loadedCollections;
        isLoadingCollections = false;
      });
    } catch (e) {
      setState(() {
        isLoadingCollections = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load collections: $e')),
        );
      }
    }
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

    return RefreshIndicator(
      onRefresh: _loadAlbums,
      child: ListView(
        children: [
          // 用户信息区域
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Hi, 未登录',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Theme.of(context).colorScheme.primaryContainer,
                  ),
                  child: const Icon(Icons.person),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // 添加 Carousel 按钮
          SizedBox(
            height: 120,
            child: PageView.builder(
              itemCount: 3,
              controller: PageController(viewportFraction: 0.7),
              padEnds: false,
              itemBuilder: (context, index) {
                // 明确指定 Map 的类型
                final List<Map<String, dynamic>> cards = [
                  {
                    'subtitle': '根据最近播放',
                    'title': '为你推荐',
                    'icon': Icons.recommend,
                  },
                  {
                    'subtitle': '基于你的收藏',
                    'title': '猜你喜欢',
                    'icon': Icons.favorite,
                  },
                  {
                    'subtitle': '全新发现',
                    'title': '每日精选',
                    'icon': Icons.auto_awesome,
                  },
                ];

                final cardContent = cards[index];

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6.0),
                  child: InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => SongListPage()),
                      );
                    },
                    borderRadius: BorderRadius.circular(12.0),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(12.0),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 6,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    cardContent['subtitle'] as String,
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Theme.of(context).colorScheme.onPrimaryContainer.withOpacity(0.7),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    cardContent['title'] as String,
                                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          AspectRatio(
                            aspectRatio: 1,
                            child: Container(
                              margin: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.onPrimaryContainer.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                cardContent['icon'] as IconData,
                                size: 32,
                                color: Theme.of(context).colorScheme.onPrimaryContainer.withOpacity(0.7),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Pinned',
              style: Theme.of(context).textTheme.titleLarge,
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
                // _loadAlbumCover(album);
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
        ],
      ),
    );
  }
}
