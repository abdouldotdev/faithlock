import 'package:faithlock/app_routes.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'package:uni_links/uni_links.dart';
import 'dart:async';

/// Service to handle deep links and URL schemes
class DeepLinkService {
  static final DeepLinkService _instance = DeepLinkService._internal();
  factory DeepLinkService() => _instance;
  DeepLinkService._internal();

  StreamSubscription? _linkSubscription;
  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();

  /// Initialize deep link handling
  Future<void> initialize() async {
    try {
      // Initialize local notifications for handling notification taps
      await _initializeNotifications();

      // Handle initial link if app was opened from a deep link
      final initialLink = await getInitialUri();
      if (initialLink != null) {
        _handleDeepLink(initialLink);
      }

      // Listen to subsequent links when app is in background/foreground
      _linkSubscription = uriLinkStream.listen(
        (Uri? uri) {
          if (uri != null) {
            _handleDeepLink(uri);
          }
        },
        onError: (err) {
          debugPrint('Deep link error: $err');
        },
      );

      debugPrint('✅ DeepLinkService initialized');
    } catch (e) {
      debugPrint('❌ Failed to initialize deep links: $e');
    }
  }

  /// Initialize notification handling
  Future<void> _initializeNotifications() async {
    const initializationSettingsIOS = DarwinInitializationSettings(
      // CRITICAL: Do NOT request permissions here
      // Permissions are requested during onboarding flow only
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
      onDidReceiveLocalNotification: null,
    );

    const initializationSettings = InitializationSettings(
      iOS: initializationSettingsIOS,
    );

    await _notificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );
  }

  /// Handle notification tap
  void _onNotificationTapped(NotificationResponse response) {
    debugPrint('🔔 Notification tapped: ${response.payload}');

    // Extract deep link from payload
    if (response.payload != null && response.payload!.startsWith('faithlock://')) {
      final uri = Uri.parse(response.payload!);
      _handleDeepLink(uri);
    }
  }

  /// Handle a deep link URI
  void _handleDeepLink(Uri uri) {
    debugPrint('🔗 Deep link received: $uri');

    // Parse the deep link
    final scheme = uri.scheme; // faithlock
    final host = uri.host; // prayer, unlock, etc.

    if (scheme != 'faithlock') {
      debugPrint('⚠️ Unknown scheme: $scheme');
      return;
    }

    // Route based on host/path
    switch (host) {
      case 'prayer':
        _navigateToPrayer();
        break;
      case 'unlock':
        _navigateToUnlock();
        break;
      case 'promo':
        _navigateToPromoOffer(uri);
        break;
      default:
        debugPrint('⚠️ Unknown deep link host: $host');
    }
  }

  /// Navigate to Prayer Learning screen
  void _navigateToPrayer() {
    debugPrint('📿 Navigating to Prayer Learning...');

    // Small delay to ensure app is ready
    Future.delayed(const Duration(milliseconds: 500), () {
      Get.toNamed(AppRoutes.unlockChooser);
    });
  }

  /// Navigate to Unlock screen
  void _navigateToUnlock() {
    debugPrint('🔓 Navigating to Unlock...');

    Future.delayed(const Duration(milliseconds: 500), () {
      // Navigate to unlock challenge or main screen
      Get.toNamed(AppRoutes.main);
    });
  }

  /// Navigate to the welcome-offer page (tapped from the Live Activity).
  void _navigateToPromoOffer(Uri uri) {
    final source = uri.queryParameters['src'] ?? 'deeplink';
    debugPrint('🎁 Navigating to promo offer (source: $source)...');

    // Guard against stacking a second copy if the page is already up.
    if (Get.currentRoute == AppRoutes.promoOffer) return;

    Future.delayed(const Duration(milliseconds: 500), () {
      Get.toNamed<void>(
        AppRoutes.promoOffer,
        arguments: <String, dynamic>{'source': source},
      );
    });
  }

  /// Dispose the service
  void dispose() {
    _linkSubscription?.cancel();
  }
}
