import 'package:faithlock/features/companion/services/companion_chat_service.dart';

/// A saved Companion conversation (stored locally, never leaves the device).
class CompanionConversation {
  final String id;
  String title;
  final int createdAt; // ms since epoch
  int updatedAt; // ms since epoch
  List<CompanionMessage> messages;

  CompanionConversation({
    required this.id,
    required this.title,
    required this.createdAt,
    required this.updatedAt,
    required this.messages,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'createdAt': createdAt,
        'updatedAt': updatedAt,
        'messages': messages.map((m) => m.toJson()).toList(),
      };

  factory CompanionConversation.fromJson(Map<String, dynamic> j) =>
      CompanionConversation(
        id: j['id'] as String,
        title: (j['title'] as String?)?.trim().isNotEmpty == true
            ? j['title'] as String
            : 'Conversation',
        createdAt: j['createdAt'] as int? ?? 0,
        updatedAt: j['updatedAt'] as int? ?? 0,
        messages: ((j['messages'] as List?) ?? const [])
            .map((e) =>
                CompanionMessage.fromJson((e as Map).cast<String, dynamic>()))
            .toList(),
      );
}
