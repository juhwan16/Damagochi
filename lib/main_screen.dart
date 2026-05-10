import 'package:flutter/material.dart';
import 'storage_service.dart';
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
  String _themeId = 'default';
  int _customVersion = 0;

  @override
  void initState() {
    super.initState();
    _loadTheme();
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
    final themeColors = StorageService.themeColors(_themeId);

    return Scaffold(
      backgroundColor: themeColors.first,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: themeColors,
          ),
        ),
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
                  const RankingTab(),
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
    const titles = ['다마고치 🌸', '키우기 💕', '상점 🛍️', '순위 🏆'];
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 6),
      child: Row(children: [
        Container(
          width: 6,
          height: 24,
          margin: const EdgeInsets.only(right: 10),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFFFB6D9), Color(0xFFD4AAFF)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        Text(titles[_index],
            style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFFCC3366))),
      ]),
    );
  }

  Widget _buildBottomNav() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: Container(
          height: 64,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: Colors.pink.withValues(alpha: 0.18),
                blurRadius: 24,
                offset: const Offset(0, 6),
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: NavigationBar(
              height: 64,
              selectedIndex: _index,
              onDestinationSelected: (i) => setState(() => _index = i),
              backgroundColor: Colors.transparent,
              indicatorColor: const Color(0xFFFFD0E8),
              labelBehavior:
                  NavigationDestinationLabelBehavior.alwaysShow,
              destinations: List.generate(
                4,
                (i) => NavigationDestination(
                  icon: Icon(_icons[i],
                      color: Colors.grey[400], size: 22),
                  label: _labels[i],
                  selectedIcon: Icon(_icons[i],
                      color: const Color(0xFFCC3366), size: 22),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
