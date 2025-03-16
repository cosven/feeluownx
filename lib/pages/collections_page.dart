import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:feeluownx/client.dart';
import 'package:feeluownx/global.dart';
import 'package:feeluownx/pages/song_list_page.dart';

class CollectionsPage extends StatefulWidget {
  const CollectionsPage({super.key});

  @override
  State<CollectionsPage> createState() => _CollectionsPageState();
}

class _CollectionsPageState extends State<CollectionsPage> {
  final Client client = Global.getIt<Client>();
  List<Map<String, dynamic>> collections = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCollections();
  }

  Future<void> _loadCollections() async {
    try {
      final loadedCollections = await client.listCollections();
      setState(() {
        collections = loadedCollections;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load collections: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('收藏'),
      ),
      body: RefreshIndicator(
        onRefresh: _loadCollections,
        child: ListView(
          children: [
            if (isLoading)
              const Center(child: CircularProgressIndicator())
            else if (collections.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    '无本地收藏集',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: collections.length,
                itemBuilder: (context, index) {
                  final collection = collections[index];
                  return ListTile(
                    leading: const Icon(Icons.folder),
                    title: Text(collection['name'] ?? 'Unknown Collection'),
                    subtitle: Text('${collection['models_count']} items'),
                    trailing: client.host != '127.0.0.1' ? StatefulBuilder(
                      builder: (context, setState) {
                        bool isSyncing = false;
                        return FilledButton.tonalIcon(
                          icon: isSyncing 
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.sync),
                          label: isSyncing ? const Text('同步中...') : const Text('同步'),
                          onPressed: () async {
                            if (isSyncing) return;
                            
                            setState(() => isSyncing = true);
                            try {
                              final statusCode = await client.collectionSyncToLocal(collection);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    statusCode == 201 
                                      ? '成功创建并同步收藏集'
                                      : '成功同步收藏集'
                                  ),
                                ),
                              );
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('同步失败: $e')),
                              );
                              rethrow;
                            } finally {
                              setState(() => isSyncing = false);
                            }
                          },
                        );
                      },
                    ) : null,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => SongListPage(
                            collectionIdentifier: collection['identifier'].toString(),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}
