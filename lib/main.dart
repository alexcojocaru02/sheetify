import 'package:flutter/material.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(const SheetifyApp());
}

class SheetifyApp extends StatelessWidget {
  const SheetifyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sheetify',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1A237E)),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}
