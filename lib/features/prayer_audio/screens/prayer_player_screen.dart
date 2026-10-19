import 'dart:async';

import 'package:faithlock/config/app_config.dart';
import 'package:faithlock/features/faithlock/controllers/stats_controller.dart';
import 'package:faithlock/features/faithlock/models/export.dart';
import 'package:faithlock/features/faithlock/screens/cozy_mood_check_in_screen.dart';
import 'package:faithlock/features/faithlock/services/stats_service.dart';
import 'package:faithlock/features/prayer_audio/constants/prayer_palette.dart';
import 'package:faithlock/features/prayer_audio/controllers/prayer_player_controller.dart';
import 'package:faithlock/features/prayer_audio/models/prayer.dart';
import 'package:faithlock/features/prayer_audio/widgets/synced_script_reader.dart';
import 'package:faithlock/features/onboarding/feature_tour/feature_tour.dart';
import 'package:faithlock/services/analytics/posthog/export.dart';
import 'package:faithlock/services/rate_app_service.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Colors;
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:share_plus/share_plus.dart';

// ─── Constants ───────────────────────────────────────────────────────────────

const _cream = PrayerPalette.cream;
const _card = PrayerPalette.card;
const _ink = PrayerPalette.ink;
const _orange = PrayerPalette.orange;
const _peach = PrayerPalette.peach;
const _subtle = PrayerPalette.subtle;
const _font = PrayerPalette.font;

// ─── Prayer Player Screen ─────────────────────────────────────────────────────
//
// A guided-reading player: the script is the hero, highlighted line-by-line in
// sync with the on-device voice (SyncedScriptReader). Transport lives in a
// chunky dock at the bottom.

class PrayerPlayerScreen extends StatefulWidget {
  const PrayerPlayerScreen({super.key, required this.prayer, this.onCompleted});

  final Prayer prayer;

  /// When set (e.g. praying to unlock an app), this runs after the post-prayer
  /// mood check-in — letting the caller release the blocked apps. When null,
  /// finishing just surfaces the mood check-in as before.
  final Future<void> Function()? onCompleted;

  @override
  State<PrayerPlayerScreen> createState() => _PrayerPlayerScreenState();
}

class _PrayerPlayerScreenState extends State<PrayerPlayerScreen> {
  late final PrayerPlayerController _controller;
  final PostHogService _analytics = PostHogService.instance;

  void _track(String event, Map<String, dynamic> props) {
    if (_analytics.isReady) _analytics.events.trackCustom(event, props);
  }

  /// Anchors the iPad share popover to the share button's frame.
  final GlobalKey _shareKey = GlobalKey();

  /// Reacts to playback completion to surface the post-prayer mood check-in.
  Worker? _finishWorker;

  /// Guards the post-prayer check-in to once per screen lifetime (the prayer
  /// can be replayed, which re-fires [PrayerPlayerController.isFinished]).
  bool _postPrayerShown = false;

