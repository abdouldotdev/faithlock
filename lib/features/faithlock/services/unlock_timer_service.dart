import 'dart:async';

import 'package:faithlock/features/faithlock/services/screen_time_service.dart';
import 'package:faithlock/services/analytics/posthog/export.dart';
import 'package:faithlock/services/notifications/local_notification_service.dart';
import 'package:faithlock/services/storage/secure_storage_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Service managing temporary unlock timer after prayer
/// Handles re-blocking when timer expires (in-app or via notification)
class UnlockTimerService with WidgetsBindingObserver {
  static final UnlockTimerService _instance = UnlockTimerService._internal();
  factory UnlockTimerService() => _instance;
  UnlockTimerService._internal();

  final ScreenTimeService _screenTimeService = ScreenTimeService();
  final StorageService _storage = StorageService();
  final LocalNotificationService _notificationService =
      LocalNotificationService();
  final PostHogService _analytics = PostHogService.instance;

  void _track(String event, [Map<String, dynamic> props = const {}]) {
    if (_analytics.isReady) _analytics.events.trackCustom(event, props);
  }

  // Storage keys
  static const String _keyUnlockEndTime = 'unlock_end_time';
  static const String _keyNeedsRelock = 'needs_relock';
  static const String _keyReminderCount = 'reminder_count';

  Timer? _unlockTimer;
  bool _isAppInForeground = true;

  /// Start observing app lifecycle
  void initialize() {
    WidgetsBinding.instance.addObserver(this);
    debugPrint('✅ UnlockTimerService initialized');
  }

  /// Stop observing and cleanup
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _unlockTimer?.cancel();
    debugPrint('🗑️ UnlockTimerService disposed');
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _isAppInForeground = state == AppLifecycleState.resumed;
    debugPrint(
        '📱 App lifecycle: ${state.name} (foreground: $_isAppInForeground)');

