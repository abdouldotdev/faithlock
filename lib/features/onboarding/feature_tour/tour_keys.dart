import 'package:flutter/widgets.dart';

/// Shared anchors for the first-day feature tour.
///
/// The tour spotlights elements that live in different widgets (the home
/// screen's garden + pray button, the navigation shell's tabs + companion
/// FAB). Each of those widgets attaches the matching key below to the exact
/// element it owns; the tour reads their geometry to cut the spotlight hole.
///
/// Keys are stable for the app's lifetime — a [GlobalKey] is built to follow
/// its element across rebuilds, and on a replayed tour the previous element is
/// already unmounted, so the same key simply re-binds to the fresh build.
class TourKeys {
  TourKeys._();

  static final GlobalKey lockApps = GlobalKey(debugLabel: 'tour_lockApps');
  static final GlobalKey prayButton = GlobalKey(debugLabel: 'tour_prayButton');
  static final GlobalKey garden = GlobalKey(debugLabel: 'tour_garden');
  static final GlobalKey bibleTab = GlobalKey(debugLabel: 'tour_bibleTab');
  static final GlobalKey companionFab =
      GlobalKey(debugLabel: 'tour_companionFab');
}
