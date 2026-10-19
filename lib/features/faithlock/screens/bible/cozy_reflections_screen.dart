import 'package:faithlock/features/bible/controllers/bible_controller.dart';
import 'package:faithlock/features/bible/controllers/bible_engagement_controller.dart';
import 'package:faithlock/features/bible/models/bible_engagement_models.dart';
import 'package:faithlock/features/faithlock/screens/bible/cozy_reading_screen.dart';
import 'package:faithlock/shared/widgets/cozy/cozy.dart';
import 'package:faithlock/services/analytics/posthog/export.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:intl/intl.dart';

/// "Saved" — a cozy two-tab view over the user's Bible engagement:
///   • Reflections — personal notes saved on verses.
///   • Bookmarks   — chapters/verses saved for quick return.
/// Reads the same store the reader writes to ([BibleEngagementController]).
class CozyReflectionsScreen extends StatefulWidget {
  const CozyReflectionsScreen({super.key, this.initialTab = 0});

  /// 0 = Reflections, 1 = Bookmarks.
  final int initialTab;

  @override
  State<CozyReflectionsScreen> createState() => _CozyReflectionsScreenState();
}

class _CozyReflectionsScreenState extends State<CozyReflectionsScreen> {
  late int _tab = widget.initialTab;

  BibleEngagementController get _engagement {
    if (!Get.isRegistered<BibleEngagementController>()) {
      Get.put(BibleEngagementController());
    }
    return Get.find<BibleEngagementController>();
  }

  BibleController get _bible {
    if (!Get.isRegistered<BibleController>()) {
      Get.put(BibleController());
    }
    return Get.find<BibleController>();
  }

  bool _opening = false;