  @override
  void initState() {
    super.initState();
    _controller = Get.put(PrayerPlayerController(), tag: widget.prayer.id);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controller.load(
        widget.prayer,
        source: widget.onCompleted != null ? 'unlock' : 'home',
      );
    });
    _finishWorker = ever<bool>(_controller.isFinished, _onPlaybackFinished);
  }

  void _onPlaybackFinished(bool finished) {
    if (!finished || _postPrayerShown || !mounted) return;
    _postPrayerShown = true;
    _controller.markCompleted();
    // Capture the prayed duration now, before the mood check-in dialog so its
    // interaction time isn't counted as prayer time.
    final prayedSeconds = _controller.sessionSeconds;
    // Defer past the current frame so the route push doesn't run mid-build.
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
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
          'context': 'audio_prayer',
        });
      } else {
        _track('mood_skipped', {'phase': 'post', 'context': 'audio_prayer'});
      }
      // Increment global prayer count (for rating prompt logic)
      // This counts ALL prayers: written, audio, and learning
      await RateAppService().incrementPrayerCount();
      unawaited(RateAppService().tryShowRatingPrompt());

      if (widget.onCompleted != null) {
        // Unlock mode: release the blocked apps (this navigates away).
        // The unlock flow records its own prayer stats — don't double-count.
        await widget.onCompleted!.call();
      } else if (mounted) {
        // Home mode: record the session so "prayed today" reflects it.
        try {
          await StatsService().recordUnlockAttempt(
            verseId: widget.prayer.id,
            wasSuccessful: true,
            attemptCount: 1,
            timeToUnlockSeconds: prayedSeconds,
            method: UnlockMethod.prayerAudio,
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
          // to the main screen (closing both the player and the library).
          tourController!.completeInteractiveStep('pray');
          // Pop twice: player -> library -> main screen
          Get.back(); // close player
          Get.back(); // close library
        } else {
          // Normal flow: return all the way home (close both the player and
          // the library) instead of landing back on the prayer list. Navigator
          // is used over Get.back() to dodge the stale-snackbar crash (see the
          // close button above).
          final nav = Navigator.of(context);
          nav.pop(); // close player
          nav.pop(); // close library
        }
      }
    });
  }

  @override
  void dispose() {
    _controller.trackAbandonedIfNeeded();
    _finishWorker?.dispose();
    Get.delete<PrayerPlayerController>(tag: widget.prayer.id, force: true);
    super.dispose();
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return CupertinoTheme(
      data: const CupertinoThemeData(primaryColor: _orange),
      child: DefaultTextStyle(
        style: const TextStyle(
          fontFamily: _font,
          fontSize: 16,
          color: _ink,
          decoration: TextDecoration.none,
        ),
        child: CupertinoPageScaffold(
          backgroundColor: _cream,
          child: SafeArea(
            child: Column(
              children: [
                _buildTopBar(),
                const SizedBox(height: 4),
                _buildRefBadge(),
                const SizedBox(height: 8),
                Expanded(child: _buildReader()),
                _buildDock(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Top bar (collapse + centered title) ──────────────────────────────────────

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Row(
        children: [
          _CircleButton(
            icon: CupertinoIcons.chevron_down,
            diameter: 48,
            iconSize: 22,
            // Use Navigator directly: Get.back() unconditionally invokes
            // closeCurrentSnackbar() internally, which crashes on a stale
            // snackbar job left in the GetX queue (LateInitializationError
            // on its `late` AnimationController). maybePop skips that path.
            onTap: () {
              HapticFeedback.lightImpact();
              Navigator.of(context).maybePop();
            },
          ),
          Expanded(
            child: Text(
              widget.prayer.title,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontFamily: _font,
                fontSize: 23,
                fontWeight: FontWeight.w700,
                color: _ink,
                letterSpacing: -0.3,
              ),
            ),
          ),
          _CircleButton(
            key: _shareKey,
            icon: CupertinoIcons.share,
            diameter: 48,
            iconSize: 21,
            onTap: _shareApp,
          ),
        ],
      ),
    );
  }

  // ── Share the app ────────────────────────────────────────────────────────────

  Future<void> _shareApp() async {
    HapticFeedback.lightImpact();
    // Anchor the share sheet to the button on iPad (required there, ignored on
    // iPhone/Android) — without it share_plus throws on large screens.
    final box = _shareKey.currentContext?.findRenderObject() as RenderBox?;
    final Rect? origin = (box != null && box.hasSize)
        ? box.localToGlobal(Offset.zero) & box.size
        : null;
    await SharePlus.instance.share(
      ShareParams(
        text: '${'share_app_message'.tr}\n${AppConfig.appStoreUrl}',
        subject: 'FaithLock',
        sharePositionOrigin: origin,
      ),
    );
  }

  // ── Reference badge ──────────────────────────────────────────────────────────

  Widget _buildRefBadge() {
    final ref = widget.prayer.scriptureRef.trim();
    if (ref.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
      decoration: BoxDecoration(
        color: _peach,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _ink, width: 2),
      ),
      child: Text(
        ref.toUpperCase(),
        style: const TextStyle(
          fontFamily: _font,
          fontSize: 12,
          fontWeight: FontWeight.w800,
          color: _ink,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  // ── Reader (hero) ────────────────────────────────────────────────────────────

  Widget _buildReader() {
    return Obx(() {
      if (_controller.isPreparing.value) {
        return const Center(child: CupertinoActivityIndicator(color: _ink));
      }
      if (_controller.isUnavailable.value) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 36),
            child: Text(
              widget.prayer.scriptureText != null
                  ? '"${widget.prayer.scriptureText!}"'
                  : 'prayer_settleIn'.tr,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: _font,
                fontSize: 23,
                fontWeight: FontWeight.w600,
                fontStyle: FontStyle.italic,
                color: _ink,
                height: 1.5,
              ),
            ),
          ),
        );
      }
      return SyncedScriptReader(controller: _controller);
    });
  }

  // ── Bottom dock (transport) ──────────────────────────────────────────────────

  Widget _buildDock() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 0, 28, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Obx(() => _ProgressBar(
                progress: _controller.progress,
                enabled: !_controller.isUnavailable.value,
                onSeek: (f) => _controller.seek(_controller.total.value * f),
              )),
          const SizedBox(height: 10),
          Obx(_buildTimeLabels),
          const SizedBox(height: 18),
          _buildControls(),
        ],
      ),
    );
  }

  Widget _buildTimeLabels() {
    final pos = _controller.elapsed.value;
    final remaining = _controller.total.value - pos;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(_fmt(pos), style: _timeStyle),
        Text(
          '-${_fmt(remaining > Duration.zero ? remaining : Duration.zero)}',
          style: _timeStyle,
        ),
      ],
    );
  }

  static const _timeStyle = TextStyle(
    fontFamily: _font,
    fontSize: 13,
    fontWeight: FontWeight.w700,
    color: _subtle,
    letterSpacing: 0.5,
  );

  Widget _buildControls() {
    return Obx(() {
      final disabled = _controller.isUnavailable.value;
      final playing = _controller.isPlaying.value;
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _CircleButton(
            icon: CupertinoIcons.gobackward_15,
            diameter: 60,
            iconSize: 26,
            disabled: disabled,
            onTap: () {
              HapticFeedback.selectionClick();
              _controller.skipBack();
            },
          ),
          _PlayButton(
            playing: playing,
            disabled: disabled,
            onTap: () {
              HapticFeedback.mediumImpact();
              _controller.playPause();
            },
          ),
          _CircleButton(
            icon: CupertinoIcons.goforward_15,
            diameter: 60,
            iconSize: 26,
            disabled: disabled,
            onTap: () {
              HapticFeedback.selectionClick();
              _controller.skipForward();
            },
          ),
        ],
      );
    });
  }

  String _fmt(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }
}

