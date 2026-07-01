import 'dart:io';

class Score {
  Score({
    required this.path,
    required this.name,
    required this.lastOpened,
  });

  final String path;
  final String name;
  DateTime lastOpened;

  bool get exists => File(path).existsSync();
  bool get isPdf => path.toLowerCase().endsWith('.pdf');

  Map<String, dynamic> toJson() => {
        'path': path,
        'name': name,
        'lastOpened': lastOpened.millisecondsSinceEpoch,
      };

  factory Score.fromJson(Map<String, dynamic> json) => Score(
        path: json['path'] as String,
        name: json['name'] as String,
        lastOpened:
            DateTime.fromMillisecondsSinceEpoch(json['lastOpened'] as int),
      );
}
