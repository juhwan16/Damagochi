import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const _goalKey = 'goal_minutes';
  static const _levelKey = 'pet_level';
  static const _xpKey = 'pet_xp';
  static const _lastDateKey = 'last_reward_date';

  static Future<int> getGoalMinutes() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_goalKey) ?? 60;
  }

  static Future<void> setGoalMinutes(int minutes) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_goalKey, minutes);
  }

  static Future<int> getLevel() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_levelKey) ?? 1;
  }

  static Future<int> getXp() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_xpKey) ?? 0;
  }

  static Future<({int level, int xp, bool rewarded})> checkDailyReward(
      int usageMinutes, int goalMinutes) async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final lastDate = prefs.getString(_lastDateKey) ?? '';

    int level = prefs.getInt(_levelKey) ?? 1;
    int xp = prefs.getInt(_xpKey) ?? 0;

    if (lastDate == today || goalMinutes == 0 || usageMinutes >= goalMinutes) {
      return (level: level, xp: xp, rewarded: false);
    }

    await prefs.setString(_lastDateKey, today);
    xp += 20;
    while (xp >= level * 100) {
      xp -= level * 100;
      level++;
    }
    await prefs.setInt(_levelKey, level);
    await prefs.setInt(_xpKey, xp);

    return (level: level, xp: xp, rewarded: true);
  }
}
