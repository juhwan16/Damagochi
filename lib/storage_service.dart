import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const _goalKey = 'goal_minutes';
  static const _levelKey = 'pet_level';
  static const _xpKey = 'pet_xp';
  static const _lastDateKey = 'last_reward_date';
  static const _hungerKey = 'pet_hunger';
  static const _happinessKey = 'pet_happiness';
  static const _energyKey = 'pet_energy';
  static const _coinsKey = 'pet_coins';
  static const _lastUpdateKey = 'last_update_time';
  static const _streakKey = 'current_streak';
  static const _totalDaysKey = 'total_goal_days';

  static Future<Map<String, dynamic>> loadAll() async {
    final prefs = await SharedPreferences.getInstance();

    // Time-based stat decay
    final lastUpdate =
        prefs.getInt(_lastUpdateKey) ?? DateTime.now().millisecondsSinceEpoch;
    final now = DateTime.now().millisecondsSinceEpoch;
    final hours = (now - lastUpdate) / 3600000.0;

    int hunger = ((prefs.getInt(_hungerKey) ?? 80) - hours * 4).round().clamp(0, 100);
    int happiness = ((prefs.getInt(_happinessKey) ?? 80) - hours * 3).round().clamp(0, 100);
    int energy = ((prefs.getInt(_energyKey) ?? 80) - hours * 2).round().clamp(0, 100);

    await prefs.setInt(_hungerKey, hunger);
    await prefs.setInt(_happinessKey, happiness);
    await prefs.setInt(_energyKey, energy);
    await prefs.setInt(_lastUpdateKey, now);

    return {
      'hunger': hunger,
      'happiness': happiness,
      'energy': energy,
      'coins': prefs.getInt(_coinsKey) ?? 0,
      'level': prefs.getInt(_levelKey) ?? 1,
      'xp': prefs.getInt(_xpKey) ?? 0,
      'goalMinutes': prefs.getInt(_goalKey) ?? 60,
      'streak': prefs.getInt(_streakKey) ?? 0,
      'totalDays': prefs.getInt(_totalDaysKey) ?? 0,
    };
  }

  static Future<int> getGoalMinutes() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_goalKey) ?? 60;
  }

  static Future<void> setGoalMinutes(int minutes) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_goalKey, minutes);
  }

  // Care actions
  static Future<void> feed() async {
    final prefs = await SharedPreferences.getInstance();
    final v = (prefs.getInt(_hungerKey) ?? 50) + 25;
    await prefs.setInt(_hungerKey, v.clamp(0, 100));
  }

  static Future<void> play() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_happinessKey, ((prefs.getInt(_happinessKey) ?? 50) + 20).clamp(0, 100));
    await prefs.setInt(_energyKey, ((prefs.getInt(_energyKey) ?? 50) - 10).clamp(0, 100));
    await prefs.setInt(_hungerKey, ((prefs.getInt(_hungerKey) ?? 50) - 5).clamp(0, 100));
  }

  static Future<void> sleep() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_energyKey, ((prefs.getInt(_energyKey) ?? 50) + 35).clamp(0, 100));
    await prefs.setInt(_happinessKey, ((prefs.getInt(_happinessKey) ?? 50) + 5).clamp(0, 100));
  }

  static Future<void> clean() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_happinessKey, ((prefs.getInt(_happinessKey) ?? 50) + 10).clamp(0, 100));
    await prefs.setInt(_energyKey, ((prefs.getInt(_energyKey) ?? 50) + 5).clamp(0, 100));
  }

  // Shop purchase: apply stat effects and deduct coins
  static Future<bool> buyItem(int cost, Map<String, int> effects) async {
    final prefs = await SharedPreferences.getInstance();
    final coins = prefs.getInt(_coinsKey) ?? 0;
    if (coins < cost) return false;

    await prefs.setInt(_coinsKey, coins - cost);
    if (effects.containsKey('hunger')) {
      await prefs.setInt(_hungerKey, ((prefs.getInt(_hungerKey) ?? 50) + effects['hunger']!).clamp(0, 100));
    }
    if (effects.containsKey('happiness')) {
      await prefs.setInt(_happinessKey, ((prefs.getInt(_happinessKey) ?? 50) + effects['happiness']!).clamp(0, 100));
    }
    if (effects.containsKey('energy')) {
      await prefs.setInt(_energyKey, ((prefs.getInt(_energyKey) ?? 50) + effects['energy']!).clamp(0, 100));
    }
    return true;
  }

  // Daily reward check
  static Future<({int level, int xp, int coins, int streak, int totalDays, bool rewarded})>
      checkDailyReward(int usageMinutes, int goalMinutes) async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final lastDate = prefs.getString(_lastDateKey) ?? '';

    int level = prefs.getInt(_levelKey) ?? 1;
    int xp = prefs.getInt(_xpKey) ?? 0;
    int coins = prefs.getInt(_coinsKey) ?? 0;
    int streak = prefs.getInt(_streakKey) ?? 0;
    int totalDays = prefs.getInt(_totalDaysKey) ?? 0;

    if (lastDate == today || goalMinutes == 0 || usageMinutes >= goalMinutes) {
      return (level: level, xp: xp, coins: coins, streak: streak, totalDays: totalDays, rewarded: false);
    }

    await prefs.setString(_lastDateKey, today);
    xp += 20;
    coins += 15;
    streak++;
    totalDays++;

    while (xp >= level * 100) {
      xp -= level * 100;
      level++;
    }

    await prefs.setInt(_levelKey, level);
    await prefs.setInt(_xpKey, xp);
    await prefs.setInt(_coinsKey, coins);
    await prefs.setInt(_streakKey, streak);
    await prefs.setInt(_totalDaysKey, totalDays);

    return (level: level, xp: xp, coins: coins, streak: streak, totalDays: totalDays, rewarded: true);
  }
}
