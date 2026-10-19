import 'dart:convert';
import 'package:faithlock/app_routes.dart';
import 'package:faithlock/services/analytics/posthog/export.dart';
import 'package:faithlock/services/app_group_storage.dart';
import 'package:faithlock/services/storage/secure_storage_service.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

/// Service to auto-navigate to prayer learning when in active schedule
class AutoNavigationService {
  static final AutoNavigationService _instance = AutoNavigationService._internal();
  factory AutoNavigationService() => _instance;
  AutoNavigationService._internal();

  final StorageService _storage = StorageService();
  final PostHogService _analytics = PostHogService.instance;
  static const String _keyOnboardingSchedules = 'onboarding_schedules';

  void _track(String event, [Map<String, dynamic> props = const {}]) {
    if (_analytics.isReady) _analytics.events.trackCustom(event, props);
  }

  Future<void> checkAndNavigate() async {
    try {
      // Wait a bit to let notification handler execute first if app was launched by notification
      await Future.delayed(const Duration(milliseconds: 1000));

      int attempts = 0;
      while (Get.context == null && attempts < 10) {
        await Future.delayed(const Duration(milliseconds: 500));
        attempts++;
      }

      if (Get.context == null) return;

      final shouldPray = await _checkPrayerFlag();
      if (shouldPray) {
        debugPrint('🙏 Prayer flag detected - navigating immediately');
        // DON'T clear the flag here - let LocalNotificationService handle it
        // This ensures the notification tap handler can also see the flag
        // _clearPrayerFlag(); // REMOVED
        _track('unlock_entry', {'source': 'shield_notification'});
        Get.toNamed(AppRoutes.unlockChooser);
        return;
      }

      if (!await _hasConfiguredSchedules()) return;
      if (!await _hasSelectedApps()) return;

      if (await _isCurrentlyInActiveSchedule()) {
        _track('unlock_entry', {'source': 'active_schedule'});
        Get.toNamed(AppRoutes.unlockChooser);
      }
    } catch (e) {
      debugPrint('❌ Error checking auto-navigation: $e');
    }
  }

  /// Check if user clicked "Start Prayer" from Shield
  Future<bool> _checkPrayerFlag() async {
    return await AppGroupStorage.shouldNavigateToPrayer();
  }

  Future<bool> _hasConfiguredSchedules() async {
    try {
      final schedulesJson = await _storage.readString(_keyOnboardingSchedules);
      return schedulesJson != null && schedulesJson.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  Future<bool> _hasSelectedApps() async {
    try {
      final appsJson = await _storage.readString('selected_apps');
      return appsJson != null && appsJson.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  /// Check if currently in an active blocking schedule
  Future<bool> _isCurrentlyInActiveSchedule() async {
    final schedule = await getActiveSchedule();
    return schedule != null;
  }

  /// Get the currently active schedule, if any
  Future<Map<String, dynamic>?> getActiveSchedule() async {
    try {
      final schedulesJson = await _storage.readString(_keyOnboardingSchedules);

      if (schedulesJson == null || schedulesJson.isEmpty) {
        return null;
      }

      final List<dynamic> schedulesData = jsonDecode(schedulesJson);
      final List<Map<String, dynamic>> schedules =
          schedulesData.map((s) => Map<String, dynamic>.from(s)).toList();

      // Check if any schedule is active right now
      final now = DateTime.now();
      final nowMinutes = now.hour * 60 + now.minute;

      for (final schedule in schedules) {
        final enabled = schedule['enabled'] as bool;
        if (!enabled) continue;

        final startHour = schedule['startHour'] as int;
        final startMinute = schedule['startMinute'] as int;
        final endHour = schedule['endHour'] as int;
        final endMinute = schedule['endMinute'] as int;

        final startMinutes = startHour * 60 + startMinute;
        final endMinutes = endHour * 60 + endMinute;

        bool isActive;
        if (endMinutes > startMinutes) {
          // Same day schedule
          isActive = nowMinutes >= startMinutes && nowMinutes < endMinutes;
        } else {
          // Overnight schedule
          isActive = nowMinutes >= startMinutes || nowMinutes < endMinutes;
        }

        if (isActive) {
          debugPrint('📅 Active schedule found: ${schedule['name']}');
          return schedule;
        }
      }

      return null;
    } catch (e) {
      debugPrint('❌ Error checking active schedule: $e');
      return null;
    }
  }

  /// Calculate remaining minutes until end of active schedule
  /// Returns 5 minutes as fallback if no active schedule found
  Future<int> getRemainingMinutesInActiveSchedule() async {
    try {
      final schedule = await getActiveSchedule();

      if (schedule == null) {
        debugPrint('⚠️ No active schedule found, using default 5 minutes');
        return 5; // Fallback
      }

      final now = DateTime.now();
      final nowMinutes = now.hour * 60 + now.minute;

      final endHour = schedule['endHour'] as int;
      final endMinute = schedule['endMinute'] as int;
      final endMinutes = endHour * 60 + endMinute;

      final startHour = schedule['startHour'] as int;
      final startMinute = schedule['startMinute'] as int;
      final startMinutes = startHour * 60 + startMinute;

      int remainingMinutes;

      if (endMinutes > startMinutes) {
        // Same day schedule
        remainingMinutes = endMinutes - nowMinutes;
      } else {
        // Overnight schedule
        if (nowMinutes >= startMinutes) {
          // We're in the first part (before midnight)
          remainingMinutes = (24 * 60) - nowMinutes + endMinutes;
        } else {
          // We're in the second part (after midnight)
          remainingMinutes = endMinutes - nowMinutes;
        }
      }

      // Ensure at least 1 minute
      remainingMinutes = remainingMinutes.clamp(1, 24 * 60);

      debugPrint('⏱️ Remaining minutes in schedule: $remainingMinutes');
      return remainingMinutes;
    } catch (e) {
      debugPrint('❌ Error calculating remaining minutes: $e');
      return 5; // Fallback
    }
  }
}
