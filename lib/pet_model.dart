enum PetState { happy, normal, tired, sick }

class PetModel {
  final int goalMinutes;
  final int usageMinutes;
  final int level;
  final int xp;
  final int hunger;
  final int happiness;
  final int energy;
  final int coins;

  const PetModel({
    required this.goalMinutes,
    required this.usageMinutes,
    required this.level,
    required this.xp,
    required this.hunger,
    required this.happiness,
    required this.energy,
    required this.coins,
  });

  double get overallHealth => (hunger + happiness + energy) / 300.0;

  PetState get state {
    if (overallHealth < 0.25) return PetState.sick;
    if (goalMinutes > 0 && usageMinutes >= goalMinutes * 1.5) return PetState.sick;
    if (goalMinutes > 0 && usageMinutes >= goalMinutes) return PetState.tired;
    if (overallHealth < 0.5) return PetState.tired;
    if (overallHealth >= 0.75 &&
        (goalMinutes == 0 || usageMinutes < goalMinutes * 0.5)) {
      return PetState.happy;
    }
    return PetState.normal;
  }

  int get healthHearts {
    final statScore = overallHealth;
    final usageScore = goalMinutes > 0
        ? (1.0 - (usageMinutes / goalMinutes).clamp(0.0, 1.0))
        : 1.0;
    final combined = statScore * 0.6 + usageScore * 0.4;
    return (combined * 5).ceil().clamp(0, 5);
  }

  String get statusMessage {
    switch (state) {
      case PetState.happy:
        return '최고의 컨디션이에요! 🌟';
      case PetState.normal:
        return '오늘도 잘 지내고 있어요 😊';
      case PetState.tired:
        return '조금 힘들어요... 💦';
      case PetState.sick:
        return '많이 아파요! 도와주세요 😢';
    }
  }

  String get svgAsset {
    switch (state) {
      case PetState.happy:
        return 'assets/svg/pet_happy.svg';
      case PetState.normal:
        return 'assets/svg/pet_normal.svg';
      case PetState.tired:
        return 'assets/svg/pet_tired.svg';
      case PetState.sick:
        return 'assets/svg/pet_sick.svg';
    }
  }

  int get xpToNextLevel => level * 100;
  double get xpProgress => xp / xpToNextLevel;

  String get tierName {
    if (level < 3) return '🐣 새싹';
    if (level < 6) return '🌱 초보자';
    if (level < 10) return '🌿 성장중';
    if (level < 15) return '🌸 능숙자';
    if (level < 20) return '🌟 전문가';
    return '👑 마스터';
  }
}
