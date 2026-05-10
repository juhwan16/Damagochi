import 'package:flutter/material.dart';
import 'storage_service.dart';
import 'usage_service.dart';
import 'pet_model.dart';

class RankingTab extends StatefulWidget {
  const RankingTab({super.key});

  @override
  State<RankingTab> createState() => _RankingTabState();
}

class _RankingTabState extends State<RankingTab> {
  Map<String, dynamic> _data = {};
  int _usageMinutes = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
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

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFFFF85B3)));
    }
    final pet = _makePet();
    final streak = _data['streak'] as int? ?? 0;
    final totalDays = _data['totalDays'] as int? ?? 0;
    final savedMinutes = _data['goalMinutes'] as int > 0
        ? ((_data['goalMinutes'] as int) - _usageMinutes).clamp(0, 9999)
        : 0;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      child: Column(children: [
        _buildTierCard(pet),
        const SizedBox(height: 14),
        _buildStreakCard(streak),
        const SizedBox(height: 14),
        _buildStatsGrid(totalDays, savedMinutes, pet),
        const SizedBox(height: 14),
        _buildAchievements(totalDays, pet.level, streak),
      ]),
    );
  }

  Widget _buildTierCard(PetModel pet) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
          gradient: const LinearGradient(
              colors: [Color(0xFFFFB6D9), Color(0xFFD4AAFF)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight),
          borderRadius: BorderRadius.circular(22)),
      child: Column(children: [
        Text(pet.tierName, style: const TextStyle(fontSize: 32)),
        const SizedBox(height: 6),
        Text('Lv.${pet.level}',
            style: const TextStyle(
                fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
        const SizedBox(height: 4),
        Text('${pet.xp} / ${pet.xpToNextLevel} XP',
            style: const TextStyle(color: Colors.white70, fontSize: 14)),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: pet.xpProgress,
            backgroundColor: Colors.white30,
            color: Colors.white,
            minHeight: 10,
          ),
        ),
      ]),
    );
  }

  Widget _buildStreakCard(int streak) {
    final message = streak == 0
        ? '오늘부터 시작해보세요!'
        : streak < 3
            ? '좋은 시작이에요!'
            : streak < 7
                ? '잘하고 있어요! 🔥'
                : '대단해요! 연속 달성 중 🏆';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(20)),
      child: Row(children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
              color: streak > 0 ? const Color(0xFFFF85B3) : Colors.grey[200],
              shape: BoxShape.circle),
          child: Center(
            child: Text(streak > 0 ? '🔥' : '💧',
                style: const TextStyle(fontSize: 28)),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('연속 달성',
                style: TextStyle(color: Colors.black45, fontSize: 13)),
            Text('${streak}일 연속',
                style: const TextStyle(
                    fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFFCC3366))),
            Text(message,
                style: const TextStyle(color: Colors.black54, fontSize: 13)),
          ]),
        ),
      ]),
    );
  }

  Widget _buildStatsGrid(int totalDays, int savedMinutes, PetModel pet) {
    final items = [
      _StatItem('📅', '누적 달성일', '${totalDays}일'),
      _StatItem('⏰', '오늘 절약 시간', '${savedMinutes}분'),
      _StatItem('🪙', '보유 코인', '${pet.coins}개'),
      _StatItem('❤️', '현재 체력', '${(pet.overallHealth * 100).round()}%'),
    ];

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.6,
      children: items.map((item) => Container(
        decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(16)),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Text(item.emoji, style: const TextStyle(fontSize: 24)),
          const SizedBox(height: 4),
          Text(item.label, style: const TextStyle(color: Colors.black45, fontSize: 12)),
          Text(item.value,
              style: const TextStyle(
                  fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFFCC3366))),
        ]),
      )).toList(),
    );
  }

  Widget _buildAchievements(int totalDays, int level, int streak) {
    final badges = [
      _Badge('🌱', '첫걸음', '처음 목표 달성', totalDays >= 1),
      _Badge('🔥', '3일 연속', '3일 연속 달성', streak >= 3),
      _Badge('⭐', '일주일', '7일 달성', totalDays >= 7),
      _Badge('🏆', '한달', '30일 달성', totalDays >= 30),
      _Badge('👑', '레벨 10', 'Lv.10 달성', level >= 10),
      _Badge('💎', '연속 7일', '7일 연속 달성', streak >= 7),
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(20)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('업적',
            style: TextStyle(
                fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFFCC3366))),
        const SizedBox(height: 14),
        GridView.count(
          crossAxisCount: 3,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 0.9,
          children: badges.map((b) => Container(
            decoration: BoxDecoration(
                color: b.achieved
                    ? Colors.pink[50]
                    : Colors.grey[100],
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                    color: b.achieved ? const Color(0xFFFF85B3) : Colors.grey[300]!,
                    width: 1.5)),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Text(b.emoji,
                  style: TextStyle(
                      fontSize: 28,
                      color: b.achieved ? null : const Color(1728053247))),
              const SizedBox(height: 4),
              Text(b.name,
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: b.achieved ? const Color(0xFFCC3366) : Colors.grey),
                  textAlign: TextAlign.center),
              Text(b.desc,
                  style: TextStyle(fontSize: 9, color: Colors.grey[500]),
                  textAlign: TextAlign.center),
            ]),
          )).toList(),
        ),
      ]),
    );
  }
}

class _StatItem {
  final String emoji, label, value;
  const _StatItem(this.emoji, this.label, this.value);
}

class _Badge {
  final String emoji, name, desc;
  final bool achieved;
  const _Badge(this.emoji, this.name, this.desc, this.achieved);
}
