import 'package:faithlock/features/bible/controllers/bible_controller.dart';
import 'package:faithlock/services/analytics/posthog/export.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hugeicons/hugeicons.dart';

import 'package:faithlock/shared/widgets/cozy/cozy.dart';
import 'cozy_reading_screen.dart';
import 'cozy_version_selection_sheet.dart';

// ── Screen ─────────────────────────────────────────────────────────────────

/// Book detail screen — shows chapter selector and verse list.
/// Wired to [BibleController] for real chapters, verses, and version.
class CozyBookDetailScreen extends StatefulWidget {
  final String bookName;
  final String bookAbbr;
  final String category;
  final Color badgeColor;
  final int chapterCount;

  const CozyBookDetailScreen({
    super.key,
    required this.bookName,
    required this.bookAbbr,
    required this.category,
    required this.badgeColor,
    required this.chapterCount,
  });

  @override
  State<CozyBookDetailScreen> createState() => _CozyBookDetailScreenState();
}

class _CozyBookDetailScreenState extends State<CozyBookDetailScreen>
    with SingleTickerProviderStateMixin {
  int _selectedChapter = 1;

  // Live verse data
  List<({int number, String text})> _verses = [];
  bool _versesLoading = false;

  // Book name in the selected version (e.g. "Genèse" under LSG). The canonical
  // [widget.bookName] is still used for engagement/bookmark keys.
  late String _localizedBookName = widget.bookName;

  // Reloads the open chapter when the selected Bible version changes.
  Worker? _versionWorker;

  // Periodic attention wiggle on the Reading Mode button. The button rests
  // flat most of the cycle, then gives a short tilt to invite a tap.
  late final AnimationController _wiggleCtrl;
  late final Animation<double> _wiggle = TweenSequence<double>([
    TweenSequenceItem(tween: ConstantTween(0.0), weight: 72),
    TweenSequenceItem(
        tween: Tween(begin: 0.0, end: -0.045)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 7),
    TweenSequenceItem(
        tween: Tween(begin: -0.045, end: 0.045)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 7),
    TweenSequenceItem(
        tween: Tween(begin: 0.045, end: -0.03)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 7),
    TweenSequenceItem(
        tween: Tween(begin: -0.03, end: 0.0)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 7),
  ]).animate(_wiggleCtrl);

  final PostHogService _analytics = PostHogService.instance;

  void _track(String event, [Map<String, dynamic> props = const {}]) {
    if (_analytics.isReady) _analytics.events.trackCustom(event, props);
  }

  BibleController get _ctrl {
    if (!Get.isRegistered<BibleController>()) {
      Get.put(BibleController());
    }
    return Get.find<BibleController>();
  }

  @override
  void initState() {
    super.initState();
    _loadVerses();
    _loadLocalizedName();
    _trackChapterOpened(_selectedChapter);
    // Refresh the open chapter + localized title whenever the version changes.
    _versionWorker = ever(_ctrl.selectedVersion, (_) {
      if (mounted) {
        _loadVerses();
        _loadLocalizedName();
      }
    });
    _wiggleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    )..repeat();
  }

  @override
  void dispose() {
    _versionWorker?.dispose();
    _wiggleCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadVerses() async {
    setState(() => _versesLoading = true);
    try {
      final v = await _ctrl.versesFor(
        bookName: widget.bookName,
        chapter: _selectedChapter,
      );
      if (mounted) setState(() => _verses = v);
    } finally {
      if (mounted) setState(() => _versesLoading = false);
    }
  }

  Future<void> _loadLocalizedName() async {
    final name = await _ctrl.localizedBookName(widget.bookName);
    if (mounted) setState(() => _localizedBookName = name);
  }

  void _selectChapter(int chapter) {
    setState(() {
      _selectedChapter = chapter;
      _verses = [];
    });
    _loadVerses();
    _trackChapterOpened(chapter);
  }

  void _trackChapterOpened(int chapter) {
    _track('bible_chapter_opened', {
      'book': widget.bookName,
      'chapter': chapter,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CozyColors.background,
      body: SafeArea(
        bottom: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _topBar(),
            const SizedBox(height: 16),
            _chapterSelector(),
            const SizedBox(height: 24),
            Expanded(child: _contentContainer()),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // ── Top bar ───────────────────────────────────────────────────────────────

  Widget _topBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          CozyIconButton.back(onTap: Get.back),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _localizedBookName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: CozyText.title,
                ),
                const SizedBox(height: 2),
                Text(
                  widget.category.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: CozyText.label.copyWith(
                    fontSize: 11,
                    letterSpacing: 1.0,
                    color: CozyColors.inkMuted,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          _versionPill(),
        ],
      ),
    );
  }

  Widget _versionPill() {
    return Obx(() {
      final abbr = _ctrl.selectedVersion.value.abbr;
      return GestureDetector(
        onTap: () => CozyVersionSelectionSheet.show(context),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: CozyColors.primary,
            borderRadius: BorderRadius.circular(CozyTokens.radiusPill),
            border: Border.all(
                color: CozyColors.outline, width: CozyTokens.borderWidth),
            boxShadow: CozyTokens.shadowHard,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                abbr,
                style: CozyText.label.copyWith(
                  color: CozyColors.onPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(width: 4),
              const HugeIcon(
                icon: HugeIcons.strokeRoundedArrowDown01,
                size: 16,
                color: CozyColors.onPrimary,
              ),
            ],
          ),
        ),
      );
    });
  }

  // ── Chapter selector ──────────────────────────────────────────────────────

  Widget _chapterSelector() {
    return SizedBox(
      height: 56,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: widget.chapterCount,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, index) {
          final int chapter = index + 1;
          return CozyChapterChip(
            number: chapter,
            selected: chapter == _selectedChapter,
            onTap: () => _selectChapter(chapter),
          );
        },
      ),
    );
  }

  // ── Content container (chunky bordered "scroll", with Chapter pill notch) ──

  /// Wraps the verse list + reading-mode button in a single chunky bordered
  /// "scroll" container. A peach "Chapter X" pill straddles the top edge of
  /// the border (notch effect), matching the design mock.
  Widget _contentContainer() {
    // Half the pill's outer height — the amount the pill overlaps above the
    // container's top edge. The container is inset by this amount at the top
    // so the pill sits exactly centered on the border.
    const double pillHalf = 19.0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            top: pillHalf,
            child: Container(
              decoration: ShapeDecoration(
                color: CozyColors.surface,
                shape: CozyTokens.smooth(
                  CozyTokens.radiusLg,
                  side: const BorderSide(
                    color: CozyColors.outline,
                    width: CozyTokens.borderWidth,
                  ),
                ),
                shadows: CozyTokens.shadowHard,
              ),
              child: Padding(
                // Top padding accounts for the half-protruding pill so the
                // first verse doesn't slide under it.
                padding: const EdgeInsets.fromLTRB(16, pillHalf + 14, 16, 16),
                child: Column(
                  children: [
                    Expanded(child: _verseList()),
                    const SizedBox(height: 12),
                    _readingModeButton(),
                  ],
                ),
              ),
            ),
          ),
          // Chapter pill — centered on the container's top border.
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Center(child: _chapterPill()),
          ),
        ],
      ),
    );
  }

  Widget _chapterPill() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 9),
      decoration: ShapeDecoration(
        color: CozyColors.peach,
        shape: CozyTokens.smooth(
          CozyTokens.radiusPill,
          side: const BorderSide(
            color: CozyColors.outline,
            width: CozyTokens.borderWidth,
          ),
        ),
      ),
      child: Text(
        'bibleui_chapterN'.trParams({'number': '$_selectedChapter'}),
        style: CozyText.label.copyWith(
          fontSize: 13,
          color: CozyColors.ink,
          letterSpacing: 0.4,
        ),
      ),
    );
  }

  // ── Verse list ────────────────────────────────────────────────────────────

  Widget _verseList() {
    if (_versesLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: CozyColors.primary,
          strokeWidth: 2,
        ),
      );
    }

    if (_verses.isEmpty) {
      return Center(
        child: Text(
          'bible_noVersesAvailable'.tr,
          style: CozyText.body.copyWith(color: CozyColors.inkMuted),
        ),
      );
    }

    return ListView.builder(
      // The bordered container provides horizontal padding; keep the inner
      // ListView edge-to-edge so the verse rows align with the container.
      padding: EdgeInsets.zero,
      itemCount: _verses.length,
      itemBuilder: (_, index) {
        final verse = _verses[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 20),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 28,
                child: Text(
                  '${verse.number}',
                  style: CozyText.heading.copyWith(
                    color: CozyColors.primary,
                    fontSize: 17,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  verse.text,
                  style: CozyText.body.copyWith(height: 1.6),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ── Reading mode button (dashed border style) ─────────────────────────────

  Widget _readingModeButton() {
    // Outer horizontal padding removed — the content container now provides
    // it. The button sits inside the bordered "scroll" alongside the verses.
    return GestureDetector(
      onTap: _openReadingMode,
      child: AnimatedBuilder(
        animation: _wiggle,
        builder: (context, child) => Transform.rotate(
          angle: _wiggle.value,
          child: child,
        ),
        child: CustomPaint(
          painter: _DashedBorderPainter(
            color: CozyColors.primary,
            radius: CozyTokens.radiusPill,
            dashWidth: 8,
            dashSpace: 5,
            strokeWidth: CozyTokens.borderWidth,
          ),
          child: Container(
            height: 56,
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(CozyTokens.radiusPill),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const HugeIcon(
                  icon: HugeIcons.strokeRoundedFullscreen,
                  color: CozyColors.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'bible_readingMode'.tr,
                  style: CozyText.button.copyWith(color: CozyColors.primary),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _openReadingMode() {
    if (_verses.isEmpty) return;
    Get.to(
      () => CozyReadingScreen(
        reference: '${widget.bookName} $_selectedChapter',
        verses: _verses,
      ),
    );
  }
}

// ── Dashed border painter ─────────────────────────────────────────────────────

class _DashedBorderPainter extends CustomPainter {
  final Color color;
  final double radius;
  final double dashWidth;
  final double dashSpace;
  final double strokeWidth;

  const _DashedBorderPainter({
    required this.color,
    required this.radius,
    required this.dashWidth,
    required this.dashSpace,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final path = Path()
      ..addRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width, size.height),
        Radius.circular(radius),
      ));

    final metricsPath = path.computeMetrics().first;
    double distance = 0;
    bool draw = true;
    while (distance < metricsPath.length) {
      final double len = draw ? dashWidth : dashSpace;
      if (draw) {
        canvas.drawPath(
          metricsPath.extractPath(distance, distance + len),
          paint,
        );
      }
      distance += len;
      draw = !draw;
    }
  }

  @override
  bool shouldRepaint(_DashedBorderPainter oldDelegate) =>
      oldDelegate.color != color ||
      oldDelegate.radius != radius ||
      oldDelegate.dashWidth != dashWidth ||
      oldDelegate.dashSpace != dashSpace ||
      oldDelegate.strokeWidth != strokeWidth;
}
