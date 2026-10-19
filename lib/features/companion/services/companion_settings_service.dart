import 'dart:convert';

import 'package:faithlock/features/companion/models/companion_settings.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Local-only persistence for the Companion's per-user settings
/// (translation + voice mode). Nothing leaves the device.
class CompanionSettingsService {
  static const String _key = 'companion_settings_v1';

  static final CompanionSettingsService _instance =
      CompanionSettingsService._internal();
  factory CompanionSettingsService() => _instance;
  CompanionSettingsService._internal();

  Future<CompanionSettings> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key);
      if (raw == null || raw.isEmpty) return CompanionSettings.defaults;
      return CompanionSettings.fromJson(
          jsonDecode(raw) as Map<String, dynamic>);
    } catch (e) {
      debugPrint('⚠️ Companion settings load failed: $e');
      return CompanionSettings.defaults;
    }
  }

  Future<void> save(CompanionSettings s) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(s.toJson()));
  }
}
