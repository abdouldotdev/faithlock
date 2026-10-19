/// GENERATED CODE - DO NOT MODIFY BY HAND
/// *****************************************************
///  FlutterGen
/// *****************************************************

// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: directives_ordering,unnecessary_import,implicit_dynamic_list_literal,deprecated_member_use

import 'package:flutter/widgets.dart';

class $AssetsDatabasesGen {
  const $AssetsDatabasesGen();

  /// File path: assets/databases/README.md
  String get readme => 'assets/databases/README.md';

  /// File path: assets/databases/bible_bsb.db
  String get bibleBsb => 'assets/databases/bible_bsb.db';

  /// File path: assets/databases/bible_bsb.db.backup
  String get bibleBsbDb => 'assets/databases/bible_bsb.db.backup';

  /// File path: assets/databases/fix_temptation_duplicates.sql
  String get fixTemptationDuplicates =>
      'assets/databases/fix_temptation_duplicates.sql';

  /// File path: assets/databases/migration_add_curriculum.sql
  String get migrationAddCurriculum =>
      'assets/databases/migration_add_curriculum.sql';

  /// File path: assets/databases/seed_curriculum.sql
  String get seedCurriculum => 'assets/databases/seed_curriculum.sql';

  /// File path: assets/databases/seed_curriculum.sql.bak
  String get seedCurriculumSql => 'assets/databases/seed_curriculum.sql.bak';

  /// File path: assets/databases/seed_curriculum_200_additional.sql
  String get seedCurriculum200Additional =>
      'assets/databases/seed_curriculum_200_additional.sql';

  /// File path: assets/databases/seed_curriculum_complete_500.sql
  String get seedCurriculumComplete500 =>
      'assets/databases/seed_curriculum_complete_500.sql';

  /// File path: assets/databases/seed_curriculum_extended.sql
  String get seedCurriculumExtended =>
      'assets/databases/seed_curriculum_extended.sql';

  /// List of all assets
  List<String> get values => [
        readme,
        bibleBsb,
        bibleBsbDb,
        fixTemptationDuplicates,
        migrationAddCurriculum,
        seedCurriculum,
        seedCurriculumSql,
        seedCurriculum200Additional,
        seedCurriculumComplete500,
        seedCurriculumExtended
      ];
}

class $AssetsFontsGen {
  const $AssetsFontsGen();

  /// File path: assets/fonts/garamon.ttf
  String get garamon => 'assets/fonts/garamon.ttf';

  /// List of all assets
  List<String> get values => [garamon];
}

class $AssetsImagesGen {
  const $AssetsImagesGen();

  /// File path: assets/images/app-icon.png
  AssetGenImage get appIcon =>
      const AssetGenImage('assets/images/app-icon.png');

  /// File path: assets/images/bible_verse_illustration.png
  AssetGenImage get bibleVerseIllustration =>
      const AssetGenImage('assets/images/bible_verse_illustration.png');

  /// List of all assets
  List<AssetGenImage> get values => [appIcon, bibleVerseIllustration];
}

class $AssetsMascotGen {
  const $AssetsMascotGen();

  /// File path: assets/mascot/happy.mov
  String get happy => 'assets/mascot/happy.mov';

  /// File path: assets/mascot/judah_app_protection.gif
  AssetGenImage get judahAppProtection =>
      const AssetGenImage('assets/mascot/judah_app_protection.gif');

  /// File path: assets/mascot/judah_app_protectionn.gif
  AssetGenImage get judahAppProtectionn =>
      const AssetGenImage('assets/mascot/judah_app_protectionn.gif');

  /// File path: assets/mascot/judah_encouraging.gif
  AssetGenImage get judahEncouraging =>
      const AssetGenImage('assets/mascot/judah_encouraging.gif');

  /// File path: assets/mascot/judah_happy.gif
  AssetGenImage get judahHappy =>
      const AssetGenImage('assets/mascot/judah_happy.gif');

  /// File path: assets/mascot/judah_neutral.gif
  AssetGenImage get judahNeutral =>
      const AssetGenImage('assets/mascot/judah_neutral.gif');

  /// File path: assets/mascot/judah_pointing.gif
  AssetGenImage get judahPointing =>
      const AssetGenImage('assets/mascot/judah_pointing.gif');

  /// File path: assets/mascot/judah_praying.gif
  AssetGenImage get judahPraying =>
      const AssetGenImage('assets/mascot/judah_praying.gif');