    // Check if relock needed when app comes to foreground
    if (_isAppInForeground) {
      _checkAndRelockIfNeeded();
    }
  }

  /// Start temporary unlock with duration
  Future<void> startUnlock({required Duration duration}) async {
    try {
      // Cancel existing timers
      _unlockTimer?.cancel();

      // Remove shields
      await _screenTimeService.removeShields();

      // Calculate end time
      final endTime = DateTime.now().add(duration);
      await _storage.writeString(_keyUnlockEndTime, endTime.toIso8601String());
      await _storage.writeBool(_keyNeedsRelock, false);
      await _storage.writeInt(_keyReminderCount, 0);

      debugPrint('✅ Started unlock for ${duration.inMinutes} minutes');
      debugPrint(
          '⏰ Will relock at: ${endTime.hour}:${endTime.minute.toString().padLeft(2, '0')}');

      // Schedule notification for when timer expires (works even if app closed)
      await _scheduleRelockNotification(endTime);

      // Start in-app timer (for foreground relock)
      _startUnlockTimer(duration);
    } catch (e) {
      debugPrint('❌ Error starting unlock: $e');
      rethrow;
    }
  }

  /// Schedule notification to fire when unlock expires
  Future<void> _scheduleRelockNotification(DateTime scheduledTime) async {
    try {
      // Note: LocalNotificationService must be initialized in onboarding
      // before this method is called. If not initialized, notifications won't work.
      // We don't initialize here to avoid triggering iOS permission prompt.

      // Cancel any existing scheduled notification
      await _notificationService.cancelNotification(100);

      await _notificationService.scheduleNotification(
        id: 100,
        title: 'timer_timesUp'.tr,
        body: 'timer_openToRelock'.tr,
        scheduledDate: scheduledTime,
        payload: 'relock_required',
      );

      debugPrint(
          '📅 Scheduled relock notification for ${scheduledTime.hour}:${scheduledTime.minute}');
    } catch (e) {
      debugPrint('❌ Error scheduling notification: $e');
    }
  }

  /// Start timer that triggers when unlock expires
  void _startUnlockTimer(Duration duration) {
    _unlockTimer = Timer(duration, () async {
      debugPrint('⏰ Unlock timer expired');
      _track('unlock_expired', {
        'duration_minutes': duration.inMinutes,
        'foreground': _isAppInForeground,
      });

      if (_isAppInForeground) {
        // App in foreground - relock directly
        await _relockApps(reason: 'timer_foreground');

        // Cancel scheduled notification since we relocked in-app
        await _notificationService.cancelNotification(100);
      } else {
        // App in background - notification already scheduled
        // Just set the relock flag and start reminders
        await _storage.writeBool(_keyNeedsRelock, true);
        await _startReminderTimer();
        debugPrint('📲 App in background - notification should fire soon');
      }
    });
  }

  /// Relock apps immediately (user in app)
  Future<void> _relockApps({String reason = 'timer'}) async {
    try {
      await _screenTimeService.applyShields();
      await _storage.writeBool(_keyNeedsRelock, false);
      await _storage.deleteData(_keyUnlockEndTime);

      // Cancel all reminders since apps are now locked
      await _cancelReminders();

      _track('apps_relocked', {'reason': reason});
      debugPrint('🔒 Apps re-locked (user in app)');

      // Show toast to user
      // FastToast will be called from UI layer
    } catch (e) {
      debugPrint('❌ Error re-locking apps: $e');
    }
  }

  /// Start repeating reminder notification (every 5 minutes until app opened)
  Future<void> _startReminderTimer() async {
    try {
      // Note: LocalNotificationService must be initialized in onboarding
      // before this method is called. If not initialized, notifications won't work.
      // We don't initialize here to avoid triggering iOS permission prompt.

      // Cancel any existing reminders first (IDs 101-124)
      for (int i = 101; i <= 124; i++) {
        await _notificationService.cancelNotification(i);
      }

      // Schedule multiple notifications (every 5 minutes for next 2 hours)
      // This is more reliable than periodicallyShow() on iOS
      final now = DateTime.now();
      const reminderInterval = Duration(minutes: 5);
      const maxReminders = 24; // 24 notifications = 120 minutes (2 hours) of reminders

      for (int i = 0; i < maxReminders; i++) {
        final scheduledTime = now.add(reminderInterval * (i + 1));

        await _notificationService.scheduleNotification(
          id: 101 + i, // IDs 101-124
          title: 'timer_reminderTitle'.tr,
          body: 'timer_dontForget'.tr,
          scheduledDate: scheduledTime,
          payload: 'relock_reminder',
        );
      }

      debugPrint(
          '✅ Scheduled $maxReminders reminder notifications (every 5 minutes)');
      debugPrint('⏰ Notifications will fire until user opens app or cancels');

      // Check pending notifications
      final pending = await _notificationService.getPendingNotifications();
      debugPrint('📊 Total pending notifications: ${pending.length}');
    } catch (e) {
      debugPrint('❌ Error starting repeating reminder: $e');
    }
  }

  /// Cancel all reminder notifications
  Future<void> _cancelReminders() async {
    try {
      // Note: LocalNotificationService must be initialized in onboarding
      // before this method is called. If not initialized, cancellation is a no-op.
      // We don't initialize here to avoid triggering iOS permission prompt.

      // Cancel all scheduled reminder notifications (IDs 101-124)
      for (int i = 101; i <= 124; i++) {
        await _notificationService.cancelNotification(i);
      }
      debugPrint('✅ Cancelled all reminder notifications (IDs 101-124)');
    } catch (e) {
      debugPrint('❌ Error cancelling reminders: $e');
    }
  }

  /// Check if relock is needed and apply if so
  Future<void> _checkAndRelockIfNeeded() async {
    try {
      final needsRelock = await _storage.readBool(_keyNeedsRelock) ?? false;

      if (needsRelock) {
        debugPrint('🔒 Relock needed - applying shields');
        await _relockApps(reason: 'timer_background_return');
      }
    } catch (e) {
      debugPrint('❌ Error checking relock status: $e');
    }
  }

  /// Get remaining unlock time (if active)
  Future<Duration?> getRemainingTime() async {
    try {
      final endTimeStr = await _storage.readString(_keyUnlockEndTime);
      if (endTimeStr == null) return null;

      final endTime = DateTime.parse(endTimeStr);
      final now = DateTime.now();

      if (now.isAfter(endTime)) {
        // Timer expired
        await _checkAndRelockIfNeeded();
        return null;
      }

      return endTime.difference(now);
    } catch (e) {
      debugPrint('❌ Error getting remaining time: $e');
      return null;
    }
  }

  /// Check if unlock is currently active
  Future<bool> isUnlockActive() async {
    final remaining = await getRemainingTime();
    return remaining != null && remaining.inSeconds > 0;
  }

  /// Cancel unlock and relock immediately
  Future<void> cancelUnlock() async {
    try {
      _unlockTimer?.cancel();

      await _storage.deleteData(_keyUnlockEndTime);
      await _storage.writeBool(_keyNeedsRelock, false);
      await _storage.writeInt(_keyReminderCount, 0);

      // Cancel all scheduled reminders
      await _cancelReminders();

      await _screenTimeService.applyShields();

      _track('unlock_cancelled', {});
      debugPrint('🔒 Unlock cancelled - apps relocked');
    } catch (e) {
      debugPrint('❌ Error cancelling unlock: $e');
      rethrow;
    }
  }
}
