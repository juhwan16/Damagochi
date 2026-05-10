import 'dart:async';
import 'package:flutter/material.dart';
import 'pet_model.dart';
import 'pet_widget.dart';
import 'stat_bar_widget.dart';
import 'usage_service.dart';
import 'storage_service.dart';
import 'settings_screen.dart';

class HomeTab extends StatefulWidget {
  const HomeTab({super.key});

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
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _floatController =
        AnimationController(vsync: this, duration: const Duration(milliseconds: 2200))
          ..repeat(reverse: true);
    _floatAnim = Tween<double>(begin: 0, end: -10).animate(
        CurvedAnimation(parent: _floatController, curve: Curves.easeInOut));

    _shakeController =
        AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _shakeAnim = Tween<double>(begin: -5, end: 5).animate(
        CurvedAnimation(parent: _shakeController, curve: Curves.elasticIn));

    _init();
    _timer = Timer.periodic(const Duration(minutes: 5), (_) => _refresh());
  }

  Future<void> _init() async {
    _hasPermission = await UsageService.hasPermission();
    _data = await StorageService.loadAll();
    if (_hasPermission) {
      _usageMinutes = await UsageService.getInstagramUsageMinutes();
      final reward = await StorageService.checkDailyReward(
          _usageMinutes, _data['goalMinutes'] as int);
      if (reward.rewarded) {
        _data['level'] = reward.level;
        _data['xp'] = reward.xp;
        _data['coins'] = reward.coins;
        if (mounted) _showReward();
      }
    }
    if (mounted) setState(() => _loading = false);
    _updateAnimation();
  }

  Future<void> _refresh() async {
    _data = await StorageService.loadAll();
    if (_hasPermission) {
      _usageMinutes = await UsageService.getInstagramUsageMinutes();
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

  void _showReward() {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: const Row(children: [
        Icon(Icons.star_rounded, color: Colors.yellow),
        SizedBox(width: 8),
        Text('목표 달성! XP +20, 코인 +15 🎉',
            style: TextStyle(fontWeight: FontWeight.bold)),
      ]),
      backgroundColor: const Color(0xFFFF85B3),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      duration: const Duration(seconds: 3),
    ));
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
      return const Center(child: CircularProgressIndicator(color: Color(0xFFFF85B3)));
    }
    final pet = _makePet();
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      child: Column(children: [
        _buildHeader(pet),
        const SizedBox(height: 16),
        _buildCharacter(pet),
        const SizedBox(height: 16),
        _buildInfoCard(pet),
        const SizedBox(height: 12),
        _buildUsageCard(pet),
        if (!_hasPermission) ...[
          const SizedBox(height: 12),
          _buildPermissionCard(),
        ],
      ]),
    );
  }

  Widget _buildHeader(PetModel pet) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Lv.${pet.level}  ${pet.tierName}',
              style: const TextStyle(
                  fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFFCC3366))),
          const SizedBox(height: 4),
          SizedBox(
            width: 160,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: pet.xpProgress,
                backgroundColor: Colors.white54,
                color: const Color(0xFFFF85B3),
                minHeight: 8,
              ),
            ),
          ),
          Text('${pet.xp} / ${pet.xpToNextLevel} XP',
              style: const TextStyle(fontSize: 11, color: Color(0xFFCC3366))),
        ]),
        Row(children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(12)),
            child: Row(children: [
              const Text('🪙', style: TextStyle(fontSize: 16)),
              const SizedBox(width: 4),
              Text('${pet.coins}',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, color: Color(0xFFCC3366), fontSize: 16)),
            ]),
          ),
          IconButton(
            icon: const Icon(Icons.settings_rounded, color: Color(0xFFCC3366)),
            onPressed: () async {
              await Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const SettingsScreen()));
              _refresh();
            },
          ),
        ]),
      ],
    );
  }

  Widget _buildCharacter(PetModel pet) {
    return AnimatedBuilder(
      animation: Listenable.merge([_floatAnim, _shakeAnim]),
      builder: (context, child) {
        final dx = pet.state == PetState.sick ? _shakeAnim.value : 0.0;
        return Transform.translate(
            offset: Offset(dx, _floatAnim.value), child: child);
      },
      child: Column(children: [
        PetWidget(state: pet.state),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(5, (i) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3),
            child: Icon(
              i < pet.healthHearts
                  ? Icons.favorite_rounded
                  : Icons.favorite_outline_rounded,
              color: i < pet.healthHearts ? const Color(0xFFFF4488) : Colors.pink[200],
              size: 30,
            ),
          )),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
          decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.65),
              borderRadius: BorderRadius.circular(20)),
          child: Text(pet.statusMessage,
              style: const TextStyle(
                  fontSize: 15, color: Color(0xFFCC3366), fontWeight: FontWeight.w600)),
        ),
      ]),
    );
  }

  Widget _buildInfoCard(PetModel pet) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.75),
          borderRadius: BorderRadius.circular(20)),
      child: Column(children: [
        StatBar(emoji: '🍙', label: '배고픔', value: pet.hunger, color: Colors.orange),
        const SizedBox(height: 14),
        StatBar(emoji: '😊', label: '행복도', value: pet.happiness, color: Colors.pink),
        const SizedBox(height: 14),
        StatBar(emoji: '⚡', label: '에너지', value: pet.energy, color: Colors.blue),
      ]),
    );
  }

  Widget _buildUsageCard(PetModel pet) {
    final goal = pet.goalMinutes;
    final usage = _usageMinutes;
    final progress = goal > 0 ? (usage / goal).clamp(0.0, 1.0) : 0.0;
    final over = goal > 0 && usage >= goal;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.75),
          borderRadius: BorderRadius.circular(20)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          const Row(children: [
            Icon(Icons.photo_camera_rounded, size: 18, color: Color(0xFFE1306C)),
            SizedBox(width: 6),
            Text('인스타그램 사용시간',
                style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFCC3366))),
          ]),
          Text('${usage}분 / ${goal}분',
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: over ? Colors.red : const Color(0xFFCC3366))),
        ]),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.pink[100],
            color: over ? Colors.red : const Color(0xFFFF85B3),
            minHeight: 12,
          ),
        ),
        if (over)
          const Padding(
            padding: EdgeInsets.only(top: 6),
            child: Text('⚠️ 목표 시간을 초과했어요!',
                style: TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.w600)),
          ),
        if (!over && goal > 0)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text('✅ 남은 시간: ${goal - usage}분',
                style: const TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.w600)),
          ),
      ]),
    );
  }

  Widget _buildPermissionCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.75),
          borderRadius: BorderRadius.circular(20)),
      child: Column(children: [
        const Text('📱 사용 시간 권한이 필요해요',
            style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFCC3366))),
        const SizedBox(height: 8),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF85B3),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0),
          onPressed: () async {
            await UsageService.requestPermission();
            await Future.delayed(const Duration(seconds: 1));
            final ok = await UsageService.hasPermission();
            setState(() => _hasPermission = ok);
            if (ok) _refresh();
          },
          child: const Text('권한 허용하기'),
        ),
      ]),
    );
  }
}
