import 'package:flutter/material.dart';
import 'storage_service.dart';
import 'usage_service.dart';
import 'pet_model.dart';

class RankingTab extends StatefulWidget {
  final int refreshTrigger;
  const RankingTab({super.key, this.refreshTrigger = 0});

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

  @override
  void didUpdateWidget(RankingTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.refreshTrigger != widget.refreshTrigger) {
      _load();
    }
  }

  Future<void> _load() async {
    if (mounted) setState(() => _loading = true);
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
      return const Center(
          child: CircularProgressIndicator(color: Color(0xFFFF85B3)));
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
        _buildAchievements(totalDays, pet.level, streak, pet.coins),
      ]),
    );
  }

  Widget _buildTierCard(PetModel pet) {
    final progress = pet.xpProgress.clamp(0.0, 1.0);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFB6D9), Color(0xFFD4AAFF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFFB6D9).withValues(alpha: 0.5),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(children: [
        Text(pet.tierName, style: const TextStyle(fontSize: 36)),
        const SizedBox(height: 6),
        Text('Lv.${pet.level}',
            style: const TextStyle(
                fontSize: 30, fontWeight: FontWeight.bold, color: Colors.white)),
        const SizedBox(height: 4),
        Text('${pet.xp} / ${pet.xpToNextLevel} XP',
            style: const TextStyle(color: Colors.white70, fontSize: 14)),
        const SizedBox(height: 14),
        Stack(children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Container(height: 12, color: Colors.white30),
          ),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: FractionallySizedBox(
              widthFactor: progress,
              child: Container(
                height: 12,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.white70, Colors.white],
                  ),
                ),
              ),
            ),
          ),
        ]),
        const SizedBox(height: 6),
        Text('다음 레벨까지 ${pet.xpToNextLevel - pet.xp} XP',
            style: const TextStyle(color: Colors.white60, fontSize: 12)),
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
        color: const Color(0xFFFFFBF4).withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.pink.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            gradient: streak > 0
                ? const LinearGradient(
                    colors: [Color(0xFFFFB6D9), Color(0xFFFF85B3)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            color: streak == 0 ? Colors.grey[200] : null,
            shape: BoxShape.circle,
            boxShadow: streak > 0
                ? [
                    BoxShadow(
                      color: const Color(0xFFFF85B3).withValues(alpha: 0.4),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    )
                  ]
                : null,
          ),
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
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFCC3366))),
            Text(message,
                style: const TextStyle(color: Colors.black54, fontSize: 13)),
          ]),
        ),
        if (streak >= 3)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFFF3C0), Color(0xFFFFE082)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.amber[400]!),
              boxShadow: [
                BoxShadow(
                  color: Colors.amber.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(children: [
              const Text('코인 보너스',
                  style: TextStyle(fontSize: 10, color: Colors.brown)),
              Text(streak >= 7 ? '🪙 ×2' : '🪙 ×1.5',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.deepOrange,
                      fontSize: 14)),
            ]),
          ),
      ]),
    );
  }

  Widget _buildStatsGrid(int totalDays, int savedMinutes, PetModel pet) {
    final items = [
      _StatItem('📅', '누적 달성일', '${totalDays}일', const Color(0xFFFFB6D9)),
      _StatItem('⏰', '오늘 절약 시간', '${savedMinutes}분', const Color(0xFFD4AAFF)),
      _StatItem('🪙', '보유 코인', '${pet.coins}개', const Color(0xFFFFE082)),
      _StatItem('❤️', '현재 체력', '${(pet.overallHealth * 100).round()}%',
          const Color(0xFFFF85B3)),
    ];

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.6,
      children: items
          .map((item) => Container(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: item.accent.withValues(alpha: 0.25),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                  border: Border.all(
                    color: item.accent.withValues(alpha: 0.3),
                    width: 1.5,
                  ),
                ),
                child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(item.emoji,
                          style: const TextStyle(fontSize: 26)),
                      const SizedBox(height: 4),
                      Text(item.label,
                          style: const TextStyle(
                              color: Colors.black45, fontSize: 12)),
                      Text(item.value,
                          style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFCC3366))),
                    ]),
              ))
          .toList(),
    );
  }

  Widget _buildAchievements(int totalDays, int level, int streak, int coins) {
    final badges = [
      _Badge('🌱', '첫걸음', '처음 목표 달성', totalDays >= 1, _prog(totalDays, 1)),
      _Badge('🔥', '3일 연속', '3일 연속 달성', streak >= 3, _prog(streak, 3)),
      _Badge('🌊', '5일 연속', '5일 연속 달성', streak >= 5, _prog(streak, 5)),
      _Badge('⭐', '일주일', '7일 달성', totalDays >= 7, _prog(totalDays, 7)),
      _Badge('💎', '연속 7일', '7일 연속 달성', streak >= 7, _prog(streak, 7)),
      _Badge('🌟', '레벨 5', 'Lv.5 달성', level >= 5, _prog(level, 5)),
      _Badge('👑', '레벨 10', 'Lv.10 달성', level >= 10, _prog(level, 10)),
      _Badge('💫', '레벨 20', 'Lv.20 달성', level >= 20, _prog(level, 20)),
      _Badge('🏆', '한달', '30일 달성', totalDays >= 30, _prog(totalDays, 30)),
      _Badge('🚀', '50일', '50일 달성', totalDays >= 50, _prog(totalDays, 50)),
      _Badge('🎖️', '100일', '100일 달성', totalDays >= 100, _prog(totalDays, 100)),
      _Badge('🪙', '코인 부자', '300코인 보유', coins >= 300, _prog(coins, 300)),
    ];

    final achieved = badges.where((b) => b.achieved).length;

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
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Row(children: [
            Container(
              width: 4, height: 18,
              decoration: BoxDecoration(
                color: const Color(0xFFFF85B3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 8),
            const Text('업적',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFCC3366))),
          ]),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFFD0E8), Color(0xFFEDD5F5)],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text('$achieved / ${badges.length}',
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFCC3366),
                    fontSize: 13)),
          ),
        ]),
        const SizedBox(height: 16),
        GridView.count(
          crossAxisCount: 3,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 0.85,
          children: badges.map((b) => _buildBadge(b)).toList(),
        ),
      ]),
    );
  }

  Widget _buildBadge(_Badge b) {
    if (b.achieved) {
      return Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: const LinearGradient(
            colors: [Color(0xFFFFB6D9), Color(0xFFD4AAFF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFF85B3).withValues(alpha: 0.35),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(2),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.pink[50],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Stack(children: [
              Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(width: double.infinity),
                    Text(b.emoji,
                        style: const TextStyle(fontSize: 28)),
                    const SizedBox(height: 3),
                    Text(b.name,
                        style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFCC3366)),
                        textAlign: TextAlign.center),
                    Text(b.desc,
                        style: TextStyle(
                            fontSize: 9, color: Colors.grey[500]),
                        textAlign: TextAlign.center),
                  ]),
              Positioned(
                top: 4,
                right: 4,
                child: Container(
                  width: 16,
                  height: 16,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFF85B3),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check,
                      size: 11, color: Colors.white),
                ),
              ),
            ]),
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey[300]!, width: 1.5),
      ),
      child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(b.emoji,
                style: const TextStyle(
                    fontSize: 26, color: Color(0x55000000))),
            const SizedBox(height: 3),
            Text(b.name,
                style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey),
                textAlign: TextAlign.center),
            Text(b.desc,
                style: TextStyle(fontSize: 9, color: Colors.grey[400]),
                textAlign: TextAlign.center),
            if (b.progress > 0)
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: b.progress,
                    backgroundColor: Colors.grey[300],
                    color: const Color(0xFFFF85B3),
                    minHeight: 4,
                  ),
                ),
              ),
          ]),
    );
  }

  double _prog(int current, int target) =>
      (current / target).clamp(0.0, 1.0);
}

class _StatItem {
  final String emoji, label, value;
  final Color accent;
  const _StatItem(this.emoji, this.label, this.value, this.accent);
}

class _Badge {
  final String emoji, name, desc;
  final bool achieved;
  final double progress;
  const _Badge(this.emoji, this.name, this.desc, this.achieved, this.progress);
}
