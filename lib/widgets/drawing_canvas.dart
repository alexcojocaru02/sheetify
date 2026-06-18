import 'package:flutter/material.dart';
import '../models/stroke.dart';
import 'annotation_painter.dart';

class DrawingCanvas extends StatefulWidget {
  const DrawingCanvas({
    super.key,
    required this.strokes,
    required this.activeColor,
    required this.activeWidth,
    required this.isEraser,
    required this.onStrokeComplete,
  });

  final List<Stroke> strokes;
  final Color activeColor;
  final double activeWidth;
  final bool isEraser;
  final void Function(Stroke stroke) onStrokeComplete;

  @override
  State<DrawingCanvas> createState() => _DrawingCanvasState();
}

class _DrawingCanvasState extends State<DrawingCanvas> {
  Stroke? _active;

  Offset _norm(Offset local, Size size) => Offset(
        (local.dx / size.width).clamp(0.0, 1.0),
        (local.dy / size.height).clamp(0.0, 1.0),
      );

  void _start(DragStartDetails d, Size size) {
    setState(() {
      _active = Stroke(
        points: [_norm(d.localPosition, size)],
        color: widget.activeColor,
        width: widget.activeWidth,
        isEraser: widget.isEraser,
      );
    });
  }

  void _update(DragUpdateDetails d, Size size) {
    if (_active == null) return;
    setState(() {
      _active = Stroke(
        points: [..._active!.points, _norm(d.localPosition, size)],
        color: _active!.color,
        width: _active!.width,
        isEraser: _active!.isEraser,
      );
    });
  }

  void _end(DragEndDetails _) {
    if (_active == null) return;
    widget.onStrokeComplete(_active!);
    setState(() => _active = null);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        return GestureDetector(
          onPanStart: (d) => _start(d, size),
          onPanUpdate: (d) => _update(d, size),
          onPanEnd: _end,
          child: RepaintBoundary(
            child: CustomPaint(
              size: size,
              painter: AnnotationPainter(
                strokes: widget.strokes,
                activeStroke: _active,
              ),
            ),
          ),
        );
      },
    );
  }
}
