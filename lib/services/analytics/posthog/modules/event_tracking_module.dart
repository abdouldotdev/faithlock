import 'package:faithlock/services/analytics/posthog/config/event_templates.dart';
import 'package:faithlock/services/analytics/posthog/models/posthog_event.dart';
import 'package:faithlock/services/analytics/posthog/utils/privacy_manager.dart';
import 'package:flutter/foundation.dart';
import 'package:posthog_flutter/posthog_flutter.dart';

/// Event tracking module for PostHog
///
/// This module handles all events and their validation.
/// It provides simplified methods for tracking different types of events
/// with automatic validation and privacy management.
class EventTrackingModule {
  final dynamic _postHogService;
  final List<PostHogEvent> _eventQueue = [];
  bool _isInitialized = false;

  EventTrackingModule(this._postHogService);

  Future<void> init() async {
    try {
      _isInitialized = true;
      if (kDebugMode) {
        debugPrint('EventTrackingModule initialized');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Failed to initialize EventTrackingModule: $e');
      }
    }
  }

  /// Track an event with predefined type
  Future<void> track(
    PostHogEventType eventType,
    Map<String, dynamic> properties, {
    String? userId,
    Map<String, dynamic>? userProperties,
  }) async {
    try {
      final eventName = PostHogEventTemplates.eventNames[eventType];
      if (eventName == null) {
        throw ArgumentError('Unknown event type: $eventType');
      }

      await trackCustom(
        eventName,
        properties,
        userId: userId,
        userProperties: userProperties,
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Failed to track event $eventType: $e');
      }
    }
  }

  /// Track a custom event
  Future<void> trackCustom(
    String eventName,
    Map<String, dynamic> properties, {
    String? userId,
    Map<String, dynamic>? userProperties,
  }) async {
    if (!_isInitialized || !_canTrackEvent(eventName)) return;

    try {
      // Property validation and sanitization
      final sanitizedProperties =
          PostHogPrivacyManager.instance.sanitizeProperties(properties);

      // Add context properties
      final enrichedProperties = _enrichProperties(sanitizedProperties);

      // Create event
      final event = PostHogEvent(
        name: eventName,
        properties: enrichedProperties,
        distinctId: userId ?? _postHogService.currentUserId,
        sessionId: _postHogService.sessionId,
        userProperties: userProperties,
      );

      // Add to queue and send
      _eventQueue.add(event);
      await _sendEvent(event);

      // Met a jour les person properties derivees de cet event (compteurs,
      // dates de derniere activite). Un seul point d'appel ici couvre tout le
      // catalogue : voir PersonPropertiesModule pour la table event -> props.
      // Isole dans son propre try : l'event est deja parti, un echec ici ne
      // doit ni le faire passer pour rate, ni remonter a l'appelant.
      try {
        await _postHogService.personProperties.onEvent(eventName, properties);
      } catch (e) {
        if (kDebugMode) {
          debugPrint('Failed to update person properties for $eventName: $e');
        }
      }

      if (kDebugMode) {
        debugPrint('Event tracked: $eventName');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Failed to track custom event $eventName: $e');
      }
    }
  }

  /// Track an action event
  Future<void> trackAction(
    String action,
    String target, {
    Map<String, dynamic>? additionalProperties,
  }) async {
    await trackCustom('user_action', {
      'action': action,
      'target': target,
      'screen_name': _getCurrentScreenName(),
      ...?additionalProperties,
    });
  }

  /// Track a UI interaction event
  Future<void> trackInteraction(
    String elementType,
    String elementId, {
    String? value,
    Map<String, dynamic>? context,
  }) async {
    await trackCustom('ui_interaction', {
      'element_type': elementType,
      'element_id': elementId,
      if (value != null) 'value': value,
      'screen_name': _getCurrentScreenName(),
      ...?context,
    });
  }

  /// Track a performance event
  Future<void> trackPerformance(
    String metric,
    double value, {
    String? unit,
    Map<String, dynamic>? tags,
  }) async {
    await track(PostHogEventType.performanceMetric, {
      'metric_name': metric,
      'value': value,
      if (unit != null) 'unit': unit,
      'screen_name': _getCurrentScreenName(),
      ...?tags,
    });
  }

