import 'package:flutter/material.dart';
import '../models/stroke.dart';

class AnnotationPainter extends CustomPainter {
  const AnnotationPainter({required this.strokes, this.activeStroke});

  final List<Stroke> strokes;
  final Stroke? activeStroke;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.saveLayer(Offset.zero & size, Paint());

    for (final stroke in [...strokes, if (activeStroke != null) activeStroke!]) {
      _drawStroke(canvas, size, stroke);
    }

    canvas.restore();
  }

  void _drawStroke(Canvas canvas, Size size, Stroke stroke) {
    if (stroke.points.length < 2) return;

    final paint = Paint()
      ..strokeWidth = stroke.width
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke
      ..blendMode = stroke.isEraser ? BlendMode.clear : BlendMode.srcOver
      ..color = stroke.color;

    final path = Path();
    final first = _px(stroke.points.first, size);
    path.moveTo(first.dx, first.dy);
    for (var i = 1; i < stroke.points.length; i++) {
      final p = _px(stroke.points[i], size);
      path.lineTo(p.dx, p.dy);
    }
    canvas.drawPath(path, paint);
  }

  Offset _px(Offset norm, Size size) =>
      Offset(norm.dx * size.width, norm.dy * size.height);

  @override
  bool shouldRepaint(AnnotationPainter old) =>
      strokes != old.strokes || activeStroke != old.activeStroke;
}
