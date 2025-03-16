import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:feeluownx/client.dart';
import 'package:feeluownx/global.dart';

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
                padding: const EdgeInsets.all(16.0),
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: collections.length,
                itemBuilder: (context, index) {
                  final collection = collections[index];
                  return ListTile(
                    leading: const Icon(Icons.folder),
                    title: Text(collection['name'] ?? 'Unknown Collection'),
                    subtitle: Text('${collection['models_count']} items'),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}
