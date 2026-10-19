import 'dart:ui' as ui;

import 'package:faithlock/features/garden/widgets/garden_hero.dart';
import 'package:flutter/material.dart';

/// "Garden of Grace" hero — a photoreal pomegranate tree in a terracotta pot
/// that grows by cross-fading across a curated set of staged frames as
/// [progress] goes 0→1, with health-driven wilt applied entirely in code (no
/// extra images):
///   - [progress] 0→1 : drives a continuous index into [_stages] (the curated
///     growth order, see [_order]), which captures the tree's natural evolution
///     — germination → seedling → sapling → leafy young tree (vegetative),
///     then flowering (vermilion trumpet flowers), fruit set, and a mature ripe
///     canopy. The map is linear and clamped; adjacent frames cross-fade
///     (floor/ceil + fractional opacity + a subtle scale) so growth reads as
///     continuous rather than stepped.
///   - [health]   0→1 : 1 = full colour & upright; low desaturates toward a warm
///     brown and adds a gentle droop, for neglect.
///
/// [progress] is fed from `GardenController.progress` (an RxDouble, 0..1).
///
/// Graceful fallback: until the staged frames exist on disk (generation runs
/// asynchronously, and the extension may later switch from .png to .webp), the
/// [Image.asset] error builders fall through to the hand-painted [GardenHero],
/// so the screen keeps rendering today's tree. The health filter/transform wraps
/// the fallback too, so wilt keeps working either way.
class RealisticTreePot extends StatefulWidget {
  final double progress;
  final double health;

  /// When true, draws the plant directly with no background — so it can sit
  /// inside another card or beside the mascot without looking nested. Forwarded
  /// to the [GardenHero] fallback.
  final bool embedded;

  const RealisticTreePot({
    super.key,
    this.progress = 0.05,
    this.health = 1.0,
    this.embedded = true,
  });

  @override
  State<RealisticTreePot> createState() => _RealisticTreePotState();

  /// Native frame aspect ratio (width / height ≈ 0.747). The generated frames are
  /// 896×1200 (one 768×1024, ~same), so callers should size their box to this
  /// ratio — otherwise [BoxFit.contain] letterboxes the tree inside its own box
  /// and it renders smaller than the space allows.
  static const double aspectRatio = 896 / 1200;

  /// Decode width for the frames. Decoded at the native 896px so the tree stays
  /// crisp when rendered large (e.g. fullscreen). Decoding every frame to the
  /// same width keeps the whole flipbook in the image cache at once
  /// (≈47 × 4.3MB ≈ 210MB), which is what makes scrubbing smooth — no per-frame
  /// re-decode mid-drag.
  static const int _decodeWidth = 896;

  /// The shared image provider for a frame — a [ResizeImage] so the precache and
  /// the live [_frame] use the SAME cache key (otherwise precaching wouldn't hit).
  static ImageProvider _provider(String asset) =>
      ResizeImage(AssetImage(asset), width: _decodeWidth);

  /// Warm the image cache with every curated frame so the crossfade/scrub plays
  /// from decoded memory instead of decoding on the fly (the cause of stutter).
  /// Safe to call repeatedly; [precacheImage] dedups against the cache. Mounting
  /// the widget triggers this automatically, but callers may invoke it earlier
  /// (e.g. before opening the fullscreen view) to pre-warm.
  static Future<void> precacheFrames(BuildContext context) {
    final cache = PaintingBinding.instance.imageCache;
    const budget =
        260 << 20; // 260 MB — hold all decoded frames without eviction
    if (cache.maximumSizeBytes < budget) cache.maximumSizeBytes = budget;
    return Future.wait(
      _stages.map(
          (s) => precacheImage(_provider(s), context, onError: (_, __) {})),
    );
  }

  /// Asset path pieces for a growth frame. Centralised so switching the pipeline
  /// from .png to .webp (or relocating the frames) is a one-line change.
  /// Shared file contract with the asset pipeline — do not rename.
  static const String _framePrefix = 'assets/garden/tree/tree_';
  static const String _frameSuffix = '.webp';

  /// Builds the frame path for a zero-padded index, e.g. 7 → tree_07.png.
  static String _framePath(int index) =>
      '$_framePrefix${index.toString().padLeft(2, '0')}$_frameSuffix';

  /// Curated growth order over the 48 generated frames (tree_00 → tree_47).
  ///
  /// The raw chain is an AI flipbook, so a couple of early frames break the
  /// "growth is monotonic — you don't lose what God grew" rule: tree_00/tree_01
  /// are inverted (01 is the bare germination hook, 00 already has leaves) and
  /// tree_05 is a leaf-shape anomaly. The ripe-fruit tail tree_43–46 originally
  /// regressed (trunk-loss / shrink) but was regenerated with a size-monotonicity
  /// lock (see scripts/generate_garden_tree.py `stage_constraint`), so it now
  /// matures smoothly into tree_47. We curate the bad early frames out and
  /// reorder, so the on-screen arc only ever grows: germination (01,00) →
  /// seedling/sapling → leafy young tree → flowering (~30–39, vermilion trumpet
  /// flowers) → fruit set (40–42) → ripening (43–46) → grand ripe tree (47).
  /// All 48 files stay on disk; tree_05 can rejoin here once regenerated.
  static const List<int> _order = <int>[
    1, 0, 2, 3, 4, // germination → first true leaves
    6, 7, 8, 9, 10, 11, 12, 13, 14, 15, // young bushy shrub
    16, 17, 18, 19, 20, 21, 22, 23, 24, // sapling on a trunk
    25, 26, 27, 28, 29, // canopy fills in, first buds
    30, 31, 32, 33, 34, 35, 36, 37, 38, 39, // flowering (vermilion trumpets)
    40, 41, 42, // fruit set (green pomegranates)
    43, 44, 45, 46, 47, // ripening → grand mature ripe tree (size-locked regen)
  ];

