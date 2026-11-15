import 'dart:ui' show Locale;

import 'package:control_center/l10n/app_localizations.dart';

/// No eager table on the web: each locale stays a deferred part, fetched on
/// first use. Native builds get `eager_locales_io.dart` instead, imported
/// conditionally so the web compilers never see a non-deferred locale import.
const Map<Locale, AppLocalizations Function()>? eagerLocales = null;
