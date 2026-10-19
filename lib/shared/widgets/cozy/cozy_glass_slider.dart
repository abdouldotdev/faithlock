import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/cozy/cozy.dart';

/// Cozy "liquid glass" slider — a chunky bordered pill track with a glassy
/// orb thumb that feels physical. Designed as a drop-in for [Slider] /
/// [FastSlider] anywhere the cozy aesthetic is in play.
///
/// Visual anatomy:
/// - **Track**: pill-shaped, soft beige fill, signature ink outline
/// - **Active fill**: gradient (active tint → lighter tint) with a subtle
///   inner highlight, only on the left portion up to the value
/// - **Thumb**: round 34 px orb with a white→cream radial highlight that
///   reads as a glass marble, ink border, hard offset shadow
/// - **Divisions** (optional): values snap to integer multiples and a tiny
///   selection haptic fires on each crossing
///
/// Example:
/// ```dart
/// CozyGlassSlider(
///   value: hours,
///   min: 0,
///   max: 16,
///   divisions: 32,
///   activeColor: CozyColors.primary,
///   onChanged: (v) => setState(() => hours = v),
/// )
/// ```
class CozyGlassSlider extends StatefulWidget {
  final double value;
  final double min;
  final double max;
  final int? divisions;
  final ValueChanged<double>? onChanged;

  /// Optional fill tint override. Defaults to [CozyColors.primary]. Useful
  /// when the screen colors the value by severity (e.g. screen-time bucket).
  final Color? activeColor;

  /// Track height (pill thickness). Default reads as substantial without
  /// dominating the layout.
  final double trackHeight;

  /// Thumb diameter. The chunky shadow + border are accounted for outside
  /// this measurement.
  final double thumbSize;

  /// Whether selection haptics fire on each division crossing.
  final bool hapticFeedback;

  const CozyGlassSlider({
    super.key,
    required this.value,
    this.min = 0,
    this.max = 1,
    this.divisions,
    this.onChanged,
    this.activeColor,
    this.trackHeight = 16,
    this.thumbSize = 34,
    this.hapticFeedback = true,
  });

  @override
  State<CozyGlassSlider> createState() => _CozyGlassSliderState();
}

class _CozyGlassSliderState extends State<CozyGlassSlider> {
  bool _pressed = false;
  int? _lastDivisionTick;

  double get _range => widget.max - widget.min;

  double _snap(double v) {
    if (widget.divisions == null) return v;
    final step = _range / widget.divisions!;
    return widget.min + ((v - widget.min) / step).round() * step;
  }

  /// Translates a local x position into a value within [min, max], snapped
  /// to divisions when set.
  double _valueFromX(double dx, double trackWidth) {
    final t = (dx / trackWidth).clamp(0.0, 1.0);
    return _snap(widget.min + t * _range);
  }

  void _emit(double newValue) {
    if (newValue == widget.value) return;
    if (widget.hapticFeedback && widget.divisions != null) {
      final tick = ((newValue - widget.min) / _range * widget.divisions!)
          .round();
      if (tick != _lastDivisionTick) {
        HapticFeedback.selectionClick();
        _lastDivisionTick = tick;
      }
    }
    widget.onChanged?.call(newValue);
  }

  @override
  Widget build(BuildContext context) {
    final Color tint = widget.activeColor ?? CozyColors.primary;
    final bool enabled = widget.onChanged != null;

    return LayoutBuilder(
      builder: (context, constraints) {
        // Track is inset by half the thumb on each side so the thumb center
        // can travel from min to max without clipping outside the row.
        final double rowWidth = constraints.maxWidth;
        final double inset = widget.thumbSize / 2;
        final double trackWidth = rowWidth - inset * 2;
        final double t =
            ((widget.value - widget.min) / _range).clamp(0.0, 1.0);
        final double thumbCenterX = inset + t * trackWidth;
        final double activeWidth = t * trackWidth;

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (d) {
            if (!enabled) return;
            setState(() => _pressed = true);
            _emit(_valueFromX(d.localPosition.dx - inset, trackWidth));
          },
          onTapUp: (_) => setState(() => _pressed = false),
          onTapCancel: () => setState(() => _pressed = false),
          onHorizontalDragStart: (d) {
            if (!enabled) return;
            setState(() => _pressed = true);
            _emit(_valueFromX(d.localPosition.dx - inset, trackWidth));
          },
          onHorizontalDragUpdate: (d) {
            if (!enabled) return;
            _emit(_valueFromX(d.localPosition.dx - inset, trackWidth));
          },
          onHorizontalDragEnd: (_) => setState(() => _pressed = false),
          child: SizedBox(
            height: widget.thumbSize + 16, // breathing room for the shadow
            width: rowWidth,
            child: Stack(
              alignment: Alignment.centerLeft,
              children: [
                // Background track (full width).
                Positioned(
                  left: inset,
                  width: trackWidth,
                  child: Container(
                    height: widget.trackHeight,
                    decoration: ShapeDecoration(
                      color: CozyColors.surfaceMuted,
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(widget.trackHeight / 2),
                        side: const BorderSide(
                          color: CozyColors.outline,
                          width: CozyTokens.borderWidth,
                        ),
                      ),
                    ),
                  ),
                ),
                // Active fill (left portion up to value).
                if (activeWidth > 2)
                  Positioned(
                    left: inset,
                    width: activeWidth,
                    child: AnimatedContainer(
                      duration: CozyTokens.fast,
                      curve: Curves.easeOut,
                      height: widget.trackHeight,
                      decoration: ShapeDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          colors: [
                            tint,
                            Color.lerp(tint, Colors.white, 0.18)!,
                          ],
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(widget.trackHeight / 2),
                          side: BorderSide(
                            color: CozyColors.outline,
                            width: CozyTokens.borderWidth,
                          ),
                        ),
                      ),
                    ),
                  ),
                // Glassy thumb.
                Positioned(
                  left: thumbCenterX - widget.thumbSize / 2,
                  child: AnimatedScale(
                    duration: CozyTokens.fast,
                    scale: _pressed ? 1.08 : 1.0,
                    curve: Curves.easeOut,
                    child: _GlassThumb(
                      size: widget.thumbSize,
                      enabled: enabled,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _GlassThumb extends StatelessWidget {
  final double size;
  final bool enabled;

  const _GlassThumb({required this.size, required this.enabled});

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1.0 : 0.6,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          // Two-color radial gradient: brighter cream top-left, fading to
          // pure surface — fakes the refraction highlight of a glass orb.
          gradient: const RadialGradient(
            center: Alignment(-0.4, -0.5),
            radius: 0.95,
            colors: [
              Color(0xFFFFFFFF),
              CozyColors.surface,
              Color(0xFFF7EBD8),
            ],
            stops: [0.0, 0.55, 1.0],
          ),
          border: Border.all(
            color: CozyColors.outline,
            width: CozyTokens.borderWidth,
          ),
          boxShadow: CozyTokens.shadowHard,
        ),
        // Subtle inner highlight stripe — adds the "wet glass" feel without
        // needing a real backdrop blur (overkill on a small thumb).
        child: ClipOval(
          child: Align(
            alignment: const Alignment(-0.3, -0.7),
            child: Container(
              width: size * 0.42,
              height: size * 0.18,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(size),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
