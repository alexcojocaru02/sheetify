import 'dart:io';
import 'package:flutter/material.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:flutter_svg/flutter_svg.dart';

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
  int _currentPage = 1;
  int _totalPages = 1;

  bool get _isPdf => widget.filePath.toLowerCase().endsWith('.pdf');

  @override
  void initState() {
    super.initState();
    if (_isPdf) {
      _pdfController = PdfViewerController();
      _pdfController.addListener(_onPdfControllerUpdate);
    }
  }

  @override
  void dispose() {
    if (_isPdf) {
      _pdfController.removeListener(_onPdfControllerUpdate);
      _pdfController.dispose();
    }
    super.dispose();
  }

  void _onPdfControllerUpdate() {
    final page = _pdfController.currentPageNumber;
    final total = _pdfController.pageCount;
    if (page != null && total != null) {
      setState(() {
        _currentPage = page;
        _totalPages = total;
      });
    }
  }

  void _goToPreviousPage() {
    if (_currentPage > 1) {
      _pdfController.goToPage(pageNumber: _currentPage - 1);
    }
  }

  void _goToNextPage() {
    if (_currentPage < _totalPages) {
      _pdfController.goToPage(pageNumber: _currentPage + 1);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.fileName,
          overflow: TextOverflow.ellipsis,
        ),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: _isPdf
            ? [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: _currentPage > 1 ? _goToPreviousPage : null,
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
                  onPressed:
                      _currentPage < _totalPages ? _goToNextPage : null,
                  tooltip: 'Next page',
                ),
                const SizedBox(width: 8),
              ]
            : null,
      ),
      body: _isPdf ? _buildPdfViewer() : _buildSvgViewer(),
    );
  }

  Widget _buildPdfViewer() {
    return PdfViewer.file(
      widget.filePath,
      controller: _pdfController,
    );
  }

  Widget _buildSvgViewer() {
    return InteractiveViewer(
      minScale: 0.5,
      maxScale: 4.0,
      child: Center(
        child: SvgPicture.file(
          File(widget.filePath),
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}
