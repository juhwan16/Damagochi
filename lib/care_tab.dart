import 'package:flutter/material.dart';
import 'pet_model.dart';
import 'pet_widget.dart';
import 'stat_bar_widget.dart';
import 'storage_service.dart';
import 'usage_service.dart';

class CareTab extends StatefulWidget {
  const CareTab({super.key});

  @override
  State<CareTab> createState() => _CareTabState();
}

class _CareTabState extends State<CareTab> {
  Map<String, dynamic> _data = {};
  int _usageMinutes = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    _data = await StorageService.loadAll();
    _usageMinutes = await UsageService.getInstagramUsageMinutes();
    if (mounted) setState(() => _loading = false);
  }

  PetModel _makePet() => PetModel(
        goalMinutes: _data['goalMinutes'] ?? 60,
        usageMinutes: _usageMinutes,
        level: _data['level'] ?? 1,
        xp: _data['xp'] ?? 0,
        hunger: _data['hunger'] ?? 80,
        happiness: _data['happiness'] ?? 80,
        energy: _data['energy'] ?? 80,
        coins: _data['coins'] ?? 0,
      );

  Future<void> _doAction(Future<void> Function() action, String message) async {
    await action();
    await _refresh();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(message,
            style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFFFF85B3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFFFF85B3)));
    }
    final pet = _makePet();

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      child: Column(children: [
        _buildPetPreview(pet),
        const SizedBox(height: 16),
        _buildStatsCard(pet),
        const SizedBox(height: 16),
        _buildCareButtons(),
      ]),
    );
  }

  Widget _buildPetPreview(PetModel pet) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(20)),
      child: Column(children: [
        PetWidget(state: pet.state, size: 160),
        const SizedBox(height: 8),
        Text(pet.statusMessage,
            style: const TextStyle(
                fontSize: 14, color: Color(0xFFCC3366), fontWeight: FontWeight.w600)),
      ]),
    );
  }

  Widget _buildStatsCard(PetModel pet) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.75),
          borderRadius: BorderRadius.circular(20)),
      child: Column(children: [
        const Align(
          alignment: Alignment.centerLeft,
          child: Text('현재 상태',
              style: TextStyle(
                  fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFFCC3366))),
        ),
        const SizedBox(height: 16),
        StatBar(emoji: '🍙', label: '배고픔', value: pet.hunger, color: Colors.orange),
        const SizedBox(height: 14),
        StatBar(emoji: '😊', label: '행복도', value: pet.happiness, color: Colors.pink),
        const SizedBox(height: 14),
        StatBar(emoji: '⚡', label: '에너지', value: pet.energy, color: Colors.blue),
        const SizedBox(height: 14),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('전체 건강도: ', style: TextStyle(color: Color(0xFFCC3366), fontWeight: FontWeight.w600)),
            Text('${(pet.overallHealth * 100).round()}%',
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFFFF4488))),
          ],
        ),
      ]),
    );
  }

  Widget _buildCareButtons() {
    final actions = [
      _CareAction(emoji: '🍙', label: '밥주기', sub: '배고픔 +25', color: Colors.orange[100]!,
          onTap: () => _doAction(StorageService.feed, '🍙 맛있게 먹었어요! 배고픔 +25')),
      _CareAction(emoji: '🎮', label: '놀아주기', sub: '행복 +20', color: Colors.pink[100]!,
          onTap: () => _doAction(StorageService.play, '🎮 신나게 놀았어요! 행복 +20')),
      _CareAction(emoji: '💤', label: '재우기', sub: '에너지 +35', color: Colors.blue[100]!,
          onTap: () => _doAction(StorageService.sleep, '💤 푹 잤어요! 에너지 +35')),
      _CareAction(emoji: '🛁', label: '씻기기', sub: '행복 +10', color: Colors.green[100]!,
          onTap: () => _doAction(StorageService.clean, '🛁 깨끗해졌어요! 행복 +10')),
    ];

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.3,
      children: actions.map((a) => _buildActionButton(a)).toList(),
    );
  }

  Widget _buildActionButton(_CareAction action) {
    return GestureDetector(
      onTap: action.onTap,
      child: Container(
        decoration: BoxDecoration(
            color: action.color.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white54, width: 2)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(action.emoji, style: const TextStyle(fontSize: 36)),
            const SizedBox(height: 6),
            Text(action.label,
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFFCC3366))),
            Text(action.sub,
                style: const TextStyle(fontSize: 12, color: Colors.black54)),
          ],
        ),
      ),
    );
  }
}

class _CareAction {
  final String emoji;
  final String label;
  final String sub;
  final Color color;
  final VoidCallback onTap;
  const _CareAction({
    required this.emoji,
    required this.label,
    required this.sub,
    required this.color,
    required this.onTap,
  });
}
