import 'dart:async';
import 'package:flutter/material.dart';
import 'pet_model.dart';
import 'pet_widget.dart';
import 'stat_bar_widget.dart';
import 'usage_service.dart';
import 'storage_service.dart';
import 'settings_screen.dart';
import 'level_up_dialog.dart';
import 'mini_game_screen.dart';

class HomeTab extends StatefulWidget {
  final int customVersion;
  const HomeTab({super.key, this.customVersion = 0});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> with TickerProviderStateMixin {
  late AnimationController _floatController;
  late AnimationController _shakeController;
  late AnimationController _pulseController;
  late Animation<double> _floatAnim;
  late Animation<double> _shakeAnim;
  late Animation<double> _pulseAnim;

  Map<String, dynamic> _data = {};
  int _usageMinutes = 0;
  bool _hasPermission = false;
  bool _loading = true;
  String? _accessoryAsset;
  Color? _characterColor;
  String _petPrefix = 'pet';
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

    _pulseController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1400))
      ..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.95, end: 1.05).animate(
        CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut));

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
    _petPrefix = await StorageService.getSvgPrefix();

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
    _pulseController.dispose();
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
        const SizedBox(height: 14),
        _buildCharacter(pet),
        const SizedBox(height: 14),
        if (_hasLowStat(pet)) ...[
          _buildLowStatWarning(pet),
          const SizedBox(height: 12),
        ],
        _buildStatsCard(pet),
        const SizedBox(height: 12),
        _buildMiniGameCard(),
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
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 10, 14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBF4).withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.pink.withValues(alpha: 0.1),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              _buildBadge(pet.level),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFFB6D9), Color(0xFFD4AAFF)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFFB6D9).withValues(alpha: 0.5),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text('Lv.${pet.level}',
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Colors.white)),
              ),
            ]),
            const SizedBox(height: 8),
            SizedBox(
              width: 170,
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Stack(children: [
                    Container(height: 10, color: Colors.pink[50]),
                    FractionallySizedBox(
                      widthFactor: pet.xpProgress.clamp(0.0, 1.0),
                      child: Container(
                        height: 10,
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Color(0xFFFFB6D9), Color(0xFFD4AAFF)],
                          ),
                        ),
                      ),
                    ),
                  ]),
                ),
                const SizedBox(height: 3),
                Text('${pet.xp} / ${pet.xpToNextLevel} XP',
                    style: const TextStyle(
                        fontSize: 11, color: Colors.black45)),
              ]),
            ),
          ]),
          Row(children: [
            _buildCoinBadge(pet.coins),
            const SizedBox(width: 2),
            IconButton(
              icon: const Icon(Icons.settings_rounded,
                  color: Color(0xFFCC3366), size: 22),
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
      ),
    );
  }

  Widget _buildMiniGameCard() {
    return GestureDetector(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => MiniGameScreen(
              petPrefix: _petPrefix,
              characterColor: _characterColor,
              accessoryAsset: _accessoryAsset,
            ),
          ),
        );
        _refresh();
      },
      child: Container(
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFFFF3E0), Color(0xFFFFE0B2)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: const Color(0xFFFFCC80), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.orange.withValues(alpha: 0.18),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFFB6D9), Color(0xFFD4AAFF)],
              ),
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Text('✏️', style: TextStyle(fontSize: 26)),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('한붓그리기 미니게임',
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF5A3210))),
              const SizedBox(height: 3),
              const Text('3가지 퍼즐 · 클리어 시 XP & 코인 획득',
                  style: TextStyle(fontSize: 12, color: Colors.black45)),
            ]),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFD4914A).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text('시작 →',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFD4914A))),
          ),
        ]),
      ),
    );
  }

  Widget _buildBadge(int level) {
    final badge = StorageService.levelBadge(level);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: badge.gradient),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: badge.gradient.last.withValues(alpha: 0.35),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Text(badge.emoji, style: const TextStyle(fontSize: 13)),
        const SizedBox(width: 4),
        Text(badge.name,
            style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.white)),
      ]),
    );
  }

  Widget _buildCoinBadge(int coins) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFF8E1), Color(0xFFFFECB3)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.amber[300]!, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.amber.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(children: [
        const Text('🪙', style: TextStyle(fontSize: 16)),
        const SizedBox(width: 4),
        Text('$coins',
            style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(0xFFCC3366),
                fontSize: 16)),
      ]),
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
          // 외부 넓은 글로우
          Container(
            width: 260,
            height: 260,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  glowColor.withValues(alpha: 0.12),
                  Colors.transparent,
                ],
                stops: const [0.4, 1.0],
              ),
            ),
          ),
          // 내부 강한 글로우
          Container(
            width: 190,
            height: 190,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  glowColor.withValues(alpha: 0.25),
                  glowColor.withValues(alpha: 0.06),
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
            petPrefix: _petPrefix,
          ),
        ]),
        const SizedBox(height: 12),
        // 하트 상태
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            5,
            (i) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                transitionBuilder: (child, anim) =>
                    ScaleTransition(scale: anim, child: child),
                child: Icon(
                  i < pet.healthHearts
                      ? Icons.favorite_rounded
                      : Icons.favorite_outline_rounded,
                  key: ValueKey('${i}_${i < pet.healthHearts}'),
                  color: i < pet.healthHearts
                      ? const Color(0xFFFF4488)
                      : Colors.pink[200],
                  size: 28,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        // 상태 메시지 버블
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.white.withValues(alpha: 0.9),
                glowColor.withValues(alpha: 0.12),
              ],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: glowColor.withValues(alpha: 0.3),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: glowColor.withValues(alpha: 0.18),
                blurRadius: 12,
                offset: const Offset(0, 3),
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
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.orange[300]!),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withValues(alpha: 0.18),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(children: [
        ScaleTransition(
          scale: _pulseAnim,
          child: const Text('⚠️', style: TextStyle(fontSize: 24)),
        ),
        const SizedBox(width: 10),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('케어가 필요해요!',
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.deepOrange,
                  fontSize: 13)),
          Text(warnings.join(' · '),
              style: const TextStyle(fontSize: 12, color: Colors.orange)),
        ]),
      ]),
    );
  }

  Widget _buildStatsCard(PetModel pet) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBF4).withValues(alpha: 0.93),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.pink.withValues(alpha: 0.09),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(children: [
        Row(children: [
          Container(
            width: 4, height: 18,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFFB6D9), Color(0xFFD4AAFF)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          const Text('상태 지표',
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFCC3366))),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFFD0E8), Color(0xFFEDD5F5)],
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '${(pet.overallHealth * 100).round()}%',
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFCC3366)),
            ),
          ),
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
      ]),
    );
  }

  Widget _buildUsageCard(PetModel pet) {
    final goal = pet.goalMinutes;
    final usage = _usageMinutes;
    final progress = goal > 0 ? (usage / goal).clamp(0.0, 1.0) : 0.0;
    final pct = (progress * 100).round();
    final over = goal > 0 && usage >= goal;
    final saved = (goal - usage).clamp(0, goal);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBF4).withValues(alpha: 0.93),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.pink.withValues(alpha: 0.09),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Row(children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: over
                      ? [Colors.red[200]!, Colors.red[400]!]
                      : [const Color(0xFFFFB6D9), const Color(0xFFE1306C)],
                ),
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Icon(Icons.photo_camera_rounded,
                    size: 17, color: Colors.white),
              ),
            ),
            const SizedBox(width: 10),
            const Text('인스타그램 사용시간',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: Color(0xFFCC3366))),
          ]),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: over ? Colors.red[50] : Colors.pink[50],
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                  color: over ? Colors.red[300]! : Colors.pink[200]!),
            ),
            child: Text('$pct%',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: over ? Colors.red : const Color(0xFFCC3366))),
          ),
        ]),
        const SizedBox(height: 14),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('${usage}분 사용',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: over ? Colors.red : Colors.black54)),
            Text('목표 ${goal}분',
                style: const TextStyle(fontSize: 13, color: Colors.black38)),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Stack(children: [
            Container(height: 16, color: Colors.pink[50]),
            FractionallySizedBox(
              widthFactor: progress,
              child: Container(
                height: 16,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: over
                        ? [Colors.red[300]!, Colors.red[600]!]
                        : [const Color(0xFFFFB6D9), const Color(0xFFFF4488)],
                  ),
                ),
              ),
            ),
          ]),
        ),
        const SizedBox(height: 10),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            decoration: BoxDecoration(
              gradient: over
                  ? LinearGradient(
                      colors: [Colors.red[100]!, Colors.red[200]!])
                  : const LinearGradient(
                      colors: [Color(0xFFDCF8DC), Color(0xFFB8EEB8)]),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: over
                      ? Colors.red.withValues(alpha: 0.15)
                      : Colors.green.withValues(alpha: 0.15),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Text(over ? '⚠️' : '✅',
                  style: const TextStyle(fontSize: 14)),
              const SizedBox(width: 6),
              Text(
                over
                    ? '목표 시간 ${usage - goal}분 초과!'
                    : '${saved}분 아꼈어요!',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: over ? Colors.red[700] : Colors.green[700]),
              ),
            ]),
          ),
        ]),
      ]),
    );
  }

  Widget _buildPermissionCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFF0F8), Color(0xFFFFE0F0)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFFFB6D9), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.pink.withValues(alpha: 0.12),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(children: [
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                  colors: [Color(0xFFFFB6D9), Color(0xFFFF85B3)]),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.phone_android_rounded,
                color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('사용 시간 권한 필요',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFCC3366),
                    fontSize: 14)),
            Text('인스타그램 사용량을 측정해요',
                style: TextStyle(fontSize: 12, color: Colors.black45)),
          ]),
        ]),
        const SizedBox(height: 14),
        GestureDetector(
          onTap: () async {
            await UsageService.requestPermission();
            await Future.delayed(const Duration(seconds: 1));
            final ok = await UsageService.hasPermission();
            if (mounted) setState(() => _hasPermission = ok);
            if (ok) _refresh();
          },
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 28, vertical: 11),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFFB6D9), Color(0xFFFF85B3)],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFF85B3).withValues(alpha: 0.4),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Text('권한 허용하기',
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15)),
          ),
        ),
      ]),
    );
  }
}
