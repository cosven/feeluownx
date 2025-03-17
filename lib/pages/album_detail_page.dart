import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:feeluownx/client.dart';
import 'package:feeluownx/global.dart';

class AlbumDetailPage extends StatefulWidget {
  final Map<String, dynamic> album;
  final String? coverUrl;

  const AlbumDetailPage({
    super.key,
    required this.album,
    this.coverUrl,
  });

  @override
  State<AlbumDetailPage> createState() => _AlbumDetailPageState();
}

class _AlbumDetailPageState extends State<AlbumDetailPage> {
  final Client client = Global.getIt<Client>();
  List<Map<String, dynamic>> songs = [];
  bool isLoading = true;
  int? playingIndex;

  @override
  void initState() {
    super.initState();
    _loadSongs();
  }

  Future<void> _loadSongs() async {
    try {
      final loadedSongs = await client.listAlbumSongs(widget.album);
      if (mounted) {
        setState(() {
          songs = loadedSongs;
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load songs: $e')),
        );
      }
    }
  }

  Future<void> _playAll() async {
    try {
      await client.playlistSetModels(songs);
      await client.playerResume();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('播放全部失败: $e')),
        );
      }
    }
  }

  Future<void> _playSong(int index) async {
    try {
      await client.playSong(songs[index]);
      setState(() {
        playingIndex = index;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to play song: $e')),
        );
      }
    }
  }

  String _formatDuration(String durationStr) {
    // 如果已经是 mm:ss 格式就直接返回
    if (durationStr.contains(':')) return durationStr;
    // 否则尝试将其转换为 mm:ss 格式
    try {
      final duration = Duration(milliseconds: int.parse(durationStr));
      final minutes = duration.inMinutes;
      final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
      return '$minutes:$seconds';
    } catch (e) {
      return durationStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.album['name'] ?? 'Unknown Album'),
        actions: [
          if (songs.isNotEmpty)
            TextButton.icon(
              icon: const Icon(Icons.play_arrow),
              label: const Text('播放全部'),
              onPressed: _playAll,
            ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Album cover and info section
          Container(
            color: Theme.of(context).colorScheme.surface,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Album cover
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: SizedBox(
                      width: 120,
                      height: 120,
                      child: widget.coverUrl != null
                          ? Image.network(
                              widget.coverUrl!,
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
                            )
                          : Container(
                              color: Colors.grey[300],
                              child: const Center(
                                child:
                                    Icon(Icons.album, size: 48, color: Colors.grey),
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Album info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.album['name'] ?? 'Unknown Album',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          widget.album['artists_name'] ?? 'Unknown Artist',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Source: ${widget.album['provider'] ?? 'Unknown'}',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Songs list
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : songs.isEmpty
                    ? const Center(child: Text('No songs found'))
                    : ListView.builder(
                        itemCount: songs.length,
                        itemBuilder: (context, index) {
                          final song = songs[index];
                          final isPlaying = index == playingIndex;

                          return ListTile(
                            leading: SizedBox(
                              width: 32,
                              child: isPlaying
                                  ? const Icon(Icons.play_arrow, color: Colors.blue)
                                  : Text(
                                      '${index + 1}',
                                      style: Theme.of(context).textTheme.bodyLarge,
                                      textAlign: TextAlign.center,
                                    ),
                            ),
                            title: Text(
                              song['title'] ?? 'Unknown Title',
                              style: TextStyle(
                                color: isPlaying ? Colors.blue : null,
                                fontWeight: isPlaying ? FontWeight.bold : null,
                              ),
                            ),
                            subtitle: Text(song['artists_name'] ?? 'Unknown Artist'),
                            trailing: Text(_formatDuration(
                                song['duration_ms']?.toString() ?? '')),
                            onTap: () => _playSong(index),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
