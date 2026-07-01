import 'package:flutter/material.dart';
import 'models/library_store.dart';
import 'models/setlist_store.dart';
import 'screens/main_screen.dart';

void main() {
  runApp(const SheetifyApp());
}

class SheetifyApp extends StatefulWidget {
  const SheetifyApp({super.key});

  @override
  State<SheetifyApp> createState() => _SheetifyAppState();
}

class _SheetifyAppState extends State<SheetifyApp> {
  final _library = LibraryStore();
  final _setlists = SetlistStore();

  @override
  void initState() {
    super.initState();
    _library.load();
    _setlists.load();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sheetify',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.system,
      theme: _buildTheme(Brightness.light),
      darkTheme: _buildTheme(Brightness.dark),
      home: MainScreen(library: _library, setlists: _setlists),
    );
  }

  ThemeData _buildTheme(Brightness brightness) {
    const seed = Color(0xFF3949AB);
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: seed, brightness: brightness),
      useMaterial3: true,
    );
  }
}
