import 'package:faithlock/services/analytics/posthog/config/posthog_config.dart';
import 'package:faithlock/services/analytics/posthog/modules/campaign_module.dart';
import 'package:faithlock/services/analytics/posthog/modules/conversion_module.dart';
import 'package:faithlock/services/analytics/posthog/modules/event_tracking_module.dart';
import 'package:faithlock/services/analytics/posthog/modules/feature_flags_module.dart';
import 'package:faithlock/services/analytics/posthog/modules/onboarding_analytics_module.dart';
import 'package:faithlock/services/analytics/posthog/modules/paywall_analytics_module.dart';
import 'package:faithlock/services/analytics/posthog/modules/person_properties_module.dart';
import 'package:faithlock/services/analytics/posthog/modules/screen_tracking_module.dart';
import 'package:faithlock/services/analytics/posthog/modules/session_recording_module.dart';
import 'package:faithlock/services/analytics/posthog/modules/surveys_module.dart';
import 'package:faithlock/services/analytics/posthog/modules/user_analytics_module.dart';
import 'package:faithlock/services/analytics/posthog/utils/privacy_manager.dart';
import 'package:flutter/foundation.dart';
import 'package:posthog_flutter/posthog_flutter.dart';

/// Complete PostHog service for analytics and tracking
///
/// This service provides a comprehensive interface for all PostHog functionalities
/// with specialized modules for different types of tracking.
///
/// Main features:
/// - Event tracking with validation
/// - User analytics and profiles
/// - Navigation and screen tracking
/// - Feature flags and A/B testing
/// - Session recording and replay
/// - Conversion tracking for marketing
/// - Campaign management
/// - Surveys and feedback
/// - GDPR compliance and privacy
///
/// Usage:
/// ```dart
/// final posthog = PostHogService.instance;
/// await posthog.init();
///
/// // Event tracking
/// posthog.events.track(PostHogEventType.userSignup, {'method': 'email'});
///
/// // User analytics
/// posthog.users.identify('user_123', {'email': 'user@example.com'});
///
/// // Feature flags
/// final showNewFeature = await posthog.featureFlags.isEnabled('new_feature');
/// ```
class PostHogService {
  static PostHogService? _instance;
  static PostHogService get instance {
    _instance ??= PostHogService._();
    return _instance!;
  }

  PostHogService._();

  bool _isInitialized = false;
  bool _isEnabled = true;
  String? _currentUserId;
  String? _sessionId;

  // Modules
  late final EventTrackingModule _eventModule;
  late final UserAnalyticsModule _userModule;
  late final ScreenTrackingModule _screenModule;
  late final FeatureFlagsModule _featureFlagsModule;
  late final SessionRecordingModule _sessionModule;
  late final ConversionModule _conversionModule;
  late final CampaignModule _campaignModule;
  late final SurveysModule _surveysModule;
  late final OnboardingAnalyticsModule _onboardingModule;
  late final PaywallAnalyticsModule _paywallModule;
  late final PersonPropertiesModule _personPropertiesModule;

  // Getters with safety checks
  EventTrackingModule get events {
    if (!_isInitialized) {
      throw StateError(
          'PostHogService must be initialized before accessing events module');
    }
    return _eventModule;
  }

  UserAnalyticsModule get users {
    if (!_isInitialized) {
      throw StateError(
          'PostHogService must be initialized before accessing users module');
    }
    return _userModule;
  }

  ScreenTrackingModule get screens {
    if (!_isInitialized) {
      throw StateError(
          'PostHogService must be initialized before accessing screens module');
    }
    return _screenModule;
  }

  FeatureFlagsModule get featureFlags {
    if (!_isInitialized) {
      throw StateError(
          'PostHogService must be initialized before accessing featureFlags module');
    }
    return _featureFlagsModule;
  }

  SessionRecordingModule get sessions {
    if (!_isInitialized) {
      throw StateError(
          'PostHogService must be initialized before accessing sessions module');
    }
    return _sessionModule;
  }

  ConversionModule get conversions {
    if (!_isInitialized) {
      throw StateError(
          'PostHogService must be initialized before accessing conversions module');
    }
    return _conversionModule;
  }

  CampaignModule get campaigns {
    if (!_isInitialized) {
      throw StateError(
          'PostHogService must be initialized before accessing campaigns module');
    }
    return _campaignModule;
  }

  SurveysModule get surveys {
    if (!_isInitialized) {
      throw StateError(
          'PostHogService must be initialized before accessing surveys module');
    }
    return _surveysModule;
  }

  OnboardingAnalyticsModule get onboarding {
    if (!_isInitialized) {
      throw StateError(
          'PostHogService must be initialized before accessing onboarding module');
    }
    return _onboardingModule;
  }

  PaywallAnalyticsModule get paywall {
    if (!_isInitialized) {
      throw StateError(
          'PostHogService must be initialized before accessing paywall module');
    }
    return _paywallModule;
  }

  PersonPropertiesModule get personProperties {
    if (!_isInitialized) {
      throw StateError(
          'PostHogService must be initialized before accessing personProperties module');
    }
    return _personPropertiesModule;
  }

  bool get isInitialized => _isInitialized;
  bool get isEnabled => _isEnabled;
  String? get currentUserId => _currentUserId;
  String? get sessionId => _sessionId;

