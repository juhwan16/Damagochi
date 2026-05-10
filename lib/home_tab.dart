import 'dart:async';
import 'package:flutter/material.dart';
import 'pet_model.dart';
import 'pet_widget.dart';
import 'stat_bar_widget.dart';
import 'usage_service.dart';
import 'storage_service.dart';
import 'settings_screen.dart';
import 'level_up_dialog.dart';

class HomeTab extends StatefulWidget {
  final int customVersion;
  const HomeTab({super.key, this.customVersion = 0});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> with TickerProviderStateMixin {
  late AnimationController _floatController;
  late AnimationController _shakeController;
  late Animation<double> _floatAnim;
  late Animation<double> _shakeAnim;

  Map<String, dynamic> _data = {};
  int _usageMinutes = 0;
  bool _hasPermission = false;
  bool _loading = true;
  String? _accessoryAsset;
  Color? _characterColor;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _floatController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2200))
      ..repeat(reverse: true);
    _floatAnim = Tween<double>(begin: 0, end: -10).animate(
        CurvedAnimation(parent: _floatController, curve: Curves.easeInOut));
    _shakeController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _shakeAnim = Tween<double>(begin: -5, end: 5).animate(
        CurvedAnimation(parent: _shakeController, curve: Curves.elasticIn));

    _init();
    _timer = Timer.periodic(const Duration(minutes: 5), (_) => _refresh());
  }

  @override
  void didUpdateWidget(HomeTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.customVersion != widget.customVersion) {
      _refresh();
    }
  }

  Future<void> _init() async {
    _hasPermission = await UsageService.hasPermission();
    await _refresh();
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _refresh() async {
    _data = await StorageService.loadAll();
    final custom = await StorageService.loadCustomization();
    _accessoryAsset =
        StorageService.accessoryAsset(custom['accessory'] as String);
    _characterColor =
        StorageService.characterColor(custom['color'] as String);

    final isTestMode = await StorageService.isTestMode();
    if (isTestMode || _hasPermission || await UsageService.hasPermission()) {
      if (!isTestMode) _hasPermission = true;
      _usageMinutes = await UsageService.getInstagramUsageMinutes();
      final prevLevel = _data['level'] as int? ?? 1;
      final reward = await StorageService.checkDailyReward(
          _usageMinutes, _data['goalMinutes'] as int);
      if (reward.rewarded) {
        _data['level'] = reward.level;
        _data['xp'] = reward.xp;
        _data['coins'] = reward.coins;
        if (mounted) {
          _showReward(reward.coinBonus, reward.streak);
          if (reward.leveledUp && reward.level > prevLevel) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) showLevelUpDialog(context, reward.level);
            });
          }
        }
      }
    }

    if (mounted) {
      setState(() {});
      _updateAnimation();
    }
  }

  void _updateAnimation() {
    final pet = _makePet();
    if (pet.state == PetState.sick) {
      _shakeController.repeat(reverse: true);
    } else {
      _shakeController.stop();
      _shakeController.reset();
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

  void _showReward(int coinBonus, int streak) {
    final streakMsg = streak >= 7
        ? ' 🔥 7일 연속! 코인 2배!'
        : streak >= 3
            ? ' 🔥 ${streak}일 연속!'
            : '';
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        const Icon(Icons.star_rounded, color: Colors.yellow),
        const SizedBox(width: 8),
        Flexible(
          child: Text('목표 달성! XP +20, 코인 +$coinBonus$streakMsg 🎉',
              style: const TextStyle(fontWeight: FontWeight.bold)),
        ),
      ]),
      backgroundColor: const Color(0xFFFF85B3),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      duration: const Duration(seconds: 4),
    ));
  }

  Color _petGlowColor(PetModel pet) {
    switch (pet.state) {
      case PetState.happy:
        return const Color(0xFFFFD700);
      case PetState.normal:
        return const Color(0xFFFF85B3);
      case PetState.tired:
        return const Color(0xFFFF9944);
      case PetState.sick:
        return const Color(0xFFFF4444);
    }
  }

  @override
  void dispose() {
    _floatController.dispose();
    _shakeController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(
          child: CircularProgressIndicator(color: Color(0xFFFF85B3)));
    }
    final pet = _makePet();
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      child: Column(children: [
        _buildHeader(pet),
        const SizedBox(height: 16),
        _buildCharacter(pet),
        const SizedBox(height: 16),
        if (_hasLowStat(pet)) ...[
          _buildLowStatWarning(pet),
          const SizedBox(height: 12),
        ],
        _buildStatsCard(pet),
        const SizedBox(height: 12),
        _buildUsageCard(pet),
        if (!_hasPermission) ...[
          const SizedBox(height: 12),
          _buildPermissionCard(),
        ],
      ]),
    );
  }

  bool _hasLowStat(PetModel pet) =>
      pet.hunger < 20 || pet.happiness < 20 || pet.energy < 20;

  Widget _buildHeader(PetModel pet) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Text(pet.tierName,
                style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFCC3366))),
            const SizedBox(width: 6),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFFB6D9), Color(0xFFD4AAFF)],
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text('Lv.${pet.level}',
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Colors.white)),
            ),
          ]),
          const SizedBox(height: 6),
          SizedBox(
            width: 160,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Stack(children: [
                Container(height: 8, color: Colors.white54),
                FractionallySizedBox(
                  widthFactor: pet.xpProgress.clamp(0.0, 1.0),
                  child: Container(
                    height: 8,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                          colors: [Color(0xFFFFB6D9), Color(0xFFFF85B3)]),
                    ),
                  ),
                ),
              ]),
            ),
          ),
          const SizedBox(height: 2),
          Text('${pet.xp} / ${pet.xpToNextLevel} XP',
              style:
                  const TextStyle(fontSize: 11, color: Color(0xFFCC3366))),
        ]),
        Row(children: [
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFFF8E1), Color(0xFFFFECB3)],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.amber.withValues(alpha: 0.25),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(children: [
              const Text('🪙', style: TextStyle(fontSize: 16)),
              const SizedBox(width: 4),
              Text('${pet.coins}',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFCC3366),
                      fontSize: 16)),
            ]),
          ),
          const SizedBox(width: 4),
          IconButton(
            icon: const Icon(Icons.settings_rounded,
                color: Color(0xFFCC3366)),
            onPressed: () async {
              await Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const SettingsScreen()));
              _refresh();
            },
          ),
        ]),
      ],
    );
  }

  Widget _buildCharacter(PetModel pet) {
    final glowColor = _petGlowColor(pet);
    return AnimatedBuilder(
      animation: Listenable.merge([_floatAnim, _shakeAnim]),
      builder: (context, child) {
        final dx = pet.state == PetState.sick ? _shakeAnim.value : 0.0;
        return Transform.translate(
            offset: Offset(dx, _floatAnim.value), child: child);
      },
      child: Column(children: [
        Stack(alignment: Alignment.center, children: [
          // 상태별 글로우 원
          Container(
            width: 230,
            height: 230,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  glowColor.withValues(alpha: 0.22),
                  glowColor.withValues(alpha: 0.05),
                  Colors.transparent,
                ],
                stops: const [0.0, 0.5, 1.0],
              ),
            ),
          ),
          PetWidget(
            state: pet.state,
            accessoryAsset: _accessoryAsset,
            characterColor: _characterColor,
          ),
        ]),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            5,
            (i) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: Icon(
                  i < pet.healthHearts
                      ? Icons.favorite_rounded
                      : Icons.favorite_outline_rounded,
                  key: ValueKey('${i}_${i < pet.healthHearts}'),
                  color: i < pet.healthHearts
                      ? const Color(0xFFFF4488)
                      : Colors.pink[200],
                  size: 30,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 9),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.75),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: glowColor.withValues(alpha: 0.15),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Text(pet.statusMessage,
              style: const TextStyle(
                  fontSize: 15,
                  color: Color(0xFFCC3366),
                  fontWeight: FontWeight.w600)),
        ),
      ]),
    );
  }

  Widget _buildLowStatWarning(PetModel pet) {
    final warnings = <String>[];
    if (pet.hunger < 20) warnings.add('🍙 배고파해요');
    if (pet.happiness < 20) warnings.add('😢 외로워해요');
    if (pet.energy < 20) warnings.add('⚡ 지쳤어요');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.orange[50]!, Colors.red[50]!],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.orange[300]!),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withValues(alpha: 0.15),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(children: [
        const Text('⚠️', style: TextStyle(fontSize: 22)),
        const SizedBox(width: 10),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('케어가 필요해요!',
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.deepOrange,
                  fontSize: 13)),
          Text(warnings.join(' • '),
              style: const TextStyle(fontSize: 12, color: Colors.orange)),
        ]),
      ]),
    );
  }

  Widget _buildStatsCard(PetModel pet) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.85),
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
        StatBar(
            emoji: '🍙',
            label: '배고픔',
            value: pet.hunger,
            color: Colors.orange),
        const SizedBox(height: 14),
        StatBar(
            emoji: '😊',
            label: '행복도',
            value: pet.happiness,
            color: Colors.pink),
        const SizedBox(height: 14),
        StatBar(
            emoji: '⚡',
            label: '에너지',
            value: pet.energy,
            color: Colors.blue),
      ]),
    );
  }

  Widget _buildUsageCard(PetModel pet) {
    final goal = pet.goalMinutes;
    final usage = _usageMinutes;
    final progress = goal > 0 ? (usage / goal).clamp(0.0, 1.0) : 0.0;
    final pct = (progress * 100).round();
    final over = goal > 0 && usage >= goal;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.85),
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
          const Row(children: [
            Icon(Icons.photo_camera_rounded,
                size: 18, color: Color(0xFFE1306C)),
            SizedBox(width: 6),
            Text('인스타그램 사용시간',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFCC3366))),
          ]),
          Text('${usage}분 / ${goal}분',
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: over ? Colors.red : const Color(0xFFCC3366))),
        ]),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Stack(children: [
            Container(height: 14, color: Colors.pink[50]),
            FractionallySizedBox(
              widthFactor: progress,
              child: Container(
                height: 14,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: over
                        ? [Colors.red[300]!, Colors.red[600]!]
                        : [const Color(0xFFFFB6D9), const Color(0xFFFF85B3)],
                  ),
                ),
              ),
            ),
          ]),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              over
                  ? const Text('⚠️ 목표 시간 초과!',
                      style: TextStyle(
                          color: Colors.red,
                          fontSize: 12,
                          fontWeight: FontWeight.w600))
                  : Text('✅ 남은 시간: ${goal - usage}분',
                      style: const TextStyle(
                          color: Colors.green,
                          fontSize: 12,
                          fontWeight: FontWeight.w600)),
              Text('$pct%',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: over ? Colors.red : Colors.grey[500])),
            ],
          ),
        ),
      ]),
    );
  }

  Widget _buildPermissionCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(children: [
        const Text('📱 사용 시간 권한이 필요해요',
            style: TextStyle(
                fontWeight: FontWeight.bold, color: Color(0xFFCC3366))),
        const SizedBox(height: 8),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF85B3),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              elevation: 0),
          onPressed: () async {
            await UsageService.requestPermission();
            await Future.delayed(const Duration(seconds: 1));
            final ok = await UsageService.hasPermission();
            if (mounted) setState(() => _hasPermission = ok);
            if (ok) _refresh();
          },
          child: const Text('권한 허용하기'),
        ),
      ]),
    );
  }
}
