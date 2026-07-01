import 'package:flutter/material.dart';
import '../models/library_store.dart';
import '../models/score.dart';
import '../models/setlist.dart';
import '../models/setlist_store.dart';
import 'viewer_screen.dart';

class SetlistDetailScreen extends StatelessWidget {
  const SetlistDetailScreen({
    super.key,
    required this.setlist,
    required this.setlists,
    required this.library,
  });

  final Setlist setlist;
  final SetlistStore setlists;
  final LibraryStore library;

  Score? _scoreFor(String path) {
    try {
      return library.scores.firstWhere((s) => s.path == path);
    } catch (_) {
      return null;
    }
  }

  void _openScore(BuildContext context, Score score) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ViewerScreen(score: score, library: library),
      ),
    );
  }

  void _showRename(BuildContext context) {
    final ctrl = TextEditingController(text: setlist.name);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rename setlist'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Setlist name'),
          onSubmitted: (_) => _doRename(ctx, ctrl.text),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => _doRename(ctx, ctrl.text),
            child: const Text('Rename'),
          ),
        ],
      ),
    );
  }

  void _doRename(BuildContext context, String name) {
    if (name.trim().isNotEmpty) setlists.rename(setlist.id, name.trim());
    Navigator.pop(context);
  }

  void _showAddScores(BuildContext context) {
    final allScores = library.scores;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.6,
          maxChildSize: 0.9,
          builder: (_, scrollCtrl) => Column(
            children: [
              Container(
                width: 36, height: 4,
                margin: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.grey[400],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: Row(
                  children: [
                    Text('Add to "${setlist.name}"',
                        style: Theme.of(context).textTheme.titleMedium),
                  ],
                ),
              ),
              Expanded(
                child: ListenableBuilder(
                  listenable: setlists,
                  builder: (context, _) => ListView.builder(
                    controller: scrollCtrl,
                    itemCount: allScores.length,
                    itemBuilder: (_, i) {
                      final score = allScores[i];
                      final inSetlist = setlist.scorePaths.contains(score.path);
                      return CheckboxListTile(
                        value: inSetlist,
                        onChanged: (_) => setlists.toggleScore(setlist.id, score.path),
                        title: Text(score.name, overflow: TextOverflow.ellipsis),
                        secondary: Icon(
                          score.isPdf ? Icons.picture_as_pdf_rounded : Icons.image_rounded,
                          color: score.isPdf ? const Color(0xFFE53935) : const Color(0xFF1E88E5),
                        ),
                        controlAffinity: ListTileControlAffinity.trailing,
                      );
                    },
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: FilledButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(44)),
                  child: const Text('Done'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return ListenableBuilder(
      listenable: setlists,
      builder: (context, _) {
        final paths = setlist.scorePaths;

        return Scaffold(
          appBar: AppBar(
            backgroundColor: scheme.surface,
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(setlist.name,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                Text('${paths.length} scores',
                    style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant)),
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit_outlined),
                onPressed: () => _showRename(context),
                tooltip: 'Rename',
              ),
              IconButton(
                icon: const Icon(Icons.add),
                onPressed: () => _showAddScores(context),
                tooltip: 'Add scores',
              ),
            ],
          ),
          body: paths.isEmpty
              ? _buildEmpty(context, scheme)
              : ReorderableListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: paths.length,
                  onReorder: (oldIndex, newIndex) =>
                      setlists.reorder(setlist.id, oldIndex, newIndex),
                  itemBuilder: (context, i) {
                    final path = paths[i];
                    final score = _scoreFor(path);

                    return ListTile(
                      key: ValueKey(path),
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      leading: CircleAvatar(
                        backgroundColor: score?.isPdf == true
                            ? const Color(0xFFFFEBEE)
                            : const Color(0xFFE3F2FD),
                        child: Icon(
                          score?.isPdf == true
                              ? Icons.picture_as_pdf_rounded
                              : Icons.image_rounded,
                          color: score?.isPdf == true
                              ? const Color(0xFFE53935)
                              : const Color(0xFF1E88E5),
                          size: 20,
                        ),
                      ),
                      title: Text(
                        score?.name ?? path.split('/').last,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: score == null ? scheme.onSurfaceVariant : null,
                        ),
                      ),
                      subtitle: score == null
                          ? Text('File not found',
                              style: TextStyle(color: scheme.error, fontSize: 12))
                          : null,
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove_circle_outline, size: 20),
                            color: scheme.error,
                            onPressed: () =>
                                setlists.removeScore(setlist.id, path),
                            tooltip: 'Remove from setlist',
                          ),
                          const Icon(Icons.drag_handle, color: Colors.grey),
                        ],
                      ),
                      onTap: score != null ? () => _openScore(context, score) : null,
                    );
                  },
                ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _showAddScores(context),
            icon: const Icon(Icons.add),
            label: const Text('Add scores'),
          ),
        );
      },
    );
  }

  Widget _buildEmpty(BuildContext context, ColorScheme scheme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.queue_music, size: 80, color: scheme.outlineVariant),
          const SizedBox(height: 16),
          Text('No scores in this setlist',
              style: TextStyle(color: scheme.onSurfaceVariant)),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () => _showAddScores(context),
            icon: const Icon(Icons.add),
            label: const Text('Add scores'),
          ),
        ],
      ),
    );
  }
}
