/// A locale that the app supports for localization.
class AppLocale {
/// Creates an [AppLocale] for the given [languageCode].
  const AppLocale(this.languageCode);

/// ISO 639-1 language code (e.g. `'en'`, `'fr'`).
  final String languageCode;

  static const _languageNames = <String, String>{
    'fr': 'French',
    'es': 'Spanish',
    'it': 'Italian',
    'de': 'German',
    'pt': 'Portuguese',
    'nl': 'Dutch',
  };

/// Display name in the user's own language, or `null` for English.

  String? get displayName => _languageNames[languageCode];

/// Whether this locale represents English.

  bool get isEnglish => languageCode == 'en';

/// Whether localization data exists for this locale.

  bool get hasLocalization => _languageNames.containsKey(languageCode);

/// Structural equality based on [languageCode].

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppLocale &&
          runtimeType == other.runtimeType &&
          languageCode == other.languageCode;

  @override
/// Hash based on [languageCode].

  int get hashCode => languageCode.hashCode;
}
