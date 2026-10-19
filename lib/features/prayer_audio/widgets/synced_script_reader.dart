import 'package:faithlock/features/prayer_audio/constants/prayer_palette.dart';
import 'package:faithlock/features/prayer_audio/controllers/prayer_player_controller.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Colors, Curves;
import 'package:flutter/services.dart';
import 'package:get/get.dart';

const _font = PrayerPalette.font;
const _ink = PrayerPalette.ink;
const _muted = PrayerPalette.muted;

/// A guided-reading teleprompter that highlights the prayer script in sync
/// with the on-device voice.
///
/// The active sentence is rendered dark and bold and gently auto-centered;
/// neighbours fade out; `(pause)` beats pulse. Within the active line a karaoke
/// "fill" sweeps left-to-right as each word is spoken — driven by the real
/// word-boundary offsets from [PrayerPlayerController] (flutter_tts). Tapping a
/// line seeks the read to that point.
class SyncedScriptReader extends StatefulWidget {
  const SyncedScriptReader({super.key, required this.controller});

  final PrayerPlayerController controller;

  @override
  State<SyncedScriptReader> createState() => _SyncedScriptReaderState();
}

class _SyncedScriptReaderState extends State<SyncedScriptReader> {
  final ScrollController _scroll = ScrollController();
  final Map<int, GlobalKey> _keys = {};

  int _active = 0;
  Worker? _activeWorker;

  @override
  void initState() {
    super.initState();
    _active = widget.controller.activeIndex.value;
    _activeWorker = ever<int>(widget.controller.activeIndex, (i) {
      if (i != _active && mounted) {
        setState(() => _active = i);
        _centerActive();
      }
    });
    // Center whatever line is active when the reader first appears (playback
    // may already have advanced while we were preparing).
    _centerActive();
  }

  @override
  void dispose() {
    _activeWorker?.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _centerActive() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scroll.hasClients) return;
      final ctx = _keys[_active]?.currentContext;
      if (ctx != null) {
        // The line is built (near the viewport) — center it smoothly.
        Scrollable.ensureVisible(
          ctx,
          alignment: 0.5,
          duration: const Duration(milliseconds: 640),
          curve: Curves.easeInOutCubic,
        );
        return;
      }
      // After a big scrub the active line is far off-screen, so the lazy
      // ListView never built it (no context to ensureVisible). Jump to an
      // estimated offset to force it to build, then center it precisely on the
      // next frame.
      final pos = _scroll.position;
      _scroll.jumpTo(
        _estimateOffsetFor(_active)
            .clamp(pos.minScrollExtent, pos.maxScrollExtent),
      );
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !_scroll.hasClients) return;
        final built = _keys[_active]?.currentContext;
        if (built != null) {
          Scrollable.ensureVisible(
            built,
            alignment: 0.5,
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeOutCubic,
          );
        }
      });
    });
  }

  /// Rough scroll offset that centers line [index] when it isn't built yet —
  /// based on the average height of the lines currently on screen. Precision
  /// isn't critical: the jump only needs to get [index] built so the follow-up
  /// [Scrollable.ensureVisible] can center it exactly.
  double _estimateOffsetFor(int index) {
    double sum = 0;
    int n = 0;
    for (final key in _keys.values) {
      final box = key.currentContext?.findRenderObject() as RenderBox?;
      if (box != null && box.hasSize) {
        sum += box.size.height;
        n++;
      }
    }
    final avg = n > 0 ? sum / n : 64.0;
    final topPad = MediaQuery.of(context).size.height * 0.40;
    final viewport = _scroll.position.viewportDimension;
    return topPad + index * avg + avg / 2 - viewport / 2;
  }

  @override
  Widget build(BuildContext context) {
    final segs = widget.controller.segments;
    if (segs.isEmpty) return const SizedBox.shrink();

    // Generous top/bottom room so first & last lines can sit centered.
    final pad = MediaQuery.of(context).size.height * 0.40;

    return ShaderMask(
      shaderCallback: (rect) => const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Colors.transparent, Colors.white, Colors.white, Colors.transparent],
        stops: [0.0, 0.16, 0.84, 1.0],
      ).createShader(rect),
      blendMode: BlendMode.dstIn,
      child: ListView.builder(
        controller: _scroll,
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.fromLTRB(30, pad, 30, pad),
        itemCount: segs.length,
        itemBuilder: (context, i) {
          final key = _keys.putIfAbsent(i, () => GlobalKey());
          final seg = segs[i];
          final distance = (i - _active).abs();

          if (seg.isPause) {
            return _PauseBeat(key: key, active: i == _active);
          }
          // One widget type per line (kept alive by its GlobalKey) so the
          // grow/shrink + darken/fade between states tweens smoothly instead
          // of snapping when the active sentence advances.
          return _Line(
            key: key,
            text: seg.text,
            active: i == _active,
            far: distance >= 2,
            controller: widget.controller,
            onTap: () => _seekTo(i),
          );
        },
      ),
    );
  }

  void _seekTo(int i) {
    HapticFeedback.selectionClick();
    widget.controller.jumpToSegment(i);
  }
}

