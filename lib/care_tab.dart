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
  String? _accessoryAsset;
  Color? _characterColor;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    _data = await StorageService.loadAll();
    _usageMinutes = await UsageService.getInstagramUsageMinutes();
    final custom = await StorageService.loadCustomization();
    _accessoryAsset = StorageService.accessoryAsset(custom['accessory'] as String);
    _characterColor = StorageService.characterColor(custom['color'] as String);
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
        content: Text(message, style: const TextStyle(fontWeight: FontWeight.bold)),
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
        _buildPreview(pet),
        const SizedBox(height: 16),
        _buildStatsCard(pet),
        const SizedBox(height: 16),
        _buildCareButtons(),
      ]),
    );
  }

  Widget _buildPreview(PetModel pet) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(20)),
      child: Column(children: [
        PetWidget(
          state: pet.state,
          size: 160,
          accessoryAsset: _accessoryAsset,
          characterColor: _characterColor,
        ),
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
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFFCC3366))),
        ),
        const SizedBox(height: 16),
        StatBar(emoji: '🍙', label: '배고픔', value: pet.hunger, color: Colors.orange),
        const SizedBox(height: 14),
        StatBar(emoji: '😊', label: '행복도', value: pet.happiness, color: Colors.pink),
        const SizedBox(height: 14),
        StatBar(emoji: '⚡', label: '에너지', value: pet.energy, color: Colors.blue),
        const SizedBox(height: 14),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Text('전체 건강도: ',
              style: TextStyle(color: Color(0xFFCC3366), fontWeight: FontWeight.w600)),
          Text('${(pet.overallHealth * 100).round()}%',
              style: const TextStyle(
                  fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFFFF4488))),
        ]),
      ]),
    );
  }

  Widget _buildCareButtons() {
    final actions = [
      _Action('🍙', '밥주기', '배고픔 +25', Colors.orange[100]!,
          () => _doAction(StorageService.feed, '🍙 맛있게 먹었어요! 배고픔 +25')),
      _Action('🎮', '놀아주기', '행복 +20', Colors.pink[100]!,
          () => _doAction(StorageService.play, '🎮 신나게 놀았어요! 행복 +20')),
      _Action('💤', '재우기', '에너지 +35', Colors.blue[100]!,
          () => _doAction(StorageService.sleep, '💤 푹 잤어요! 에너지 +35')),
      _Action('🛁', '씻기기', '행복 +10', Colors.green[100]!,
          () => _doAction(StorageService.clean, '🛁 깨끗해졌어요! 행복 +10')),
    ];

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.3,
      children: actions.map((a) => GestureDetector(
        onTap: a.onTap,
        child: Container(
          decoration: BoxDecoration(
              color: a.color.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.white54, width: 2)),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Text(a.emoji, style: const TextStyle(fontSize: 36)),
            const SizedBox(height: 6),
            Text(a.label,
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFFCC3366))),
            Text(a.sub, style: const TextStyle(fontSize: 12, color: Colors.black54)),
          ]),
        ),
      )).toList(),
    );
  }
}

class _Action {
  final String emoji, label, sub;
  final Color color;
  final VoidCallback onTap;
  const _Action(this.emoji, this.label, this.sub, this.color, this.onTap);
}
