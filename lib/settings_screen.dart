import 'package:flutter/material.dart';
import 'storage_service.dart';
import 'usage_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  double _goalMinutes = 60;
  bool _hasPermission = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final goal = await StorageService.getGoalMinutes();
    final perm = await UsageService.hasPermission();
    setState(() {
      _goalMinutes = goal.toDouble();
      _hasPermission = perm;
    });
  }

  String _formatMinutes(double minutes) {
    final m = minutes.toInt();
    if (m < 60) return '$m분';
    final h = m ~/ 60;
    final rem = m % 60;
    if (rem == 0) return '${h}시간';
    return '${h}시간 ${rem}분';
  }

  @override
  Widget build(BuildContext context) {
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 12, 16, 0),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_rounded,
                          color: Color(0xFFCC3366)),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const Text(
                      '설정',
                      style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFCC3366)),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      _buildGoalCard(),
                      const SizedBox(height: 16),
                      _buildPermissionCard(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGoalCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.timer_rounded, color: Color(0xFFFF85B3)),
              SizedBox(width: 8),
              Text(
                '하루 목표 사용 시간',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFCC3366)),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            '인스타그램 하루 목표 시간을 설정하세요',
            style: TextStyle(color: Colors.black45, fontSize: 13),
          ),
          const SizedBox(height: 22),
          Center(
            child: Text(
              _formatMinutes(_goalMinutes),
              style: const TextStyle(
                fontSize: 42,
                fontWeight: FontWeight.bold,
                color: Color(0xFFFF4488),
              ),
            ),
          ),
          Slider(
            value: _goalMinutes,
            min: 10,
            max: 180,
            divisions: 34,
            activeColor: const Color(0xFFFF85B3),
            inactiveColor: Colors.pink[100],
            onChanged: (v) => setState(() => _goalMinutes = v),
            onChangeEnd: (v) async {
              await StorageService.setGoalMinutes(v.toInt());
            },
          ),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('10분', style: TextStyle(color: Colors.black38, fontSize: 12)),
              Text('3시간', style: TextStyle(color: Colors.black38, fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.security_rounded, color: Color(0xFFFF85B3)),
              SizedBox(width: 8),
              Text(
                '권한 설정',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFCC3366)),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Icon(
                _hasPermission
                    ? Icons.check_circle_rounded
                    : Icons.cancel_rounded,
                color: _hasPermission ? Colors.green : Colors.red[300],
                size: 22,
              ),
              const SizedBox(width: 8),
              Text(
                _hasPermission ? '사용 정보 접근 허용됨' : '사용 정보 접근 권한 필요',
                style: TextStyle(
                  color: _hasPermission ? Colors.green[700] : Colors.red[400],
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          if (!_hasPermission) ...[
            const SizedBox(height: 16),
            const Text(
              '설정 → 디지털 웰빙 → 사용 정보 접근에서\n이 앱을 허용해 주세요.',
              style: TextStyle(color: Colors.black45, fontSize: 13),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF85B3),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  elevation: 0,
                ),
                onPressed: () async {
                  await UsageService.requestPermission();
                  await Future.delayed(const Duration(seconds: 1));
                  final ok = await UsageService.hasPermission();
                  setState(() => _hasPermission = ok);
                },
                child: const Text('권한 설정하러 가기',
                    style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
