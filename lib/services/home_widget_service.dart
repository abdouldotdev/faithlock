import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:home_widget/home_widget.dart';

import 'package:faithlock/features/bible/data/bible_repository.dart';
import 'package:faithlock/features/faithlock/controllers/stats_controller.dart';
import 'package:faithlock/features/faithlock/services/bible_database_loader.dart';
import 'package:faithlock/features/garden/controllers/garden_controller.dart';

/// Pushes the live "faith state" into the iOS App Group so the home-screen
/// widget can render it. The *verse of the day* is NOT pushed from here — the
/// widget rotates it itself by day-of-year so it changes every day even when
/// the app is never opened. This service only feeds the live numbers (streak,
/// prayed-today, garden stage) that the widget can't compute on its own.
///
/// iOS only. On other platforms every call is a no-op.
///
/// Setup requirements (see the Xcode steps in the PR notes):
/// - App Group `group.com.appbiz.faithlock` on both Runner and the widget.
/// - A Widget Extension whose `kind` is `FaithLockWidget`.
class HomeWidgetService {
  HomeWidgetService._();
  static final HomeWidgetService instance = HomeWidgetService._();

  /// Must match the App Group already used by Runner + the Screen Time
  /// extensions, and the one added to the widget target.
  static const String _appGroupId = 'group.com.appbiz.faithlock';

  /// Must match the SwiftUI `Widget`'s `kind` string.
  static const String _iOSWidgetName = 'FaithLockWidget';

  bool _initialized = false;

  Future<void> _ensureInit() async {
    if (_initialized) return;
    // Only meaningful on iOS; guard so Android/desktop stay no-ops.
    if (!GetPlatform.isIOS) return;
    await HomeWidget.setAppGroupId(_appGroupId);
    _initialized = true;
  }

  /// Reads whatever controllers are currently registered and syncs. Safe to
  /// call from anywhere; silently skips values it can't resolve.
  Future<void> refreshFromControllers() async {
    if (!GetPlatform.isIOS) return;

    final stats = Get.isRegistered<StatsController>()
        ? Get.find<StatsController>().userStats.value
        : null;
    final garden = Get.isRegistered<GardenController>()
        ? Get.find<GardenController>()
        : null;

    await sync(
      streak: stats?.currentStreak ?? 0,
      prayedToday: (stats?.hasStreakToday ?? false) ||
          ((stats?.prayedMinutesToday ?? 0) > 0),
      prayedMinutes: stats?.prayedMinutesToday ?? 0,
      versesToday: stats?.versesReadToday ?? 0,
      gardenStage: _stageFor(garden?.progress.value ?? 0),
      gardenHealth: garden?.health.value ?? 1.0,
    );

    // Verse of the day: same source + same date-seed as the Bible screen, so
    // the widget shows the exact same verse. Cached per-day; the pool is
    // exported once for the widget's offline day-advance.
    await _syncVerseOfDay();
  }

  int? _lastVerseSeed;
  bool _poolExported = false;

  /// Date-seed identical to [BibleRepository.verseOfDay]: year*10000 + …
  int _todaySeed() {
    final t = DateTime.now();
    return t.year * 10000 + t.month * 100 + t.day;
  }

  /// Pushes today's localized verse (exactly what the Bible screen shows) plus,
  /// once per session, the whole curriculum pool so the widget can advance to
  /// the next day's verse on its own if the app isn't opened.
  Future<void> _syncVerseOfDay() async {
    if (!GetPlatform.isIOS) return;
    final seed = _todaySeed();
    if (_lastVerseSeed == seed && _poolExported) return;

    try {
      // 1) Export the pool once (BSB curriculum, in the SAME order the Bible
      //    screen indexes into — so pool[seed % n] matches offline).
      if (!_poolExported) {
        final pool = await BibleDatabaseLoader.loadCurriculumVerses();
        if (pool.isNotEmpty) {
          final json = jsonEncode(pool
              .map((v) => {'t': v.text, 'r': v.reference})
              .toList(growable: false));
          await HomeWidget.saveWidgetData<String>('versePool', json);
          _poolExported = true;
        }
      }

      // 2) Push today's verse, localized via the same repository call the
      //    Bible screen uses (FR → LSG, else BSB).
      final today = await BibleRepository().verseOfDay();
      if (today != null) {
        await Future.wait([
          HomeWidget.saveWidgetData<String>('verseText', today.text),
          HomeWidget.saveWidgetData<String>('verseRef', today.reference),
          HomeWidget.saveWidgetData<int>('verseSeed', seed),
        ]);
      }

      await HomeWidget.updateWidget(iOSName: _iOSWidgetName);
      _lastVerseSeed = seed;
    } catch (e) {
      debugPrint('⚠️ [HomeWidget] verse sync failed: $e');
    }
  }

  /// Writes the state to the App Group and asks iOS to reload the widget.
  Future<void> sync({
    required int streak,
    required bool prayedToday,
    required int prayedMinutes,
    required int versesToday,
    required int gardenStage,
    required double gardenHealth,
  }) async {
    if (!GetPlatform.isIOS) return;
    try {
      await _ensureInit();
      await Future.wait([
        HomeWidget.saveWidgetData<int>('streak', streak),
        HomeWidget.saveWidgetData<bool>('prayedToday', prayedToday),
        HomeWidget.saveWidgetData<int>('prayedMinutes', prayedMinutes),
        HomeWidget.saveWidgetData<int>('versesToday', versesToday),
        HomeWidget.saveWidgetData<int>('gardenStage', gardenStage),
        HomeWidget.saveWidgetData<int>(
            'gardenHealth', (gardenHealth * 100).round()),
        // Lets the widget tell "today's push" from a stale one.
        HomeWidget.saveWidgetData<int>('updatedDay', _dayOfYear()),
      ]);
      await HomeWidget.updateWidget(iOSName: _iOSWidgetName);
    } catch (e) {
      debugPrint('⚠️ [HomeWidget] sync failed: $e');
    }
  }

  /// Same growth-stage breakpoints as the fullscreen pot (spec §6): 1..5.
  int _stageFor(double p) {
    if (p < 0.10) return 1; // seed
    if (p < 0.35) return 2; // sprout
    if (p < 0.60) return 3; // growing
    if (p < 0.85) return 4; // blooming
    return 5; // fruit
  }

  int _dayOfYear() {
    final now = DateTime.now();
    return now.difference(DateTime(now.year, 1, 1)).inDays;
  }
}
