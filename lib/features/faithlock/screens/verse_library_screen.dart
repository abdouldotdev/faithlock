import 'package:faithlock/features/faithlock/controllers/verse_library_controller.dart';
import 'package:faithlock/features/faithlock/models/export.dart';
import 'package:faithlock/features/onboarding/constants/onboarding_theme.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Colors;
import 'package:get/get.dart';

// ---------------------------------------------------------------------------
// Verse Library Screen — iOS Cupertino, Apple Design Award quality
// ---------------------------------------------------------------------------

class VerseLibraryScreen extends StatefulWidget {
  const VerseLibraryScreen({super.key});

  @override
  State<VerseLibraryScreen> createState() => _VerseLibraryScreenState();
}

class _VerseLibraryScreenState extends State<VerseLibraryScreen> {
  late final VerseLibraryController _controller;
  late final ScrollController _scrollController;

  // Persistent search controller — fixes the inline TextEditingController bug
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _controller = Get.put(VerseLibraryController());
    _searchController = TextEditingController();
    _scrollController = ScrollController()..addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _controller.loadMoreVerses();
    }
  }

  // ── Theme helpers ───────────────────────────────────────────────────────

  static const _gold = OnboardingTheme.goldColor;
  static const _cardBg = OnboardingTheme.cardBackground;
  static const _cardBorder = OnboardingTheme.cardBorder;
  static const _textPrimary = OnboardingTheme.labelPrimary;
  static const _textTertiary = OnboardingTheme.labelTertiary;
  static const _font = OnboardingTheme.fontFamily;

  // ── Build ───────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return CupertinoTheme(
      data: CupertinoThemeData(
        brightness: Brightness.dark,
        primaryColor: _gold,
        textTheme: CupertinoTextThemeData(
          // Large nav title — white Satoshi
          navLargeTitleTextStyle: const TextStyle(
            fontFamily: _font,
            fontSize: 34,
            fontWeight: FontWeight.w700,
            color: _textPrimary,
            letterSpacing: -0.5,
          ),
          // Collapsed nav title
          navTitleTextStyle: const TextStyle(
            fontFamily: _font,
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: _textPrimary,
          ),
        ),
      ),
      // Builder so resolveFrom() picks up the dark Cupertino brightness above.
      child: Builder(
        builder: (context) => CupertinoPageScaffold(
          backgroundColor:
              CupertinoColors.secondarySystemGroupedBackground.resolveFrom(context),
          child: CustomScrollView(
            controller: _scrollController,
            slivers: [
              // ── Large collapsing nav bar (native liquid glass) ──────────
              _buildNavBar(),

            // ── Search field ────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: CupertinoSearchTextField(
                  controller: _searchController,
                  placeholder: 'searchVerses'.tr,
                  placeholderStyle: const TextStyle(
                    fontFamily: _font,
                    color: _textTertiary,
                    fontSize: 15,
                  ),
                  style: const TextStyle(
                    fontFamily: _font,
                    color: _textPrimary,
                    fontSize: 15,
                  ),
                  backgroundColor: _cardBg,
                  onChanged: _controller.searchVerses,
                  onSuffixTap: () {
                    _searchController.clear();
                    _controller.searchVerses('');
                  },
                ),
              ),
            ),

            // ── Category filter pills ───────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Obx(() => _CategoryFilter(
                      selectedCategory: _controller.selectedCategory.value,
                      onSelect: _controller.filterByCategory,
                    )),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 20)),

            // ── Content: loading / error / empty / list ─────────────────
            Obx(() {
              if (_controller.isLoading.value) {
                return const SliverFillRemaining(
                  child: _LoadingState(),
                );
              }

              if (_controller.errorMessage.value.isNotEmpty) {
                return SliverFillRemaining(
                  child: _ErrorState(
                    message: _controller.errorMessage.value,
                    onRetry: _controller.loadVerses,
                  ),
                );
              }

              if (_controller.filteredVerses.isEmpty) {
                return SliverFillRemaining(
                  child: _EmptyState(
                    favoritesOnly: _controller.showFavoritesOnly.value,
                  ),
                );
              }

              return _VerseList(
                controller: _controller,
              );
            }),

            // Bottom safe area padding
            const SliverToBoxAdapter(child: SizedBox(height: 40)),
            ],
          ),
        ),
      ),
    );
  }

  // ── Nav bar ─────────────────────────────────────────────────────────────

  Widget _buildNavBar() {
    return CupertinoSliverNavigationBar(
      largeTitle: Text('verseLibrary'.tr),
      // Trailing: gold heart favorites toggle
      trailing: Obx(() {
        final active = _controller.showFavoritesOnly.value;
        return CupertinoButton(
          padding: const EdgeInsets.all(11),
          onPressed: _controller.toggleFavoritesView,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            transitionBuilder: (child, anim) => ScaleTransition(
              scale: anim,
              child: child,
            ),
            child: Icon(
              active ? CupertinoIcons.heart_fill : CupertinoIcons.heart,
              key: ValueKey(active),
              color: _gold,
              size: 22,
            ),
          ),
        );
      }),
      // No opaque backgroundColor override: use the system translucent
      // "liquid glass" material so content blurs under it while scrolling.
      border: const Border(
        bottom: BorderSide(color: _cardBorder, width: 0.5),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Category filter — horizontal scrolling pills
// ---------------------------------------------------------------------------

class _CategoryFilter extends StatelessWidget {
  const _CategoryFilter({
    required this.selectedCategory,
    required this.onSelect,
  });

  final VerseCategory? selectedCategory;
  final void Function(VerseCategory?) onSelect;

  @override
  Widget build(BuildContext context) {
    final categories = VerseCategory.values;

    return SizedBox(
      height: 40,
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        children: [
          _Pill(
            label: 'all'.tr,
            isSelected: selectedCategory == null,
            onTap: () => onSelect(null),
          ),
          ...categories.map((cat) => Padding(
                padding: const EdgeInsets.only(left: 8),
                child: _Pill(
                  label: cat.displayName,
                  isSelected: selectedCategory == cat,
                  onTap: () => onSelect(cat),
                ),
              )),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
        alignment: Alignment.center,
        constraints: const BoxConstraints(minHeight: 40),
        decoration: BoxDecoration(
          color: isSelected ? OnboardingTheme.goldColor : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? OnboardingTheme.goldColor
                : OnboardingTheme.cardBorder,
            width: 0.5,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: OnboardingTheme.fontFamily,
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            color: isSelected ? Colors.black : OnboardingTheme.labelSecondary,
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Verse list sliver (with load-more footer)
// ---------------------------------------------------------------------------

class _VerseList extends StatelessWidget {
  const _VerseList({required this.controller});

  final VerseLibraryController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final verses = controller.filteredVerses;
      final loadingMore = controller.isLoadingMore.value;
      final itemCount = verses.length + (loadingMore ? 1 : 0);

      return SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        sliver: SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              if (index == verses.length) {
                // Load-more indicator
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: CupertinoActivityIndicator(color: OnboardingTheme.goldColor),
                  ),
                );
              }

              final verse = verses[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: _VerseCard(
                  verse: verse,
                  isFavorite: controller.isFavorite(verse.id),
                  onFavoriteTap: () => controller.toggleFavorite(verse),
                ),
              );
            },
            childCount: itemCount,
          ),
        ),
      );
    });
  }
}