  /// Track an error event
  Future<void> trackError(
    String errorType,
    String errorMessage, {
    String? stackTrace,
    String? userId,
    Map<String, dynamic>? context,
  }) async {
    await track(PostHogEventType.errorOccurred, {
      'error_type': errorType,
      'error_message': errorMessage,
      if (stackTrace != null) 'error_stack': stackTrace,
      'screen_name': _getCurrentScreenName(),
      if (userId != null) 'user_id': userId,
      ...?context,
    });
  }

  /// Track a feature usage event
  Future<void> trackFeatureUsage(
    String featureName, {
    String? category,
    Map<String, dynamic>? parameters,
    bool isPremium = false,
  }) async {
    await track(PostHogEventType.featureUsed, {
      'feature_name': featureName,
      if (category != null) 'feature_category': category,
      'is_premium_feature': isPremium,
      'usage_timestamp': DateTime.now().toIso8601String(),
      ...?parameters,
    });
  }

  /// Track a business event (purchase, subscription, etc.)
  Future<void> trackBusiness(
    PostHogEventType businessEventType,
    Map<String, dynamic> businessData, {
    String? transactionId,
    double? revenue,
    String? currency,
  }) async {
    final businessEvents = [
      PostHogEventType.purchaseCompleted,
      PostHogEventType.subscriptionStarted,
      PostHogEventType.subscriptionCancelled,
      PostHogEventType.trialStarted,
      PostHogEventType.trialEnded,
    ];

    if (!businessEvents.contains(businessEventType)) {
      throw ArgumentError('Invalid business event type: $businessEventType');
    }

    await track(businessEventType, {
      ...businessData,
      if (transactionId != null) 'transaction_id': transactionId,
      if (revenue != null) 'revenue': revenue,
      if (currency != null) 'currency': currency,
      'business_event': true,
    });
  }

  /// Get recent events
  List<PostHogEvent> getRecentEvents({int limit = 50}) {
    return _eventQueue.take(limit).toList();
  }

  /// Empty the event queue
  Future<void> flushEvents() async {
    if (!_isInitialized) return;

    try {
      await Posthog().flush();
      if (kDebugMode) {
        debugPrint('Event queue flushed (${_eventQueue.length} events)');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Failed to flush events: $e');
      }
    }
  }

  /// Internal methods

  bool _canTrackEvent(String eventName) {
    return PostHogPrivacyManager.instance.canTrackEvent(eventName);
  }

  Map<String, dynamic> _enrichProperties(Map<String, dynamic> properties) {
    return {
      ...properties,
      'app_version': '1.0.0',
      'platform': defaultTargetPlatform.name,
      'session_id': _postHogService.sessionId,
      'timestamp': DateTime.now().toIso8601String(),
      'timezone': DateTime.now().timeZoneName,
      'locale': 'fr_FR',
    };
  }

  String? _getCurrentScreenName() {
    // TODO: Integration with navigation service
    return 'unknown_screen';
  }

  Future<void> _sendEvent(PostHogEvent event) async {
    try {
      // PostHog properties must be non-null Objects. Drop null-valued props
      // instead of casting them (`null as Object` throws, which silently
      // dropped any event carrying an optional property — and our spec uses
      // many nullable props: prayer_id?, mode:null, mood?, step_id on skip…).
      final safeProps = <String, Object>{};
      event.properties.forEach((key, value) {
        if (value != null) safeProps[key] = value as Object;
      });
      await Posthog().capture(
        eventName: event.name,
        properties: safeProps,
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Failed to send event ${event.name}: $e');
      }
      rethrow;
    }
  }

  /// Stop the module
  Future<void> shutdown() async {
    try {
      await flushEvents();
      _eventQueue.clear();
      _isInitialized = false;
      if (kDebugMode) {
        debugPrint('EventTrackingModule shutdown');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error during EventTrackingModule shutdown: $e');
      }
    }
  }

  /// Module statistics
  Map<String, dynamic> getStats() {
    return {
      'initialized': _isInitialized,
      'queued_events': _eventQueue.length,
      'can_track': PostHogPrivacyManager.instance.canTrackEvent('test'),
    };
  }
}
