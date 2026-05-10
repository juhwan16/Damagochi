import 'package:flutter/material.dart';
import 'character_select_screen.dart';
import 'settings_screen.dart';

void main() {
  runApp(const DamagochiApp());
}

class DamagochiApp extends StatelessWidget {
  const DamagochiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '다마고치',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFFF85B3)),
        useMaterial3: true,
      ),
      home: const CharacterSelectScreen(),
      routes: {
        '/settings': (context) => const SettingsScreen(),
      },
    );
  }
}
