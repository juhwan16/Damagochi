import 'package:flutter/material.dart';
import 'storage_service.dart';
import 'main_screen.dart';
import 'game_background.dart';

class CharacterSelectScreen extends StatefulWidget {
  const CharacterSelectScreen({super.key});

  @override
  State<CharacterSelectScreen> createState() => _CharacterSelectScreenState();
}

class _CharacterSelectScreenState extends State<CharacterSelectScreen> {
  List<(int, String?, int)> _slots = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    _slots = await StorageService.listSlots();
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _selectSlot(int slot) async {
    StorageService.setActiveSlot(slot);
    if (!mounted) return;
    await Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const MainScreen()),
    );
  }

  Future<void> _createCharacter(int slot) async {
    final name = await _showNameDialog();
    if (name == null || name.trim().isEmpty) return;
    await StorageService.createSlot(slot, name.trim());
    StorageService.setActiveSlot(slot);
    if (!mounted) return;
    await Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const MainScreen()),
    );
  }

  Future<void> _deleteSlot(int slot, String name) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('캐릭터 삭제'),
        content: Text('[$name]을 삭제할까요?\n모든 데이터가 사라져요 😢'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('취소')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('삭제', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (ok != true) return;
    await StorageService.deleteSlot(slot);
    setState(() => _loading = true);
    await _load();
  }

  Future<String?> _showNameDialog() async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('캐릭터 이름'),
        content: TextField(
          controller: controller,
          maxLength: 10,
          autofocus: true,
          decoration: InputDecoration(
            hintText: '이름을 입력하세요',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onSubmitted: (_) => Navigator.pop(ctx, controller.text),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, null),
              child: const Text('취소')),
          ElevatedButton(
              onPressed: () => Navigator.pop(ctx, controller.text),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF85B3),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('만들기')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF38B8F0),
      body: GameBackground(
        child: SafeArea(
          child: _loading
              ? const Center(
                  child: CircularProgressIndicator(color: Colors.white))
              : Column(children: [
                  const SizedBox(height: 36),
                  // Title
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 24),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.88),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: const Color(0xFFD4914A).withValues(alpha: 0.4),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('🦆', style: TextStyle(fontSize: 28)),
                        SizedBox(width: 10),
                        Text(
                          '캐릭터 선택',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF5A3210),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    '최대 3개의 캐릭터를 만들 수 있어요',
                    style: TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                        fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 28),
                  // Slot cards
                  Expanded(
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      itemCount: 3,
                      separatorBuilder: (_, __) => const SizedBox(height: 14),
                      itemBuilder: (_, i) {
                        final (slot, name, level) = _slots[i];
                        return name != null
                            ? _FilledSlot(
                                slot: slot,
                                name: name,
                                level: level,
                                onTap: () => _selectSlot(slot),
                                onDelete: () => _deleteSlot(slot, name),
                              )
                            : _EmptySlot(
                                slot: slot,
                                onTap: () => _createCharacter(slot),
                              );
                      },
                    ),
                  ),
                  const SizedBox(height: 20),
                ]),
        ),
      ),
    );
  }
}

class _FilledSlot extends StatelessWidget {
  final int slot;
  final String name;
  final int level;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _FilledSlot({
    required this.slot,
    required this.name,
    required this.level,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onDelete,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.92),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: const Color(0xFFD4914A).withValues(alpha: 0.35),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 14,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(children: [
          // Duck emoji in circle
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFFE082), Color(0xFFFFCA28)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFFCA28).withValues(alpha: 0.4),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: const Center(
              child: Text('🦆', style: TextStyle(fontSize: 30)),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name,
                      style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF5A3210))),
                  const SizedBox(height: 4),
                  Row(children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFFB6D9), Color(0xFFD4AAFF)],
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text('Lv.$level',
                          style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Colors.white)),
                    ),
                    const SizedBox(width: 8),
                    Text('슬롯 $slot',
                        style: const TextStyle(
                            fontSize: 12, color: Colors.black38)),
                  ]),
                ]),
          ),
          const Icon(Icons.arrow_forward_ios_rounded,
              size: 18, color: Color(0xFFD4914A)),
        ]),
      ),
    );
  }
}

class _EmptySlot extends StatelessWidget {
  final int slot;
  final VoidCallback onTap;

  const _EmptySlot({required this.slot, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.55),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.7),
            width: 2,
          ),
        ),
        child: Row(children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.6),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.add_rounded, size: 32, color: Color(0xFFD4914A)),
          ),
          const SizedBox(width: 16),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('새 캐릭터 만들기',
                style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF5A3210))),
            Text('슬롯 $slot',
                style: const TextStyle(fontSize: 12, color: Colors.black38)),
          ]),
        ]),
      ),
    );
  }
}
