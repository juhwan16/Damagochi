import 'package:flutter/material.dart';
import 'main_screen.dart';
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
      home: const MainScreen(),
      routes: {
        '/settings': (context) => const SettingsScreen(),
      },
    );
  }
}
