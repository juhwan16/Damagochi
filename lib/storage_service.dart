import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

typedef CareResult = ({
  bool onCooldown,
  int remainingMs,
  int xpGained,
  int coinsGained,
  bool leveledUp,
  int newLevel,
});

class StorageService {
  // ─── Active slot (1~3) ───────────────────────────────────────
  static int _slot = 1;
  static int get activeSlot => _slot;
  static void setActiveSlot(int s) => _slot = s;

  // Per-slot key prefix
  static String get _p => 's${_slot}_';

  // 3 character types (randomly assigned on creation)
  static const List<Map<String, String>> charTypes = [
    {'id': 'yellow_duck', 'name': '노랑이', 'emoji': '🐥', 'color': 'pink',   'prefix': 'pet'},
    {'id': 'white_duck',  'name': '흰둥이', 'emoji': '🐣', 'color': 'pink',   'prefix': 'pet2'},
    {'id': 'white_dog',   'name': '뽀삐',   'emoji': '🐶', 'color': 'pink',   'prefix': 'pet3'},
  ];

  static Future<String> getSvgPrefix() async {
    final idx = await getCharTypeIndex();
    return charTypes[idx]['prefix']!;
  }

  // Per-slot keys
  static String get _goalKey       => '${_p}goal_minutes';
  static String get _levelKey      => '${_p}pet_level';
  static String get _xpKey         => '${_p}pet_xp';
  static String get _lastDateKey   => '${_p}last_reward_date';
  static String get _hungerKey     => '${_p}pet_hunger';
  static String get _happinessKey  => '${_p}pet_happiness';
  static String get _energyKey     => '${_p}pet_energy';
  static String get _coinsKey      => '${_p}pet_coins';
  static String get _lastUpdateKey => '${_p}last_update_time';
  static String get _streakKey     => '${_p}current_streak';
  static String get _totalDaysKey  => '${_p}total_goal_days';

  // Per-slot customization keys
  static String get _equippedAccKey    => '${_p}equipped_accessory';
  static String get _equippedThemeKey  => '${_p}equipped_theme';
  static String get _equippedColorKey  => '${_p}equipped_color';
  static String get _unlockedAccKey    => '${_p}unlocked_accessories';
  static String get _unlockedThemesKey => '${_p}unlocked_themes';
  static String get _unlockedColorsKey => '${_p}unlocked_colors';

  // Global keys (not per-slot)
  static const _testModeKey  = 'test_mode';
  static const _testUsageKey = 'test_usage_minutes';

  // ─── Character slot management ───────────────────────────────

  static String _slotNameKey(int slot) => 'slot_${slot}_name';

  static Future<String?> getSlotName(int slot) async {
    final prefs = await SharedPreferences.getInstance();
    final name = prefs.getString(_slotNameKey(slot));
    return (name == null || name.isEmpty) ? null : name;
  }

