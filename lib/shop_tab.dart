import 'package:flutter/material.dart';
import 'storage_service.dart';

class ShopItem {
  final String emoji;
  final String name;
  final String description;
  final int cost;
  final Map<String, int> effects;

  const ShopItem({
    required this.emoji,
    required this.name,
    required this.description,
    required this.cost,
    required this.effects,
  });
}

const _items = [
  ShopItem(emoji: '🍙', name: '주먹밥', description: '배고픔 +25', cost: 10,
      effects: {'hunger': 25}),
  ShopItem(emoji: '🎂', name: '생일케이크', description: '배고픔 +45\n행복 +15', cost: 35,
      effects: {'hunger': 45, 'happiness': 15}),
  ShopItem(emoji: '🎮', name: '장난감', description: '행복 +35', cost: 25,
      effects: {'happiness': 35}),
  ShopItem(emoji: '⚡', name: '에너지드링크', description: '에너지 +40', cost: 20,
      effects: {'energy': 40}),
  ShopItem(emoji: '💊', name: '비타민', description: '모든 스탯 +20', cost: 55,
      effects: {'hunger': 20, 'happiness': 20, 'energy': 20}),
  ShopItem(emoji: '🍱', name: '프리미엄 도시락', description: '배고픔 +60\n에너지 +20', cost: 65,
      effects: {'hunger': 60, 'energy': 20}),
];

class ShopTab extends StatefulWidget {
  const ShopTab({super.key});

  @override
  State<ShopTab> createState() => _ShopTabState();
}

class _ShopTabState extends State<ShopTab> {
  int _coins = 0;

  @override
  void initState() {
    super.initState();
    _loadCoins();
  }

  Future<void> _loadCoins() async {
    final data = await StorageService.loadAll();
    if (mounted) setState(() => _coins = data['coins'] as int);
  }

  Future<void> _buy(ShopItem item) async {
    if (_coins < item.cost) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text('코인이 부족해요! 목표를 달성해서 코인을 모으세요 🪙'),
        backgroundColor: Colors.red[400],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
      return;
    }
    final ok = await StorageService.buyItem(item.cost, item.effects);
    if (ok) {
      await _loadCoins();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('${item.emoji} ${item.name} 구매 완료!',
              style: const TextStyle(fontWeight: FontWeight.bold)),
          backgroundColor: const Color(0xFFFF85B3),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      // Coin header
      Container(
        margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(18)),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          const Text('내 코인', style: TextStyle(
              fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFFCC3366))),
          Row(children: [
            const Text('🪙', style: TextStyle(fontSize: 24)),
            const SizedBox(width: 6),
            Text('$_coins',
                style: const TextStyle(
                    fontSize: 26, fontWeight: FontWeight.bold, color: Color(0xFFCC3366))),
          ]),
        ]),
      ),
      const Padding(
        padding: EdgeInsets.fromLTRB(20, 12, 20, 4),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text('💡 목표 달성 시 코인 +15 획득!',
              style: TextStyle(color: Colors.black45, fontSize: 12)),
        ),
      ),
      // Items grid
      Expanded(
        child: GridView.builder(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.85,
          ),
          itemCount: _items.length,
          itemBuilder: (context, i) => _buildItemCard(_items[i]),
        ),
      ),
    ]);
  }

  Widget _buildItemCard(ShopItem item) {
    final canAfford = _coins >= item.cost;
    return Container(
      decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
              color: canAfford ? Colors.pink[200]! : Colors.grey[300]!, width: 1.5)),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(item.emoji, style: const TextStyle(fontSize: 40)),
          const SizedBox(height: 6),
          Text(item.name,
              style: const TextStyle(
                  fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFFCC3366))),
          const SizedBox(height: 4),
          Text(item.description,
              style: const TextStyle(fontSize: 11, color: Colors.black54),
              textAlign: TextAlign.center),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: () => _buy(item),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
              decoration: BoxDecoration(
                  color: canAfford ? const Color(0xFFFF85B3) : Colors.grey[300],
                  borderRadius: BorderRadius.circular(12)),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Text('🪙', style: TextStyle(fontSize: 14)),
                const SizedBox(width: 4),
                Text('${item.cost}',
                    style: TextStyle(
                        color: canAfford ? Colors.white : Colors.grey[600],
                        fontWeight: FontWeight.bold,
                        fontSize: 14)),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}
