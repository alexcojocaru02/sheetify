import 'package:flutter/material.dart';
import '../models/library_store.dart';
import '../models/setlist_store.dart';
import 'setlist_detail_screen.dart';

class SetlistsScreen extends StatelessWidget {
  const SetlistsScreen({
    super.key,
    required this.setlists,
    required this.library,
  });

  final SetlistStore setlists;
  final LibraryStore library;

  void _createSetlist(BuildContext context) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('New setlist'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Setlist name (e.g. Concert 2024)'),
          onSubmitted: (_) => _doCreate(ctx, ctrl.text),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => _doCreate(ctx, ctrl.text),
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _doCreate(BuildContext context, String name) {
    if (name.trim().isNotEmpty) setlists.create(name.trim());
    Navigator.pop(context);
  }

  void _showOptions(BuildContext context, dynamic setlist) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36, height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey[400],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.red),
              title: const Text('Delete setlist', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                setlists.delete(setlist.id);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: AppBar(
        backgroundColor: scheme.surface,
        scrolledUnderElevation: 1,
        title: Row(
          children: [
            Icon(Icons.queue_music, color: scheme.primary, size: 28),
            const SizedBox(width: 10),
            Text('Setlists',
                style: TextStyle(
                    fontWeight: FontWeight.bold, color: scheme.primary)),
          ],
        ),
      ),
      body: ListenableBuilder(
        listenable: setlists,
        builder: (context, _) {
          final list = setlists.setlists;

          if (list.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.queue_music_outlined,
                      size: 100, color: scheme.outlineVariant),
                  const SizedBox(height: 24),
                  Text('No setlists yet',
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(color: scheme.onSurfaceVariant)),
                  const SizedBox(height: 8),
                  Text('Create a setlist to organise your concert programme',
                      textAlign: TextAlign.center,
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(color: scheme.onSurfaceVariant)),
                  const SizedBox(height: 32),
                  FilledButton.icon(
                    onPressed: () => _createSetlist(context),
                    icon: const Icon(Icons.add),
                    label: const Text('New setlist'),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
            itemCount: list.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, i) {
              final s = list[i];
              return Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: BorderSide(color: scheme.outlineVariant, width: 0.8),
                ),
                child: ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  leading: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: scheme.primaryContainer,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.queue_music,
                        color: scheme.onPrimaryContainer, size: 24),
                  ),
                  title: Text(s.name,
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text('${s.count} ${s.count == 1 ? 'score' : 'scores'}',
                      style: TextStyle(color: scheme.onSurfaceVariant)),
                  trailing: IconButton(
                    icon: const Icon(Icons.more_vert),
                    onPressed: () => _showOptions(context, s),
                  ),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => SetlistDetailScreen(
                        setlist: s,
                        setlists: setlists,
                        library: library,
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _createSetlist(context),
        icon: const Icon(Icons.add),
        label: const Text('New setlist'),
      ),
    );
  }
}