// ─── Chunky bordered progress bar (drag to seek) ──────────────────────────────

class _ProgressBar extends StatelessWidget {
  const _ProgressBar({
    required this.progress,
    required this.enabled,
    required this.onSeek,
  });

  final double progress;
  final bool enabled;
  final ValueChanged<double> onSeek;

  static const double _h = 16;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1 : 0.4,
      child: LayoutBuilder(
        builder: (context, c) {
          final w = c.maxWidth;
          void handle(Offset local) {
            if (!enabled) return;
            onSeek((local.dx / w).clamp(0.0, 1.0));
          }

          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapDown: (d) => handle(d.localPosition),
            onHorizontalDragStart: (d) => handle(d.localPosition),
            onHorizontalDragUpdate: (d) => handle(d.localPosition),
            child: SizedBox(
              height: _h + 8,
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.centerLeft,
                children: [
                  // Track
                  Container(
                    height: _h,
                    decoration: BoxDecoration(
                      color: _card,
                      borderRadius: BorderRadius.circular(_h),
                      border: Border.all(color: _ink, width: 2),
                    ),
                  ),
                  // Fill
                  FractionallySizedBox(
                    widthFactor: progress.clamp(0.0, 1.0).toDouble(),
                    child: Container(
                      height: _h,
                      decoration: BoxDecoration(
                        color: _orange,
                        borderRadius: BorderRadius.circular(_h),
                        border: Border.all(color: _ink, width: 2),
                      ),
                    ),
                  ),
                  // Knob
                  Positioned(
                    left: (w * progress.clamp(0.0, 1.0) - 11)
                        .clamp(0.0, w - 22)
                        .toDouble(),
                    child: Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        color: _card,
                        shape: BoxShape.circle,
                        border: Border.all(color: _ink, width: 2.5),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ─── Circular bordered button (collapse / skip) ───────────────────────────────

class _CircleButton extends StatefulWidget {
  const _CircleButton({
    super.key,
    required this.icon,
    required this.onTap,
    required this.diameter,
    required this.iconSize,
    this.disabled = false,
  });

  final IconData icon;
  final VoidCallback onTap;
  final double diameter;
  final double iconSize;
  final bool disabled;

  @override
  State<_CircleButton> createState() => _CircleButtonState();
}

class _CircleButtonState extends State<_CircleButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _press;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _press = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 80),
      reverseDuration: const Duration(milliseconds: 150),
    );
    _scale = Tween<double>(begin: 1.0, end: 0.9).animate(_press);
  }

  @override
  void dispose() {
    _press.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: widget.disabled ? 0.35 : 1.0,
      child: GestureDetector(
        onTapDown: widget.disabled ? null : (_) => _press.forward(),
        onTapUp: widget.disabled
            ? null
            : (_) {
                _press.reverse();
                widget.onTap();
              },
        onTapCancel: () => _press.reverse(),
        child: ScaleTransition(
          scale: _scale,
          child: Container(
            width: widget.diameter,
            height: widget.diameter,
            decoration: BoxDecoration(
              color: _card,
              shape: BoxShape.circle,
              border: Border.all(color: _ink, width: 2.5),
              boxShadow: PrayerPalette.hardShadow(offset: const Offset(0, 3)),
            ),
            child: Icon(widget.icon, color: _ink, size: widget.iconSize),
          ),
        ),
      ),
    );
  }
}

// ─── Big play / pause button ──────────────────────────────────────────────────

class _PlayButton extends StatefulWidget {
  const _PlayButton({
    required this.playing,
    required this.disabled,
    required this.onTap,
  });

  final bool playing;
  final bool disabled;
  final VoidCallback onTap;

  @override
  State<_PlayButton> createState() => _PlayButtonState();
}

class _PlayButtonState extends State<_PlayButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _press;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _press = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 80),
      reverseDuration: const Duration(milliseconds: 150),
    );
    _scale = Tween<double>(begin: 1.0, end: 0.93).animate(_press);
  }

  @override
  void dispose() {
    _press.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: widget.disabled ? 0.4 : 1.0,
      child: GestureDetector(
        onTapDown: widget.disabled ? null : (_) => _press.forward(),
        onTapUp: widget.disabled
            ? null
            : (_) {
                _press.reverse();
                widget.onTap();
              },
        onTapCancel: () => _press.reverse(),
        child: ScaleTransition(
          scale: _scale,
          child: Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              color: _orange,
              shape: BoxShape.circle,
              border: Border.all(color: _ink, width: 3),
              boxShadow: PrayerPalette.hardShadow(offset: const Offset(0, 6)),
            ),
            child: Icon(
              widget.playing
                  ? CupertinoIcons.pause_fill
                  : CupertinoIcons.play_fill,
              color: Colors.white,
              size: 34,
            ),
          ),
        ),
      ),
    );
  }
}
