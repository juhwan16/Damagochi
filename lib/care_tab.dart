import 'dart:async';
import 'package:flutter/material.dart';
import 'pet_model.dart';
import 'pet_widget.dart';
import 'stat_bar_widget.dart';
import 'storage_service.dart';
import 'usage_service.dart';
import 'level_up_dialog.dart';

class CareTab extends StatefulWidget {
  final int customVersion;
  const CareTab({super.key, this.customVersion = 0});

  @override
  State<CareTab> createState() => _CareTabState();
}

class _CareTabState extends State<CareTab> {
  Map<String, dynamic> _data = {};
  int _usageMinutes = 0;
  bool _loading = true;
  int _currentLevel = 1;
  String? _accessoryAsset;
  Color? _characterColor;
  String _petPrefix = 'pet';

  Map<String, int> _cooldowns = {
    'feed': 0,
    'play': 0,
    'sleep': 0,
    'clean': 0,
    'special_snack': 0,
    'spa': 0,
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
  void didUpdateWidget(CareTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.customVersion != widget.customVersion) {
      _refresh();
    }
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
    _accessoryAsset =
        StorageService.accessoryAsset(custom['accessory'] as String);
    _characterColor =
        StorageService.characterColor(custom['color'] as String);
    _petPrefix = await StorageService.getSvgPrefix();

    final feeds = <String, int>{};
    for (final action in ['feed', 'play', 'sleep', 'clean', 'special_snack', 'spa']) {
      feeds[action] = await StorageService.getCooldownRemaining(action);
    }

    if (mounted) {
      setState(() {
        _loading = false;
        _currentLevel = _data['level'] ?? 1;
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

  Future<void> _handleCare(
      String actionKey,
      Future<CareResult> Function() action,
      String label) async {
    final result = await action();
    if (result.onCooldown) {
      _snack('⏰ 아직 쿨타임이에요! ${_fmtCooldown(result.remainingMs)} 남았어요',
          isWarning: true);
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
      backgroundColor:
          isWarning ? Colors.orange[700] : const Color(0xFFFF85B3),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      duration: const Duration(seconds: 2),
    ));
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(
          child: CircularProgressIndicator(color: Color(0xFFFF85B3)));
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
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white.withValues(alpha: 0.9),
            Colors.pink[50]!.withValues(alpha: 0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.pink.withValues(alpha: 0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(children: [
        PetWidget(
          state: pet.state,
          size: 150,
          accessoryAsset: _accessoryAsset,
          characterColor: _characterColor,
          petPrefix: _petPrefix,
        ),
        const SizedBox(height: 8),
        Text(pet.statusMessage,
            style: const TextStyle(
                fontSize: 14,
                color: Color(0xFFCC3366),
                fontWeight: FontWeight.w600)),
      ]),
    );
  }

  Widget _buildStatsCard(PetModel pet) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBF4).withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.pink.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(children: [
        Row(children: [
          Container(
            width: 4, height: 18,
            decoration: BoxDecoration(
              color: const Color(0xFFFF85B3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          const Text('현재 상태',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFCC3366))),
        ]),
        const SizedBox(height: 16),
        StatBar(
            emoji: '🍙', label: '배고픔', value: pet.hunger, color: Colors.orange),
        const SizedBox(height: 14),
        StatBar(
            emoji: '😊', label: '행복도', value: pet.happiness, color: Colors.pink),
        const SizedBox(height: 14),
        StatBar(
            emoji: '⚡', label: '에너지', value: pet.energy, color: Colors.blue),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFFFD0E8), Color(0xFFEDD5F5)],
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Text('전체 건강도',
                style: TextStyle(
                    color: Color(0xFFCC3366), fontWeight: FontWeight.w600)),
            const SizedBox(width: 10),
            Text('${(pet.overallHealth * 100).round()}%',
                style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFFF4488))),
          ]),
        ),
      ]),
    );
  }

  Widget _buildCareButtons() {
    final actions = [
      _Action('🍙', '밥주기', '배고픔 +25 · +3XP', 'feed', '🍙 맛있게 먹었어요!',
          [const Color(0xFFFFF0C8), const Color(0xFFFFD080)], StorageService.feed),
      _Action('🎮', '놀아주기', '행복 +20 · +5XP', 'play', '🎮 신나게 놀았어요!',
          [const Color(0xFFFFE0F0), const Color(0xFFFFB6D9)], StorageService.play),
      _Action('💤', '재우기', '에너지 +35 · +4XP', 'sleep', '💤 푹 잤어요!',
          [const Color(0xFFDCEEFF), const Color(0xFFB0D4F8)], StorageService.sleep),
      _Action('🛁', '씻기기', '행복 +10 · +3XP', 'clean', '🛁 깨끗해졌어요!',
          [const Color(0xFFDCF5DC), const Color(0xFFB0E0B0)], StorageService.clean),
      _Action('🍰', '특별 간식', '배고픔 +50\n행복 +20 · +10XP', 'special_snack', '🍰 특별 간식을 먹었어요!',
          [const Color(0xFFFFE0B2), const Color(0xFFFFCC80)], StorageService.specialSnack, requiredLevel: 5),
      _Action('🧖', '스파', '행복 +50\n에너지 +30 · +15XP', 'spa', '🧖 스파를 즐겼어요!',
          [const Color(0xFFE0F7FA), const Color(0xFFB2EBF2)], StorageService.spa, requiredLevel: 10),
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
        final isLocked = _currentLevel < a.requiredLevel;

        if (isLocked) {
          return Container(
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: Colors.grey[200]!, width: 1.5),
            ),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Text(a.emoji, style: const TextStyle(fontSize: 36, color: Color(0x44000000))),
              const SizedBox(height: 5),
              Text(a.label, style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.grey[400])),
              const SizedBox(height: 4),
              Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.lock_rounded, size: 12, color: Colors.grey[400]),
                const SizedBox(width: 3),
                Text('Lv.${a.requiredLevel} 해금', style: TextStyle(fontSize: 11, color: Colors.grey[400])),
              ]),
            ]),
          );
        }

        return GestureDetector(
          onTap: () => _handleCare(a.key, a.action, a.successMsg),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            decoration: BoxDecoration(
              gradient: onCooldown
                  ? null
                  : LinearGradient(
                      colors: a.gradient,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
              color: onCooldown ? const Color(0xFFF5F5F5) : null,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: onCooldown
                    ? Colors.grey[200]!
                    : a.gradient.last.withValues(alpha: 0.5),
                width: 1.5,
              ),
              boxShadow: onCooldown
                  ? null
                  : [
                      BoxShadow(
                        color: a.gradient.last.withValues(alpha: 0.35),
                        blurRadius: 12,
                        offset: const Offset(0, 5),
                      ),
                    ],
            ),
            child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(a.emoji,
                      style: TextStyle(
                          fontSize: 36,
                          color: onCooldown
                              ? const Color(0x44000000)
                              : null)),
                  const SizedBox(height: 5),
                  Text(a.label,
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: onCooldown
                              ? Colors.grey[400]
                              : const Color(0xFFCC3366))),
                  const SizedBox(height: 3),
                  onCooldown
                      ? Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.timer_outlined,
                                size: 11, color: Colors.grey[400]),
                            const SizedBox(width: 3),
                            Text(_fmtCooldown(cd),
                                style: TextStyle(
                                    fontSize: 11, color: Colors.grey[400])),
                          ],
                        )
                      : Text(a.sub,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              fontSize: 11, color: Colors.black45)),
                ]),
          ),
        );
      }).toList(),
    );
  }
}

class _Action {
  final String emoji, label, sub, key, successMsg;
  final List<Color> gradient;
  final Future<CareResult> Function() action;
  final int requiredLevel;
  const _Action(this.emoji, this.label, this.sub, this.key, this.successMsg,
      this.gradient, this.action, {this.requiredLevel = 1});
}
