import 'package:flutter/services.dart';

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
      final result = await _channel.invokeMethod<int>('getInstagramUsage');
      return result ?? 0;
    } on PlatformException {
      return 0;
    }
  }
}
