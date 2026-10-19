// ignore_for_file: non_constant_identifier_names

/// Translations for COMPANION + HOME + NAV + STREAK strings extracted from
/// hardcoded UI text. Merged into the app locales in `AppTranslations`.
/// Keys missing in other locales fall back to en_US via GetX `fallbackLocale`.

const Map<String, String> appMiscEnUS = {
  // ── Nav ──────────────────────────────────────────────
  'nav_today': "Today",
  'nav_bible': "Bible",

  // ── Home (Today) ─────────────────────────────────────
  'home_letsPrayNow': "Let's Pray Now",
  'home_dayStreak': "@count Day Streak",
  'home_personalBest': "PERSONAL BEST: @best",
  'home_streakBest': "BEST!",
  'home_streakEpic': "EPIC!",
  'home_streakAwesome': "AWESOME!",
  'home_streakGreat': "GREAT!",
  'home_streakNice': "NICE!",
  'home_prayedToday': "Prayed today",
  'home_versesRead': "Verses read",
  // 7 weekday initials, Mon→Sun, comma-separated (split at the call site).
  'home_weekdayInitials': "M,T,W,T,F,S,S",

  // ── Companion ────────────────────────────────────────
  'companion_title': "Companion",
  'companion_subtitle': "Your Bible companion",
  'companion_history': "History",
  'companion_newChat': "New chat",
  'companion_settings': "Settings",
  'companion_emptyTitle': "Let's talk it through",
  'companion_emptyReflecting': "Reflecting on @label. What's on your heart?",
  'companion_emptyDefault':
      "Bring whatever you're carrying. I'll meet you in Scripture.",
  'companion_tryAsking': "TRY ASKING",
  'companion_starter1': "I feel anxious today",
  'companion_starter2': "Help me pray",
  'companion_starter3': "I'm struggling to forgive",
  'companion_starter4': "What does the Bible say about hope?",
  'companion_connectionError':
      "I'm here with you, but I'm having trouble connecting right now. Give me a moment and try again. 🙏",
  'companion_composerHint': "Share what's on your heart…",

  // ── Companion settings sheet ─────────────────────────
  'companionSettings_meetTitle': "Meet your Companion",
  'companionSettings_title': "Companion settings",
  'companionSettings_firstRunSub': "A couple of quick choices and we'll begin.",
  'companionSettings_sub': "How I quote Scripture, and whether I speak.",
  'companionSettings_bibleTranslation': "BIBLE TRANSLATION",
  'companionSettings_voice': "VOICE",
  'companionSettings_start': "Start",
  'companionSettings_save': "Save",
  'companionSettings_readAloud': "Read replies aloud",
  'companionSettings_readAloudSub': "I'll speak each response",

  // ── Streak intro ─────────────────────────────────────
  'streak_dayStreak': "DAY STREAK",
  // 12 month abbreviations, Jan→Dec, comma-separated (split at the call site).
  'streak_months': "JAN,FEB,MAR,APR,MAY,JUN,JUL,AUG,SEP,OCT,NOV,DEC",

  // ── First-day feature tour (coach-mark) ──────────────
  'tour_welcome_title': "Welcome to FaithLock 🌱",
  'tour_welcome_body':
      "Let's start with the heart of it — a short, real prayer. Ready?",
  'tour_pray_title': "Let's pray first",
  'tour_pray_body':
      "Tap the button, choose a prayer, and take a real moment with God. We'll wait right here.",
  'tour_pray_hint': "Tap to pray",
  'tour_curated_title': "Chosen just for you ✨",
  'tour_curated_body':
      "Because you're feeling @mood, we picked a prayer made for this moment. Your daily prayer always follows how you feel.",
  'tour_curated_body_generic':
      "Each day we choose a prayer for you based on how you're feeling — so it always meets you right where you are.",
  'tour_curated_card_body':
      "This prayer was matched to how you're feeling. Tap it to begin.",
  'tour_lock_title': "Lock what pulls you away",
  'tour_lock_body':
      "Choose the apps that distract you. They stay sealed until you pray — exactly like the moment you just had.",
  'tour_bible_title': "The Word, always with you",
  'tour_bible_body':
      "Open the Bible anytime — a verse of the day and every book, one tap away.",
  'tour_companion_title': "You're never alone",
  'tour_companion_body':
      "Tap here to chat with your Bible companion — ask anything, anytime.",
  'tour_garden_title': "Toby's little garden 🌱",
  'tour_garden_body':
      "You just prayed — and Toby's tree is already growing. The more you pray, the more it blooms. Come back each day.",
  'tour_streak_title': "Your streak begins 🔥",
  'tour_streak_body':
      "You showed up today. Pray each day to keep the flame alive and watch your streak grow.",
  'tour_finish_title': "You're all set 🙏",
  'tour_finish_body':
      "That's the heart of it: pray, grow, and lock out the noise — one day at a time.",
  'tour_next': "Next",
  'tour_back': "Back",
  'tour_finish': "Let's go",
  'tour_skip': "Skip tour",
  'tour_tapToContinue': "Tap to continue",

  // ── Unlock chooser (earn a blocked app back) ─────────
  'unlock_chooser_title': "How would you like to unlock?",
  'unlock_chooser_subtitle': "Take a moment before you open it.",
  'unlock_method_setting': "Unlock method",
  'unlock_method_settingSub': "How you earn a blocked app back.",
  'unlock_method_ask': "Ask every time",
  'unlock_method_quiz': "Quiz",
  'unlock_method_prayer': "Prayer",
  'unlock_method_audio': "Prayer · Audio",
  'unlock_method_text': "Prayer · Read",
  'unlock_quiz_sub': "Answer a quick verse question",
  'unlock_prayer_sub': "Pray a moment to unlock",
  'unlock_audio_sub': "Listen to a guided prayer",
  'unlock_text_sub': "Read a prayer at your pace",
  'unlock_remember': "Remember my choice",
  'unlock_remember_hint': "You can change this anytime in Profile.",

  // ── Replay tour ──────────────────────────────────────
  'replayTour_title': "Replay the tour",
  'replayTour_sub': "See the first-day walkthrough again",
};

