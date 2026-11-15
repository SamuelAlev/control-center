import 'dart:ui' show Locale;

import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/l10n/app_localizations_ar.dart' as ar;
import 'package:control_center/l10n/app_localizations_cs.dart' as cs;
import 'package:control_center/l10n/app_localizations_de.dart' as de;
import 'package:control_center/l10n/app_localizations_el.dart' as el;
import 'package:control_center/l10n/app_localizations_en.dart' as en;
import 'package:control_center/l10n/app_localizations_es.dart' as es;
import 'package:control_center/l10n/app_localizations_fa.dart' as fa;
import 'package:control_center/l10n/app_localizations_fr.dart' as fr;
import 'package:control_center/l10n/app_localizations_he.dart' as he;
import 'package:control_center/l10n/app_localizations_hu.dart' as hu;
import 'package:control_center/l10n/app_localizations_id.dart' as id;
import 'package:control_center/l10n/app_localizations_it.dart' as it;
import 'package:control_center/l10n/app_localizations_ja.dart' as ja;
import 'package:control_center/l10n/app_localizations_ko.dart' as ko;
import 'package:control_center/l10n/app_localizations_ms.dart' as ms;
import 'package:control_center/l10n/app_localizations_nb.dart' as nb;
import 'package:control_center/l10n/app_localizations_nl.dart' as nl;
import 'package:control_center/l10n/app_localizations_pl.dart' as pl;
import 'package:control_center/l10n/app_localizations_pt.dart' as pt;
import 'package:control_center/l10n/app_localizations_ro.dart' as ro;
import 'package:control_center/l10n/app_localizations_ru.dart' as ru;
import 'package:control_center/l10n/app_localizations_sv.dart' as sv;
import 'package:control_center/l10n/app_localizations_th.dart' as th;
import 'package:control_center/l10n/app_localizations_tr.dart' as tr;
import 'package:control_center/l10n/app_localizations_uk.dart' as uk;
import 'package:control_center/l10n/app_localizations_ur.dart' as ur;
import 'package:control_center/l10n/app_localizations_vi.dart' as vi;
import 'package:control_center/l10n/app_localizations_zh.dart' as zh;

/// Every shipped locale, built without a deferred load. Native builds only
/// (see `eager_locales.dart`): under the Flutter engine outside the web, a
/// deferred `loadLibrary()` never completes, so the loader must not await one
/// there. Keyed by the exact [AppLocalizations.supportedLocales] entry.
final Map<Locale, AppLocalizations Function()> eagerLocales = {
  const Locale('en'): en.AppLocalizationsEn.new,
  const Locale('ar'): ar.AppLocalizationsAr.new,
  const Locale('cs'): cs.AppLocalizationsCs.new,
  const Locale('de'): de.AppLocalizationsDe.new,
  const Locale('el'): el.AppLocalizationsEl.new,
  const Locale('en', 'GB'): en.AppLocalizationsEnGb.new,
  const Locale('es'): es.AppLocalizationsEs.new,
  const Locale('es', 'MX'): es.AppLocalizationsEsMx.new,
  const Locale('fa'): fa.AppLocalizationsFa.new,
  const Locale('fr'): fr.AppLocalizationsFr.new,
  const Locale('fr', 'CA'): fr.AppLocalizationsFrCa.new,
  const Locale('he'): he.AppLocalizationsHe.new,
  const Locale('hu'): hu.AppLocalizationsHu.new,
  const Locale('id'): id.AppLocalizationsId.new,
  const Locale('it'): it.AppLocalizationsIt.new,
  const Locale('ja'): ja.AppLocalizationsJa.new,
  const Locale('ko'): ko.AppLocalizationsKo.new,
  const Locale('ms'): ms.AppLocalizationsMs.new,
  const Locale('nb'): nb.AppLocalizationsNb.new,
  const Locale('nl'): nl.AppLocalizationsNl.new,
  const Locale('pl'): pl.AppLocalizationsPl.new,
  const Locale('pt'): pt.AppLocalizationsPt.new,
  const Locale('pt', 'PT'): pt.AppLocalizationsPtPt.new,
  const Locale('ro'): ro.AppLocalizationsRo.new,
  const Locale('ru'): ru.AppLocalizationsRu.new,
  const Locale('sv'): sv.AppLocalizationsSv.new,
  const Locale('th'): th.AppLocalizationsTh.new,
  const Locale('tr'): tr.AppLocalizationsTr.new,
  const Locale('uk'): uk.AppLocalizationsUk.new,
  const Locale('ur'): ur.AppLocalizationsUr.new,
  const Locale('vi'): vi.AppLocalizationsVi.new,
  const Locale('zh'): zh.AppLocalizationsZh.new,
  const Locale('zh', 'HK'): zh.AppLocalizationsZhHk.new,
  const Locale('zh', 'TW'): zh.AppLocalizationsZhTw.new,
};
