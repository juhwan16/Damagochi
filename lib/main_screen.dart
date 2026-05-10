import 'package:flutter/material.dart';
import 'storage_service.dart';
import 'home_tab.dart';
import 'care_tab.dart';
import 'shop_tab.dart';
import 'ranking_tab.dart';
import 'game_background.dart';
import 'character_select_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _index = 0;
  String _themeId = 'default';
  int _customVersion = 0;

  @override
  void initState() {
    super.initState();
    _loadTheme();
  }

  void _goToCharacterSelect() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const CharacterSelectScreen()),
    );
  }

  Future<void> _loadTheme() async {
    final custom = await StorageService.loadCustomization();
    if (mounted) {
      setState(() {
        _themeId = custom['theme'] as String;
        _customVersion++;
      });
    }
  }

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
      backgroundColor: const Color(0xFF38B8F0),
      body: GameBackground(
        themeId: _themeId,
        child: SafeArea(
          bottom: false,
          child: Column(children: [
            _buildAppBar(),
            Expanded(
              child: IndexedStack(
                index: _index,
                children: [
                  HomeTab(customVersion: _customVersion),
                  CareTab(customVersion: _customVersion),
                  ShopTab(onCustomizationChanged: _loadTheme),
                  RankingTab(refreshTrigger: _index == 3 ? _customVersion : 0),
                ],
              ),
            ),
          ]),
        ),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildAppBar() {
    const titles = ['내 다마고치 🐱', '케어하기 💕', '상점 🛍️', '랭킹 🏆'];
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 6),
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 10, 12, 10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.88),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: const Color(0xFFD4914A).withValues(alpha: 0.45),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFD4914A).withValues(alpha: 0.18),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(children: [
          // Wooden-style left accent
          Container(
            width: 6, height: 24,
            margin: const EdgeInsets.only(right: 10),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFE8A050), Color(0xFFC87828)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          Expanded(
            child: Text(
              titles[_index],
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF5A3210),
              ),
            ),
          ),
          GestureDetector(
            onTap: _goToCharacterSelect,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFFFE0A0).withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFFD4914A).withValues(alpha: 0.5),
                ),
              ),
              child: const Row(mainAxisSize: MainAxisSize.min, children: [
                Text('🦆', style: TextStyle(fontSize: 14)),
                SizedBox(width: 4),
                Text('변경', style: TextStyle(fontSize: 12, color: Color(0xFF5A3210), fontWeight: FontWeight.bold)),
              ]),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _buildBottomNav() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 6, 14, 10),
        child: Container(
          height: 66,
          decoration: BoxDecoration(
            // Warm wood-toned bottom bar
            gradient: const LinearGradient(
              colors: [Color(0xFFFFF8EE), Color(0xFFFFF0D8)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: const Color(0xFFD4914A).withValues(alpha: 0.5),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFD4914A).withValues(alpha: 0.22),
                blurRadius: 16,
                offset: const Offset(0, 5),
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(27),
            child: NavigationBar(
              height: 66,
              selectedIndex: _index,
              onDestinationSelected: (i) => setState(() {
                _index = i;
                if (i == 3) _customVersion++; // ranking 탭 진입 시 새로고침
              }),
              backgroundColor: Colors.transparent,
              indicatorColor: const Color(0xFFFFD0A0),
              labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
              destinations: List.generate(
                4,
                (i) => NavigationDestination(
                  icon: Icon(_icons[i], color: const Color(0xFFB87840), size: 22),
                  label: _labels[i],
                  selectedIcon: Icon(_icons[i], color: const Color(0xFF8B4C10), size: 22),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
