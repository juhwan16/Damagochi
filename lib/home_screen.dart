import 'dart:async';
import 'package:flutter/material.dart';
import 'pet_model.dart';
import 'pet_widget.dart';
import 'usage_service.dart';
import 'storage_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late AnimationController _floatController;
  late AnimationController _shakeController;
  late Animation<double> _floatAnimation;
  late Animation<double> _shakeAnimation;

  int _usageMinutes = 0;
  int _goalMinutes = 60;
  int _level = 1;
  int _xp = 0;
  bool _hasPermission = false;
  bool _loading = true;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);
    _floatAnimation = Tween<double>(begin: 0, end: -10).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );

    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _shakeAnimation = Tween<double>(begin: -4, end: 4).animate(
      CurvedAnimation(parent: _shakeController, curve: Curves.elasticIn),
    );

    _init();
    _refreshTimer = Timer.periodic(
      const Duration(minutes: 5),
      (_) => _refresh(),
    );
  }

  Future<void> _init() async {
    _hasPermission = await UsageService.hasPermission();
    _goalMinutes = await StorageService.getGoalMinutes();
    _level = await StorageService.getLevel();
    _xp = await StorageService.getXp();

    if (_hasPermission) {
      _usageMinutes = await UsageService.getInstagramUsageMinutes();
      final reward = await StorageService.checkDailyReward(_usageMinutes, _goalMinutes);
      if (reward.rewarded) {
        _level = reward.level;
        _xp = reward.xp;
        if (mounted) _showRewardSnackbar();
      }
    }

    if (mounted) setState(() => _loading = false);
    _startStateAnimation();
  }

  void _startStateAnimation() {
    final pet = PetModel(
      goalMinutes: _goalMinutes,
      usageMinutes: _usageMinutes,
      level: _level,
      xp: _xp,
    );
    if (pet.state == PetState.sick) {
      _shakeController.repeat(reverse: true);
    } else {
      _shakeController.stop();
    }
  }

  Future<void> _refresh() async {
    if (!_hasPermission) return;
    final usage = await UsageService.getInstagramUsageMinutes();
    final goal = await StorageService.getGoalMinutes();
    final level = await StorageService.getLevel();
    final xp = await StorageService.getXp();
    if (mounted) {
      setState(() {
        _usageMinutes = usage;
        _goalMinutes = goal;
        _level = level;
        _xp = xp;
      });
      _startStateAnimation();
    }
  }

  void _showRewardSnackbar() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.star_rounded, color: Colors.yellow),
            SizedBox(width: 8),
            Text('목표 달성! XP +20 획득! 🎉',
                style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        backgroundColor: const Color(0xFFFF85B3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  void dispose() {
    _floatController.dispose();
    _shakeController.dispose();
    _refreshTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pet = PetModel(
      goalMinutes: _goalMinutes,
      usageMinutes: _usageMinutes,
      level: _level,
      xp: _xp,
    );

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFFCE4EC), Color(0xFFF8BBD9), Color(0xFFEDD5F5)],
          ),
        ),
        child: SafeArea(
          child: _loading
              ? const Center(
                  child: CircularProgressIndicator(color: Color(0xFFFF85B3)))
              : Column(
                  children: [
                    _buildHeader(pet),
                    Expanded(child: _buildBody(pet)),
                    if (_hasPermission) _buildStats(pet),
                    const SizedBox(height: 20),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildHeader(PetModel pet) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Lv. ${pet.level}',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFCC3366),
                ),
              ),
              const SizedBox(height: 5),
              SizedBox(
                width: 140,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: pet.xpProgress,
                    backgroundColor: Colors.white54,
                    color: const Color(0xFFFF85B3),
                    minHeight: 9,
                  ),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${pet.xp} / ${pet.xpToNextLevel} XP',
                style: const TextStyle(
                    fontSize: 11, color: Color(0xFFCC3366)),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.settings_rounded,
                color: Color(0xFFCC3366), size: 28),
            onPressed: () async {
              await Navigator.pushNamed(context, '/settings');
              _refresh();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBody(PetModel pet) {
    if (!_hasPermission) return _buildPermissionCard();

    return Center(
      child: AnimatedBuilder(
        animation: Listenable.merge([_floatAnimation, _shakeAnimation]),
        builder: (context, child) {
          final dx = pet.state == PetState.sick ? _shakeAnimation.value : 0.0;
          final dy = _floatAnimation.value;
          return Transform.translate(
            offset: Offset(dx, dy),
            child: child,
          );
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            PetWidget(state: pet.state),
            const SizedBox(height: 16),
            _buildHearts(pet),
            const SizedBox(height: 14),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.65),
                borderRadius: BorderRadius.circular(22),
              ),
              child: Text(
                pet.statusMessage,
                style: const TextStyle(
                  fontSize: 16,
                  color: Color(0xFFCC3366),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHearts(PetModel pet) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (i) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Icon(
            i < pet.healthHearts
                ? Icons.favorite_rounded
                : Icons.favorite_outline_rounded,
            color: i < pet.healthHearts
                ? const Color(0xFFFF4488)
                : Colors.pink[200],
            size: 34,
          ),
        );
      }),
    );
  }

  Widget _buildPermissionCard() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.lock_open_rounded,
                  size: 64, color: Color(0xFFFF85B3)),
              const SizedBox(height: 18),
              const Text(
                '앱 사용 시간 권한이 필요해요',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFCC3366)),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              const Text(
                '인스타그램 사용 시간을 측정하려면\n"사용 정보 접근" 권한이 필요합니다.',
                style: TextStyle(fontSize: 14, color: Colors.black54),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 26),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF85B3),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 36, vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                onPressed: () async {
                  await UsageService.requestPermission();
                  await Future.delayed(const Duration(seconds: 1));
                  final ok = await UsageService.hasPermission();
                  if (mounted) {
                    setState(() => _hasPermission = ok);
                    if (ok) _refresh();
                  }
                },
                child: const Text('권한 허용하기',
                    style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStats(PetModel pet) {
    final progress =
        _goalMinutes > 0 ? (_usageMinutes / _goalMinutes).clamp(0.0, 1.0) : 0.0;
    final overGoal = _usageMinutes >= _goalMinutes && _goalMinutes > 0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.75),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.photo_camera_rounded,
                        size: 20, color: Color(0xFFE1306C)),
                    SizedBox(width: 8),
                    Text('인스타그램 사용시간',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFCC3366))),
                  ],
                ),
                Text(
                  '${_usageMinutes}분 / ${_goalMinutes}분',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: overGoal
                        ? Colors.red[400]
                        : const Color(0xFFCC3366),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: Colors.pink[100],
                color: overGoal ? Colors.red[400] : const Color(0xFFFF85B3),
                minHeight: 10,
              ),
            ),
            if (overGoal)
              const Padding(
                padding: EdgeInsets.only(top: 6),
                child: Text(
                  '목표 시간을 초과했어요!',
                  style: TextStyle(color: Colors.red, fontSize: 12),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
