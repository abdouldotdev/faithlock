/// Public-domain translations the Companion can quote (free to quote verbatim +
/// share; gpt-5/opus know them well). Copyrighted NIV/ESV/NLT are excluded.
const List<({String name, String short, String subtitle})> kCompanionVersions = [
  (
    name: 'Berean Standard Bible (BSB)',
    short: 'BSB',
    subtitle: 'Modern · accurate · public domain'
  ),
  (
    name: 'King James Version (KJV)',
    short: 'KJV',
    subtitle: 'Classic English · public domain'
  ),
  (
    name: 'World English Bible (WEB)',
    short: 'WEB',
    subtitle: 'Modern · readable · public domain'
  ),
  (
    name: 'American Standard Version (ASV)',
    short: 'ASV',
    subtitle: 'Literal · 1901 · public domain'
  ),
];

/// Per-user Companion preferences (stored locally, never leaves the device).
class CompanionSettings {
  /// Full translation name, fed into the prompt's {{BIBLE_VERSION}}.
  final String bibleVersion;

  /// Read the Companion's replies aloud (TTS).
  final bool voiceEnabled;

  /// Whether the first-run setup has been completed.
  final bool configured;

  const CompanionSettings({
    required this.bibleVersion,
    required this.voiceEnabled,
    required this.configured,
  });

  static const CompanionSettings defaults = CompanionSettings(
    bibleVersion: 'Berean Standard Bible (BSB)',
    voiceEnabled: true,
    configured: false,
  );

  CompanionSettings copyWith({
    String? bibleVersion,
    bool? voiceEnabled,
    bool? configured,
  }) =>
      CompanionSettings(
        bibleVersion: bibleVersion ?? this.bibleVersion,
        voiceEnabled: voiceEnabled ?? this.voiceEnabled,
        configured: configured ?? this.configured,
      );

  Map<String, dynamic> toJson() => {
        'bibleVersion': bibleVersion,
        'voiceEnabled': voiceEnabled,
        'configured': configured,
      };

  factory CompanionSettings.fromJson(Map<String, dynamic> j) =>
      CompanionSettings(
        bibleVersion: j['bibleVersion'] as String? ?? defaults.bibleVersion,
        voiceEnabled: j['voiceEnabled'] as bool? ?? true,
        configured: j['configured'] as bool? ?? false,
      );
}