  static Future<void> createSlot(int slot, String name, int typeIndex) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_slotNameKey(slot), name);
    await prefs.setInt('s${slot}_char_type', typeIndex);
    final charColor = charTypes[typeIndex]['color']!;
    await prefs.setString('s${slot}_equipped_color', charColor);
    final unlocked = {'pink', charColor};
    await prefs.setString('s${slot}_unlocked_colors', unlocked.join(','));
  }

  static Future<int> getCharTypeIndex() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('${_p}char_type') ?? 0;
  }

  static Future<void> deleteSlot(int slot) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_slotNameKey(slot));
    // Remove all slot-specific keys
    final prefix = 's${slot}_';
    final keys = prefs.getKeys().where((k) => k.startsWith(prefix)).toList();
    for (final k in keys) {
      await prefs.remove(k);
    }
  }

  // Returns list of (slot, name, level, charTypeIndex) for all 3 slots
  static Future<List<(int, String?, int, int)>> listSlots() async {
    final prefs = await SharedPreferences.getInstance();
    return List.generate(3, (i) {
      final slot = i + 1;
      final name = prefs.getString(_slotNameKey(slot));
      final level = prefs.getInt('s${slot}_pet_level') ?? 1;
      final charType = prefs.getInt('s${slot}_char_type') ?? 0;
      return (slot, (name == null || name.isEmpty) ? null : name, level, charType);
    });
  }

  // ─── Pet stats ───────────────────────────────────────────────

  static Future<Map<String, dynamic>> loadAll() async {
    final prefs = await SharedPreferences.getInstance();

    final lastUpdate =
        prefs.getInt(_lastUpdateKey) ?? DateTime.now().millisecondsSinceEpoch;
    final now = DateTime.now().millisecondsSinceEpoch;
    final hours = (now - lastUpdate) / 3600000.0;

    final today = DateTime.now().toIso8601String().substring(0, 10);
    final lastDate = prefs.getString(_lastDateKey) ?? '';
    final decayMult = lastDate == today ? 0.5 : 1.0;

    int hunger =
        ((prefs.getInt(_hungerKey) ?? 80) - hours * 2.5 * decayMult).round().clamp(0, 100);
    int happiness =
        ((prefs.getInt(_happinessKey) ?? 80) - hours * 2.0 * decayMult).round().clamp(0, 100);
    int energy =
        ((prefs.getInt(_energyKey) ?? 80) - hours * 1.5 * decayMult).round().clamp(0, 100);

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

  // ─── Care actions ────────────────────────────────────────────

  static int _cooldownMs(int hours) => hours * 60 * 60 * 1000;

  static Future<int> getCooldownRemaining(String action) async {
    final prefs = await SharedPreferences.getInstance();
    const cooldownHours = {'feed': 2, 'play': 1, 'sleep': 4, 'clean': 3, 'special_snack': 12, 'spa': 24};
    final hours = cooldownHours[action] ?? 1;
    final lastTime = prefs.getInt('${_p}last_${action}_time') ?? 0;
    final now = DateTime.now().millisecondsSinceEpoch;
    final remaining = _cooldownMs(hours) - (now - lastTime);
    return remaining > 0 ? remaining : 0;
  }

  static Future<CareResult> _doCare({
    required String key,
    required int cooldownHours,
    required Map<String, int> statDeltas,
    required int xpGain,
    required int coinGain,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now().millisecondsSinceEpoch;
    final lastTime = prefs.getInt('${_p}last_${key}_time') ?? 0;
    final remaining = _cooldownMs(cooldownHours) - (now - lastTime);

    if (remaining > 0) {
      return (
        onCooldown: true,
        remainingMs: remaining,
        xpGained: 0,
        coinsGained: 0,
        leveledUp: false,
        newLevel: prefs.getInt(_levelKey) ?? 1,
      );
    }

    await prefs.setInt('${_p}last_${key}_time', now);

    final statKeyMap = {
      'hunger': _hungerKey,
      'happiness': _happinessKey,
      'energy': _energyKey,
    };
    for (final e in statDeltas.entries) {
      final sk = statKeyMap[e.key]!;
      await prefs.setInt(
          sk, ((prefs.getInt(sk) ?? 50) + e.value).clamp(0, 100));
    }

    int xp = (prefs.getInt(_xpKey) ?? 0) + xpGain;
    int coins = (prefs.getInt(_coinsKey) ?? 0) + coinGain;
    int level = prefs.getInt(_levelKey) ?? 1;
    bool leveledUp = false;
    while (xp >= level * 50) {
      xp -= level * 50;
      level++;
      leveledUp = true;
    }
    await prefs.setInt(_xpKey, xp);
    await prefs.setInt(_coinsKey, coins);
    await prefs.setInt(_levelKey, level);

    return (
      onCooldown: false,
      remainingMs: 0,
      xpGained: xpGain,
      coinsGained: coinGain,
      leveledUp: leveledUp,
      newLevel: level,
    );
  }

  static Future<CareResult> feed() => _doCare(
        key: 'feed',
        cooldownHours: 2,
        statDeltas: {'hunger': 25},
        xpGain: 6,
        coinGain: 1,
      );

  static Future<CareResult> play() => _doCare(
        key: 'play',
        cooldownHours: 1,
        statDeltas: {'happiness': 20, 'energy': -10, 'hunger': -5},
        xpGain: 10,
        coinGain: 2,
      );

  static Future<CareResult> sleep() => _doCare(
        key: 'sleep',
        cooldownHours: 4,
        statDeltas: {'energy': 35, 'happiness': 5},
        xpGain: 8,
        coinGain: 1,
      );

  static Future<CareResult> clean() => _doCare(
        key: 'clean',
        cooldownHours: 3,
        statDeltas: {'happiness': 10, 'energy': 5},
        xpGain: 6,
        coinGain: 1,
      );

  static Future<CareResult> specialSnack() => _doCare(
        key: 'special_snack',
        cooldownHours: 12,
        statDeltas: {'hunger': 50, 'happiness': 20},
        xpGain: 20,
        coinGain: 3,
      );

  static Future<CareResult> spa() => _doCare(
        key: 'spa',
        cooldownHours: 24,
        statDeltas: {'happiness': 50, 'energy': 30, 'hunger': 10},
        xpGain: 30,
        coinGain: 5,
      );

  static Future<bool> buyItem(int cost, Map<String, int> effects) async {
    final prefs = await SharedPreferences.getInstance();
    final coins = prefs.getInt(_coinsKey) ?? 0;
    if (coins < cost) return false;
    await prefs.setInt(_coinsKey, coins - cost);
    final statKeyMap = {
      'hunger': _hungerKey,
      'happiness': _happinessKey,
      'energy': _energyKey,
    };
    for (final e in effects.entries) {
      final sk = statKeyMap[e.key] ?? '';
      if (sk.isNotEmpty) {
        await prefs.setInt(
            sk, ((prefs.getInt(sk) ?? 50) + e.value).clamp(0, 100));
      }
    }
    return true;
  }

  static Future<({
    int level,
    int xp,
    int coins,
    int streak,
    int totalDays,
    bool rewarded,
    bool leveledUp,
    int coinBonus,
  })> checkDailyReward(int usageMinutes, int goalMinutes) async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final lastDate = prefs.getString(_lastDateKey) ?? '';

    int level = prefs.getInt(_levelKey) ?? 1;
    int xp = prefs.getInt(_xpKey) ?? 0;
    int coins = prefs.getInt(_coinsKey) ?? 0;
    int streak = prefs.getInt(_streakKey) ?? 0;
    int totalDays = prefs.getInt(_totalDaysKey) ?? 0;

    if (lastDate == today || goalMinutes == 0 || usageMinutes >= goalMinutes) {
      return (
        level: level, xp: xp, coins: coins, streak: streak,
        totalDays: totalDays, rewarded: false, leveledUp: false, coinBonus: 0,
      );
    }

    await prefs.setString(_lastDateKey, today);
    xp += 30;

    final minutesSaved = (goalMinutes - usageMinutes).clamp(0, goalMinutes);
    final minuteBonus = minutesSaved ~/ 5;

    int coinBonus = 20;
    if (streak >= 7) coinBonus = 50;
    else if (streak >= 3) coinBonus = 35;
    coinBonus += minuteBonus;
    coins += coinBonus;
    streak++;
    totalDays++;

    bool leveledUp = false;
    while (xp >= level * 50) {
      xp -= level * 50;
      level++;
      leveledUp = true;
    }
    await prefs.setInt(_levelKey, level);
    await prefs.setInt(_xpKey, xp);
    await prefs.setInt(_coinsKey, coins);
    await prefs.setInt(_streakKey, streak);
    await prefs.setInt(_totalDaysKey, totalDays);

    return (
      level: level, xp: xp, coins: coins, streak: streak,
      totalDays: totalDays, rewarded: true, leveledUp: leveledUp,
      coinBonus: coinBonus,
    );
  }

  // ─── Mini-game reward ────────────────────────────────────────

  static Future<({bool leveledUp, int newLevel})> addMiniGameReward(int xp, int coins) async {
    final prefs = await SharedPreferences.getInstance();
    int currentXp = (prefs.getInt(_xpKey) ?? 0) + xp;
    int currentCoins = (prefs.getInt(_coinsKey) ?? 0) + coins;
    int level = prefs.getInt(_levelKey) ?? 1;
    bool leveledUp = false;
    while (currentXp >= level * 50) {
      currentXp -= level * 50;
      level++;
      leveledUp = true;
    }
    await prefs.setInt(_xpKey, currentXp);
    await prefs.setInt(_coinsKey, currentCoins);
    await prefs.setInt(_levelKey, level);
    return (leveledUp: leveledUp, newLevel: level);
  }

  // ─── Customization ───────────────────────────────────────────

  static Future<Map<String, dynamic>> loadCustomization() async {
    final prefs = await SharedPreferences.getInstance();
    final unlockedAcc = (prefs.getString(_unlockedAccKey) ?? '')
        .split(',')
        .where((s) => s.isNotEmpty)
        .toList();
    final unlockedThemes = (prefs.getString(_unlockedThemesKey) ?? 'default')
        .split(',')
        .where((s) => s.isNotEmpty)
        .toList();
    final unlockedColors = (prefs.getString(_unlockedColorsKey) ?? 'pink')
        .split(',')
        .where((s) => s.isNotEmpty)
        .toList();

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

  // ─── Dev mode helpers ────────────────────────────────────────

  static Future<({int level, int xp})> devGetLevelXp() async {
    final prefs = await SharedPreferences.getInstance();
    return (
      level: prefs.getInt(_levelKey) ?? 1,
      xp: prefs.getInt(_xpKey) ?? 0,
    );
  }

  static Future<({int level, int xp})> devSetLevel(int level, int xp) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_levelKey, level);
    await prefs.setInt(_xpKey, xp);
    return (level: level, xp: xp);
  }

  static Future<({int level, int xp})> devAddXp(int amount) async {
    final prefs = await SharedPreferences.getInstance();
    int xp = (prefs.getInt(_xpKey) ?? 0) + amount;
    int level = prefs.getInt(_levelKey) ?? 1;
    while (xp >= level * 100) { xp -= level * 100; level++; }
    await prefs.setInt(_xpKey, xp);
    await prefs.setInt(_levelKey, level);
    return (level: level, xp: xp);
  }

  static Future<void> devSetCoins(int coins) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_coinsKey, coins);
  }

  static Future<void> devSetStats(int hunger, int happiness, int energy) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_hungerKey, hunger);
    await prefs.setInt(_happinessKey, happiness);
    await prefs.setInt(_energyKey, energy);
  }

  static Future<void> devReset() async {
    final prefs = await SharedPreferences.getInstance();
    for (final k in [_coinsKey, _xpKey, _levelKey, _hungerKey,
                      _happinessKey, _energyKey, _streakKey, _totalDaysKey]) {
      await prefs.remove(k);
    }
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
      case 'ribbon':     return 'assets/svg/acc_ribbon.svg';
      case 'monocle':    return 'assets/svg/acc_monocle.svg';
      case 'glasses':    return 'assets/svg/acc_glasses.svg';
      case 'bow_tie':    return 'assets/svg/acc_bow_tie.svg';
      case 'hat':        return 'assets/svg/acc_hat.svg';
      case 'flower':     return 'assets/svg/acc_flower.svg';
      case 'santa':      return 'assets/svg/acc_santa.svg';
      case 'pirate':     return 'assets/svg/acc_pirate.svg';
      case 'headphones': return 'assets/svg/acc_headphones.svg';
      case 'crown':      return 'assets/svg/acc_crown.svg';
      case 'witch':      return 'assets/svg/acc_witch.svg';
      case 'scarf':      return 'assets/svg/acc_scarf.svg';
      case 'party':      return 'assets/svg/acc_party.svg';
      case 'devil':      return 'assets/svg/acc_devil.svg';
      case 'halo':       return 'assets/svg/acc_halo.svg';
      case 'star':       return 'assets/svg/acc_star.svg';
      default:           return null;
    }
  }

  static Color? characterColor(String id) {
    switch (id) {
      case 'mint':     return const Color(0xFF80D0C0);
      case 'yellow':   return const Color(0xFFFFD080);
      case 'sky':      return const Color(0xFF80B8E0);
      case 'lavender': return const Color(0xFFB880E0);
      case 'peach':    return const Color(0xFFFFB080);
      default:         return null;
    }
  }

  static ({String emoji, String name, List<Color> gradient}) levelBadge(int level) {
    if (level >= 20) return (
      emoji: '💎', name: '전설',
      gradient: const [Color(0xFF80DEEA), Color(0xFF0097A7)],
    );
    if (level >= 15) return (
      emoji: '👑', name: '왕관',
      gradient: const [Color(0xFFCE93D8), Color(0xFF8E24AA)],
    );
    if (level >= 10) return (
      emoji: '🌟', name: '영웅',
      gradient: const [Color(0xFFFFD54F), Color(0xFFFF8F00)],
    );
    if (level >= 5) return (
      emoji: '⭐', name: '모험가',
      gradient: const [Color(0xFF90CAF9), Color(0xFF1E88E5)],
    );
    return (
      emoji: '🌱', name: '새싹',
      gradient: const [Color(0xFFA5D6A7), Color(0xFF43A047)],
    );
  }

  static List<Color> themeColors(String id) {
    switch (id) {
      case 'sky':
        return [const Color(0xFFE3F2FD), const Color(0xFFBBDEFB), const Color(0xFFE1F5FE)];
      case 'forest':
        return [const Color(0xFFE8F5E9), const Color(0xFFC8E6C9), const Color(0xFFDCEDC8)];
      case 'sunset':
        return [const Color(0xFFFFF8E1), const Color(0xFFFFECB3), const Color(0xFFFFE0B2)];
      case 'lavender':
        return [const Color(0xFFF3E5F5), const Color(0xFFE1BEE7), const Color(0xFFEDE7F6)];
      case 'ocean':
        return [const Color(0xFFE0F7FA), const Color(0xFFB2EBF2), const Color(0xFFE0F2F1)];
      default:
        return [const Color(0xFFFCE4EC), const Color(0xFFF8BBD9), const Color(0xFFEDD5F5)];
    }
  }
}
