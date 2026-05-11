import 'package:flutter/material.dart';
import 'storage_service.dart';

class LevelUpDialog extends StatefulWidget {
  final int newLevel;
  const LevelUpDialog({super.key, required this.newLevel});

  @override
  State<LevelUpDialog> createState() => _LevelUpDialogState();
}

class _LevelUpDialogState extends State<LevelUpDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _scale = CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut);
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeIn);
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  String _tierName(int level) {
    if (level < 5) return '새싹';
    if (level < 10) return '모험가';
    if (level < 15) return '영웅';
    if (level < 20) return '왕관';
    return '전설';
  }

  String? _unlockMessage(int level) {
    switch (level) {
      case 5:  return '⭐ 모험가 휘장 획득!\n🍰 특별 간식 케어 해금!';
      case 10: return '🌟 영웅 휘장 획득!\n🧖 스파 케어 해금!';
      case 15: return '👑 왕관 휘장 획득!';
      case 20: return '💎 전설 휘장 획득!';
      default: return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFFFB6D9), Color(0xFFD4AAFF)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: Colors.pink.withValues(alpha: 0.45),
                blurRadius: 24,
                spreadRadius: 4,
              ),
            ],
          ),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Text('🎉 레벨업!',
                style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white)),
            const SizedBox(height: 20),
            ScaleTransition(
              scale: _scale,
              child: _BadgeCircle(level: widget.newLevel),
            ),
            const SizedBox(height: 14),
            Text(_tierName(widget.newLevel),
                style: const TextStyle(
                    fontSize: 22,
                    color: Colors.white,
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            Text('Lv.${widget.newLevel} 달성을 축하해요!',
                style: const TextStyle(fontSize: 14, color: Colors.white70)),
            if (_unlockMessage(widget.newLevel) != null) ...[
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white38, width: 1),
                ),
                child: Column(children: [
                  const Text('🎁 새로운 콘텐츠 해금!',
                      style: TextStyle(fontSize: 13, color: Colors.white, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  Text(_unlockMessage(widget.newLevel)!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 13, color: Colors.white, height: 1.6)),
                ]),
              ),
            ],
            const SizedBox(height: 16),
            const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Text('⭐', style: TextStyle(fontSize: 22)),
              SizedBox(width: 6),
              Text('✨', style: TextStyle(fontSize: 30)),
              SizedBox(width: 6),
              Text('⭐', style: TextStyle(fontSize: 22)),
            ]),
            const SizedBox(height: 22),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFFCC3366),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  elevation: 0,
                ),
                onPressed: () => Navigator.pop(context),
                child: const Text('축하해요! 🎊',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

void showLevelUpDialog(BuildContext context, int newLevel) {
  showDialog(
    context: context,
    barrierDismissible: true,
    builder: (_) => LevelUpDialog(newLevel: newLevel),
  );
}

class _BadgeCircle extends StatelessWidget {
  final int level;
  const _BadgeCircle({required this.level});

  @override
  Widget build(BuildContext context) {
    final badge = StorageService.levelBadge(level);
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: badge.gradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 4),
        boxShadow: [
          BoxShadow(
            color: badge.gradient.last.withValues(alpha: 0.5),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Text(badge.emoji, style: const TextStyle(fontSize: 36)),
        Text('Lv.$level',
            style: const TextStyle(
                fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
      ]),
    );
  }
}
