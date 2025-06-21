import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class CacheHelper {
  static SharedPreferences? _prefs;

  static Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
  }

  static Future<void> setString(String key, String value) async {
    await _prefs?.setString(key, value);
  }

  static String? getString(String key) {
    return _prefs?.getString(key);
  }

  static Future<void> setInt(String key, int value) async {
    await _prefs?.setInt(key, value);
  }

  static int? getInt(String key) {
    return _prefs?.getInt(key);
  }

  static Future<void> setBool(String key, bool value) async {
    await _prefs?.setBool(key, value);
  }

  static bool? getBool(String key) {
    return _prefs?.getBool(key);
  }

  static Future<void> setJson(String key, Map<String, dynamic> value) async {
    await _prefs?.setString(key, jsonEncode(value));
  }

  static Map<String, dynamic>? getJson(String key) {
    final String? jsonString = _prefs?.getString(key);
    if (jsonString != null) {
      try {
        return jsonDecode(jsonString) as Map<String, dynamic>;
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  static Future<void> remove(String key) async {
    await _prefs?.remove(key);
  }

  static Future<void> clear() async {
    await _prefs?.clear();
  }

  // 캐시 키 상수들
  static const String CURRENT_PLANT_ID = 'current_plant_id';
  static const String USER_SETTINGS = 'user_settings';
  static const String LAST_SYNC_TIME = 'last_sync_time';
  static const String PLANT_PROFILES_CACHE = 'plant_profiles_cache';
}