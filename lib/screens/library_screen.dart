import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../models/library_store.dart';
import '../models/score.dart';
import '../widgets/score_card.dart';
import 'viewer_screen.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key, required this.library});

  final LibraryStore library;

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  String _search = '';
  bool _isGridView = true;

  Future<void> _importScore() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'svg'],
    );
    if (result == null || result.files.single.path == null) return;
    if (!mounted) return;

    final score = Score(
      path: result.files.single.path!,
      name: result.files.single.name,
      lastOpened: DateTime.now(),
    );
    await widget.library.addOrUpdate(score);
    if (!mounted) return;
    _openScore(score);
  }

  void _openScore(Score score) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ViewerScreen(score: score, library: widget.library),
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
        title: _search.isEmpty
            ? Row(children: [
                Icon(Icons.library_music, color: scheme.primary, size: 28),
                const SizedBox(width: 10),
                Text('Sheetify',
                    style: TextStyle(
                        fontWeight: FontWeight.bold, color: scheme.primary)),
              ])
            : TextField(
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Search scores…',
                  border: InputBorder.none,
                ),
                onChanged: (v) => setState(() => _search = v),
              ),
        actions: [
          IconButton(
            icon: Icon(_search.isEmpty ? Icons.search : Icons.close),
            onPressed: () => setState(() => _search = _search.isEmpty ? ' ' : ''),
            tooltip: 'Search',
          ),
          IconButton(
            icon: Icon(_isGridView ? Icons.view_list_rounded : Icons.grid_view_rounded),
            onPressed: () => setState(() => _isGridView = !_isGridView),
            tooltip: _isGridView ? 'List view' : 'Grid view',
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: widget.library,
        builder: (context, _) {
          final all = widget.library.scores;
          final scores = _search.trim().isEmpty
              ? all
              : all
                  .where((s) =>
                      s.name.toLowerCase().contains(_search.trim().toLowerCase()))
                  .toList();

          if (all.isEmpty) return _buildEmpty(context);

          return _isGridView
              ? _buildGrid(context, scores)
              : _buildList(context, scores);
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _importScore,
        icon: const Icon(Icons.add),
        label: const Text('Import'),
        tooltip: 'Import sheet music',
      ),
    );
  }

  Widget _buildEmpty(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.library_music_outlined, size: 100, color: scheme.outlineVariant),
          const SizedBox(height: 24),
          Text('No scores yet',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(color: scheme.onSurfaceVariant)),
          const SizedBox(height: 8),
          Text('Import a PDF or SVG score to get started',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: scheme.onSurfaceVariant)),
          const SizedBox(height: 32),
          FilledButton.icon(
            onPressed: _importScore,
            icon: const Icon(Icons.folder_open),
            label: const Text('Import Score'),
          ),
        ],
      ),
    );
  }

  Widget _buildGrid(BuildContext context, List<Score> scores) {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.78,
      ),
      itemCount: scores.length,
      itemBuilder: (context, i) => ScoreCard(
        score: scores[i],
        onTap: () => _openScore(scores[i]),
        onDelete: () => widget.library.remove(scores[i].path),
      ),
    );
  }

  Widget _buildList(BuildContext context, List<Score> scores) {
    final scheme = Theme.of(context).colorScheme;
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
      itemCount: scores.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, i) {
        final s = scores[i];
        return Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: scheme.outlineVariant, width: 0.8),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            leading: CircleAvatar(
              backgroundColor:
                  s.isPdf ? const Color(0xFFFFEBEE) : const Color(0xFFE3F2FD),
              child: Icon(
                s.isPdf ? Icons.picture_as_pdf_rounded : Icons.image_rounded,
                color: s.isPdf ? const Color(0xFFE53935) : const Color(0xFF1E88E5),
              ),
            ),
            title: Text(s.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Text(_timeAgo(s.lastOpened),
                style: TextStyle(color: scheme.onSurfaceVariant)),
            trailing: IconButton(
              icon: const Icon(Icons.more_vert),
              onPressed: () => _showScoreOptions(context, s),
            ),
            onTap: () => _openScore(s),
          ),
        );
      },
    );
  }

  void _showScoreOptions(BuildContext context, Score score) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                  color: Colors.grey[400], borderRadius: BorderRadius.circular(2)),
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.red),
              title: const Text('Remove', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                widget.library.remove(score.path);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 30) return '${diff.inDays}d ago';
    return '${diff.inDays ~/ 30}mo ago';
  }
}