// ---------------------------------------------------------------------------
// Editorial verse card
// ---------------------------------------------------------------------------

class _VerseCard extends StatelessWidget {
  const _VerseCard({
    required this.verse,
    required this.isFavorite,
    required this.onFavoriteTap,
  });

  final BibleVerse verse;
  final bool isFavorite;
  final VoidCallback onFavoriteTap;

  // Category → display colour (accent only, never background fill)
  static Color _categoryAccent(VerseCategory cat) {
    switch (cat) {
      case VerseCategory.temptation:
        return const Color(0xFFFF6B47); // warm red-orange
      case VerseCategory.fearAnxiety:
        return const Color(0xFF64B5F6); // soft sky blue
      case VerseCategory.pride:
        return const Color(0xFFCE93D8); // muted violet
      case VerseCategory.lust:
        return const Color(0xFFEF9A9A); // dusty rose
      case VerseCategory.anger:
        return const Color(0xFFFFCC80); // warm amber
    }
  }

  @override
  Widget build(BuildContext context) {
    final accent = _categoryAccent(verse.category);

    return CupertinoContextMenu(
      enableHapticFeedback: true,
      actions: [
        CupertinoContextMenuAction(
          onPressed: () {
            Navigator.of(context, rootNavigator: true).pop();
            onFavoriteTap();
          },
          trailingIcon: isFavorite
              ? CupertinoIcons.heart_slash
              : CupertinoIcons.heart_fill,
          child: Text(
            isFavorite ? 'removeFavorite'.tr : 'addFavorite'.tr,
            style: const TextStyle(fontFamily: OnboardingTheme.fontFamily),
          ),
        ),
      ],
      // Bound the width: CupertinoContextMenu wraps the child in a FittedBox
      // for its long-press preview, handing it UNBOUNDED width. Without a
      // finite width the inner Row (overline + Spacer + heart) crashes.
      // 16 px matches the list's horizontal padding on each side.
      child: SizedBox(
        width: MediaQuery.sizeOf(context).width - 32,
        child: _CardBody(
          verse: verse,
          accent: accent,
          isFavorite: isFavorite,
          onFavoriteTap: onFavoriteTap,
        ),
      ),
    );
  }
}

