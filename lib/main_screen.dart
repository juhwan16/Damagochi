import 'package:flutter/material.dart';
import 'home_tab.dart';
import 'care_tab.dart';
import 'shop_tab.dart';
import 'ranking_tab.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _index = 0;

  static const _tabs = [
    HomeTab(),
    CareTab(),
    ShopTab(),
    RankingTab(),
  ];

  static const _labels = ['메인', '키우기', '상점', '순위'];
  static const _icons = [
    Icons.home_rounded,
    Icons.favorite_rounded,
    Icons.storefront_rounded,
    Icons.emoji_events_rounded,
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFFCE4EC), Color(0xFFF8BBD9), Color(0xFFEDD5F5)],
          ),
        ),
        child: SafeArea(
          child: Column(children: [
            _buildAppBar(),
            Expanded(
              child: IndexedStack(index: _index, children: _tabs),
            ),
          ]),
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        backgroundColor: Colors.white,
        indicatorColor: const Color(0xFFFFD0E8),
        destinations: List.generate(4, (i) => NavigationDestination(
          icon: Icon(_icons[i]),
          label: _labels[i],
          selectedIcon: Icon(_icons[i], color: const Color(0xFFCC3366)),
        )),
      ),
    );
  }

  Widget _buildAppBar() {
    final titles = ['다마고치 🌸', '키우기 💕', '상점 🛍️', '순위 🏆'];
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
      child: Row(children: [
        Text(
          titles[_index],
          style: const TextStyle(
              fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFFCC3366)),
        ),
      ]),
    );
  }
}
