enum PetState { happy, normal, tired, sick }

class PetModel {
  final int goalMinutes;
  final int usageMinutes;
  final int level;
  final int xp;

  const PetModel({
    required this.goalMinutes,
    required this.usageMinutes,
    required this.level,
    required this.xp,
  });

  PetState get state {
    if (goalMinutes == 0) return PetState.normal;
    final ratio = usageMinutes / goalMinutes;
    if (ratio < 0.5) return PetState.happy;
    if (ratio < 1.0) return PetState.normal;
    if (ratio < 1.5) return PetState.tired;
    return PetState.sick;
  }

  int get healthHearts {
    if (goalMinutes == 0) return 5;
    final ratio = usageMinutes / goalMinutes;
    if (ratio <= 0.2) return 5;
    if (ratio <= 0.5) return 4;
    if (ratio <= 0.8) return 3;
    if (ratio <= 1.0) return 2;
    if (ratio <= 1.5) return 1;
    return 0;
  }

  String get statusMessage {
    switch (state) {
      case PetState.happy:
        return '오늘도 건강해요! 💪';
      case PetState.normal:
        return '조금 더 힘내요! 😊';
      case PetState.tired:
        return '핸드폰을 잠깐 내려놓아요... 😓';
      case PetState.sick:
        return '많이 아파요! 쉬어주세요... 😢';
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
}