  final PostHogService _analytics = PostHogService.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CozyColors.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _header(),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
              child: CozySegmentedControl(
                segments: [
                  'bibleui_tabReflections'.tr,
                  'bibleui_tabBookmarks'.tr,
                ],
                selectedIndex: _tab,
                onChanged: (i) => setState(() => _tab = i),
              ),
            ),
            Expanded(
              child: _tab == 0 ? _reflectionsTab() : _bookmarksTab(),
            ),
          ],
        ),
      ),
    );
  }

  // ── Header ─────────────────────────────────────────────────────────────────

  Widget _header() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 20, 8),
      child: Row(
        children: [
          CozyTappable(
            onTap: Get.back,
            pressedScale: 0.94,
            child: const Padding(
              padding: EdgeInsets.all(8),
              child: HugeIcon(
                icon: HugeIcons.strokeRoundedArrowLeft01,
                color: CozyColors.ink,
                size: 26,
              ),
            ),
          ),
          const SizedBox(width: 4),
          Text('bibleui_savedTitle'.tr, style: CozyText.title),
        ],
      ),
    );
  }

  // ── Reflections tab ──────────────────────────────────────────────────────

  Widget _reflectionsTab() {
    return Obx(() {
      final items = _engagement.reflections;
      if (items.isEmpty) {
        return _empty(
          icon: HugeIcons.strokeRoundedNote01,
          title: 'bibleui_noReflectionsTitle'.tr,
          subtitle: 'bibleui_noReflectionsSub'.tr,
        );
      }
      return ListView.separated(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 14),
        itemBuilder: (_, i) => _ReflectionCard(
          reflection: items[i],
          onDelete: () => _confirmDeleteReflection(items[i]),
        ),
      );
    });
  }

  // ── Bookmarks tab ────────────────────────────────────────────────────────

  Widget _bookmarksTab() {
    return Obx(() {
      // Newest first.
      final items = _engagement.bookmarks.toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      if (items.isEmpty) {
        return _empty(
          icon: HugeIcons.strokeRoundedBookmark02,
          title: 'bibleui_noBookmarksTitle'.tr,
          subtitle: 'bibleui_noBookmarksSub'.tr,
        );
      }
      return ListView.separated(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (_, i) => _BookmarkCard(
          bookmark: items[i],
          onOpen: () => _openBookmark(items[i]),
          onDelete: () => _confirmDeleteBookmark(items[i]),
        ),
      );
    });
  }

  /// Opens the bookmarked passage in the reader. Parses "Book Chapter" (book
  /// names may contain spaces, e.g. "1 Samuel 3"; older verse bookmarks like
  /// "Genesis 1:5" resolve to their chapter), loads that chapter's verses in
  /// the currently-selected version, then pushes the reading screen.
  Future<void> _openBookmark(BibleBookmark bookmark) async {
    if (_opening) return;
    final ref = bookmark.reference.trim();
    final lastSpace = ref.lastIndexOf(' ');
    if (lastSpace <= 0) return;

    final bookName = ref.substring(0, lastSpace).trim();
    var chapterToken = ref.substring(lastSpace + 1).trim();
    if (chapterToken.contains(':')) {
      chapterToken = chapterToken.split(':').first;
    }
    final chapter = int.tryParse(chapterToken);
    if (chapter == null) return;

    setState(() => _opening = true);
    try {
      final verses =
          await _bible.versesFor(bookName: bookName, chapter: chapter);
      if (!mounted || verses.isEmpty) return;
      if (_analytics.isReady) {
        _analytics.events.trackCustom('reflections_bookmark_opened', {
          'reference': '$bookName $chapter',
        });
      }
      Get.to(() => CozyReadingScreen(
            reference: '$bookName $chapter',
            verses: verses,
          ));
    } finally {
      if (mounted) setState(() => _opening = false);
    }
  }

  // ── Empty state ─────────────────────────────────────────────────────────────

  Widget _empty({
    required List<List<dynamic>> icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CozyIconChip(
              icon: icon,
              iconColor: CozyColors.ink,
              background: CozyColors.peach,
              bordered: false,
              size: 64,
              iconSize: 30,
            ),
            const SizedBox(height: 18),
            Text(title, textAlign: TextAlign.center, style: CozyText.heading),
            const SizedBox(height: 8),
            Text(subtitle, textAlign: TextAlign.center, style: CozyText.subtitle),
          ],
        ),
      ),
    );
  }

  // ── Delete ──────────────────────────────────────────────────────────────────

  void _confirmDeleteReflection(BibleReflection reflection) {
    _confirmDelete(
      title: 'bibleui_deleteReflection'.tr,
      message: 'bibleui_deleteReflectionConfirm'.tr,
      onConfirm: () async {
        await _engagement.removeReflection(reflection.id);
        _toast('bibleui_reflectionDeleted'.tr);
      },
    );
  }

  void _confirmDeleteBookmark(BibleBookmark bookmark) {
    _confirmDelete(
      title: 'bibleui_deleteBookmark'.tr,
      message: 'bibleui_deleteBookmarkConfirm'.tr,
      onConfirm: () async {
        await _engagement.removeBookmark(bookmark.reference);
        _toast('bibleui_bookmarkDeleted'.tr);
      },
    );
  }

  void _toast(String message) {
    if (mounted) {
      CozyToast.show(context, message, variant: CozyToastVariant.success);
    }
  }

  void _confirmDelete({
    required String title,
    required String message,
    required Future<void> Function() onConfirm,
  }) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: CozyColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(CozyTokens.radiusLg)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: CozyText.title),
              const SizedBox(height: 8),
              Text(message, style: CozyText.subtitle),
              const SizedBox(height: 20),
              CozyButton(
                text: 'bibleui_delete'.tr,
                icon: const HugeIcon(
                  icon: HugeIcons.strokeRoundedDelete02,
                  color: CozyColors.onPrimary,
                  size: 20,
                ),
                fillColor: CozyColors.error,
                onTap: () async {
                  Navigator.of(sheetContext).pop();
                  await onConfirm();
                },
              ),
              const SizedBox(height: 10),
              CozyButton(
                text: 'bibleui_cancel'.tr,
                variant: CozyButtonVariant.secondary,
                onTap: () => Navigator.of(sheetContext).pop(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// One reflection entry: passage reference + date, optional title, the note,
/// and a delete affordance.
class _ReflectionCard extends StatelessWidget {
  const _ReflectionCard({required this.reflection, required this.onDelete});

  final BibleReflection reflection;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    // Title is only meaningful when the user typed one (the saver defaults it
    // to the passage reference when left blank).
    final hasTitle = reflection.title.trim().isNotEmpty &&
        reflection.title.trim() != reflection.passageReference.trim();

    return CozyCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const HugeIcon(
                icon: HugeIcons.strokeRoundedBookOpen01,
                color: CozyColors.primary,
                size: 16,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  reflection.passageReference,
                  style: CozyText.label.copyWith(color: CozyColors.primary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                DateFormat.yMMMd().format(reflection.createdAt),
                style: CozyText.label.copyWith(color: CozyColors.inkMuted),
              ),
              const SizedBox(width: 6),
              _DeleteButton(onTap: onDelete),
            ],
          ),
          if (hasTitle) ...[
            const SizedBox(height: 10),
            Text(
              reflection.title,
              style: CozyText.body.copyWith(fontWeight: FontWeight.w700),
            ),
          ],
          if (reflection.note.trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              reflection.note,
              style: CozyText.body.copyWith(
                color: CozyColors.inkMuted,
                height: 1.5,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// One bookmark entry: reference + date. Tap to open the passage in the
/// reader; the trailing button deletes it.
class _BookmarkCard extends StatelessWidget {
  const _BookmarkCard({
    required this.bookmark,
    required this.onOpen,
    required this.onDelete,
  });

  final BibleBookmark bookmark;
  final VoidCallback onOpen;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return CozyCard(
      onTap: onOpen,
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          CozyIconChip(
            icon: HugeIcons.strokeRoundedBookmark02,
            iconColor: CozyColors.ink,
            background: CozyColors.sage,
            bordered: false,
            size: 40,
            iconSize: 20,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  bookmark.reference,
                  style: CozyText.body.copyWith(fontWeight: FontWeight.w700),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  DateFormat.yMMMd().format(bookmark.createdAt),
                  style: CozyText.label.copyWith(color: CozyColors.inkMuted),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _DeleteButton(onTap: onDelete),
        ],
      ),
    );
  }
}

/// Shared small delete affordance.
class _DeleteButton extends StatelessWidget {
  const _DeleteButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return CozyTappable(
      onTap: onTap,
      pressedScale: 0.9,
      child: const Padding(
        padding: EdgeInsets.all(4),
        child: HugeIcon(
          icon: HugeIcons.strokeRoundedDelete02,
          color: CozyColors.inkMuted,
          size: 20,
        ),
      ),
    );
  }
}
