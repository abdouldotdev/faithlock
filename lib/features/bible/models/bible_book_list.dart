import 'bible_book.dart';

/// Complete canonical list of 66 Bible books with accurate chapter counts.
///
/// Data source: standard Protestant canon (KJV / BSB).
/// Chapter counts verified against BSB database schema.
const List<BibleBook> kBibleBooks = [
  // ── Old Testament ─────────────────────────────────────────────────────────

  // Pentateuch
  BibleBook(name: 'Genesis', abbreviation: 'Gn', chapterCount: 50, testament: Testament.old, category: BibleBookCategory.pentateuch),
  BibleBook(name: 'Exodus', abbreviation: 'Ex', chapterCount: 40, testament: Testament.old, category: BibleBookCategory.pentateuch),
  BibleBook(name: 'Leviticus', abbreviation: 'Lv', chapterCount: 27, testament: Testament.old, category: BibleBookCategory.pentateuch),
  BibleBook(name: 'Numbers', abbreviation: 'Nm', chapterCount: 36, testament: Testament.old, category: BibleBookCategory.pentateuch),
  BibleBook(name: 'Deuteronomy', abbreviation: 'Dt', chapterCount: 34, testament: Testament.old, category: BibleBookCategory.pentateuch),

  // Historical
  BibleBook(name: 'Joshua', abbreviation: 'Jos', chapterCount: 24, testament: Testament.old, category: BibleBookCategory.historical),
  BibleBook(name: 'Judges', abbreviation: 'Jdg', chapterCount: 21, testament: Testament.old, category: BibleBookCategory.historical),
  BibleBook(name: 'Ruth', abbreviation: 'Ru', chapterCount: 4, testament: Testament.old, category: BibleBookCategory.historical),
  BibleBook(name: '1 Samuel', abbreviation: '1Sm', chapterCount: 31, testament: Testament.old, category: BibleBookCategory.historical),
  BibleBook(name: '2 Samuel', abbreviation: '2Sm', chapterCount: 24, testament: Testament.old, category: BibleBookCategory.historical),
  BibleBook(name: '1 Kings', abbreviation: '1Kg', chapterCount: 22, testament: Testament.old, category: BibleBookCategory.historical),
  BibleBook(name: '2 Kings', abbreviation: '2Kg', chapterCount: 25, testament: Testament.old, category: BibleBookCategory.historical),
  BibleBook(name: '1 Chronicles', abbreviation: '1Ch', chapterCount: 29, testament: Testament.old, category: BibleBookCategory.historical),
  BibleBook(name: '2 Chronicles', abbreviation: '2Ch', chapterCount: 36, testament: Testament.old, category: BibleBookCategory.historical),
  BibleBook(name: 'Ezra', abbreviation: 'Ezr', chapterCount: 10, testament: Testament.old, category: BibleBookCategory.historical),
  BibleBook(name: 'Nehemiah', abbreviation: 'Ne', chapterCount: 13, testament: Testament.old, category: BibleBookCategory.historical),
  BibleBook(name: 'Esther', abbreviation: 'Est', chapterCount: 10, testament: Testament.old, category: BibleBookCategory.historical),

  // Wisdom
  BibleBook(name: 'Job', abbreviation: 'Jb', chapterCount: 42, testament: Testament.old, category: BibleBookCategory.wisdom),
  BibleBook(name: 'Psalms', abbreviation: 'Ps', chapterCount: 150, testament: Testament.old, category: BibleBookCategory.wisdom),
  BibleBook(name: 'Proverbs', abbreviation: 'Prv', chapterCount: 31, testament: Testament.old, category: BibleBookCategory.wisdom),
  BibleBook(name: 'Ecclesiastes', abbreviation: 'Ec', chapterCount: 12, testament: Testament.old, category: BibleBookCategory.wisdom),
  BibleBook(name: 'Song of Solomon', abbreviation: 'Sg', chapterCount: 8, testament: Testament.old, category: BibleBookCategory.wisdom),

  // Major Prophets
  BibleBook(name: 'Isaiah', abbreviation: 'Is', chapterCount: 66, testament: Testament.old, category: BibleBookCategory.majorProphets),
  BibleBook(name: 'Jeremiah', abbreviation: 'Jr', chapterCount: 52, testament: Testament.old, category: BibleBookCategory.majorProphets),
  BibleBook(name: 'Lamentations', abbreviation: 'Lm', chapterCount: 5, testament: Testament.old, category: BibleBookCategory.majorProphets),
  BibleBook(name: 'Ezekiel', abbreviation: 'Ezk', chapterCount: 48, testament: Testament.old, category: BibleBookCategory.majorProphets),
  BibleBook(name: 'Daniel', abbreviation: 'Dn', chapterCount: 12, testament: Testament.old, category: BibleBookCategory.majorProphets),

  // Minor Prophets
  BibleBook(name: 'Hosea', abbreviation: 'Hos', chapterCount: 14, testament: Testament.old, category: BibleBookCategory.minorProphets),
  BibleBook(name: 'Joel', abbreviation: 'Jl', chapterCount: 3, testament: Testament.old, category: BibleBookCategory.minorProphets),
  BibleBook(name: 'Amos', abbreviation: 'Am', chapterCount: 9, testament: Testament.old, category: BibleBookCategory.minorProphets),
  BibleBook(name: 'Obadiah', abbreviation: 'Ob', chapterCount: 1, testament: Testament.old, category: BibleBookCategory.minorProphets),
  BibleBook(name: 'Jonah', abbreviation: 'Jon', chapterCount: 4, testament: Testament.old, category: BibleBookCategory.minorProphets),
  BibleBook(name: 'Micah', abbreviation: 'Mi', chapterCount: 7, testament: Testament.old, category: BibleBookCategory.minorProphets),
  BibleBook(name: 'Nahum', abbreviation: 'Na', chapterCount: 3, testament: Testament.old, category: BibleBookCategory.minorProphets),
  BibleBook(name: 'Habakkuk', abbreviation: 'Hab', chapterCount: 3, testament: Testament.old, category: BibleBookCategory.minorProphets),
  BibleBook(name: 'Zephaniah', abbreviation: 'Zep', chapterCount: 3, testament: Testament.old, category: BibleBookCategory.minorProphets),
  BibleBook(name: 'Haggai', abbreviation: 'Hg', chapterCount: 2, testament: Testament.old, category: BibleBookCategory.minorProphets),
  BibleBook(name: 'Zechariah', abbreviation: 'Zec', chapterCount: 14, testament: Testament.old, category: BibleBookCategory.minorProphets),
  BibleBook(name: 'Malachi', abbreviation: 'Mal', chapterCount: 4, testament: Testament.old, category: BibleBookCategory.minorProphets),

  // ── New Testament ─────────────────────────────────────────────────────────

  // Gospels
  BibleBook(name: 'Matthew', abbreviation: 'Mt', chapterCount: 28, testament: Testament.newTestament, category: BibleBookCategory.gospels),
  BibleBook(name: 'Mark', abbreviation: 'Mk', chapterCount: 16, testament: Testament.newTestament, category: BibleBookCategory.gospels),
  BibleBook(name: 'Luke', abbreviation: 'Lk', chapterCount: 24, testament: Testament.newTestament, category: BibleBookCategory.gospels),
  BibleBook(name: 'John', abbreviation: 'Jn', chapterCount: 21, testament: Testament.newTestament, category: BibleBookCategory.gospels),

  // Acts
  BibleBook(name: 'Acts', abbreviation: 'Ac', chapterCount: 28, testament: Testament.newTestament, category: BibleBookCategory.acts),

  // Pauline Epistles
  BibleBook(name: 'Romans', abbreviation: 'Rm', chapterCount: 16, testament: Testament.newTestament, category: BibleBookCategory.paulineEpistles),
  BibleBook(name: '1 Corinthians', abbreviation: '1Co', chapterCount: 16, testament: Testament.newTestament, category: BibleBookCategory.paulineEpistles),
  BibleBook(name: '2 Corinthians', abbreviation: '2Co', chapterCount: 13, testament: Testament.newTestament, category: BibleBookCategory.paulineEpistles),
  BibleBook(name: 'Galatians', abbreviation: 'Gal', chapterCount: 6, testament: Testament.newTestament, category: BibleBookCategory.paulineEpistles),
  BibleBook(name: 'Ephesians', abbreviation: 'Eph', chapterCount: 6, testament: Testament.newTestament, category: BibleBookCategory.paulineEpistles),
  BibleBook(name: 'Philippians', abbreviation: 'Php', chapterCount: 4, testament: Testament.newTestament, category: BibleBookCategory.paulineEpistles),
  BibleBook(name: 'Colossians', abbreviation: 'Col', chapterCount: 4, testament: Testament.newTestament, category: BibleBookCategory.paulineEpistles),
  BibleBook(name: '1 Thessalonians', abbreviation: '1Th', chapterCount: 5, testament: Testament.newTestament, category: BibleBookCategory.paulineEpistles),
  BibleBook(name: '2 Thessalonians', abbreviation: '2Th', chapterCount: 3, testament: Testament.newTestament, category: BibleBookCategory.paulineEpistles),
  BibleBook(name: '1 Timothy', abbreviation: '1Tm', chapterCount: 6, testament: Testament.newTestament, category: BibleBookCategory.paulineEpistles),
  BibleBook(name: '2 Timothy', abbreviation: '2Tm', chapterCount: 4, testament: Testament.newTestament, category: BibleBookCategory.paulineEpistles),
  BibleBook(name: 'Titus', abbreviation: 'Ti', chapterCount: 3, testament: Testament.newTestament, category: BibleBookCategory.paulineEpistles),
  BibleBook(name: 'Philemon', abbreviation: 'Phm', chapterCount: 1, testament: Testament.newTestament, category: BibleBookCategory.paulineEpistles),
  BibleBook(name: 'Hebrews', abbreviation: 'Heb', chapterCount: 13, testament: Testament.newTestament, category: BibleBookCategory.paulineEpistles),

  // General Epistles
  BibleBook(name: 'James', abbreviation: 'Jas', chapterCount: 5, testament: Testament.newTestament, category: BibleBookCategory.generalEpistles),
  BibleBook(name: '1 Peter', abbreviation: '1Pt', chapterCount: 5, testament: Testament.newTestament, category: BibleBookCategory.generalEpistles),
  BibleBook(name: '2 Peter', abbreviation: '2Pt', chapterCount: 3, testament: Testament.newTestament, category: BibleBookCategory.generalEpistles),
  BibleBook(name: '1 John', abbreviation: '1Jn', chapterCount: 5, testament: Testament.newTestament, category: BibleBookCategory.generalEpistles),
  BibleBook(name: '2 John', abbreviation: '2Jn', chapterCount: 1, testament: Testament.newTestament, category: BibleBookCategory.generalEpistles),
  BibleBook(name: '3 John', abbreviation: '3Jn', chapterCount: 1, testament: Testament.newTestament, category: BibleBookCategory.generalEpistles),
  BibleBook(name: 'Jude', abbreviation: 'Jde', chapterCount: 1, testament: Testament.newTestament, category: BibleBookCategory.generalEpistles),

  // Prophecy
  BibleBook(name: 'Revelation', abbreviation: 'Rv', chapterCount: 22, testament: Testament.newTestament, category: BibleBookCategory.prophecy),
];
