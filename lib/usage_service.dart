import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UsageService {
  static const _channel = MethodChannel('com.juhwan16.damagochi/usage');

  static Future<bool> hasPermission() async {
    try {
      return await _channel.invokeMethod<bool>('hasPermission') ?? false;
    } on PlatformException {
      return false;
    }
  }

  static Future<void> requestPermission() async {
    try {
      await _channel.invokeMethod('requestPermission');
    } on PlatformException {
      // ignore
    }
  }

  static Future<int> getInstagramUsageMinutes() async {
    try {
      // 테스트 모드: SharedPreferences에서 직접 값 반환
      final prefs = await SharedPreferences.getInstance();
      if (prefs.getBool('test_mode') ?? false) {
        return prefs.getInt('test_usage_minutes') ?? 0;
      }
      final result = await _channel.invokeMethod<int>('getInstagramUsage');
      return result ?? 0;
    } on PlatformException {
      return 0;
    }
  }
}
