class AppLocale {
  const AppLocale(this.languageCode);

  final String languageCode;

  static const _languageNames = <String, String>{
    'fr': 'French',
    'es': 'Spanish',
    'it': 'Italian',
    'de': 'German',
    'pt': 'Portuguese',
    'nl': 'Dutch',
  };

  String? get displayName => _languageNames[languageCode];

  bool get isEnglish => languageCode == 'en';

  bool get hasLocalization => _languageNames.containsKey(languageCode);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppLocale &&
          runtimeType == other.runtimeType &&
          languageCode == other.languageCode;

  @override
  int get hashCode => languageCode.hashCode;
}