  /// The curated frames in seed→mature order; [build] snaps to the nearest one.
  static final List<String> _stages =
      _order.map(_framePath).toList(growable: false);
}

class _RealisticTreePotState extends State<RealisticTreePot> {
  bool _precached = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Warm the whole flipbook once, after we have a context, so scrubbing/growth
    // plays from decoded memory instead of decoding each frame on the fly.
    if (!_precached) {
      _precached = true;
      RealisticTreePot.precacheFrames(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Snap to the NEAREST frame — no cross-fade. Cross-fading two photoreal
    // frames whose pots differ slightly let both pots show at once ("nested
    // pots" / mixed images). Showing a single clean frame per progress value
    // removes all ghosting; with 47 dense frames the stepping is fine.
    final stages = RealisticTreePot._stages;
    final idx = (widget.progress.clamp(0.0, 1.0) * (stages.length - 1)).round();

    final h = widget.health.clamp(0.0, 1.0);

    final stack = _frame(
      stages[idx],
      opacity: 1.0,
      scale: 1.0,
      errorBuilder: (_, __, ___) => GardenHero(
        progress: widget.progress,
        health: widget.health,
        embedded: widget.embedded,
      ),
    );

    // Fast path: at (near) full health the wilt Transform + ColorFilter are the
    // identity but still cost two GPU layers, so skip them — keeps scrubbing the
    // healthy growth arc smooth.
    if (h >= 0.999) return stack;

    // Wilt: desaturate toward warm brown, then droop + slightly squash from the
    // base. Both pivot on bottomCenter so the pot stays planted.
    // TODO(2D wilt grid): once per-health wilt frames exist, swap this code-only
    // ColorFilter/Transform for a 2D lookup — pick the asset by (frame, health),
    // e.g. tree_${lo}_h${bucket}.png via a variant of [_framePath], and fall
    // back to the current code wilt when a variant is missing.
    return Transform(
      alignment: Alignment.bottomCenter,
      transform: Matrix4.identity()
        ..rotateZ((1 - h) * 0.06)
        ..scaleByDouble(1.0, ui.lerpDouble(0.96, 1.0, h)!, 1.0, 1.0),
      child: ColorFiltered(
        colorFilter: ColorFilter.matrix(_wiltMatrix(h)),
        child: stack,
      ),
    );
  }

  /// A single staged image, expanded to fill, anchored at the pot base, with a
  /// subtle scale to soften the stepping between stages. Uses the shared resized
  /// provider so it hits the cache warmed by [RealisticTreePot.precacheFrames].
  Widget _frame(
    String asset, {
    required double opacity,
    required double scale,
    required ImageErrorWidgetBuilder errorBuilder,
  }) {
    return Opacity(
      opacity: opacity.clamp(0.0, 1.0),
      child: Transform.scale(
        scale: scale,
        alignment: Alignment.bottomCenter,
        child: Image(
          image: RealisticTreePot._provider(asset),
          fit: BoxFit.contain,
          alignment: Alignment.bottomCenter,
          gaplessPlayback: true,
          errorBuilder: errorBuilder,
        ),
      ),
    );
  }

  /// 4×5 colour matrix lerped from identity (health 1) to a ~30%-saturation,
  /// warm-shifted matrix (health 0), so neglect drains the colour toward brown.
  List<double> _wiltMatrix(double health) {
    // Identity — full colour.
    const identity = <double>[
      1, 0, 0, 0, 0, //
      0, 1, 0, 0, 0, //
      0, 0, 1, 0, 0, //
      0, 0, 0, 1, 0, //
    ];

    // Desaturated saturation matrix (s = 0.3) with a small warm/brown bias
    // baked into the offset column (more red, slightly less green, less blue).
    const s = 0.3;
    const lr = 0.2126, lg = 0.7152, lb = 0.0722;
    final desaturated = <double>[
      (1 - s) * lr + s, (1 - s) * lg, (1 - s) * lb, 0, 18, //
      (1 - s) * lr, (1 - s) * lg + s, (1 - s) * lb, 0, 6, //
      (1 - s) * lr, (1 - s) * lg, (1 - s) * lb + s, 0, -10, //
      0, 0, 0, 1, 0, //
    ];

    return List<double>.generate(
      identity.length,
      (i) => ui.lerpDouble(desaturated[i], identity[i], health)!,
    );
  }
}
