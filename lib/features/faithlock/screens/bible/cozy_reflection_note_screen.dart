import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:share_plus/share_plus.dart';

import 'package:faithlock/features/bible/controllers/bible_engagement_controller.dart';
import 'package:faithlock/services/analytics/posthog/export.dart';
import 'package:faithlock/shared/widgets/cozy/cozy.dart';

/// Reflection / note-taking screen.
///
/// Constructor:
/// ```dart
/// CozyReflectionNoteScreen(passageReference: 'Genesis 1:1')
/// ```
///
/// Saving persists the reflection via [BibleEngagementController] then
/// pops back and shows a confirmation snackbar.
class CozyReflectionNoteScreen extends StatefulWidget {
  /// Verse reference this reflection is tied to, e.g. "Genesis 1:1".
  final String passageReference;

  const CozyReflectionNoteScreen({
    super.key,
    required this.passageReference,
  });

  @override
  State<CozyReflectionNoteScreen> createState() =>
      _CozyReflectionNoteScreenState();
}

class _CozyReflectionNoteScreenState extends State<CozyReflectionNoteScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();

  bool _isSaving = false;

  final PostHogService _analytics = PostHogService.instance;

  // Lazily find-or-create the engagement controller.
  BibleEngagementController get _engagement {
    if (!Get.isRegistered<BibleEngagementController>()) {
      Get.put(BibleEngagementController());
    }
    return Get.find<BibleEngagementController>();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  // ── Save ───────────────────────────────────────────────────────────────────

  Future<void> _save() async {
    final title = _titleController.text.trim();
    final note = _noteController.text.trim();

    if (title.isEmpty && note.isEmpty) {
      CozyToast.show(
        context,
        'bibleui_reflectionEmptyWarning'.tr,
        variant: CozyToastVariant.error,
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      await _engagement.addReflection(
        passageReference: widget.passageReference,
        title: title.isEmpty ? widget.passageReference : title,
        note: note,
      );

      if (_analytics.isReady) {
        _analytics.events.trackCustom('bible_reflection_saved', {
          'passage_ref': widget.passageReference,
          'note_length': note.length,
          'has_title': title.isNotEmpty,
        });
      }

      if (!mounted) return;
      // Insert the toast into the root overlay *before* popping — it outlives
      // the popped route and lands visually over the reading screen.
      CozyToast.show(
        context,
        'bibleui_reflectionSaved'.tr,
        variant: CozyToastVariant.success,
      );
      Get.back();
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  // ── Share ──────────────────────────────────────────────────────────────────

  Future<void> _shareReflection() async {
    final title = _titleController.text.trim();
    final note = _noteController.text.trim();
    final parts = <String>[
      if (title.isNotEmpty) title,
      widget.passageReference,
      if (note.isNotEmpty) note,
    ];
    final text = parts.join('\n\n');
    try {
      await SharePlus.instance.share(
        ShareParams(text: text, subject: widget.passageReference),
      );
    } catch (_) {
      // System share unavailable — fall back to clipboard.
      await Clipboard.setData(ClipboardData(text: text));
      if (!mounted) return;
      CozyToast.show(context, 'bibleui_reflectionCopied'.tr);
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CozyColors.background,
      // Keyboard pushes content up; scroll handles any overflow.
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(),
            Expanded(
              child: SingleChildScrollView(
                // Extra bottom padding tracks the keyboard height dynamically.
                padding: EdgeInsets.fromLTRB(
                  20,
                  20,
                  20,
                  24 + MediaQuery.of(context).viewInsets.bottom,
                ),
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildPassageCard(),
                    const SizedBox(height: 24),
                    _fieldLabel('bible_thoughtTitle'.tr.toUpperCase()),
                    const SizedBox(height: 8),
                    CozyTextField(
                      controller: _titleController,
                      hintText: 'bible_reflectionTitleHint'.tr,
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: 20),
                    _fieldLabel('bible_heartsNote'.tr.toUpperCase()),
                    const SizedBox(height: 8),
                    CozyTextField(
                      controller: _noteController,
                      hintText: 'bible_reflectionNoteHint'.tr,
                      maxLines: 7,
                      minLines: 5,
                      textInputAction: TextInputAction.done,
                    ),
                    const SizedBox(height: 28),
                    CozyButton(
                      text: 'bible_saveReflection'.tr,
                      icon: const HugeIcon(
                        icon: HugeIcons.strokeRoundedBookmark01,
                        color: CozyColors.onPrimary,
                        size: 20,
                      ),
                      isLoading: _isSaving,
                      onTap: _save,
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Top bar ────────────────────────────────────────────────────────────────

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        children: [
          CozyIconButton(
            icon: HugeIcons.strokeRoundedCancel01,
            onTap: Get.back,
            size: 48,
          ),
          Expanded(
            child: Text(
              'bible_reflection'.tr,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: CozyText.title,
            ),
          ),
          CozyIconButton(
            icon: HugeIcons.strokeRoundedShare01,
            onTap: _shareReflection,
            size: 48,
          ),
        ],
      ),
    );
  }

  // ── Passage card ───────────────────────────────────────────────────────────

  Widget _buildPassageCard() {
    return CozyCard(
      color: CozyColors.surfaceMuted,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          CozyIconChip(
            size: 52,
            iconSize: 26,
            background: CozyColors.peach,
            child: const Text('📖', style: TextStyle(fontSize: 22)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'bibleui_passage'.tr,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: CozyText.label.copyWith(
                    fontSize: 10,
                    letterSpacing: 1.2,
                    color: CozyColors.inkMuted,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.passageReference,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: CozyText.heading,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Field label ────────────────────────────────────────────────────────────

  Widget _fieldLabel(String text) {
    return Text(
      text,
      style: CozyText.label.copyWith(
        fontSize: 11,
        letterSpacing: 1.2,
        color: CozyColors.inkMuted,
      ),
    );
  }
}
