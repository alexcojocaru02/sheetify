import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'stroke.dart';

class AnnotationStore {
  AnnotationStore(this.sourceFilePath);

  final String sourceFilePath;
  final Map<int, List<Stroke>> _pages = {};
  final Set<int> _bookmarks = {};

  List<Stroke> getPage(int page) => List.unmodifiable(_pages[page] ?? []);
  bool hasStrokes(int page) => (_pages[page]?.isNotEmpty) ?? false;

  bool isBookmarked(int page) => _bookmarks.contains(page);
  List<int> get bookmarks => (_bookmarks.toList()..sort());

  void toggleBookmark(int page) {
    if (_bookmarks.contains(page)) {
      _bookmarks.remove(page);
    } else {
      _bookmarks.add(page);
    }
  }

  void addStroke(int page, Stroke stroke) {
    _pages.putIfAbsent(page, () => []).add(stroke);
  }

  bool undoLastStroke(int page) {
    final strokes = _pages[page];
    if (strokes == null || strokes.isEmpty) return false;
    strokes.removeLast();
    return true;
  }

  Future<File> _file() async {
    final dir = await getApplicationDocumentsDirectory();
    final hash = sourceFilePath.hashCode.toRadixString(16);
    return File('${dir.path}/annotations_$hash.json');
  }

  Future<void> save() async {
    try {
      final file = await _file();
      final data = {
        'pages': _pages.map(
          (page, strokes) => MapEntry(
            '$page',
            strokes.map((s) => s.toJson()).toList(),
          ),
        ),
        'bookmarks': _bookmarks.toList(),
      };
      await file.writeAsString(jsonEncode(data));
    } catch (_) {}
  }

  Future<void> load() async {
    try {
      final file = await _file();
      if (!file.existsSync()) return;
      final raw = jsonDecode(await file.readAsString()) as Map<String, dynamic>;

      _pages.clear();
      final pages = raw['pages'] as Map<String, dynamic>? ?? {};
      pages.forEach((key, value) {
        _pages[int.parse(key)] = (value as List)
            .map((s) => Stroke.fromJson(s as Map<String, dynamic>))
            .toList();
      });

      _bookmarks.clear();
      final bm = raw['bookmarks'] as List?;
      if (bm != null) _bookmarks.addAll(bm.cast<int>());
    } catch (_) {}
  }
}
