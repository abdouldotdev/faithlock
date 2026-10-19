import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:share_plus/share_plus.dart';

import 'package:faithlock/features/faithlock/controllers/stats_controller.dart';
import 'package:faithlock/features/faithlock/models/export.dart';
import 'package:faithlock/features/faithlock/screens/bible/cozy_reflection_note_screen.dart';
import 'package:faithlock/features/faithlock/screens/cozy_mood_check_in_screen.dart';
import 'package:faithlock/features/faithlock/services/stats_service.dart';
import 'package:faithlock/features/onboarding/feature_tour/feature_tour.dart';
import 'package:faithlock/features/prayer_audio/models/prayer.dart';
import 'package:faithlock/services/analytics/posthog/export.dart';
import 'package:faithlock/services/rate_app_service.dart';
import 'package:faithlock/shared/widgets/cozy/cozy.dart';

/// Calm, readable screen for praying a written prayer at your own pace.
///
/// The prayer text isn't dumped all at once — it's revealed in small ~3-line
/// blocks that fade in one after another (with `(pause)` markers stripped and
/// used as longer breaths), so reading feels guided and unhurried. The "Amen"
/// button stays hidden until the whole prayer has surfaced, then slides in with
/// a haptic. Tapping the text reveals everything instantly for those who'd
/// rather read at their own speed. Finishing opens the post-prayer mood
/// check-in, then pops back.
class CozyWrittenPrayerScreen extends StatefulWidget {
  const CozyWrittenPrayerScreen({
    super.key,
    required this.prayer,
    this.onCompleted,
  });

  final Prayer prayer;

  /// When set (e.g. praying to unlock an app), this runs after the post-prayer
  /// mood check-in instead of simply popping — letting the caller release the
  /// blocked apps. When null, finishing just pops back as before.
  final Future<void> Function()? onCompleted;

  @override
  State<CozyWrittenPrayerScreen> createState() =>
      _CozyWrittenPrayerScreenState();
}

