import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'score.dart';

class LibraryStore extends ChangeNotifier {
  static const _key = 'sheetify_library_v1';

  List<Score> _scores = [];

  List<Score> get scores {
    return _scores.where((s) => s.exists).toList()
      ..sort((a, b) => b.lastOpened.compareTo(a.lastOpened));
  }

  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key);
      if (raw == null) return;
      final list = jsonDecode(raw) as List;
      _scores = list
          .map((e) => Score.fromJson(e as Map<String, dynamic>))
          .toList();
      notifyListeners();
    } catch (_) {}
  }

  Future<void> _save() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
          _key, jsonEncode(_scores.map((s) => s.toJson()).toList()));
    } catch (_) {}
  }

  Future<void> addOrUpdate(Score score) async {
    final idx = _scores.indexWhere((s) => s.path == score.path);
    if (idx >= 0) {
      _scores[idx].lastOpened = score.lastOpened;
    } else {
      _scores.add(score);
    }
    notifyListeners();
    await _save();
  }

  Future<void> remove(String path) async {
    _scores.removeWhere((s) => s.path == path);
    notifyListeners();
    await _save();
  }
}
