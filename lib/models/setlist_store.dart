import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'setlist.dart';

class SetlistStore extends ChangeNotifier {
  static const _key = 'sheetify_setlists_v1';

  List<Setlist> _setlists = [];

  List<Setlist> get setlists => List.unmodifiable(_setlists);

  List<Setlist> setlistsContaining(String scorePath) =>
      _setlists.where((s) => s.scorePaths.contains(scorePath)).toList();

  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key);
      if (raw == null) return;
      final list = jsonDecode(raw) as List;
      _setlists = list
          .map((e) => Setlist.fromJson(e as Map<String, dynamic>))
          .toList();
      notifyListeners();
    } catch (_) {}
  }

  Future<void> _save() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
          _key, jsonEncode(_setlists.map((s) => s.toJson()).toList()));
    } catch (_) {}
  }

  Future<Setlist> create(String name) async {
    final setlist = Setlist(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      scorePaths: [],
      createdAt: DateTime.now(),
    );
    _setlists.add(setlist);
    notifyListeners();
    await _save();
    return setlist;
  }

  Future<void> delete(String id) async {
    _setlists.removeWhere((s) => s.id == id);
    notifyListeners();
    await _save();
  }

  Future<void> rename(String id, String name) async {
    final s = _setlists.firstWhere((s) => s.id == id);
    s.name = name;
    notifyListeners();
    await _save();
  }

  Future<void> addScore(String setlistId, String scorePath) async {
    final s = _setlists.firstWhere((s) => s.id == setlistId);
    if (!s.scorePaths.contains(scorePath)) {
      s.scorePaths.add(scorePath);
      notifyListeners();
      await _save();
    }
  }

  Future<void> removeScore(String setlistId, String scorePath) async {
    final s = _setlists.firstWhere((s) => s.id == setlistId);
    s.scorePaths.remove(scorePath);
    notifyListeners();
    await _save();
  }

  Future<void> reorder(String setlistId, int oldIndex, int newIndex) async {
    final s = _setlists.firstWhere((s) => s.id == setlistId);
    if (newIndex > oldIndex) newIndex--;
    final path = s.scorePaths.removeAt(oldIndex);
    s.scorePaths.insert(newIndex, path);
    notifyListeners();
    await _save();
  }

  Future<void> toggleScore(String setlistId, String scorePath) async {
    final s = _setlists.firstWhere((s) => s.id == setlistId);
    if (s.scorePaths.contains(scorePath)) {
      s.scorePaths.remove(scorePath);
    } else {
      s.scorePaths.add(scorePath);
    }
    notifyListeners();
    await _save();
  }
}
