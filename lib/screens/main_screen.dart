import 'package:flutter/material.dart';
import '../models/library_store.dart';
import '../models/setlist_store.dart';
import 'library_screen.dart';
import 'setlists_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({
    super.key,
    required this.library,
    required this.setlists,
  });

  final LibraryStore library;
  final SetlistStore setlists;

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _tab,
        children: [
          LibraryScreen(library: widget.library, setlists: widget.setlists),
          SetlistsScreen(setlists: widget.setlists, library: widget.library),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.library_music_outlined),
            selectedIcon: Icon(Icons.library_music),
            label: 'Library',
          ),
          NavigationDestination(
            icon: Icon(Icons.queue_music_outlined),
            selectedIcon: Icon(Icons.queue_music),
            label: 'Setlists',
          ),
        ],
      ),
    );
  }
}
