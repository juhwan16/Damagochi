import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  // Pet stats
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

  // Customization
  static const _equippedAccKey = 'equipped_accessory';
  static const _equippedThemeKey = 'equipped_theme';
  static const _equippedColorKey = 'equipped_color';
  static const _unlockedAccKey = 'unlocked_accessories';
  static const _unlockedThemesKey = 'unlocked_themes';
  static const _unlockedColorsKey = 'unlocked_colors';

  // Test mode
  static const _testModeKey = 'test_mode';
  static const _testUsageKey = 'test_usage_minutes';

  // ─── Pet stats ───────────────────────────────────────────────

  static Future<Map<String, dynamic>> loadAll() async {
    final prefs = await SharedPreferences.getInstance();

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

  static Future<void> feed() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_hungerKey, ((prefs.getInt(_hungerKey) ?? 50) + 25).clamp(0, 100));
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

  // ─── Customization ───────────────────────────────────────────

  static Future<Map<String, dynamic>> loadCustomization() async {
    final prefs = await SharedPreferences.getInstance();
    final unlockedAcc = (prefs.getString(_unlockedAccKey) ?? '')
        .split(',').where((s) => s.isNotEmpty).toList();
    final unlockedThemes = (prefs.getString(_unlockedThemesKey) ?? 'default')
        .split(',').where((s) => s.isNotEmpty).toList();
    final unlockedColors = (prefs.getString(_unlockedColorsKey) ?? 'pink')
        .split(',').where((s) => s.isNotEmpty).toList();

    return {
      'accessory': prefs.getString(_equippedAccKey) ?? 'none',
      'theme': prefs.getString(_equippedThemeKey) ?? 'default',
      'color': prefs.getString(_equippedColorKey) ?? 'pink',
      'unlockedAcc': unlockedAcc,
      'unlockedThemes': unlockedThemes,
      'unlockedColors': unlockedColors,
    };
  }

  static Future<void> equipAccessory(String id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_equippedAccKey, id);
  }

  static Future<void> equipTheme(String id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_equippedThemeKey, id);
  }

  static Future<void> equipColor(String id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_equippedColorKey, id);
  }

  static Future<bool> unlockCustomItem(String type, String id, int cost) async {
    final prefs = await SharedPreferences.getInstance();
    final coins = prefs.getInt(_coinsKey) ?? 0;
    if (coins < cost) return false;
    await prefs.setInt(_coinsKey, coins - cost);

    final key = type == 'accessory'
        ? _unlockedAccKey
        : type == 'theme'
            ? _unlockedThemesKey
            : _unlockedColorsKey;
    final current = prefs.getString(key) ?? '';
    final items = current.split(',').where((s) => s.isNotEmpty).toList();
    if (!items.contains(id)) {
      items.add(id);
      await prefs.setString(key, items.join(','));
    }
    return true;
  }

  // ─── Test mode ───────────────────────────────────────────────

  static Future<bool> isTestMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_testModeKey) ?? false;
  }

  static Future<void> setTestMode(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_testModeKey, enabled);
  }

  static Future<int> getTestUsageMinutes() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_testUsageKey) ?? 0;
  }

  static Future<void> setTestUsageMinutes(int minutes) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_testUsageKey, minutes);
  }

  // ─── Utility ─────────────────────────────────────────────────

  static String? accessoryAsset(String id) {
    switch (id) {
      case 'crown': return 'assets/svg/acc_crown.svg';
      case 'ribbon': return 'assets/svg/acc_ribbon.svg';
      case 'hat': return 'assets/svg/acc_hat.svg';
      case 'glasses': return 'assets/svg/acc_glasses.svg';
      case 'santa': return 'assets/svg/acc_santa.svg';
      case 'halo': return 'assets/svg/acc_halo.svg';
      default: return null;
    }
  }

  static Color? characterColor(String id) {
    switch (id) {
      case 'mint': return const Color(0xFF80D0C0);
      case 'yellow': return const Color(0xFFFFD080);
      case 'sky': return const Color(0xFF80B8E0);
      case 'lavender': return const Color(0xFFB880E0);
      case 'peach': return const Color(0xFFFFB080);
      default: return null;
    }
  }

  static List<Color> themeColors(String id) {
    switch (id) {
      case 'sky': return [const Color(0xFFE3F2FD), const Color(0xFFBBDEFB), const Color(0xFFE1F5FE)];
      case 'forest': return [const Color(0xFFE8F5E9), const Color(0xFFC8E6C9), const Color(0xFFDCEDC8)];
      case 'sunset': return [const Color(0xFFFFF8E1), const Color(0xFFFFECB3), const Color(0xFFFFE0B2)];
      case 'lavender': return [const Color(0xFFF3E5F5), const Color(0xFFE1BEE7), const Color(0xFFEDE7F6)];
      case 'ocean': return [const Color(0xFFE0F7FA), const Color(0xFFB2EBF2), const Color(0xFFE0F2F1)];
      default: return [const Color(0xFFFCE4EC), const Color(0xFFF8BBD9), const Color(0xFFEDD5F5)];
    }
  }
}
