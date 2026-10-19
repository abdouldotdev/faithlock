// ignore_for_file: non_constant_identifier_names

import 'package:faithlock/core/localization/de_DE.dart';
import 'package:faithlock/core/localization/fr_FR.dart';
import 'package:faithlock/core/localization/ja_JP.dart';
import 'package:faithlock/core/localization/pt_BR.dart';
import 'package:get/get.dart';

import 'added/app_misc_strings.dart';
import 'added/bible_ui_strings.dart';
import 'added/prayer_strings.dart';
import 'en_US.dart';

class AppTranslations extends Translations {
  @override
  Map<String, Map<String, String>> get keys => {
        // New feature strings (mood/prayer, bible UI, companion/home/nav) live
        // in added/*.dart and are spread in here so each agent could own its
        // own file without touching the big base maps. Other locales fall back
        // to en_US for any key they don't have yet.
        'en_US': {...en_US, ...prayerEnUS, ...bibleUiEnUS, ...appMiscEnUS},
        'fr_FR': {...fr_FR, ...prayerFrFR, ...bibleUiFrFR, ...appMiscFrFR},
        'pt_BR': pt_BR,
        'de_DE': de_DE,
        'ja_JP': ja_JP,
      };
}
