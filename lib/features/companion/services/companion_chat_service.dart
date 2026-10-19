import 'dart:convert';

import 'package:faithlock/config/env.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

/// One message in a Companion conversation.
class CompanionMessage {
  final String role; // 'user' or 'assistant'
  final String content;
  const CompanionMessage({required this.role, required this.content});

  Map<String, String> toApi() => {'role': role, 'content': content};

  Map<String, dynamic> toJson() => {'role': role, 'content': content};

  factory CompanionMessage.fromJson(Map<String, dynamic> j) => CompanionMessage(
        role: j['role'] as String,
        content: j['content'] as String,
      );
}

/// Backend for "The Companion" chat — gpt-5 via OpenRouter, driven by the
/// hardened, adversarially-tested system prompt
/// (assets/prompts/companion_system_prompt.txt, source of truth in
/// docs/companion-system-prompt.md).
///
/// Citation discipline is enforced at the prompt level (graceful abstention,
/// home-version-first, no verse fabrication) and reinforced with low
/// temperature. Phase B will additionally inject verbatim verse text retrieved
/// from the bundled BSB database (assets/databases/bible_bsb.db) under a
/// "VERIFIED SCRIPTURE" block so the model never relies on memory.
class CompanionChatService {
  static final CompanionChatService _instance = CompanionChatService._internal();
  factory CompanionChatService() => _instance;
  CompanionChatService._internal();

  static const String _apiUrl = 'https://openrouter.ai/api/v1/chat/completions';
  static const String _model = 'anthropic/claude-opus-4.1';
  static const String _promptAsset = 'assets/prompts/companion_system_prompt.txt';

  /// OpenAI/Google reasoning models need a capped effort so the answer isn't
  /// starved of tokens by "thinking"; Anthropic models run fine without it.
  static bool get _needsReasoningCap =>
      _model.startsWith('openai/') || _model.startsWith('google/');

  /// Default translation when the caller doesn't pass one (BSB is bundled).
  static const String _defaultVersion = 'Berean Standard Bible (BSB)';

  String? _promptTemplate; // cached raw prompt with {{...}} placeholders

  Future<String> _loadPrompt() async {
    return _promptTemplate ??= await rootBundle.loadString(_promptAsset);
  }

  /// A response-language directive appended to the (English) base prompt so the
  /// Companion answers in the app's current language. Mirrors the settings
  /// language picker (EN/FR); anything else falls back to English.
  String _languageDirective() {
    switch (Get.locale?.languageCode) {
      case 'fr':
        return '\n\n# LANGUAGE\n'
            'Respond entirely in French (français) — warm, natural and '
            'pastoral. When you quote or reference Scripture, give it in French.';
      default:
        return ''; // English — the base prompt is already English.
    }
  }

  Future<List<Map<String, String>>> _buildMessages(
    List<CompanionMessage> history,
    String? bibleVersion,
    String? verseContext,
  ) async {
    final template = await _loadPrompt();
    final system = template
            .replaceAll('{{BIBLE_VERSION}}', bibleVersion ?? _defaultVersion)
            .replaceAll('{{VERSE_CONTEXT}}', verseContext ?? '') +
        _languageDirective();
    return [
      {'role': 'system', 'content': system},
      ...history.map((m) => m.toApi()),
    ];
  }

  /// Streams the Companion's reply token-by-token (SSE) so the UI can type it
  /// out in real time. Yields incremental text deltas; on any failure yields a
  /// single graceful fallback string and completes.
  Stream<String> replyStream({
    required List<CompanionMessage> history,
    String? bibleVersion,
    String? verseContext,
  }) async* {
    if (Env.openRouterApiKey.isEmpty) {
      debugPrint('⚠️ Companion: OPENROUTER_API_KEY not set');
      yield _genericError;
      return;
    }

    final client = http.Client();
    try {
      final messages = await _buildMessages(history, bibleVersion, verseContext);
      final request = http.Request('POST', Uri.parse(_apiUrl))
        ..headers.addAll({
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${Env.openRouterApiKey}',
          'HTTP-Referer': 'https://faithlock.app',
          'X-Title': 'FaithLock Companion',
        })
        ..body = jsonEncode({
          'model': _model,
          'messages': messages,
          'temperature': 0.3,
          'max_tokens': 1500,
          if (_needsReasoningCap) 'reasoning': {'effort': 'low'},
          'stream': true,
        });

      final response = await client.send(request);
      if (response.statusCode != 200) {
        final body = await response.stream.bytesToString();
        debugPrint('❌ Companion stream: ${response.statusCode} - $body');
        yield _genericError;
        return;
      }

      bool sawContent = false;
      final lines = response.stream
          .transform(utf8.decoder)
          .transform(const LineSplitter());
      await for (final line in lines) {
        if (!line.startsWith('data:')) continue; // skip SSE comments/keepalives
        final data = line.substring(5).trim();
        if (data.isEmpty) continue;
        if (data == '[DONE]') break;
        try {
          final json = jsonDecode(data);
          final delta =
              json['choices']?[0]?['delta']?['content'] as String?;
          if (delta != null && delta.isNotEmpty) {
            sawContent = true;
            yield delta;
          }
        } catch (_) {
          // Ignore malformed partial frames.
        }
      }
      if (!sawContent) yield _genericError;
    } catch (e) {
      debugPrint('❌ Companion stream error: $e');
      yield _genericError;
    } finally {
      client.close();
    }
  }

  /// Returns the Companion's reply to the conversation so far.
  ///
  /// [history] is oldest → newest (includes the just-sent user message).
  /// [bibleVersion] is the translation the person is reading in.
  /// [verseContext] preloads a passage the user is reflecting on.
  Future<String> reply({
    required List<CompanionMessage> history,
    String? bibleVersion,
    String? verseContext,
  }) async {
    if (Env.openRouterApiKey.isEmpty) {
      debugPrint('⚠️ Companion: OPENROUTER_API_KEY not set');
      return _genericError;
    }

    try {
      final template = await _loadPrompt();
      final system = template
              .replaceAll('{{BIBLE_VERSION}}', bibleVersion ?? _defaultVersion)
              .replaceAll('{{VERSE_CONTEXT}}', verseContext ?? '') +
          _languageDirective();

      final messages = <Map<String, String>>[
        {'role': 'system', 'content': system},
        ...history.map((m) => m.toApi()),
      ];

      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${Env.openRouterApiKey}',
          'HTTP-Referer': 'https://faithlock.app',
          'X-Title': 'FaithLock Companion',
        },
        body: jsonEncode({
          'model': _model,
          'messages': messages,
          // Low temperature → citation fidelity, less wording drift.
          'temperature': 0.3,
          'max_tokens': 1500,
          if (_needsReasoningCap) 'reasoning': {'effort': 'low'},
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        final content =
            (data['choices']?[0]?['message']?['content'] as String?)?.trim();
        if (content == null || content.isEmpty) {
          debugPrint('⚠️ Companion: empty content from $_model');
          return _genericError;
        }
        return content;
      }

      if (response.statusCode == 402) {
        debugPrint('💳 Companion: OpenRouter out of credit (402)');
        return _genericError;
      }

      debugPrint('❌ Companion: ${response.statusCode} - ${response.body}');
      return _genericError;
    } catch (e) {
      debugPrint('❌ Companion error: $e');
      return _genericError;
    }
  }

  static const String _genericError =
      "I'm here with you, but I'm having trouble connecting right now. "
      'Give me a moment and try again. 🙏';
}
