import 'package:envied/envied.dart';

part 'env.g.dart';

@Envied(path: '.env', obfuscate: true)
abstract class Env {
  @EnviedField(varName: 'POSTHOG_API_KEY')
  static String postHogApiKey = _Env.postHogApiKey;

  @EnviedField(varName: 'POSTHOG_HOST', defaultValue: 'https://us.i.posthog.com')
  static String postHogHost = _Env.postHogHost;

  @EnviedField(varName: 'REVENUECAT_API_KEY')
  static String revenueCatApiKey = _Env.revenueCatApiKey;

  @EnviedField(varName: 'OPENAI_API_KEY')
  static String openAiApiKey = _Env.openAiApiKey;

  /// OpenRouter API key — powers the Companion chat (gpt-5 via OpenRouter).
  @EnviedField(varName: 'OPENROUTER_API_KEY', defaultValue: '')
  static String openRouterApiKey = _Env.openRouterApiKey;

  @EnviedField(varName: 'TIKTOK_IOS_APP_ID', defaultValue: 'YOUR_TIKTOK_IOS_APP_ID')
  static String tiktokIosAppId = _Env.tiktokIosAppId;

  @EnviedField(varName: 'TIKTOK_IOS_ID', defaultValue: 'YOUR_TIKTOK_IOS_ID')
  static String tiktokIosId = _Env.tiktokIosId;

  @EnviedField(varName: 'TIKTOK_ANDROID_APP_ID', defaultValue: 'YOUR_TIKTOK_ANDROID_APP_ID')
  static String tiktokAndroidAppId = _Env.tiktokAndroidAppId;

  @EnviedField(varName: 'TIKTOK_ANDROID_ID', defaultValue: 'YOUR_TIKTOK_ANDROID_ID')
  static String tiktokAndroidId = _Env.tiktokAndroidId;

  // ── Supabase ─────────────────────────────────────────────────────────────────

  /// Supabase project URL, e.g. https://xyzcompany.supabase.co
  @EnviedField(varName: 'SUPABASE_URL', defaultValue: 'https://YOUR_PROJECT.supabase.co')
  static String supabaseUrl = _Env.supabaseUrl;

  /// Supabase anon (public) key — safe to ship in the client.
  @EnviedField(varName: 'SUPABASE_ANON_KEY', defaultValue: 'YOUR_SUPABASE_ANON_KEY')
  static String supabaseAnonKey = _Env.supabaseAnonKey;
}
