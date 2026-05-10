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
  bool _testMode = false;
  double _testUsage = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final goal = await StorageService.getGoalMinutes();
    final perm = await UsageService.hasPermission();
    final test = await StorageService.isTestMode();
    final usage = await StorageService.getTestUsageMinutes();
    setState(() {
      _goalMinutes = goal.toDouble();
      _hasPermission = perm;
      _testMode = test;
      _testUsage = usage.toDouble();
    });
  }

  String _fmt(double m) {
    final min = m.toInt();
    if (min < 60) return '$min분';
    final h = min ~/ 60;
    final r = min % 60;
    return r == 0 ? '${h}시간' : '${h}시간 ${r}분';
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
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 12, 16, 0),
              child: Row(children: [
                IconButton(
                    icon: const Icon(Icons.arrow_back_ios_rounded, color: Color(0xFFCC3366)),
                    onPressed: () => Navigator.pop(context)),
                const Text('설정',
                    style: TextStyle(
                        fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFFCC3366))),
              ]),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(children: [
                  _buildGoalCard(),
                  const SizedBox(height: 16),
                  _buildPermissionCard(),
                  const SizedBox(height: 16),
                  _buildTestModeCard(),
                ]),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _buildGoalCard() {
    return _card(children: [
      const Row(children: [
        Icon(Icons.timer_rounded, color: Color(0xFFFF85B3)),
        SizedBox(width: 8),
        Text('하루 목표 사용 시간',
            style: TextStyle(
                fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFFCC3366))),
      ]),
      const SizedBox(height: 4),
      const Text('인스타그램 하루 목표 시간을 설정하세요',
          style: TextStyle(color: Colors.black45, fontSize: 13)),
      const SizedBox(height: 22),
      Center(
        child: Text(_fmt(_goalMinutes),
            style: const TextStyle(
                fontSize: 40, fontWeight: FontWeight.bold, color: Color(0xFFFF4488))),
      ),
      Slider(
        value: _goalMinutes,
        min: 10,
        max: 180,
        divisions: 34,
        activeColor: const Color(0xFFFF85B3),
        inactiveColor: Colors.pink[100],
        onChanged: (v) => setState(() => _goalMinutes = v),
        onChangeEnd: (v) => StorageService.setGoalMinutes(v.toInt()),
      ),
      const Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('10분', style: TextStyle(color: Colors.black38, fontSize: 12)),
          Text('3시간', style: TextStyle(color: Colors.black38, fontSize: 12)),
        ],
      ),
    ]);
  }

  Widget _buildPermissionCard() {
    return _card(children: [
      const Row(children: [
        Icon(Icons.security_rounded, color: Color(0xFFFF85B3)),
        SizedBox(width: 8),
        Text('권한 설정',
            style: TextStyle(
                fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFFCC3366))),
      ]),
      const SizedBox(height: 16),
      Row(children: [
        Icon(
            _hasPermission ? Icons.check_circle_rounded : Icons.cancel_rounded,
            color: _hasPermission ? Colors.green : Colors.red[300],
            size: 22),
        const SizedBox(width: 8),
        Text(
            _hasPermission ? '사용 정보 접근 허용됨' : '사용 정보 접근 권한 필요',
            style: TextStyle(
                color: _hasPermission ? Colors.green[700] : Colors.red[400],
                fontWeight: FontWeight.w600)),
      ]),
      if (!_hasPermission) ...[
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF85B3),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                padding: const EdgeInsets.symmetric(vertical: 14),
                elevation: 0),
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
    ]);
  }

  Widget _buildTestModeCard() {
    return _card(children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        const Row(children: [
          Icon(Icons.science_rounded, color: Color(0xFFFF85B3)),
          SizedBox(width: 8),
          Text('개발자 테스트 모드',
              style: TextStyle(
                  fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFFCC3366))),
        ]),
        Switch(
          value: _testMode,
          activeColor: const Color(0xFFFF85B3),
          onChanged: (v) async {
            await StorageService.setTestMode(v);
            setState(() => _testMode = v);
          },
        ),
      ]),
      const SizedBox(height: 4),
      Text(
        _testMode
            ? '✅ 테스트 모드 활성화 — 아래 값으로 인스타 시간 시뮬레이션'
            : '실제 인스타그램 사용 시간을 가져옵니다',
        style: TextStyle(
            color: _testMode ? Colors.green[700] : Colors.black45, fontSize: 13),
      ),
      if (_testMode) ...[
        const SizedBox(height: 20),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          const Text('인스타 사용시간 (테스트)',
              style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFFCC3366))),
          Text('${_testUsage.toInt()}분',
              style: const TextStyle(
                  fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFFFF4488))),
        ]),
        Slider(
          value: _testUsage,
          min: 0,
          max: 300,
          divisions: 60,
          activeColor: const Color(0xFFFF85B3),
          inactiveColor: Colors.pink[100],
          onChanged: (v) => setState(() => _testUsage = v),
          onChangeEnd: (v) => StorageService.setTestUsageMinutes(v.toInt()),
        ),
        const Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('0분', style: TextStyle(color: Colors.black38, fontSize: 12)),
          Text('5시간', style: TextStyle(color: Colors.black38, fontSize: 12)),
        ]),
        const SizedBox(height: 12),
        // 빠른 테스트 버튼
        const Text('빠른 설정',
            style: TextStyle(color: Color(0xFFCC3366), fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _quickBtn('😊 목표의 30%', (_goalMinutes * 0.3).round()),
            _quickBtn('😐 목표의 80%', (_goalMinutes * 0.8).round()),
            _quickBtn('😓 목표 초과', (_goalMinutes * 1.2).round()),
            _quickBtn('😢 2배 초과', (_goalMinutes * 2.0).round()),
          ],
        ),
      ],
    ]);
  }

  Widget _quickBtn(String label, int minutes) {
    return GestureDetector(
      onTap: () async {
        final v = minutes.toDouble().clamp(0, 300);
        await StorageService.setTestUsageMinutes(v.toInt());
        setState(() => _testUsage = v);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
            color: Colors.pink[50],
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFFF85B3))),
        child: Text(label,
            style: const TextStyle(fontSize: 12, color: Color(0xFFCC3366), fontWeight: FontWeight.w600)),
      ),
    );
  }

  Widget _card({required List<Widget> children}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.82),
          borderRadius: BorderRadius.circular(20)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
    );
  }
}
