import 'dart:ui';

class Stroke {
  const Stroke({
    required this.points,
    required this.color,
    required this.width,
    this.isEraser = false,
  });

  // Points are normalized [0,1] relative to page size so they survive zoom changes
  final List<Offset> points;
  final Color color;
  final double width;
  final bool isEraser;

  Map<String, dynamic> toJson() => {
        'points': points.map((p) => [p.dx, p.dy]).toList(),
        'color': color.value,
        'width': width,
        'isEraser': isEraser,
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
      );
}
