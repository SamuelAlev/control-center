import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// Widgets-layer localizations, hand-rolled instead of
/// `GlobalWidgetsLocalizations` from flutter_localizations.
///
/// The only thing this app needs from the widgets delegate is the ambient
/// [TextDirection] per locale — RTL for Arabic/Hebrew/Persian/Urdu. The global
/// delegate carries per-locale data this bandwidth-sensitive tier would ship
/// for four lines of logic. Everything else (context-menu button labels)
/// inherits [DefaultWidgetsLocalizations]' values.
class PhoneWidgetsLocalizations extends DefaultWidgetsLocalizations {
  /// Creates widgets localizations that pin [textDirection].
  const PhoneWidgetsLocalizations(this._textDirection);

  final TextDirection _textDirection;

  @override
  TextDirection get textDirection => _textDirection;
}

/// Loads [PhoneWidgetsLocalizations] for every locale.
class PhoneWidgetsLocalizationsDelegate
    extends LocalizationsDelegate<WidgetsLocalizations> {
  /// Creates the delegate.
  const PhoneWidgetsLocalizationsDelegate();

  /// Language codes written right-to-left. Matches the set
  /// `GlobalWidgetsLocalizations` would resolve as RTL for the locales this
  /// app can ever receive (the resolved locale is bounded by
  /// `kSupportedRemoteLocales`).
  static const Set<String> rtlLanguageCodes = {'ar', 'he', 'fa', 'ur'};

  @override
  bool isSupported(Locale locale) => true;

  @override
  Future<WidgetsLocalizations> load(Locale locale) {
    return SynchronousFuture<WidgetsLocalizations>(
      PhoneWidgetsLocalizations(
        rtlLanguageCodes.contains(locale.languageCode)
            ? TextDirection.rtl
            : TextDirection.ltr,
      ),
    );
  }

  @override
  bool shouldReload(PhoneWidgetsLocalizationsDelegate old) => false;
}