// ─── A script line — animates between active / neighbour / far states ───────

class _Line extends StatelessWidget {
  const _Line({
    super.key,
    required this.text,
    required this.active,
    required this.far,
    required this.controller,
    required this.onTap,
  });

  final String text;
  final bool active;
  final bool far;
  final PrayerPlayerController controller;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    // Target style per state — AnimatedDefaultTextStyle tweens size / weight /
    // colour as the active sentence moves. The active line then overlays a
    // per-word karaoke sweep (the spans only override colour, so size & weight
    // still inherit the animating style).
    final Color baseColor = active ? _ink : _muted.withValues(alpha: far ? 0.55 : 1.0);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 420),
          curve: Curves.easeOutCubic,
          style: TextStyle(
            fontFamily: _font,
            fontSize: active ? 25 : 21,
            height: 1.42,
            fontWeight: active ? FontWeight.w700 : FontWeight.w500,
            color: baseColor,
            letterSpacing: active ? -0.2 : -0.1,
            decoration: TextDecoration.none,
          ),
          child: active
              ? Obx(() {
                  final end =
                      controller.wordEnd.value.clamp(0, text.length).toInt();
                  return Text.rich(
                    TextSpan(
                      children: [
                        // Spoken words at full ink; the rest still dark but a
                        // touch softer — the boundary sweeps with the voice.
                        TextSpan(
                          text: text.substring(0, end),
                          style: const TextStyle(color: _ink),
                        ),
                        TextSpan(
                          text: text.substring(end),
                          style: TextStyle(color: _ink.withValues(alpha: 0.45)),
                        ),
                      ],
                    ),
                    textAlign: TextAlign.center,
                  );
                })
              : Text(text, textAlign: TextAlign.center),
        ),
      ),
    );
  }
}

// ─── A breath ((pause) beat) ─────────────────────────────────────────────────

class _PauseBeat extends StatefulWidget {
  const _PauseBeat({super.key, required this.active});
  final bool active;

  @override
  State<_PauseBeat> createState() => _PauseBeatState();
}

class _PauseBeatState extends State<_PauseBeat>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    if (widget.active) _pulse.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(_PauseBeat old) {
    super.didUpdateWidget(old);
    if (widget.active && !_pulse.isAnimating) {
      _pulse.repeat(reverse: true);
    } else if (!widget.active && _pulse.isAnimating) {
      _pulse
        ..stop()
        ..value = 0;
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 22),
      child: AnimatedBuilder(
        animation: _pulse,
        builder: (_, __) {
          final double alpha = widget.active ? 0.35 + 0.5 * _pulse.value : 0.22;
          final color = (widget.active ? PrayerPalette.orange : _muted)
              .withValues(alpha: alpha);
          return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              3,
              (i) => Container(
                margin: const EdgeInsets.symmetric(horizontal: 5),
                width: 7,
                height: 7,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
            ),
          );
        },
      ),
    );
  }
}