  /// File path: assets/mascot/judah_proud.gif
  AssetGenImage get judahProud =>
      const AssetGenImage('assets/mascot/judah_proud.gif');

  /// File path: assets/mascot/judah_sad.gif
  AssetGenImage get judahSad =>
      const AssetGenImage('assets/mascot/judah_sad.gif');

  /// File path: assets/mascot/judah_sleeping.gif
  AssetGenImage get judahSleeping =>
      const AssetGenImage('assets/mascot/judah_sleeping.gif');

  /// File path: assets/mascot/judah_time_selection.gif
  AssetGenImage get judahTimeSelection =>
      const AssetGenImage('assets/mascot/judah_time_selection.gif');

  /// File path: assets/mascot/neutral.mov
  String get neutral => 'assets/mascot/neutral.mov';

  /// File path: assets/mascot/sad.mov
  String get sad => 'assets/mascot/sad.mov';

  /// File path: assets/mascot/very_happy.mov
  String get veryHappy => 'assets/mascot/very_happy.mov';

  /// List of all assets
  List<dynamic> get values => [
        happy,
        judahAppProtection,
        judahAppProtectionn,
        judahEncouraging,
        judahHappy,
        judahNeutral,
        judahPointing,
        judahPraying,
        judahProud,
        judahSad,
        judahSleeping,
        judahTimeSelection,
        neutral,
        sad,
        veryHappy
      ];
}

class $AssetsPromptsGen {
  const $AssetsPromptsGen();

  /// File path: assets/prompts/companion_system_prompt.txt
  String get companionSystemPrompt =>
      'assets/prompts/companion_system_prompt.txt';

  /// List of all assets
  List<String> get values => [companionSystemPrompt];
}

class Assets {
  Assets._();

  static const $AssetsDatabasesGen databases = $AssetsDatabasesGen();
  static const $AssetsFontsGen fonts = $AssetsFontsGen();
  static const $AssetsImagesGen images = $AssetsImagesGen();
  static const $AssetsMascotGen mascot = $AssetsMascotGen();
  static const $AssetsPromptsGen prompts = $AssetsPromptsGen();
  static const String shorebird = 'shorebird.yaml';

  /// List of all assets
  static List<String> get values => [shorebird];
}

class AssetGenImage {
  const AssetGenImage(
    this._assetName, {
    this.size,
    this.flavors = const {},
  });

  final String _assetName;

  final Size? size;
  final Set<String> flavors;

  Image image({
    Key? key,
    AssetBundle? bundle,
    ImageFrameBuilder? frameBuilder,
    ImageErrorWidgetBuilder? errorBuilder,
    String? semanticLabel,
    bool excludeFromSemantics = false,
    double? scale,
    double? width,
    double? height,
    Color? color,
    Animation<double>? opacity,
    BlendMode? colorBlendMode,
    BoxFit? fit,
    AlignmentGeometry alignment = Alignment.center,
    ImageRepeat repeat = ImageRepeat.noRepeat,
    Rect? centerSlice,
    bool matchTextDirection = false,
    bool gaplessPlayback = true,
    bool isAntiAlias = false,
    String? package,
    FilterQuality filterQuality = FilterQuality.low,
    int? cacheWidth,
    int? cacheHeight,
  }) {
    return Image.asset(
      _assetName,
      key: key,
      bundle: bundle,
      frameBuilder: frameBuilder,
      errorBuilder: errorBuilder,
      semanticLabel: semanticLabel,
      excludeFromSemantics: excludeFromSemantics,
      scale: scale,
      width: width,
      height: height,
      color: color,
      opacity: opacity,
      colorBlendMode: colorBlendMode,
      fit: fit,
      alignment: alignment,
      repeat: repeat,
      centerSlice: centerSlice,
      matchTextDirection: matchTextDirection,
      gaplessPlayback: gaplessPlayback,
      isAntiAlias: isAntiAlias,
      package: package,
      filterQuality: filterQuality,
      cacheWidth: cacheWidth,
      cacheHeight: cacheHeight,
    );
  }

  ImageProvider provider({
    AssetBundle? bundle,
    String? package,
  }) {
    return AssetImage(
      _assetName,
      bundle: bundle,
      package: package,
    );
  }

  String get path => _assetName;

  String get keyName => _assetName;
}
