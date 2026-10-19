import 'package:flutter/material.dart';
import 'package:faithlock/shared/widgets/cozy/cozy.dart';

/// A Bible translation/version.
class BibleVersion {
  final String abbr;
  final String name;
  final String subtitle;
  final Color badgeColor;

  /// Whether this version has a wired-up database. Versions with
  /// `isAvailable: false` are shown in the selector with a disabled look
  /// and a "Coming soon" tag, but cannot be selected — so the user is
  /// never lied to about which translation they're reading.
  final bool isAvailable;

  const BibleVersion({
    required this.abbr,
    required this.name,
    required this.subtitle,
    required this.badgeColor,
    this.isAvailable = true,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is BibleVersion && other.abbr == abbr);

  @override
  int get hashCode => abbr.hashCode;
}

/// The canonical list of supported versions.
///
/// The app bundles full SQLite databases for BSB, KJV and LSG (Louis Segond
/// 1910) at [assets/databases/]. NIV/NKJ are listed but marked
/// [BibleVersion.isAvailable] `false` (copyrighted text — can't be bundled)
/// — the selector renders them disabled with a "Coming soon" tag rather than
/// silently falling back to an available version.
const List<BibleVersion> kBibleVersions = [
  BibleVersion(
    abbr: 'BSB',
    name: 'Berean Standard Bible',
    subtitle: 'Modern Accurate Translation',
    badgeColor: CozyColors.sage,
  ),
  BibleVersion(
    abbr: 'KJV',
    name: 'King James Version',
    subtitle: 'Classic English Translation',
    badgeColor: CozyColors.beige,
  ),
  BibleVersion(
    abbr: 'LSG',
    name: 'Louis Segond',
    subtitle: 'Version Française (1910)',
    badgeColor: CozyColors.peach,
  ),
  BibleVersion(
    abbr: 'NIV',
    name: 'New International',
    subtitle: 'Modern English Translation',
    badgeColor: CozyColors.surfaceMuted,
    isAvailable: false,
  ),
  BibleVersion(
    abbr: 'NKJ',
    name: 'New King James',
    subtitle: 'Revised Classic English',
    badgeColor: CozyColors.primaryLight,
    isAvailable: false,
  ),
];

/// The default version on a fresh install.
BibleVersion get kDefaultBibleVersion => kBibleVersions.first;

/// The version to default to for a given app [languageCode] when the user
/// hasn't explicitly chosen one — French → Louis Segond, otherwise BSB.
/// Falls back to [kDefaultBibleVersion] if the locale's version isn't bundled.
BibleVersion bibleVersionForLocale(String? languageCode) {
  if (languageCode == 'fr') {
    return kBibleVersions.firstWhere(
      (v) => v.abbr == 'LSG' && v.isAvailable,
      orElse: () => kDefaultBibleVersion,
    );
  }
  return kDefaultBibleVersion;
}
