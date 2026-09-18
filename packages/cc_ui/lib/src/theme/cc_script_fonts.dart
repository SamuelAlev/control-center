import 'package:flutter/services.dart' show FontLoader, rootBundle;
import 'package:flutter/widgets.dart';

/// One companion face for a script Manrope does not cover.
///
/// [family] + [assetPaths] are the vendored cut, registered through
/// [FontLoader] only when that locale is active. [systemFamilies] are OS
/// faces that cover the first frame (and any deploy that cannot read the
/// asset). CJK specs ship no assets — those cuts are tens of megabytes, so
/// the platform UI face is the companion.
@immutable
class CcScriptFontSpec {
  /// Creates a script-companion spec.
  const CcScriptFontSpec({
    required this.id,
    this.family,
    this.assetPaths = const [],
    this.systemFamilies = const [],
  });

  /// Stable id (`thai`, `hebrew`, …) for tests and logging.
  final String id;

  /// Engine family name registered from [assetPaths], or null when this
  /// script uses only [systemFamilies].
  final String? family;

  /// Paths relative to the `cc_ui` package root, listed in `pubspec.yaml`
  /// `assets:` (never `fonts:` — see [CcScriptFonts]).
  final List<String> assetPaths;

  /// Platform faces consulted until (or instead of) the vendored cut.
  final List<String> systemFamilies;

  /// Names to put on [TextStyle.fontFamilyFallback] for this spec.
  List<String> get fallbackFamilies => [?family, ...systemFamilies];
}

/// Locale → script companion. Manrope itself covers Latin (including
/// Vietnamese), Cyrillic, and limited Greek; everything else named here.
///
/// The faces are chosen to sit next to Manrope (warm geometric grotesque,
/// UI proportions, Regular 400 + SemiBold 600):
///  * Thai — Sarabun
///  * Hebrew — Rubik
///  * Arabic / Persian / Urdu — IBM Plex Sans Arabic
///  * CJK — the OS UI face (PingFang, Hiragino, Apple SD Gothic Neo, …)
///
/// Bytes live under `fonts/scripts/` as **assets**, not `fonts:` entries.
/// Flutter web downloads every `FontManifest.json` family at engine boot, so
/// declaring them there would load Thai+Hebrew+Arabic on an English cold
/// start. [ensureLoaded] FontLoaders only the active spec.
abstract final class CcScriptFonts {
  const CcScriptFonts._();

  /// Thai. Cadson Demak's Sarabun — a clean UI sans with Thai + Latin.
  static const thai = CcScriptFontSpec(
    id: 'thai',
    family: 'Sarabun',
    assetPaths: [
      'fonts/scripts/Sarabun-Regular.ttf',
      'fonts/scripts/Sarabun-SemiBold.ttf',
    ],
    systemFamilies: ['Thonburi', 'Leelawadee UI'],
  );

  /// Hebrew. Rubik — warm geometric, the closest Manrope cousin that
  /// actually ships Hebrew.
  static const hebrew = CcScriptFontSpec(
    id: 'hebrew',
    family: 'Rubik',
    assetPaths: ['fonts/scripts/Rubik-Variable.ttf'],
    systemFamilies: ['SF Hebrew', 'Arial Hebrew'],
  );

  /// Arabic-script UI (Arabic, Persian, Urdu). IBM Plex Sans Arabic is the
  /// product-UI companion; Urdu stays on this Naskh sans rather than
  /// Nastaliq, which is a running-text face.
  static const arabic = CcScriptFontSpec(
    id: 'arabic',
    family: 'IBM Plex Sans Arabic',
    assetPaths: [
      'fonts/scripts/IBMPlexSansArabic-Regular.ttf',
      'fonts/scripts/IBMPlexSansArabic-SemiBold.ttf',
    ],
    systemFamilies: ['SF Arabic', 'Geeza Pro', 'Segoe UI'],
  );

  /// Simplified Chinese. System only — Noto CJK is tens of megabytes.
  static const simplifiedChinese = CcScriptFontSpec(
    id: 'simplifiedChinese',
    systemFamilies: ['PingFang SC', 'Microsoft YaHei', 'Noto Sans SC'],
  );

  /// Traditional Chinese (Taiwan + Hong Kong).
  static const traditionalChinese = CcScriptFontSpec(
    id: 'traditionalChinese',
    systemFamilies: [
      'PingFang TC',
      'PingFang HK',
      'Microsoft JhengHei',
      'Noto Sans TC',
    ],
  );

  /// Japanese. System only.
  static const japanese = CcScriptFontSpec(
    id: 'japanese',
    systemFamilies: ['Hiragino Sans', 'Yu Gothic', 'Meiryo', 'Noto Sans JP'],
  );

  /// Korean. System only.
  static const korean = CcScriptFontSpec(
    id: 'korean',
    systemFamilies: ['Apple SD Gothic Neo', 'Malgun Gothic', 'Noto Sans KR'],
  );

  /// Greek. Manrope's Greek is limited; SF/Segoe cover the missing glyphs
  /// without a second bundled file.
  static const greek = CcScriptFontSpec(
    id: 'greek',
    systemFamilies: ['SF Pro Text', 'Segoe UI', 'Noto Sans'],
  );

  /// Every spec, for ratchets and tests.
  static const all = <CcScriptFontSpec>[
    thai,
    hebrew,
    arabic,
    simplifiedChinese,
    traditionalChinese,
    japanese,
    korean,
    greek,
  ];

  /// Asset paths of every vendored companion (the CJK/Greek specs are empty).
  static List<String> get bundledAssetPaths => [
    for (final spec in all) ...spec.assetPaths,
  ];

  /// The companion for [locale], or null when Manrope covers it.
  static CcScriptFontSpec? specFor(Locale locale) {
    switch (locale.languageCode) {
      case 'th':
        return thai;
      case 'he':
        return hebrew;
      case 'ar':
      case 'fa':
      case 'ur':
        return arabic;
      case 'zh':
        final script = locale.scriptCode;
        final country = locale.countryCode;
        if (script == 'Hant' || country == 'TW' || country == 'HK') {
          return traditionalChinese;
        }
        return simplifiedChinese;
      case 'ja':
        return japanese;
      case 'ko':
        return korean;
      case 'el':
        return greek;
      default:
        return null;
    }
  }

  /// Registers [spec]'s vendored files under [CcScriptFontSpec.family].
  ///
  /// Idempotent per family. A miss is cosmetic: [systemFamilies] already
  /// render, and the family is dropped from the in-flight set so a later
  /// locale switch can retry.
  static Future<void> ensureLoaded(CcScriptFontSpec spec) async {
    final family = spec.family;
    if (family == null || spec.assetPaths.isEmpty) {
      return;
    }
    if (!_loaded.add(family)) {
      return;
    }
    try {
      final loader = FontLoader(family);
      for (final path in spec.assetPaths) {
        loader.addFont(rootBundle.load('packages/cc_ui/$path'));
      }
      await loader.load();
    } catch (e) {
      _loaded.remove(family);
      debugPrint('cc_ui: could not load script font "$family": $e');
    }
  }

  static final Set<String> _loaded = {};

  /// Forgets which families this isolate has FontLoaded. Tests go through
  /// [CcFonts.resetForTests], which is the single hook.
  static void resetLoadedForTests() => _loaded.clear();
}
