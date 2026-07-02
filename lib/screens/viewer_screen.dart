import 'dart:io';
import 'package:flutter/material.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../models/annotation_store.dart';
import '../models/draw_tool.dart';
import '../models/library_store.dart';
import '../models/score.dart';
import '../models/stroke.dart';
import '../widgets/drawing_canvas.dart';
import '../widgets/annotation_toolbar.dart';

class ViewerScreen extends StatefulWidget {
  const ViewerScreen({
    super.key,
    required this.score,
    required this.library,
  });

  final Score score;
  final LibraryStore library;

  @override
  State<ViewerScreen> createState() => _ViewerScreenState();
}

class _ViewerScreenState extends State<ViewerScreen> {
  late final PageController _pageController;
  late final AnnotationStore _store;
  final ScrollController _stripController = ScrollController();

  PdfDocument? _document;
  int _currentPage = 1;
  int _totalPages = 1;

  DrawTool _tool = DrawTool.pen;
  Color _color = const Color(0xFF000000);
  double _width = 4.0;
  bool _isDrawMode = false;

  bool get _isPdf => widget.score.isPdf;
  int get _activePage => _isPdf ? _currentPage : 1;

  @override
  void initState() {
    super.initState();
    _store = AnnotationStore(widget.score.path);
    _store.load().then((_) => setState(() {}));

    _pageController = PageController();

    if (_isPdf) _loadDocument();

    widget.library.addOrUpdate(Score(
      path: widget.score.path,
      name: widget.score.name,
      lastOpened: DateTime.now(),
    ));
  }

