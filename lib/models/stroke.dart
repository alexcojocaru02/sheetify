import 'dart:ui';

class Stroke {
  const Stroke({
    required this.points,
    required this.color,
    required this.width,
    this.isEraser = false,
    this.isHighlighter = false,
  });

  // Points stored as normalized [0,1] offsets relative to page size
  final List<Offset> points;
  final Color color;
  final double width;
  final bool isEraser;
  final bool isHighlighter;

  Map<String, dynamic> toJson() => {
        'points': points.map((p) => [p.dx, p.dy]).toList(),
        'color': color.value,
        'width': width,
        'isEraser': isEraser,
        'isHighlighter': isHighlighter,
      };

  factory Stroke.fromJson(Map<String, dynamic> json) => Stroke(
        points: (json['points'] as List)
            .map((p) => Offset(
                  (p as List)[0].toDouble(),
                  p[1].toDouble(),
                ))
            .toList(),
        color: Color(json['color'] as int),
        width: (json['width'] as num).toDouble(),
        isEraser: json['isEraser'] as bool? ?? false,
        isHighlighter: json['isHighlighter'] as bool? ?? false,
      );
}
