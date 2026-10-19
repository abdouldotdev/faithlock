import 'package:flutter/material.dart';
import 'package:faithlock/shared/widgets/cozy/cozy.dart';

/// Testament enum.
enum Testament { old, newTestament }

/// Bible book categories (for badge colour selection).
enum BibleBookCategory {
  pentateuch,
  historical,
  wisdom,
  majorProphets,
  minorProphets,
  gospels,
  acts,
  paulineEpistles,
  generalEpistles,
  prophecy,
}

extension BibleBookCategoryExtension on BibleBookCategory {
  String get displayName {
    switch (this) {
      case BibleBookCategory.pentateuch:
        return 'Pentateuch';
      case BibleBookCategory.historical:
        return 'Historical';
      case BibleBookCategory.wisdom:
        return 'Wisdom';
      case BibleBookCategory.majorProphets:
        return 'Major Prophets';
      case BibleBookCategory.minorProphets:
        return 'Minor Prophets';
      case BibleBookCategory.gospels:
        return 'Gospels';
      case BibleBookCategory.acts:
        return 'Acts';
      case BibleBookCategory.paulineEpistles:
        return 'Epistles';
      case BibleBookCategory.generalEpistles:
        return 'Epistles';
      case BibleBookCategory.prophecy:
        return 'Prophecy';
    }
  }

  Color get badgeColor {
    switch (this) {
      case BibleBookCategory.pentateuch:
        return CozyColors.peach;
      case BibleBookCategory.historical:
        return CozyColors.sage;
      case BibleBookCategory.wisdom:
        return CozyColors.primaryLight;
      case BibleBookCategory.majorProphets:
        return CozyColors.beige;
      case BibleBookCategory.minorProphets:
        return CozyColors.surfaceMuted;
      case BibleBookCategory.gospels:
        return CozyColors.peach;
      case BibleBookCategory.acts:
        return CozyColors.sage;
      case BibleBookCategory.paulineEpistles:
        return CozyColors.primaryLight;
      case BibleBookCategory.generalEpistles:
        return CozyColors.beige;
      case BibleBookCategory.prophecy:
        return CozyColors.surfaceMuted;
    }
  }
}

/// Immutable model for a Bible book.
class BibleBook {
  final String name;
  final String abbreviation;
  final int chapterCount;
  final Testament testament;
  final BibleBookCategory category;

  const BibleBook({
    required this.name,
    required this.abbreviation,
    required this.chapterCount,
    required this.testament,
    required this.category,
  });

  Color get badgeColor => category.badgeColor;
  String get categoryName => category.displayName;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is BibleBook && other.name == name);

  @override
  int get hashCode => name.hashCode;
}
