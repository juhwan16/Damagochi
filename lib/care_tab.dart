import 'dart:async';
import 'package:flutter/material.dart';
import 'pet_model.dart';
import 'pet_widget.dart';
import 'stat_bar_widget.dart';
import 'storage_service.dart';
import 'usage_service.dart';
import 'level_up_dialog.dart';

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

  // 쿨다운: 남은 시간(ms) — 매 초 감소
  Map<String, int> _cooldowns = {
    'feed': 0,
    'play': 0,
    'sleep': 0,
    'clean': 0,
  };
  Timer? _cooldownTimer;

  @override
  void initState() {
    super.initState();
    _refresh();
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {
        for (final k in _cooldowns.keys) {
          _cooldowns[k] = (_cooldowns[k]! - 1000).clamp(0, _cooldowns[k]!);
        }
      });
    });
  }

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    super.dispose();
  }

  Future<void> _refresh() async {
    _data = await StorageService.loadAll();
    _usageMinutes = await UsageService.getInstagramUsageMinutes();
    final custom = await StorageService.loadCustomization();
    _accessoryAsset = StorageService.accessoryAsset(custom['accessory'] as String);
    _characterColor = StorageService.characterColor(custom['color'] as String);

    final feeds = <String, int>{};
    for (final action in ['feed', 'play', 'sleep', 'clean']) {
      feeds[action] = await StorageService.getCooldownRemaining(action);
    }

    if (mounted) {
      setState(() {
        _loading = false;
        _cooldowns = feeds;
      });
    }
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

  Future<void> _handleCare(String actionKey, Future<CareResult> Function() action, String label) async {
    final result = await action();
    if (result.onCooldown) {
      _snack('⏰ 아직 쿨타임이에요! ${_fmtCooldown(result.remainingMs)} 남았어요', isWarning: true);
      return;
    }
    setState(() => _cooldowns[actionKey] = 0);
    await _refresh();
    if (!mounted) return;
    _snack('$label  +${result.xpGained}XP 🌟  +${result.coinsGained}🪙');
    if (result.leveledUp) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) showLevelUpDialog(context, result.newLevel);
      });
    }
  }

  String _fmtCooldown(int ms) {
    if (ms <= 0) return '';
    final total = ms ~/ 1000;
    final h = total ~/ 3600;
    final m = (total % 3600) ~/ 60;
    final s = total % 60;
    if (h > 0) return '${h}시간 ${m}분';
    if (m > 0) return '${m}분 ${s}초';
    return '${s}초';
  }

  void _snack(String msg, {bool isWarning = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: const TextStyle(fontWeight: FontWeight.bold)),
      backgroundColor: isWarning ? Colors.orange[700] : const Color(0xFFFF85B3),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      duration: const Duration(seconds: 2),
    ));
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
      _Action('🍙', '밥주기', '배고픔 +25', 'feed', '배고픔 +25  +3XP  +1🪙',
          Colors.orange[100]!, StorageService.feed),
      _Action('🎮', '놀아주기', '행복 +20', 'play', '행복 +20  +5XP  +2🪙',
          Colors.pink[100]!, StorageService.play),
      _Action('💤', '재우기', '에너지 +35', 'sleep', '에너지 +35  +4XP  +1🪙',
          Colors.blue[100]!, StorageService.sleep),
      _Action('🛁', '씻기기', '행복 +10', 'clean', '행복 +10  +3XP  +1🪙',
          Colors.green[100]!, StorageService.clean),
    ];

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.15,
      children: actions.map((a) {
        final cd = _cooldowns[a.key] ?? 0;
        final onCooldown = cd > 0;
        return GestureDetector(
          onTap: () => _handleCare(a.key, a.action, a.successMsg),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
                color: onCooldown
                    ? Colors.grey[100]!.withValues(alpha: 0.9)
                    : a.color.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                    color: onCooldown ? Colors.grey[300]! : Colors.white54,
                    width: 2)),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Text(a.emoji,
                  style: TextStyle(
                      fontSize: 34,
                      color: onCooldown ? const Color(0x88000000) : null)),
              const SizedBox(height: 5),
              Text(a.label,
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: onCooldown
                          ? Colors.grey[500]
                          : const Color(0xFFCC3366))),
              const SizedBox(height: 2),
              onCooldown
                  ? Text(_fmtCooldown(cd),
                      style: const TextStyle(fontSize: 11, color: Colors.grey))
                  : Text(a.sub,
                      style: const TextStyle(fontSize: 11, color: Colors.black54)),
            ]),
          ),
        );
      }).toList(),
    );
  }
}

class _Action {
  final String emoji, label, sub, key, successMsg;
  final Color color;
  final Future<CareResult> Function() action;
  const _Action(this.emoji, this.label, this.sub, this.key, this.successMsg,
      this.color, this.action);
}
