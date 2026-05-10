import 'package:flutter/material.dart';
import 'storage_service.dart';

// ─── 데이터 정의 ────────────────────────────────────────────────

class _Item {
  final String emoji, name, description;
  final int cost;
  final Map<String, int> effects;
  const _Item(this.emoji, this.name, this.description, this.cost, this.effects);
}

class _AccItem {
  final String id, emoji, name;
  final int cost;
  const _AccItem(this.id, this.emoji, this.name, this.cost);
}

class _ThemeItem {
  final String id, name;
  final List<Color> colors;
  final int cost;
  const _ThemeItem(this.id, this.name, this.colors, this.cost);
}

class _ColorItem {
  final String id, name;
  final Color? color;
  final int cost;
  const _ColorItem(this.id, this.name, this.color, this.cost);
}

const _items = [
  _Item('🍙', '주먹밥', '배고픔 +25', 10, {'hunger': 25}),
  _Item('🎂', '생일케이크', '배고픔 +45\n행복 +15', 35, {'hunger': 45, 'happiness': 15}),
  _Item('🎮', '장난감', '행복 +35', 25, {'happiness': 35}),
  _Item('⚡', '에너지드링크', '에너지 +40', 20, {'energy': 40}),
  _Item('💊', '비타민', '모든 스탯 +20', 55, {'hunger': 20, 'happiness': 20, 'energy': 20}),
  _Item('🍱', '프리미엄 도시락', '배고픔 +60\n에너지 +20', 65, {'hunger': 60, 'energy': 20}),
];

const _accessories = [
  _AccItem('crown', '👑', '왕관', 50),
  _AccItem('ribbon', '🎀', '리본', 30),
  _AccItem('hat', '⭐', '별모자', 40),
  _AccItem('glasses', '👓', '안경', 35),
  _AccItem('santa', '🎅', '산타모자', 45),
  _AccItem('halo', '😇', '천사링', 60),
];

final _themes = [
  _ThemeItem('default', '🌸 기본', StorageService.themeColors('default'), 0),
  _ThemeItem('sky', '☁️ 하늘', StorageService.themeColors('sky'), 30),
  _ThemeItem('forest', '🌿 숲', StorageService.themeColors('forest'), 30),
  _ThemeItem('sunset', '🌅 노을', StorageService.themeColors('sunset'), 30),
  _ThemeItem('lavender', '💜 라벤더', StorageService.themeColors('lavender'), 30),
  _ThemeItem('ocean', '🌊 바다', StorageService.themeColors('ocean'), 30),
];

final _colors = [
  _ColorItem('pink', '🩷 핑크', null, 0),
  _ColorItem('mint', '🩵 민트', const Color(0xFF80D0C0), 20),
  _ColorItem('yellow', '💛 노랑', const Color(0xFFFFD080), 20),
  _ColorItem('sky', '🩶 하늘', const Color(0xFF80B8E0), 20),
  _ColorItem('lavender', '💜 라벤더', const Color(0xFFB880E0), 20),
  _ColorItem('peach', '🧡 복숭아', const Color(0xFFFFB080), 20),
];

// ─── ShopTab ────────────────────────────────────────────────────

class ShopTab extends StatefulWidget {
  final VoidCallback? onCustomizationChanged;
  const ShopTab({super.key, this.onCustomizationChanged});

  @override
  State<ShopTab> createState() => _ShopTabState();
}

