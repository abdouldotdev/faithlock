import 'package:faithlock/app_routes.dart';
import 'package:faithlock/services/app_group_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

/// Service to handle notification tap navigation via MethodChannel
/// This works in conjunction with AppDelegate.swift
class NotificationNavigationService {
  static final NotificationNavigationService _instance =
      NotificationNavigationService._internal();

  factory NotificationNavigationService() => _instance;

  NotificationNavigationService._internal();

  static const MethodChannel _channel =
      MethodChannel('faithlock/notification');

  bool _isInitialized = false;

  /// Initialize the notification navigation handler
  Future<void> initialize() async {
    if (_isInitialized) {
      debugPrint(
          '✅ NotificationNavigationService already initialized - skipping');
      return;
    }

    _channel.setMethodCallHandler(_handleMethodCall);
    _isInitialized = true;
    debugPrint('✅ NotificationNavigationService initialized');
  }

  /// Handle method calls from iOS
  Future<dynamic> _handleMethodCall(MethodCall call) async {
    debugPrint('📲 Received method call from iOS: ${call.method}');

    switch (call.method) {
      case 'navigateToPrayer':
        await _navigateToPrayer();
        return true;

      default:
        debugPrint('⚠️ Unknown method: ${call.method}');
        return false;
    }
  }

  /// Navigate to prayer learning screen
  Future<void> _navigateToPrayer() async {
    try {
      debugPrint('🙏 Navigating to prayer learning screen from notification');

      // Clear the prayer flag so AutoNavigationService doesn't also navigate
      await AppGroupStorage.clearPrayerFlag();
      debugPrint('🧹 Cleared prayer flag');

      // Wait for Get.context to be available
      int attempts = 0;
      while (Get.context == null && attempts < 10) {
        await Future.delayed(const Duration(milliseconds: 100));
        attempts++;
      }

      if (Get.context == null) {
        debugPrint('❌ Get.context still null after waiting');
        return;
      }

      // Navigate to prayer screen
      Get.offAllNamed(AppRoutes.unlockChooser);
      debugPrint('✅ Navigation complete');
    } catch (e) {
      debugPrint('❌ Error navigating to prayer: $e');
    }
  }
}