const Map<String, String> appMiscFrFR = {
  // ── Nav ──────────────────────────────────────────────
  'nav_today': "Aujourd'hui",
  'nav_bible': "Bible",

  // ── Home (Today) ─────────────────────────────────────
  'home_letsPrayNow': "Prions maintenant",
  'home_dayStreak': "Série de @count jours",
  'home_personalBest': "RECORD : @best",
  'home_streakBest': "RECORD !",
  'home_streakEpic': "ÉPIQUE !",
  'home_streakAwesome': "BRAVO !",
  'home_streakGreat': "SUPER !",
  'home_streakNice': "BIEN !",
  'home_prayedToday': "Prié aujourd'hui",
  'home_versesRead': "Versets lus",
  'home_weekdayInitials': "L,M,M,J,V,S,D",

  // ── Companion ────────────────────────────────────────
  'companion_title': "Compagnon",
  'companion_subtitle': "Votre compagnon biblique",
  'companion_history': "Historique",
  'companion_newChat': "Nouvelle discussion",
  'companion_settings': "Réglages",
  'companion_emptyTitle': "Parlons-en ensemble",
  'companion_emptyReflecting': "Méditons sur @label. Qu'as-tu sur le cœur ?",
  'companion_emptyDefault':
      "Apporte ce que tu portes. Je te rejoindrai dans les Écritures.",
  'companion_tryAsking': "POUR COMMENCER",
  'companion_starter1': "Je me sens anxieux aujourd'hui",
  'companion_starter2': "Aide-moi à prier",
  'companion_starter3': "J'ai du mal à pardonner",
  'companion_starter4': "Que dit la Bible sur l'espérance ?",
  'companion_connectionError':
      "Je suis là avec toi, mais j'ai du mal à me connecter pour l'instant. Laisse-moi un instant et réessaie. 🙏",
  'companion_composerHint': "Partage ce que tu as sur le cœur…",

  // ── Companion settings sheet ─────────────────────────
  'companionSettings_meetTitle': "Rencontre ton compagnon",
  'companionSettings_title': "Réglages du compagnon",
  'companionSettings_firstRunSub': "Quelques choix rapides et on commence.",
  'companionSettings_sub': "Comment je cite l'Écriture, et si je parle.",
  'companionSettings_bibleTranslation': "TRADUCTION BIBLIQUE",
  'companionSettings_voice': "VOIX",
  'companionSettings_start': "Commencer",
  'companionSettings_save': "Enregistrer",
  'companionSettings_readAloud': "Lire les réponses à voix haute",
  'companionSettings_readAloudSub': "Je lirai chaque réponse",

  // ── Streak intro ─────────────────────────────────────
  'streak_dayStreak': "JOURS D'AFFILÉE",
  'streak_months': "JANV,FÉVR,MARS,AVR,MAI,JUIN,JUIL,AOÛT,SEPT,OCT,NOV,DÉC",

  // ── First-day feature tour (coach-mark) ──────────────
  'tour_welcome_title': "Bienvenue sur FaithLock 🌱",
  'tour_welcome_body':
      "Commençons par l'essentiel — une vraie prière, toute courte. Prêt ?",
  'tour_pray_title': "Commençons par prier",
  'tour_pray_body':
      "Touche le bouton, choisis une prière et prends un vrai moment avec Dieu. On t'attend ici.",
  'tour_pray_hint': "Touche pour prier",
  'tour_curated_title': "Choisie pour toi ✨",
  'tour_curated_body':
      "Parce que tu te sens @mood, on a choisi une prière faite pour ce moment. Ta prière du jour suit toujours ce que tu ressens.",
  'tour_curated_body_generic':
      "Chaque jour, on choisit une prière selon ce que tu ressens — pour qu'elle te rejoigne là où tu en es.",
  'tour_curated_card_body':
      "Cette prière correspond à ton humeur. Touche-la pour commencer.",
  'tour_lock_title': "Verrouille ce qui te distrait",
  'tour_lock_body':
      "Choisis les apps qui te détournent. Elles restent fermées tant que tu n'as pas prié — exactement comme le moment que tu viens de vivre.",
  'tour_bible_title': "La Parole, toujours avec toi",
  'tour_bible_body':
      "Ouvre la Bible à tout moment — un verset du jour et tous les livres, en un geste.",
  'tour_companion_title': "Tu n'es jamais seul",
  'tour_companion_body':
      "Touche ici pour parler à ton compagnon biblique — pose n'importe quelle question, à tout moment.",
  'tour_garden_title': "Le petit jardin de Toby 🌱",
  'tour_garden_body':
      "Tu viens de prier — et l'arbre de Toby grandit déjà. Plus tu pries, plus il fleurit. Reviens chaque jour.",
  'tour_streak_title': "Ta série commence 🔥",
  'tour_streak_body':
      "Tu es venu aujourd'hui. Prie chaque jour pour garder la flamme et faire grandir ta série.",
  'tour_finish_title': "Tout est prêt 🙏",
  'tour_finish_body':
      "Voilà l'essentiel : prie, grandis, et mets de côté le bruit — un jour à la fois.",
  'tour_next': "Suivant",
  'tour_back': "Retour",
  'tour_finish': "C'est parti",
  'tour_skip': "Passer le tour",
  'tour_tapToContinue': "Touche pour continuer",

  // ── Unlock chooser (regagner une app bloquée) ────────
  'unlock_chooser_title': "Comment veux-tu déverrouiller ?",
  'unlock_chooser_subtitle': "Prends un moment avant de l'ouvrir.",
  'unlock_method_setting': "Méthode de déverrouillage",
  'unlock_method_settingSub': "Comment regagner une app bloquée.",
  'unlock_method_ask': "Demander à chaque fois",
  'unlock_method_quiz': "Quiz",
  'unlock_method_prayer': "Prière",
  'unlock_method_audio': "Prière · Audio",
  'unlock_method_text': "Prière · Lecture",
  'unlock_quiz_sub': "Réponds à une question sur un verset",
  'unlock_prayer_sub': "Prie un instant pour déverrouiller",
  'unlock_audio_sub': "Écoute une prière guidée",
  'unlock_text_sub': "Lis une prière à ton rythme",
  'unlock_remember': "Mémoriser mon choix",
  'unlock_remember_hint': "Tu peux changer ça à tout moment dans le Profil.",

  // ── Replay tour ──────────────────────────────────────
  'replayTour_title': "Revoir le tour",
  'replayTour_sub': "Revois la visite du premier jour",
};