  Future<void> _loadDocument() async {
    final doc = await PdfDocument.openFile(widget.score.path);
    if (!mounted) return;
    setState(() {
      _document = doc;
      _totalPages = doc.pages.length;
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _document?.dispose();
    _stripController.dispose();
    super.dispose();
  }

  void _addStroke(int page, Stroke stroke) {
    setState(() => _store.addStroke(page, stroke));
    _store.save();
  }

  void _undo() {
    if (_store.undoLastStroke(_activePage)) {
      setState(() {});
      _store.save();
    }
  }

  void _toggleBookmark() {
    setState(() => _store.toggleBookmark(_activePage));
    _store.save();
  }

  void _goToPage(int page) {
    if (!_isPdf) return;
    _pageController.animateToPage(
      page - 1,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
    );
  }

  void _scrollStripToPage(int page) {
    if (!_stripController.hasClients) return;
    final offset = (page - 1) * 44.0 - 100;
    _stripController.animateTo(
      offset.clamp(0.0, _stripController.position.maxScrollExtent),
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
    );
  }

  void _showJumpToPage() {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Jump to page'),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(hintText: '1 – $_totalPages'),
          autofocus: true,
          onSubmitted: (v) {
            final p = int.tryParse(v);
            if (p != null && p >= 1 && p <= _totalPages) {
              _goToPage(p);
              Navigator.pop(ctx);
            }
          },
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              final p = int.tryParse(ctrl.text);
              if (p != null && p >= 1 && p <= _totalPages) {
                _goToPage(p);
                Navigator.pop(ctx);
              }
            },
            child: const Text('Go'),
          ),
        ],
      ),
    );
  }

  void _showBookmarks() {
    final bm = _store.bookmarks;
    if (bm.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No bookmarks yet. Tap ☆ to bookmark a page.')),
      );
      return;
    }
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 36, height: 4,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(color: Colors.grey[400], borderRadius: BorderRadius.circular(2)),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Text('Bookmarks', style: Theme.of(context).textTheme.titleMedium),
          ),
          ...bm.map((p) => ListTile(
                leading: const Icon(Icons.bookmark, color: Colors.amber),
                title: Text('Page $p'),
                onTap: () {
                  Navigator.pop(ctx);
                  _goToPage(p);
                },
              )),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isBookmarked = _store.isBookmarked(_activePage);

    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        backgroundColor: scheme.surface,
        scrolledUnderElevation: 1,
        title: Text(widget.score.name,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        actions: [
          if (_isPdf) ...[
            IconButton(
              icon: const Icon(Icons.chevron_left),
              onPressed: _currentPage > 1 ? () => _goToPage(_currentPage - 1) : null,
              tooltip: 'Previous page',
            ),
            Center(
              child: GestureDetector(
                onTap: _showJumpToPage,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: scheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text('$_currentPage / $_totalPages',
                      style: TextStyle(
                          color: scheme.onSecondaryContainer,
                          fontWeight: FontWeight.w600,
                          fontSize: 13)),
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right),
              onPressed: _currentPage < _totalPages ? () => _goToPage(_currentPage + 1) : null,
              tooltip: 'Next page',
            ),
          ],
          IconButton(
            icon: Icon(isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                color: isBookmarked ? Colors.amber : null),
            onPressed: _toggleBookmark,
            tooltip: isBookmarked ? 'Remove bookmark' : 'Bookmark page',
          ),
          PopupMenuButton<String>(
            onSelected: (v) {
              if (v == 'jump') _showJumpToPage();
              if (v == 'bookmarks') _showBookmarks();
            },
            itemBuilder: (_) => [
              if (_isPdf)
                const PopupMenuItem(value: 'jump', child: Text('Jump to page')),
              const PopupMenuItem(value: 'bookmarks', child: Text('Bookmarks')),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(child: _isPdf ? _buildPdfViewer() : _buildSvgViewer()),
          if (_isPdf && _totalPages > 1) _buildPageStrip(scheme),
          AnnotationToolbar(
            activeTool: _tool,
            activeColor: _color,
            activeWidth: _width,
            isDrawMode: _isDrawMode,
            canUndo: _store.hasStrokes(_activePage),
            onToolChanged: (t) => setState(() {
              _tool = t;
              if (t == DrawTool.highlighter && _width < 12) _width = 12;
              if (t == DrawTool.eraser && _width < 12) _width = 24;
              if (t == DrawTool.pen && _width > 16) _width = 4;
            }),
            onColorChanged: (c) => setState(() => _color = c),
            onWidthChanged: (w) => setState(() => _width = w),
            onDrawModeToggled: () => setState(() => _isDrawMode = !_isDrawMode),
            onUndo: _undo,
          ),
        ],
      ),
    );
  }

  Widget _buildPageStrip(ColorScheme scheme) {
    return Container(
      height: 40,
      color: scheme.surfaceContainerHigh,
      child: ListView.builder(
        controller: _stripController,
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        itemCount: _totalPages,
        itemBuilder: (context, i) {
          final page = i + 1;
          final isCurrent = page == _currentPage;
          final isBookmarked = _store.isBookmarked(page);
          return GestureDetector(
            onTap: () => _goToPage(page),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 3),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
              decoration: BoxDecoration(
                color: isCurrent ? scheme.primary : scheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(20),
                border: isBookmarked
                    ? Border.all(color: Colors.amber, width: 1.5)
                    : null,
              ),
              child: Text(
                '$page',
                style: TextStyle(
                  color: isCurrent ? scheme.onPrimary : scheme.onSurfaceVariant,
                  fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                  fontSize: 12,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPdfViewer() {
    if (_document == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        PageView.builder(
          controller: _pageController,
          // Disable swipe when drawing so strokes aren't interrupted
          physics: _isDrawMode ? const NeverScrollableScrollPhysics() : null,
          onPageChanged: (index) {
            setState(() => _currentPage = index + 1);
            _scrollStripToPage(index + 1);
          },
          itemCount: _totalPages,
          itemBuilder: (context, index) => _buildPdfPage(index + 1),
        ),
        // Tap zones (hidden in draw mode)
        if (!_isDrawMode) ...[
          Positioned(
            left: 0, top: 0, bottom: 0, width: 56,
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: () {
                if (_currentPage > 1) _goToPage(_currentPage - 1);
              },
            ),
          ),
          Positioned(
            right: 0, top: 0, bottom: 0, width: 56,
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: () {
                if (_currentPage < _totalPages) _goToPage(_currentPage + 1);
              },
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildPdfPage(int pageNum) {
    final page = _document!.pages[pageNum - 1];
    return LayoutBuilder(
      builder: (context, constraints) {
        // Fit the page inside available space, preserving aspect ratio
        final pageAspect = page.width / page.height;
        final screenAspect = constraints.maxWidth / constraints.maxHeight;
        final Size fitted;
        if (pageAspect < screenAspect) {
          // Taller relative to screen → fit to height
          fitted = Size(constraints.maxHeight * pageAspect, constraints.maxHeight);
        } else {
          // Wider relative to screen → fit to width
          fitted = Size(constraints.maxWidth, constraints.maxWidth / pageAspect);
        }

        return Center(
          child: SizedBox(
            width: fitted.width,
            height: fitted.height,
            child: Stack(
              fit: StackFit.expand,
              children: [
                PdfPageView(
                  pdfDocument: _document!,
                  pageNumber: pageNum,
                  margin: 0,
                ),
                IgnorePointer(
                  ignoring: !_isDrawMode,
                  child: DrawingCanvas(
                    strokes: _store.getPage(pageNum),
                    activeColor: _color,
                    activeWidth: _width,
                    isEraser: _tool == DrawTool.eraser,
                    isHighlighter: _tool == DrawTool.highlighter,
                    onStrokeComplete: (s) => _addStroke(pageNum, s),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSvgViewer() {
    return Stack(
      fit: StackFit.expand,
      children: [
        InteractiveViewer(
          minScale: 0.5,
          maxScale: 4.0,
          panEnabled: !_isDrawMode,
          scaleEnabled: !_isDrawMode,
          child: Center(
            child: SvgPicture.file(File(widget.score.path), fit: BoxFit.contain),
          ),
        ),
        IgnorePointer(
          ignoring: !_isDrawMode,
          child: DrawingCanvas(
            strokes: _store.getPage(1),
            activeColor: _color,
            activeWidth: _width,
            isEraser: _tool == DrawTool.eraser,
            isHighlighter: _tool == DrawTool.highlighter,
            onStrokeComplete: (s) => _addStroke(1, s),
          ),
        ),
      ],
    );
  }
}
