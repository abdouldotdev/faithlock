import 'dart:convert';

import 'package:faithlock/features/companion/models/companion_conversation.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Local-only persistence for Companion conversations (SharedPreferences, JSON).
/// Nothing leaves the device — conversations are private to this install.
class CompanionHistoryService {
  static const String _key = 'companion_conversations_v1';

  static final CompanionHistoryService _instance =
      CompanionHistoryService._internal();
  factory CompanionHistoryService() => _instance;
  CompanionHistoryService._internal();

  /// All saved conversations, most-recently-updated first.
  Future<List<CompanionConversation>> loadAll() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key);
      if (raw == null || raw.isEmpty) return [];
      final list = (jsonDecode(raw) as List)
          .map((e) =>
              CompanionConversation.fromJson((e as Map).cast<String, dynamic>()))
          .toList();
      list.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      return list;
    } catch (e) {
      debugPrint('⚠️ Companion history load failed: $e');
      return [];
    }
  }

  /// Insert or update a conversation.
  Future<void> upsert(CompanionConversation c) async {
    final prefs = await SharedPreferences.getInstance();
    final all = await loadAll();
    final idx = all.indexWhere((x) => x.id == c.id);
    if (idx >= 0) {
      all[idx] = c;
    } else {
      all.add(c);
    }
    await prefs.setString(
        _key, jsonEncode(all.map((x) => x.toJson()).toList()));
  }

  Future<void> delete(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final all = await loadAll();
    all.removeWhere((x) => x.id == id);
    await prefs.setString(
        _key, jsonEncode(all.map((x) => x.toJson()).toList()));
  }
}