class _CozyWrittenPrayerScreenState extends State<CozyWrittenPrayerScreen>
    with SingleTickerProviderStateMixin {
  final ScrollController _scroll = ScrollController();
  final PostHogService _analytics = PostHogService.instance;

  /// `'unlock'` when praying to earn back an app, `'home'` otherwise.
  String get _source => widget.onCompleted != null ? 'unlock' : 'home';

  /// Set once the user reaches "Amen" — distinguishes a completed prayer from
  /// one abandoned by closing the screen.
  bool _completed = false;
  late final DateTime _startedAt;

  void _track(String event, Map<String, dynamic> props) {
    if (_analytics.isReady) _analytics.events.trackCustom(event, props);
  }

  /// Reveal animation for the *newest* block (its text fades from 0 → full ink).
  late final AnimationController _fade;

  late final List<_Block> _blocks;
  int _revealed = 0;
  bool _finished = false;
  Timer? _hold;

  /// Roughly two lines of body text at the reading size below.
  static const int _blockChars = 90;

  /// Prefer the full prayer script; fall back to the verse text.
  String get _body {
    final script = widget.prayer.scriptText?.trim() ?? '';
    if (script.isNotEmpty) return script;
    return widget.prayer.scriptureText?.trim() ?? '';
  }

  @override
  void initState() {
    super.initState();
    _startedAt = DateTime.now();
    _track('prayer_started', {
      'prayer_id': widget.prayer.id,
      'mode': 'text',
      'source': _source,
    });
    _blocks = _parse(_body);
    _fade = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 560),
    )..addStatusListener(_onFadeStatus);

    if (_blocks.isEmpty) {
      // Nothing to reveal (e.g. placeholder text) — surface "Amen" right away.
      _finished = true;
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) => _revealNext());
    }
  }

  @override
  void dispose() {
    // Closed without reaching "Amen" → abandoned. Progress = how far the
    // reveal got through the prayer's blocks.
    if (!_completed) {
      final pct = _blocks.isEmpty
          ? 0
          : ((_revealed / _blocks.length) * 100).clamp(0, 100).round();
      _track('prayer_abandoned', {
        'prayer_id': widget.prayer.id,
        'mode': 'text',
        'source': _source,
        'progress_pct': pct,
      });
    }
    _hold?.cancel();
    _fade.dispose();
    _scroll.dispose();
    super.dispose();
  }

  // ── Reveal pacing ──────────────────────────────────────────────────────────

  void _onFadeStatus(AnimationStatus status) {
    if (status != AnimationStatus.completed || !mounted) return;
    if (_revealed >= _blocks.length) {
      _onFinished();
      return;
    }
    // Hold long enough to actually read the block that just surfaced — scaled
    // to its length (~human reading speed) — with an extra breath at a (pause).
    final justRead = _blocks[_revealed - 1];
    final words =
        justRead.text.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;
    var ms = (words * 190).clamp(1100, 2400);
    if (_blocks[_revealed].pauseBefore) ms += 600;
    _hold = Timer(Duration(milliseconds: ms), _revealNext);
  }

  void _revealNext() {
    if (!mounted) return;
    if (_revealed >= _blocks.length) {
      _onFinished();
      return;
    }
    setState(() => _revealed++);
    _fade.forward(from: 0);
    _autoScroll();
  }

  /// Skip the cascade — reveal everything at once.
  void _revealAll() {
    if (_finished) return;
    _hold?.cancel();
    _fade.stop();
    setState(() {
      _revealed = _blocks.length;
      _fade.value = 1.0;
    });
    _autoScroll();
    _onFinished();
  }

  void _onFinished() {
    if (_finished) return;
    setState(() => _finished = true);
    HapticFeedback.mediumImpact();
  }

  void _autoScroll() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      _scroll.animateTo(
        _scroll.position.maxScrollExtent,
        duration: const Duration(milliseconds: 480),
        curve: Curves.easeOut,
      );
    });
  }

  // ── Parsing ────────────────────────────────────────────────────────────────

  /// Splits the script on `(pause)` (stripped), then groups sentences into
  /// ~3-line blocks. The first block after a pause carries [_Block.pauseBefore].
  List<_Block> _parse(String body) {
    if (body.isEmpty) return const [];
    final parts = body.split('(pause)');
    final blocks = <_Block>[];

    for (var p = 0; p < parts.length; p++) {
      final part = parts[p].trim();
      if (part.isEmpty) continue;

      final sentences = part.split(RegExp(r'(?<=[.!?…])\s+'));
      final buf = StringBuffer();
      var firstInPart = true;

      void flush() {
        final t = buf.toString().trim();
        if (t.isEmpty) return;
        blocks.add(_Block(text: t, pauseBefore: p > 0 && firstInPart));
        firstInPart = false;
        buf.clear();
      }

      for (final s in sentences) {
        final t = s.trim();
        if (t.isEmpty) continue;
        if (buf.isNotEmpty) buf.write(' ');
        buf.write(t);
        if (buf.length >= _blockChars) flush();
      }
      flush();
    }
    return blocks;
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final hasBody = _body.isNotEmpty;

    return Scaffold(
      backgroundColor: CozyColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Top bar
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Row(
                children: [
                  CozyIconButton(
                    icon: HugeIcons.strokeRoundedCancel01,
                    onTap: Get.back,
                    size: 48,
                  ),
                  const Spacer(),
                ],
              ),
            ),
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                // Tap reveals everything while the cascade runs; once finished
                // the text is selectable, so the tap handler steps aside.
                onTap: _finished ? null : _revealAll,
                child: SingleChildScrollView(
                  controller: _scroll,
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.prayer.domain.displayName.toUpperCase(),
                        style:
                            CozyText.label.copyWith(color: CozyColors.primary),
                      ),
                      const SizedBox(height: 10),
                      Text(widget.prayer.title, style: CozyText.display),
                      const SizedBox(height: 8),
                      Text(widget.prayer.scriptureRef,
                          style: CozyText.subtitle),
                      const SizedBox(height: 28),
                      if (!hasBody)
                        Text(
                          'prayer_quietMoment'
                              .trParams({'ref': widget.prayer.scriptureRef}),
                          style: CozyText.body.copyWith(
                            fontSize: 19,
                            height: 1.7,
                            color: CozyColors.inkMuted,
                          ),
                        )
                      else if (_finished)
                        _buildSelectableBody()
                      else
                        AnimatedBuilder(
                          animation: _fade,
                          builder: (context, _) => _buildReveal(),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            // "Amen" only appears once the prayer has fully surfaced.
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 420),
              switchInCurve: Curves.easeOutCubic,
              transitionBuilder: (child, anim) => FadeTransition(
                opacity: anim,
                child: SizeTransition(
                  sizeFactor: anim,
                  axisAlignment: -1,
                  child: child,
                ),
              ),
              child: _finished
                  ? Padding(
                      key: const ValueKey('amen'),
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                      child: CozyButton(
                        text: 'prayer_amen'.tr,
                        icon: const HugeIcon(
                          icon: HugeIcons.strokeRoundedCheckmarkCircle02,
                          color: CozyColors.onPrimary,
                          size: 22,
                        ),
                        onTap: () => _finish(context),
                      ),
                    )
                  : const SizedBox(width: double.infinity),
            ),
          ],
        ),
      ),
    );
  }

  /// Flowing-paragraph spans. When [animated], only the first [_revealed]
  /// blocks are emitted and the newest fades in via [_fade]; otherwise every
  /// block is solid. `(pause)` blocks break to a new paragraph.
  List<InlineSpan> _spans({required bool animated}) {
    final base = CozyText.body.copyWith(fontSize: 19, height: 1.7);
    final count = animated ? _revealed : _blocks.length;
    final spans = <InlineSpan>[];

    for (var i = 0; i < count; i++) {
      final block = _blocks[i];
      if (i > 0) {
        spans.add(TextSpan(text: block.pauseBefore ? '\n\n' : ' '));
      }
      final isNewest = animated && i == count - 1;
      final alpha = isNewest ? _fade.value.clamp(0.0, 1.0) : 1.0;
      spans.add(TextSpan(
        text: block.text,
        style: base.copyWith(color: CozyColors.ink.withValues(alpha: alpha)),
      ));
    }
    return spans;
  }

  /// Animated reveal paragraph (newest block fading in).
  Widget _buildReveal() =>
      Text.rich(TextSpan(children: _spans(animated: true)));

  /// Fully-surfaced, selectable paragraph with the cozy context menu (mirrors
  /// the Bible reader's selection toolbar).
  Widget _buildSelectableBody() {
    return Theme(
      data: Theme.of(context).copyWith(
        textSelectionTheme: TextSelectionThemeData(
          selectionColor: CozyColors.primary.withValues(alpha: 0.28),
          selectionHandleColor: CozyColors.primary,
        ),
      ),
      child: SelectableText.rich(
        TextSpan(children: _spans(animated: false)),
        enableInteractiveSelection: true,
        contextMenuBuilder: (context, editableTextState) {
          return _PrayerSelectionToolbar(
            state: editableTextState,
            actions: [
              _PrayerToolbarAction(
                icon: HugeIcons.strokeRoundedCopy01,
                label: 'prayer_copy'.tr,
                onTap: () {
                  editableTextState.hideToolbar();
                  _copy(_selectionOf(editableTextState));
                },
              ),
              _PrayerToolbarAction(
                icon: HugeIcons.strokeRoundedShare01,
                label: 'prayer_share'.tr,
                onTap: () {
                  editableTextState.hideToolbar();
                  _share(
                    _selectionOf(editableTextState),
                    _anchorRect(editableTextState),
                  );
                },
              ),
              _PrayerToolbarAction(
                icon: HugeIcons.strokeRoundedNoteEdit,
                label: 'prayer_reflect'.tr,
                onTap: () {
                  editableTextState.hideToolbar();
                  _reflect();
                },
              ),
            ],
          );
        },
      ),
    );
  }

  // ── Selection actions (Copy / Share / Reflect) ─────────────────────────────
  // Highlight & Bookmark are verse-level in the Bible reader (book/chapter/verse
  // persistence) and don't map to a prayer, so they're intentionally omitted.

  /// The whole prayer as plain text, for copy/share when nothing is selected.
  String get _fullText {
    final b = StringBuffer();
    for (var i = 0; i < _blocks.length; i++) {
      if (i > 0) b.write(_blocks[i].pauseBefore ? '\n\n' : ' ');
      b.write(_blocks[i].text);
    }
    return b.toString();
  }

  Future<void> _copy(String? selection) async {
    _track('prayer_text_action', {
      'action': 'copy',
      'prayer_id': widget.prayer.id,
    });
    final body = (selection != null && selection.trim().isNotEmpty)
        ? selection.trim()
        : _fullText;
    await Clipboard.setData(
      ClipboardData(text: '$body\n\n— ${widget.prayer.title}'),
    );
    if (!mounted) return;
    CozyToast.show(context, 'prayer_copiedToClipboard'.tr);
  }

  Future<void> _share(String? selection, Rect? origin) async {
    _track('prayer_text_action', {
      'action': 'share',
      'prayer_id': widget.prayer.id,
    });
    final body = (selection != null && selection.trim().isNotEmpty)
        ? selection.trim()
        : _fullText;
    await SharePlus.instance.share(
      ShareParams(
        text:
            '$body\n\n— ${widget.prayer.title}, ${widget.prayer.scriptureRef}',
        subject: widget.prayer.title,
        sharePositionOrigin: origin,
      ),
    );
  }

  void _reflect() {
    _track('prayer_text_action', {
      'action': 'reflect',
      'prayer_id': widget.prayer.id,
    });
    Get.to(
      () => CozyReflectionNoteScreen(
        passageReference: widget.prayer.scriptureRef,
      ),
    );
  }

  static String? _selectionOf(EditableTextState state) {
    final v = state.textEditingValue;
    final s = v.selection;
    if (!s.isValid || s.isCollapsed) return null;
    return v.text.substring(s.start, s.end);
  }

  static Rect _anchorRect(EditableTextState state) {
    final a = state.contextMenuAnchors.primaryAnchor;
    return Rect.fromCenter(center: a, width: 1, height: 1);
  }

  Future<void> _finish(BuildContext context) async {
    _completed = true;
    // Capture the prayed duration now, before the mood check-in dialog so its
    // interaction time isn't counted as prayer time.
    final prayedSeconds = DateTime.now().difference(_startedAt).inSeconds;
    _track('prayer_completed', {
      'prayer_id': widget.prayer.id,
      'mode': 'text',
      'source': _source,
      'time_spent_seconds': DateTime.now().difference(_startedAt).inSeconds,
    });
    final mood = await showCozyMoodCheckIn(
      context,
      prompt: 'mood_howIsYourHeart'.tr,
      subtitle: 'mood_afterTimeWithGod'.tr,
      showClose: false,
    );
    if (mood != null) {
      _track('mood_recorded', {
        'mood': mood.name,
        'phase': 'post',
        'context': 'written_prayer',
      });
    } else {
      _track('mood_skipped', {'phase': 'post', 'context': 'written_prayer'});
    }
    // Increment global prayer count (for rating prompt logic)
    // This counts ALL prayers: written, audio, and learning
    await RateAppService().incrementPrayerCount();
    unawaited(RateAppService().tryShowRatingPrompt());

    // Unlock mode: hand off to the caller (release apps); otherwise just pop.
    // In unlock mode the unlock flow records its own stats — don't double-count.
    if (widget.onCompleted != null) {
      await widget.onCompleted!.call();
    } else {
      // Home mode: record the session so "prayed today" reflects it.
      try {
        await StatsService().recordUnlockAttempt(
          verseId: widget.prayer.id,
          wasSuccessful: true,
          attemptCount: 1,
          timeToUnlockSeconds: prayedSeconds,
          method: UnlockMethod.prayerText,
        );
        // Refresh the home dashboard so "prayed today" reflects this session.
        if (Get.isRegistered<StatsController>()) {
          await Get.find<StatsController>().loadStats();
        }
      } catch (e) {
        debugPrint('⚠️ Failed to record prayer stats: $e');
      }
      FeatureTourController? tourController;
      bool isTourActive = false;
      if (Get.isRegistered<FeatureTourController>()) {
        tourController = Get.find<FeatureTourController>();
        isTourActive = tourController.active.value;
      }
      if (isTourActive) {
        // During the feature tour: complete the interactive step and pop back
        // to the main screen (closing both the prayer screen and the selector).
        tourController!.completeInteractiveStep('pray');
        // Pop twice: prayer screen -> selector -> main screen
        Get.back(); // close written prayer screen
        Get.back(); // close selector screen
      } else {
        // Normal flow: just pop back to the selector
        Get.back();
      }
    }
  }
}