  /// Initialize the service
  Future<void> init({
    String? customApiKey,
    String? environment,
    bool? enableDebug,
  }) async {
    try {
      if (customApiKey == null || customApiKey.isEmpty) {
        if (kDebugMode) {
          debugPrint('PostHog API key not provided. Disabling PostHog.');
        }
        _isEnabled = false;
        return;
      }

      await PostHogPrivacyManager.instance.init();

      // Analytics is on by default for this app: the onboarding module already
      // captures directly and [_isEnabled] defaults to true. The consent gate
      // that guards every `events.trackCustom` call (PostHogPrivacyManager
      // .canTrackEvent → requires ConsentStatus.granted) was never wired to
      // grant, so every custom event was silently dropped while only the
      // direct-capture onboarding events came through. Default-grant exactly
      // once when undecided, so an explicit later opt-out / denial is honoured.
      if (PostHogPrivacyManager.instance.consentStatus ==
          ConsentStatus.pending) {
        await PostHogPrivacyManager.instance.setConsent(ConsentStatus.granted);
      }

      final config = PostHogConfigManager.createConfig(
        apiKey: customApiKey,
      );
      if (environment != null) {
        config.configureForEnvironment(environment);
      }
      if (enableDebug != null) {
        config.debug = enableDebug;
      }

      await Posthog().setup(config);

      _sessionId = _generateSessionId();

      _eventModule = EventTrackingModule(this);
      _userModule = UserAnalyticsModule(this);
      _screenModule = ScreenTrackingModule(this);
      _featureFlagsModule = FeatureFlagsModule(this);
      _sessionModule = SessionRecordingModule(this);
      _conversionModule = ConversionModule(this);
      _campaignModule = CampaignModule(this);
      _surveysModule = SurveysModule(this);
      _onboardingModule = OnboardingAnalyticsModule(this);
      _paywallModule = PaywallAnalyticsModule(this);
      _personPropertiesModule = PersonPropertiesModule(this);

      await _personPropertiesModule.init();
      await _eventModule.init();
      await _userModule.init();
      await _screenModule.init();
      await _featureFlagsModule.init();
      await _sessionModule.init();
      await _conversionModule.init();
      await _campaignModule.init();
      await _surveysModule.init();
      await _onboardingModule.init();
      await _paywallModule.init();

      _isInitialized = true;

      if (kDebugMode) {
        debugPrint('PostHog initialized successfully');
      }

      await _trackSystemEvent('posthog_initialized', {
        'session_id': _sessionId,
        'version': '1.0.0',
        'environment': environment ?? 'production',
      });
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Failed to initialize PostHog: $e');
      }
      _isEnabled = false;
    }
  }

  void disable() {
    _isEnabled = false;
    if (kDebugMode) {
      debugPrint('PostHog tracking disabled');
    }
  }

  void enable() {
    _isEnabled = true;
    if (kDebugMode) {
      debugPrint('PostHog tracking enabled');
    }
  }

  bool get isReady => _isInitialized && _isEnabled;

  Future<void> flush() async {
    if (!isReady) return;

    try {
      await Posthog().flush();
      if (kDebugMode) {
        debugPrint('PostHog events flushed');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Failed to flush PostHog events: $e');
      }
    }
  }

  Future<void> reset() async {
    if (!isReady) return;

    try {
      await Posthog().reset();
      _currentUserId = null;
      _sessionId = _generateSessionId();

      await _userModule.reset();
      await _screenModule.reset();
      await _featureFlagsModule.reset();
      await _sessionModule.reset();
      await _conversionModule.reset();
      await _campaignModule.reset();
      await _onboardingModule.reset();
      await _paywallModule.reset();
      await _personPropertiesModule.reset();

      if (kDebugMode) {
        debugPrint('PostHog service reset');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Failed to reset PostHog: $e');
      }
    }
  }

  Future<void> shutdown() async {
    if (!_isInitialized) return;

    try {
      await flush();

      // Arrêt des modules
      await _eventModule.shutdown();
      await _userModule.shutdown();
      await _screenModule.shutdown();
      await _featureFlagsModule.shutdown();
      await _sessionModule.shutdown();
      await _conversionModule.shutdown();
      await _campaignModule.shutdown();
      await _surveysModule.shutdown();
      await _onboardingModule.shutdown();
      await _paywallModule.shutdown();
      await _personPropertiesModule.shutdown();

      // Arrêt du SDK PostHog
      await Posthog().close();

      _isInitialized = false;

      if (kDebugMode) {
        debugPrint('PostHog service shutdown');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error during PostHog shutdown: $e');
      }
    }
  }

  Future<void> _trackSystemEvent(
    String eventName,
    Map<String, dynamic> properties,
  ) async {
    if (!isReady) return;

    try {
      await Posthog().capture(
        eventName: eventName,
        properties: {
          ...properties,
          'system_event': true,
          'session_id': _sessionId!,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Failed to track system event $eventName: $e');
      }
    }
  }

  String _generateSessionId() {
    return 'session_${DateTime.now().millisecondsSinceEpoch}_${_generateRandomString(8)}';
  }

  String _generateRandomString(int length) {
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    return List.generate(
            length, (index) => chars[DateTime.now().microsecond % chars.length])
        .join();
  }

  void setTestMode(bool testMode) {
    if (testMode) {
      _isEnabled = false;
      if (kDebugMode) {
        debugPrint('PostHog set to test mode - tracking disabled');
      }
    }
  }

  /// Obtient les statistiques du service
  Map<String, dynamic> getStats() {
    return {
      'initialized': _isInitialized,
      'enabled': _isEnabled,
      'current_user_id': _currentUserId,
      'session_id': _sessionId,
      'modules_loaded': _isInitialized ? 11 : 0,
      'privacy_opt_out': PostHogPrivacyManager.instance.isOptedOut,
      'consent_status': PostHogPrivacyManager.instance.consentStatus.name,
    };
  }
}