class _ShopTabState extends State<ShopTab> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _coins = 0;
  Map<String, dynamic> _custom = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final data = await StorageService.loadAll();
    final custom = await StorageService.loadCustomization();
    if (mounted) setState(() {
      _coins = data['coins'] as int;
      _custom = custom;
    });
  }

  void _snack(String msg, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: const TextStyle(fontWeight: FontWeight.bold)),
      backgroundColor: error ? Colors.red[400] : const Color(0xFFFF85B3),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      duration: const Duration(seconds: 2),
    ));
  }

  // ─── 아이템 구매 ─────────────────────────────────────────────

  Future<void> _buyItem(_Item item) async {
    if (_coins < item.cost) {
      _snack('코인이 부족해요! 목표를 달성해서 코인을 모으세요 🪙', error: true);
      return;
    }
    final ok = await StorageService.buyItem(item.cost, item.effects);
    if (ok) {
      await _load();
      widget.onCustomizationChanged?.call();
      _snack('${item.emoji} ${item.name} 구매 완료!');
    }
  }

  // ─── 커스터마이징 ──────────────────────────────────────────────

  Future<void> _buyCustom(String type, String id, int cost) async {
    if (cost == 0) return; // free
    final ok = await StorageService.unlockCustomItem(type, id, cost);
    if (ok) {
      await _load();
      _snack('구매 완료! 이제 장착할 수 있어요 ✨');
    } else {
      _snack('코인이 부족해요! 🪙', error: true);
    }
  }

  Future<void> _equipAccessory(String id) async {
    final equipped = _custom['accessory'] == id ? 'none' : id;
    await StorageService.equipAccessory(equipped);
    await _load();
    widget.onCustomizationChanged?.call();
    _snack(equipped == 'none' ? '악세서리를 해제했어요' : '악세서리를 장착했어요! 💕');
  }

  Future<void> _equipTheme(String id) async {
    await StorageService.equipTheme(id);
    await _load();
    widget.onCustomizationChanged?.call();
    _snack('배경 테마가 바뀌었어요! 🎨');
  }

  Future<void> _equipColor(String id) async {
    await StorageService.equipColor(id);
    await _load();
    widget.onCustomizationChanged?.call();
    _snack('캐릭터 색상이 바뀌었어요! 🌈');
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      // 코인 + 탭바
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(14)),
            child: Row(children: [
              const Text('🪙', style: TextStyle(fontSize: 20)),
              const SizedBox(width: 6),
              Text('$_coins',
                  style: const TextStyle(
                      fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFFCC3366))),
            ]),
          ),
          const Text('목표 달성 시 코인 +15',
              style: TextStyle(color: Colors.black45, fontSize: 12)),
        ]),
      ),
      // 탭바
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
        child: Container(
          decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(14)),
          child: TabBar(
            controller: _tabController,
            indicator: BoxDecoration(
                color: const Color(0xFFFF85B3),
                borderRadius: BorderRadius.circular(12)),
            labelColor: Colors.white,
            unselectedLabelColor: const Color(0xFFCC3366),
            tabs: const [Tab(text: '🛒  아이템'), Tab(text: '🎨  꾸미기')],
          ),
        ),
      ),
      // 탭 내용
      Expanded(
        child: TabBarView(
          controller: _tabController,
          children: [_buildItemsTab(), _buildCustomizeTab()],
        ),
      ),
    ]);
  }

  // ─── 아이템 탭 ───────────────────────────────────────────────

  Widget _buildItemsTab() {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 0.85),
      itemCount: _items.length,
      itemBuilder: (context, i) {
        final item = _items[i];
        final can = _coins >= item.cost;
        return Container(
          decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.82),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                  color: can ? Colors.pink[200]! : Colors.grey[300]!, width: 1.5)),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Text(item.emoji, style: const TextStyle(fontSize: 38)),
            const SizedBox(height: 6),
            Text(item.name,
                style: const TextStyle(
                    fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFFCC3366))),
            const SizedBox(height: 3),
            Text(item.description,
                style: const TextStyle(fontSize: 11, color: Colors.black54),
                textAlign: TextAlign.center),
            const SizedBox(height: 10),
            GestureDetector(
              onTap: () => _buyItem(item),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                    color: can ? const Color(0xFFFF85B3) : Colors.grey[300],
                    borderRadius: BorderRadius.circular(12)),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const Text('🪙', style: TextStyle(fontSize: 13)),
                  const SizedBox(width: 4),
                  Text('${item.cost}',
                      style: TextStyle(
                          color: can ? Colors.white : Colors.grey[600],
                          fontWeight: FontWeight.bold, fontSize: 14)),
                ]),
              ),
            ),
          ]),
        );
      },
    );
  }

  // ─── 꾸미기 탭 ───────────────────────────────────────────────

  Widget _buildCustomizeTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _sectionTitle('🎭 악세서리'),
        const SizedBox(height: 10),
        _buildAccessoryGrid(),
        const SizedBox(height: 20),
        _sectionTitle('🖼️ 배경 테마'),
        const SizedBox(height: 10),
        _buildThemeGrid(),
        const SizedBox(height: 20),
        _sectionTitle('🎨 캐릭터 색상'),
        const SizedBox(height: 10),
        _buildColorGrid(),
      ]),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(title,
        style: const TextStyle(
            fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFFCC3366)));
  }

  // 악세서리 그리드
  Widget _buildAccessoryGrid() {
    final unlocked = List<String>.from(_custom['unlockedAcc'] ?? []);
    final equipped = _custom['accessory'] as String? ?? 'none';

    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 0.85,
      children: [
        // 없음 (해제)
        _customCard(
          child: const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('✕', style: TextStyle(fontSize: 28, color: Colors.grey)),
              SizedBox(height: 4),
              Text('없음', style: TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          ),
          isEquipped: equipped == 'none',
          onTap: () => _equipAccessory('none'),
          isFree: true,
          isOwned: true,
        ),
        ..._accessories.map((acc) {
          final isOwned = unlocked.contains(acc.id);
          final isEquipped = equipped == acc.id;
          return _customCard(
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Text(acc.emoji, style: const TextStyle(fontSize: 30)),
              const SizedBox(height: 4),
              Text(acc.name,
                  style: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFFCC3366))),
            ]),
            isEquipped: isEquipped,
            isOwned: isOwned,
            isFree: false,
            cost: acc.cost,
            onTap: () => isOwned ? _equipAccessory(acc.id) : _buyCustom('accessory', acc.id, acc.cost),
          );
        }),
      ],
    );
  }

  // 배경 테마 그리드
  Widget _buildThemeGrid() {
    final unlocked = List<String>.from(_custom['unlockedThemes'] ?? ['default']);
    final equipped = _custom['theme'] as String? ?? 'default';

    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 0.85,
      children: _themes.map((theme) {
        final isOwned = unlocked.contains(theme.id) || theme.cost == 0;
        final isEquipped = equipped == theme.id;
        return _customCard(
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Container(
              width: 48,
              height: 30,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                    colors: theme.colors,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white54),
              ),
            ),
            const SizedBox(height: 6),
            Text(theme.name,
                style: const TextStyle(
                    fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFFCC3366)),
                textAlign: TextAlign.center),
          ]),
          isEquipped: isEquipped,
          isOwned: isOwned,
          isFree: theme.cost == 0,
          cost: theme.cost,
          onTap: () => isOwned ? _equipTheme(theme.id) : _buyCustom('theme', theme.id, theme.cost),
        );
      }).toList(),
    );
  }

  // 색상 그리드
  Widget _buildColorGrid() {
    final unlocked = List<String>.from(_custom['unlockedColors'] ?? ['pink']);
    final equipped = _custom['color'] as String? ?? 'pink';

    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 0.85,
      children: _colors.map((c) {
        final isOwned = unlocked.contains(c.id) || c.cost == 0;
        final isEquipped = equipped == c.id;
        return _customCard(
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                  color: c.color ?? const Color(0xFFFFD0E8),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2.5),
                  boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)]),
            ),
            const SizedBox(height: 6),
            Text(c.name,
                style: const TextStyle(
                    fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFFCC3366)),
                textAlign: TextAlign.center),
          ]),
          isEquipped: isEquipped,
          isOwned: isOwned,
          isFree: c.cost == 0,
          cost: c.cost,
          onTap: () => isOwned ? _equipColor(c.id) : _buyCustom('color', c.id, c.cost),
        );
      }).toList(),
    );
  }

  // 공통 커스터마이징 카드
  Widget _customCard({
    required Widget child,
    required bool isEquipped,
    required bool isOwned,
    required bool isFree,
    int cost = 0,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: isEquipped
              ? const Color(0xFFFFD0E8)
              : Colors.white.withValues(alpha: 0.82),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: isEquipped
                  ? const Color(0xFFFF85B3)
                  : Colors.pink[100]!,
              width: isEquipped ? 2.5 : 1.5),
        ),
        child: Stack(children: [
          Center(child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              child,
              const SizedBox(height: 6),
              if (isEquipped)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                      color: const Color(0xFFFF85B3),
                      borderRadius: BorderRadius.circular(8)),
                  child: const Text('장착중',
                      style: TextStyle(
                          color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                )
              else if (isOwned)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                      color: Colors.green[100],
                      borderRadius: BorderRadius.circular(8)),
                  child: const Text('장착',
                      style: TextStyle(
                          color: Colors.green, fontSize: 10, fontWeight: FontWeight.bold)),
                )
              else
                Row(mainAxisSize: MainAxisSize.min, children: [
                  const Text('🪙', style: TextStyle(fontSize: 11)),
                  const SizedBox(width: 2),
                  Text('$cost',
                      style: const TextStyle(
                          fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFFCC3366))),
                ]),
            ],
          )),
          if (!isOwned && !isFree)
            const Positioned(
                top: 6, right: 6,
                child: Icon(Icons.lock_rounded, size: 14, color: Colors.grey)),
        ]),
      ),
    );
  }
}
