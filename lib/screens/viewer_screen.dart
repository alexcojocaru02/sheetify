import 'dart:io';
import 'package:flutter/material.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../models/annotation_store.dart';
import '../models/stroke.dart';
import '../widgets/drawing_canvas.dart';
import '../widgets/annotation_toolbar.dart';

class ViewerScreen extends StatefulWidget {
  const ViewerScreen({
    super.key,
    required this.filePath,
    required this.fileName,
  });

  final String filePath;
  final String fileName;

  @override
  State<ViewerScreen> createState() => _ViewerScreenState();
}

class _ViewerScreenState extends State<ViewerScreen> {
  late final PdfViewerController _pdfController;
  late final AnnotationStore _store;

  int _currentPage = 1;
  int _totalPages = 1;

  // Toolbar state
  Color _color = const Color(0xFF000000);
  double _width = 4.0;
  bool _isEraser = false;
  bool _isDrawMode = false;

  bool get _isPdf => widget.filePath.toLowerCase().endsWith('.pdf');
  int get _activePage => _isPdf ? _currentPage : 1;

  @override
  void initState() {
    super.initState();
    _store = AnnotationStore(widget.filePath);
    _store.load().then((_) => setState(() {}));
    if (_isPdf) {
      _pdfController = PdfViewerController();
      _pdfController.addListener(_onPdfUpdate);
    }
  }

  @override
  void dispose() {
    if (_isPdf) {
      _pdfController.removeListener(_onPdfUpdate);
      _pdfController.dispose();
    }
    super.dispose();
  }

  void _onPdfUpdate() {
    final page = _pdfController.currentPageNumber;
    final total = _pdfController.pageCount;
    if (page != null && total != null) {
      setState(() {
        _currentPage = page;
        _totalPages = total;
      });
    }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.fileName, overflow: TextOverflow.ellipsis),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: _isPdf
            ? [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: _currentPage > 1
                      ? () => _pdfController.goToPage(pageNumber: _currentPage - 1)
                      : null,
                  tooltip: 'Previous page',
                ),
                Center(
                  child: Text(
                    '$_currentPage / $_totalPages',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: _currentPage < _totalPages
                      ? () => _pdfController.goToPage(pageNumber: _currentPage + 1)
                      : null,
                  tooltip: 'Next page',
                ),
                const SizedBox(width: 8),
              ]
            : null,
      ),
      body: Column(
        children: [
          Expanded(
            child: _isPdf ? _buildPdfViewer() : _buildSvgViewer(),
          ),
          AnnotationToolbar(
            activeColor: _color,
            activeWidth: _width,
            isEraser: _isEraser,
            isDrawMode: _isDrawMode,
            canUndo: _store.hasStrokes(_activePage),
            onColorChanged: (c) => setState(() => _color = c),
            onWidthChanged: (w) => setState(() => _width = w),
            onEraserToggled: () => setState(() => _isEraser = !_isEraser),
            onDrawModeToggled: () => setState(() => _isDrawMode = !_isDrawMode),
            onUndo: _undo,
          ),
        ],
      ),
    );
  }

  Widget _buildPdfViewer() {
    return PdfViewer.file(
      widget.filePath,
      controller: _pdfController,
      params: PdfViewerParams(
        pageOverlaysBuilder: (context, pageRect, page) {
          return [
            IgnorePointer(
              ignoring: !_isDrawMode,
              child: DrawingCanvas(
                strokes: _store.getPage(page.pageNumber),
                activeColor: _color,
                activeWidth: _width,
                isEraser: _isEraser,
                onStrokeComplete: (stroke) => _addStroke(page.pageNumber, stroke),
              ),
            ),
          ];
        },
      ),
    );
  }

  Widget _buildSvgViewer() {
    return Stack(
      fit: StackFit.expand,
      children: [
        InteractiveViewer(
          minScale: 0.5,
          maxScale: 4.0,
          // Disable pan when drawing so touch goes to canvas
          panEnabled: !_isDrawMode,
          scaleEnabled: !_isDrawMode,
          child: Center(
            child: SvgPicture.file(
              File(widget.filePath),
              fit: BoxFit.contain,
            ),
          ),
        ),
        IgnorePointer(
          ignoring: !_isDrawMode,
          child: DrawingCanvas(
            strokes: _store.getPage(1),
            activeColor: _color,
            activeWidth: _width,
            isEraser: _isEraser,
            onStrokeComplete: (stroke) => _addStroke(1, stroke),
          ),
        ),
      ],
    );
  }
}
