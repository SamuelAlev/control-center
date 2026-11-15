import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/l10n/eager_locales.dart'
    if (dart.library.io) 'package:control_center/l10n/eager_locales_io.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

/// Loads and caches the app's [AppLocalizations].
///
/// `l10n.yaml` generates every locale as a deferred library, so on web each
/// locale is its own `main.dart.js_N.part.js`, fetched only when used. The
/// generated [lookupAppLocalizations] and [AppLocalizations.delegate] are then
/// asynchronous every time, which renders a blank first frame and leaves no
/// synchronous lookup. This loader keeps what it loaded: [appLocalizationsDelegate]
/// answers synchronously for a loaded locale, and [lookupLoaded] serves code
/// outside the widget tree (notifications, tray, providers).
///
/// Native builds never touch the deferred libraries: under the Flutter engine
/// outside the web a deferred `loadLibrary()` never completes (a widget test
/// hung before its first test), so they build each locale from
/// `eager_locales_io.dart`, and [preloadAll] is synchronous there. The web
/// client loads its starting locale, and any other locale on first use.
abstract final class AppLocalizationsLoader {
  AppLocalizationsLoader._();

  static final Map<Locale, AppLocalizations> _loaded = {};
  static final Map<Locale, Future<AppLocalizations>> _pending = {};

  /// The shipped locale whose ARB serves [locale], matched the way the
  /// generated lookup does (language and country, then language), else
  /// English, the preferred fallback.
  static Locale supportedLocaleFor(Locale locale) {
    Locale? languageOnly;
    for (final supported in AppLocalizations.supportedLocales) {
      if (supported.languageCode != locale.languageCode) {
        continue;
      }
      if (supported.countryCode == locale.countryCode) {
        return supported;
      }
      if (supported.countryCode == null) {
        languageOnly = supported;
      }
    }
    return languageOnly ?? const Locale('en');
  }

  /// Loads [locale] (fetching its deferred part on web) and caches it.
  static Future<AppLocalizations> load(Locale locale) {
    final key = supportedLocaleFor(locale);
    final loaded = _loaded[key];
    if (loaded != null) {
      return SynchronousFuture<AppLocalizations>(loaded);
    }
    final eager = eagerLocales?[key];
    if (eager != null) {
      return SynchronousFuture<AppLocalizations>(_loaded[key] = eager());
    }
    return _pending[key] ??= lookupAppLocalizations(key)
        .then((l10n) {
          _loaded[key] = l10n;
          return l10n;
        })
        .whenComplete(() => _pending.remove(key));
  }

  /// Loads every shipped locale. The desktop and the widget tests call this
  /// before anything renders, so every lookup there is synchronous.
  static Future<void> preloadAll() =>
      Future.wait(AppLocalizations.supportedLocales.map(load));

  /// The loaded localizations for [locale], or `null` when its locale has not
  /// finished loading.
  static AppLocalizations? loaded(Locale locale) =>
      _loaded[supportedLocaleFor(locale)];

  /// Localizations for [locale] without waiting.
  ///
  /// When [locale] is not loaded yet (the web client right after a language
  /// switch), this starts loading it, calls [onLoaded] once it has, and
  /// meanwhile answers with English or any locale that is loaded.
  static AppLocalizations lookupLoaded(
    Locale locale, {
    VoidCallback? onLoaded,
  }) {
    final hit = loaded(locale);
    if (hit != null) {
      return hit;
    }
    load(locale).then((_) => onLoaded?.call(), onError: (Object _) {});
    final fallback = _loaded[const Locale('en')] ?? _loaded.values.firstOrNull;
    if (fallback == null) {
      throw StateError(
        'No AppLocalizations loaded yet: call AppLocalizationsLoader.load '
        'or preloadAll before looking one up.',
      );
    }
    return fallback;
  }
}

/// The [AppLocalizations] delegate: synchronous for a loaded locale, so the
/// first frame renders text. Use this, never [AppLocalizations.delegate].
const LocalizationsDelegate<AppLocalizations> appLocalizationsDelegate =
    _LoadedAppLocalizationsDelegate();

/// [appLocalizationsDelegate] with the Material, Cupertino and widgets
/// delegates: the generated [AppLocalizations.localizationsDelegates] with the
/// synchronous delegate in its place. Use this, never the generated list.
const List<LocalizationsDelegate<dynamic>> appLocalizationsDelegates =
    <LocalizationsDelegate<dynamic>>[
      appLocalizationsDelegate,
      // The same framework delegates the generated list carries.
      // ignore: deprecated_member_use
      GlobalMaterialLocalizations.delegate,
      // ignore: deprecated_member_use
      GlobalCupertinoLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
    ];

class _LoadedAppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _LoadedAppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) =>
      AppLocalizationsLoader.load(locale);

  @override
  bool isSupported(Locale locale) =>
      AppLocalizations.delegate.isSupported(locale);

  @override
  bool shouldReload(_LoadedAppLocalizationsDelegate old) => false;
}