/// One revealed chunk of the prayer (~3 lines). [pauseBefore] marks a chunk
/// that followed a `(pause)` in the script — rendered as a paragraph break.
class _Block {
  const _Block({required this.text, required this.pauseBefore});

  final String text;
  final bool pauseBefore;
}

// ── Cozy text-selection toolbar (mirrors the Bible reader) ───────────────────

class _PrayerToolbarAction {
  const _PrayerToolbarAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final List<List<dynamic>> icon;
  final String label;
  final VoidCallback onTap;
}

/// Positions a chunky cozy toolbar above (or below) the selection using
/// Flutter's [TextSelectionToolbarAnchors], so it never sits on the text.
class _PrayerSelectionToolbar extends StatelessWidget {
  const _PrayerSelectionToolbar({required this.state, required this.actions});

  final EditableTextState state;
  final List<_PrayerToolbarAction> actions;

  @override
  Widget build(BuildContext context) {
    final anchors = state.contextMenuAnchors;
    return TextSelectionToolbar(
      anchorAbove: anchors.primaryAnchor,
      anchorBelow: anchors.secondaryAnchor ?? anchors.primaryAnchor,
      toolbarBuilder: (context, child) => _PrayerToolbarShell(child: child),
      children: actions.map((a) => _PrayerToolbarButton(action: a)).toList(),
    );
  }
}

class _PrayerToolbarShell extends StatelessWidget {
  const _PrayerToolbarShell({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: ShapeDecoration(
        color: CozyColors.surface,
        shape: CozyTokens.smooth(
          CozyTokens.radiusPill,
          side: const BorderSide(
            color: CozyColors.outline,
            width: CozyTokens.borderWidth,
          ),
        ),
        shadows: CozyTokens.shadowHard,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      child: child,
    );
  }
}

class _PrayerToolbarButton extends StatelessWidget {
  const _PrayerToolbarButton({required this.action});

  final _PrayerToolbarAction action;

  @override
  Widget build(BuildContext context) {
    return CozyTappable(
      onTap: action.onTap,
      pressedScale: 0.9,
      child: Tooltip(
        message: action.label,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: HugeIcon(
            icon: action.icon,
            size: 22,
            color: CozyColors.ink,
          ),
        ),
      ),
    );
  }
}