// Card body extracted so CupertinoContextMenu can preview it cleanly
class _CardBody extends StatelessWidget {
  const _CardBody({
    required this.verse,
    required this.accent,
    required this.isFavorite,
    required this.onFavoriteTap,
  });

  final BibleVerse verse;
  final Color accent;
  final bool isFavorite;
  final VoidCallback onFavoriteTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        // Elevated Apple surface (#1C1C1E in dark) so cards read above the
        // grouped background instead of vanishing on flat black.
        color: CupertinoColors.tertiarySystemGroupedBackground
            .resolveFrom(context),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: OnboardingTheme.cardBorder,
          width: 0.5,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 20,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Top row: category overline + favorite ─────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Category overline — uppercase gold-ish tinted text
              Text(
                verse.category.displayName.toUpperCase(),
                style: TextStyle(
                  fontFamily: OnboardingTheme.fontFamily,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: accent,
                  letterSpacing: 1.4,
                  height: 1,
                ),
              ),
              const Spacer(),
              // Favorite heart — 44 pt touch target
              GestureDetector(
                onTap: onFavoriteTap,
                behavior: HitTestBehavior.opaque,
                child: SizedBox(
                  width: 44,
                  height: 44,
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 250),
                      transitionBuilder: (child, anim) => ScaleTransition(
                        scale: CurvedAnimation(
                          parent: anim,
                          curve: Curves.elasticOut,
                        ),
                        child: child,
                      ),
                      child: Icon(
                        isFavorite
                            ? CupertinoIcons.heart_fill
                            : CupertinoIcons.heart,
                        key: ValueKey(isFavorite),
                        color: OnboardingTheme.goldColor,
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // ── Verse text — Satoshi italic ───────────────────────────
          Text(
            '“${verse.text}”',
            style: const TextStyle(
              fontFamily: OnboardingTheme.fontFamily,
              fontSize: 17,
              fontStyle: FontStyle.italic,
              fontWeight: FontWeight.w400,
              color: OnboardingTheme.labelPrimary,
              height: 1.55,
              letterSpacing: 0.1,
            ),
          ),

          const SizedBox(height: 16),

          // ── Hairline divider ──────────────────────────────────────
          Container(
            height: 0.5,
            color: OnboardingTheme.goldColor.withValues(alpha: 0.35),
          ),

          const SizedBox(height: 14),

          // ── Reference — gold, title case + letter-spaced ─────────
          // Title-case matches the reading screen / share / copy text so
          // refs look identical wherever they appear.
          Text(
            verse.reference,
            style: const TextStyle(
              fontFamily: OnboardingTheme.fontFamily,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: OnboardingTheme.goldColor,
              letterSpacing: 1.2,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Loading state
// ---------------------------------------------------------------------------

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CupertinoActivityIndicator(
        radius: 14,
        color: OnboardingTheme.goldColor,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Error state — on-brand, elegant
// ---------------------------------------------------------------------------

class _ErrorState extends StatelessWidget {
  const _ErrorState({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              CupertinoIcons.exclamationmark_circle,
              size: 52,
              color: OnboardingTheme.goldColor,
            ),
            const SizedBox(height: 20),
            Text(
              message,
              style: const TextStyle(
                fontFamily: OnboardingTheme.fontFamily,
                fontSize: 15,
                color: OnboardingTheme.labelSecondary,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            CupertinoButton(
              onPressed: onRetry,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
              color: OnboardingTheme.goldColor,
              borderRadius: BorderRadius.circular(14),
              child: Text(
                'retry'.tr,
                style: const TextStyle(
                  fontFamily: OnboardingTheme.fontFamily,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                  fontSize: 15,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Empty state — on-brand, elegant
// ---------------------------------------------------------------------------

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.favoritesOnly});

  final bool favoritesOnly;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              favoritesOnly
                  ? CupertinoIcons.heart
                  : CupertinoIcons.book,
              size: 52,
              color: OnboardingTheme.goldColor.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 20),
            Text(
              favoritesOnly
                  ? 'noFavoriteVersesYet'.tr
                  : 'noVersesFound'.tr,
              style: const TextStyle(
                fontFamily: OnboardingTheme.fontFamily,
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: OnboardingTheme.labelPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              favoritesOnly
                  ? 'tapHeartToAdd'.tr
                  : 'tryDifferentSearch'.tr,
              style: const TextStyle(
                fontFamily: OnboardingTheme.fontFamily,
                fontSize: 14,
                color: OnboardingTheme.labelTertiary,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
