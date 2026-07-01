class Setlist {
  Setlist({
    required this.id,
    required this.name,
    required this.scorePaths,
    required this.createdAt,
    this.lastUsed,
  });

  final String id;
  String name;
  // Ordered list of score paths — same path = same annotations everywhere
  List<String> scorePaths;
  final DateTime createdAt;
  DateTime? lastUsed;

  int get count => scorePaths.length;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'scorePaths': scorePaths,
        'createdAt': createdAt.millisecondsSinceEpoch,
        'lastUsed': lastUsed?.millisecondsSinceEpoch,
      };

  factory Setlist.fromJson(Map<String, dynamic> json) => Setlist(
        id: json['id'] as String,
        name: json['name'] as String,
        scorePaths: List<String>.from(json['scorePaths'] as List),
        createdAt: DateTime.fromMillisecondsSinceEpoch(json['createdAt'] as int),
        lastUsed: json['lastUsed'] != null
            ? DateTime.fromMillisecondsSinceEpoch(json['lastUsed'] as int)
            : null,
      );
}
