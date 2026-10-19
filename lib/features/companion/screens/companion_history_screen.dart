import 'package:faithlock/features/companion/models/companion_conversation.dart';
import 'package:faithlock/features/companion/services/companion_chat_service.dart';
import 'package:faithlock/features/companion/services/companion_history_service.dart';
import 'package:faithlock/services/analytics/posthog/export.dart';
import 'package:faithlock/shared/widgets/cozy/cozy.dart';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

/// List of saved Companion conversations. Tapping one pops with the selected
/// [CompanionConversation] so the chat screen can reopen it.
class CompanionHistoryScreen extends StatefulWidget {
  const CompanionHistoryScreen({super.key});

  @override
  State<CompanionHistoryScreen> createState() => _CompanionHistoryScreenState();
}

class _CompanionHistoryScreenState extends State<CompanionHistoryScreen> {
  final CompanionHistoryService _history = CompanionHistoryService();
  final PostHogService _analytics = PostHogService.instance;
  List<CompanionConversation>? _items;
  bool _openedTracked = false;

  void _track(String event, [Map<String, dynamic> props = const {}]) {
    if (_analytics.isReady) _analytics.events.trackCustom(event, props);
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final items = await _history.loadAll();
    if (!mounted) return;
    setState(() => _items = items);
    if (!_openedTracked) {
      _openedTracked = true;
      _track('companion_history_opened', {'conversation_count': items.length});
    }
  }

  Future<void> _delete(CompanionConversation c) async {
    _track('companion_conversation_deleted');
    await _history.delete(c.id);
    await _load();
  }

  String _subtitle(CompanionConversation c) {
    final firstAssistant = c.messages.firstWhere(
      (m) => m.role == 'assistant',
      orElse: () => c.messages.isNotEmpty
          ? c.messages.last
          : const CompanionMessage(role: 'assistant', content: ''),
    );
    final text = firstAssistant.content.replaceAll('\n', ' ').trim();
    return text.length > 80 ? '${text.substring(0, 80)}…' : text;
  }

  @override
  Widget build(BuildContext context) {
    final items = _items;
    return Scaffold(
      backgroundColor: CozyColors.background,
      appBar: AppBar(
        backgroundColor: CozyColors.background,
        elevation: 0,
        titleSpacing: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              color: CozyColors.ink, size: 20),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Text('Your conversations', style: CozyText.heading),
      ),
      body: SafeArea(
        top: false,
        child: items == null
            ? const Center(child: CircularProgressIndicator())
            : items.isEmpty
                ? _empty()
                : ListView.separated(
                    padding: const EdgeInsets.all(CozyTokens.space16),
                    itemCount: items.length,
                    itemBuilder: (context, i) => _tile(items[i]),
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: CozyTokens.space12),
                  ),
      ),
    );
  }

  Widget _empty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(CozyTokens.space32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const HugeIcon(
              icon: HugeIcons.strokeRoundedBubbleChatSpark,
              color: CozyColors.inkMuted,
              size: 40,
            ),
            const SizedBox(height: CozyTokens.space16),
            Text('No conversations yet', style: CozyText.heading),
            const SizedBox(height: CozyTokens.space8),
            Text(
              'Your chats with the Companion will appear here.',
              textAlign: TextAlign.center,
              style: CozyText.subtitle,
            ),
          ],
        ),
      ),
    );
  }

  Widget _tile(CompanionConversation c) {
    return GestureDetector(
      onTap: () => Navigator.of(context).pop(c),
      child: Container(
        padding: const EdgeInsets.all(CozyTokens.space16),
        decoration: ShapeDecoration(
          color: CozyColors.surface,
          shape: CozyTokens.smooth(
            CozyTokens.radiusMd,
            side: const BorderSide(
              color: CozyColors.outline,
              width: CozyTokens.borderWidth,
            ),
          ),
          shadows: CozyTokens.shadowHard,
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    c.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: CozyText.heading,
                  ),
                  const SizedBox(height: CozyTokens.space4),
                  Text(
                    _subtitle(c),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: CozyText.subtitle,
                  ),
                ],
              ),
            ),
            const SizedBox(width: CozyTokens.space8),
            IconButton(
              icon: const HugeIcon(
                icon: HugeIcons.strokeRoundedDelete02,
                color: CozyColors.inkMuted,
                size: 20,
              ),
              onPressed: () => _delete(c),
            ),
          ],
        ),
      ),
    );
  }
}
