import 'package:faithlock/app_routes.dart';
import 'package:faithlock/services/analytics/posthog/export.dart';
import 'package:faithlock/services/app_group_storage.dart';
import 'package:faithlock/services/app_launch_service.dart';
import 'package:faithlock/services/export.dart';
import 'package:faithlock/services/notifications/daily_verse_notification_service.dart';
import 'package:faithlock/services/notifications/winback_notification_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

// This class manages local notifications in the app
class LocalNotificationService {
  // Single instance of LocalNotificationService (Singleton pattern)
  static final LocalNotificationService _instance =
      LocalNotificationService._internal();

  // Factory constructor to return the single instance
  factory LocalNotificationService() => _instance;

  // Private constructor
  LocalNotificationService._internal();

  // Plugin to handle platform-specific notification services
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  // Track initialization status
  bool _isInitialized = false;

  // Set up notifications for Android and iOS
  Future<void> initialize() async {
    // Skip if already initialized
    if (_isInitialized) {
      debugPrint('✅ LocalNotificationService already initialized - skipping');
      return;
    }

    tz.initializeTimeZones();

    // Android settings
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS settings
    final DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
      onDidReceiveLocalNotification: _onDidReceiveLocalNotification,
    );

    // Combined settings
    final InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    // Initialize the plugin
    await _flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onDidReceiveNotificationResponse,
    );

    _isInitialized = true;
    debugPrint('✅ LocalNotificationService initialized successfully');
  }

  // Handle user tapping on a notification
  Future<void> _onDidReceiveNotificationResponse(
      NotificationResponse response) async {
    debugPrint('📲 Notification tapped - checking for prayer navigation request');

    // Check AND immediately clear the prayer flag atomically
    // This prevents AutoNavigationService from also navigating
    // This flag is set by ShieldActionExtension when user taps "Start Prayer"
    final shouldNavigate = await AppGroupStorage.shouldNavigateToPrayer();

    // Clear immediately to prevent double navigation
    if (shouldNavigate) {
      await AppGroupStorage.clearPrayerFlag();
      debugPrint('✅ Prayer navigation requested - cleared flag and navigating to prayer learning');

      // Navigate to prayer learning screen
      // Use Get.offAllNamed to clear navigation stack and start fresh
      Get.offAllNamed(AppRoutes.unlockChooser);

      debugPrint('🙏 Navigated to prayer learning screen');
    } else {
      debugPrint('ℹ️ No prayer navigation requested');

      // Handle other notification types based on payload
      final String? payload = response.payload;
      if (payload != null) {
        debugPrint('Notification payload: $payload');

        // Handle relock notifications
        if (payload == 'relock_required' || payload == 'relock_reminder') {
          debugPrint('🔒 Relock notification tapped - navigating to relock screen');

          // Set launch source to relock notification
          await AppLaunchService().setLaunchSource(AppLaunchService.sourceRelockNotification);

          // Navigate to relock screen
          Get.offAllNamed(AppRoutes.relockInProgress);

          debugPrint('✅ Navigated to relock screen');
        }

        // Handle win-back notifications (winback_0, winback_1, ..., winback_4)
        if (payload.startsWith(WinBackNotificationService.payloadPrefix)) {
          debugPrint('💰 Win-back notification tapped: $payload');

          // Extract notification index for tracking
          final parts = payload.split('_');
          if (parts.length == 2) {
            final index = int.tryParse(parts[1]);
            if (index != null) {
              WinBackNotificationService().trackNotificationTapped(index);

              // Track in PostHog
              final analytics = PostHogService.instance;
              if (analytics.isReady) {
                analytics.events.trackCustom('notification_tapped', {
                  'type': 'winback',
                  'notification_index': index,
                  'payload': payload,
                });
              }

              // If this is the offer notification or its +24h reminder,
              // mark promo eligible and go directly to paywall
              if (index == WinBackNotificationService.offerNotificationIndex ||
                  index == WinBackNotificationService.offerReminderNotificationIndex) {
                await WinBackNotificationService().markPromoEligible();
                debugPrint('🎁 Win-back promo notification tapped — navigating to paywall with promo');
                // Navigate to main — PaywallController will detect promo flag
                Get.offAllNamed(AppRoutes.main);
                return;
              }
            }
          }

          // For other win-back notifications, navigate to main
          Get.offAllNamed(AppRoutes.main);
          debugPrint('✅ Navigated to main from win-back notification');
        }

        // Handle daily verse notifications (daily_verse_{verseId})
        if (payload.startsWith(DailyVerseNotificationService.payloadPrefix)) {
          debugPrint('📖 Daily verse notification tapped: $payload');

          // Track in PostHog
          final analytics = PostHogService.instance;
          if (analytics.isReady) {
            analytics.events.trackCustom('notification_tapped', {
              'type': 'daily_verse',
              'payload': payload,
            });
          }

          // Navigate to summary screen to show the verse
          Get.offAllNamed(AppRoutes.onboardingSummary);
          debugPrint('✅ Navigated to summary from daily verse notification');
        }
      }
    }
  }

  // Handle iOS foreground notifications
  Future<void> _onDidReceiveLocalNotification(
      int id, String? title, String? body, String? payload) async {
    debugPrint('Received local notification: $title, $body, $payload');
    // TODO: Handle iOS foreground notification
  }

  // Show an immediate notification
  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'faithlock_general',
      'FaithLock Notifications',
      channelDescription: 'General notifications from FaithLock',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: false,
    );

    const DarwinNotificationDetails iOSDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
      iOS: iOSDetails,
    );

    await _flutterLocalNotificationsPlugin.show(
      id,
      title,
      body,
      platformDetails,
      payload: payload,
    );
  }

  // Schedule a notification for a future time
  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    String? payload,
  }) async {
    if (scheduledDate.isBefore(DateTime.now())) {
      throw ArgumentError('Scheduled date must be in the future');
    }

    await _flutterLocalNotificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(scheduledDate, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'faithlock_reminders',
          'FaithLock Reminders',
          channelDescription: 'Reminder notifications to re-lock your apps',
          importance: Importance.max,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
          interruptionLevel: InterruptionLevel.timeSensitive,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: payload,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  // Cancel a specific notification by ID
  Future<void> cancelNotification(int id) async {
    await _flutterLocalNotificationsPlugin.cancel(id);
  }

  // Cancel all notifications
  Future<void> cancelAllNotifications() async {
    await _flutterLocalNotificationsPlugin.cancelAll();
  }

  // Get pending notifications (for debugging)
  Future<List<dynamic>> getPendingNotifications() async {
    return await _flutterLocalNotificationsPlugin.pendingNotificationRequests();
  }

  // Show repeating notification (every minute)
  // Note: Not currently used - we use scheduled notifications instead for better reliability
  Future<void> showRepeatingNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    await _flutterLocalNotificationsPlugin.periodicallyShow(
      id,
      title,
      body,
      RepeatInterval.everyMinute,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'faithlock_reminders',
          'FaithLock Reminders',
          channelDescription: 'Reminder notifications to re-lock your apps',
          importance: Importance.max,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
          interruptionLevel: InterruptionLevel.timeSensitive,
        ),
      ),
      payload: payload,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  // Request notification permissions on iOS (with explanatory dialog first)
  Future<bool> requestPermissions() async {
    final iosImplementation = _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>();

    if (iosImplementation != null) {
      final bool? granted = await iosImplementation.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      debugPrint('📱 iOS notification permissions granted: $granted');
      return granted ?? false;
    }

    // Android doesn't need runtime permission request for notifications
    debugPrint('🤖 Android - notification permissions granted by default');
    return true;
  }

  // Request permissions with explanatory dialog
  Future<bool> requestPermissionsWithDialog(BuildContext context) async {
    // Import needed for dialog
    final iosImplementation = _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>();

    if (iosImplementation != null) {
      // Show explanatory dialog first (iOS only)
      final shouldProceed = await _showPermissionExplanationDialog(context);

      if (!shouldProceed) {
        debugPrint('⚠️ User declined to see notification permission prompt');
        return false;
      }

      // User agreed, now request permissions
      final bool? granted = await iosImplementation.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      debugPrint('📱 iOS notification permissions granted: $granted');
      return granted ?? false;
    }

    // Android doesn't need runtime permission request
    debugPrint('🤖 Android - notification permissions granted by default');
    return true;
  }

  // Show dialog explaining why notifications are useful
  Future<bool> _showPermissionExplanationDialog(BuildContext context) async {
    // This will be implemented by importing FastAlertDialog in the caller
    // For now, return true to maintain backward compatibility
    return true;
  }

  // Check if the app has notification permissions
  Future<bool> hasPermissions() async {
    final iosImplementation = _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>();

    if (iosImplementation != null) {
      // On iOS, check permission status without prompting
      // Note: This uses checkPermissions() which returns current status
      // without triggering the system permission dialog
      try {
        // Unfortunately flutter_local_notifications doesn't have a direct check method
        // We'll have to use a workaround by attempting to check via notification settings
        // For now, return null to indicate unknown status
        debugPrint('⚠️ iOS notification permissions: status check not available without prompting');
        debugPrint('💡 Use requestPermissions() to check and request if needed');
        return false; // Conservative assumption
      } catch (e) {
        debugPrint('❌ Error checking iOS notification permissions: $e');
        return false;
      }
    }

    // Android defaults to true
    debugPrint('🤖 Android notification permissions: true (no runtime permission needed)');
    return true;
  }

  // DEBUG: Test notifications to verify they work
  Future<void> testNotifications() async {
    debugPrint('🧪 Testing notifications...');

    // Test 1: Immediate notification
    await showNotification(
      id: 999,
      title: '✅ Test Immediate',
      body: 'If you see this, immediate notifications work!',
      payload: 'test_immediate',
    );
    debugPrint('📤 Sent immediate test notification');

    // Test 2: Repeating notification (every minute - minimum interval)
    await showRepeatingNotification(
      id: 998,
      title: '🔁 Test Repeat',
      body: 'This notification repeats every minute',
      payload: 'test_repeat',
    );
    debugPrint('🔁 Started repeating notification (every 60 seconds)');

    // Test 3: Check pending notifications
    final pending = await getPendingNotifications();
    debugPrint('📊 Pending notifications: ${pending.length}');
    for (var notif in pending) {
      debugPrint('  - ID: ${notif.id}, Title: ${notif.title}');
    }

    // Test 4: Check permissions
    final hasPerms = await hasPermissions();
    debugPrint('🔐 Has permissions: $hasPerms');
  }
}

class Services {
  LocalDatabaseService service = LocalDatabaseService();
}
