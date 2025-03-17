import 'package:flutter/material.dart';
import '../client.dart';
import '../global.dart';

class PlaylistBottomSheet extends StatelessWidget {
  const PlaylistBottomSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final client = Global.getIt<Client>();
    
    return FutureBuilder(
      future: client.playlistList(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        
        if (snapshot.hasError) {
          return Center(child: Text('获取播放列表失败: ${snapshot.error}'));
        }
        
        final songs = snapshot.data ?? [];
        
        return SizedBox(
          height: MediaQuery.of(context).size.height * 0.75,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  '播放列表',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: songs.length,
                  itemBuilder: (context, index) {
                    final song = songs[index];
                    return ListTile(
                      leading: const Icon(Icons.music_note),
                      title: Text(
                        '${song['title'] ?? '未知歌曲'} • ${song['artists_name'] ?? '未知歌手'}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      onTap: () {
                        client.playSong(song);
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
