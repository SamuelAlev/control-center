import 'dart:async';

import 'package:cc_ui/src/foundation/cc_typography.dart';
import 'package:cc_ui/src/theme/cc_font_registry.dart';
import 'package:cc_ui/src/theme/cc_script_fonts.dart';
import 'package:flutter/widgets.dart';

/// Font helpers: Manrope (UI), Fira Code (code). Base fonts are bundled
/// (`fonts:` in pubspec) — no network for defaults. User-selected families load
/// via [CcFontRegistry]. Sole owner of bundled files; consumers use [uiFamily] /
/// [codeFamily].
///
/// Script companions (Thai/Hebrew/Arabic/CJK/…) via [activateForLocale] as
/// `fontFamilyFallback`; companions are package assets, not `fonts:` entries
/// (web must not download them on English boot). Widgets-only [TextStyle]
/// helpers — no Material `TextTheme`.
abstract final class CcFonts {
  const CcFonts._();

  /// Family name for the bundled UI font. Fonts declared in a package are
  /// resolved under `packages/<package>/<family>` — this is that resolved name,
  /// usable directly as a [TextStyle.fontFamily].
  static const uiFamily = 'packages/cc_ui/Manrope';

  /// Family name for the bundled monospace font (see [uiFamily]).
  static const codeFamily = 'packages/cc_ui/Fira Code';

  /// The families this package ships as assets.
  ///
  /// They are registered with the engine from the bundle, so they are applied
  /// BY NAME and never fetched — naming one is not "a user picked a font", it
  /// is the default. [_resolve] short-circuits on this set for that reason.
  static const bundledFamilies = {uiFamily, codeFamily};

  /// Fallback families for the *active* locale's script, or empty when
  /// Manrope covers it. Never the full catalogue — attaching every companion
  /// would FontLoader Thai while the UI is in Hebrew.
  static List<String> get scriptFallbackFamilies => _scriptFallbacks;

  static List<String> _scriptFallbacks = const [];
  static String? _activeTag;

  /// Selects the script companion for [locale] and starts loading its
  /// vendored file (if any). Passing `null` (no [Localizations] ancestor)
  /// clears the fallbacks. Idempotent for the same locale.
  ///
  /// [load] is true in the widget tree and false in list-only tests so a
  /// missing AssetBundle does not spam `debugPrint`.
  static void activateForLocale(Locale? locale, {bool load = true}) {
    final tag = locale == null
        ? ''
        : '${locale.languageCode}_${locale.scriptCode}_${locale.countryCode}';
    if (tag == _activeTag) {
      return;
    }
    _activeTag = tag;
    final spec = locale == null ? null : CcScriptFonts.specFor(locale);
    _scriptFallbacks = spec?.fallbackFamilies ?? const [];
    if (load && spec != null && spec.assetPaths.isNotEmpty) {
      unawaited(CcScriptFonts.ensureLoaded(spec));
    }
  }

  /// Forgets locale + fallback state. For tests only.
  @visibleForTesting
  static void resetForTests() {
    _activeTag = null;
    _scriptFallbacks = const [];
    CcScriptFonts.resetLoadedForTests();
  }

  /// UI / body text in the bundled Manrope, or in [family] when given.
  static TextStyle ui({TextStyle? textStyle, String? family}) =>
      _resolve(textStyle: textStyle, family: family, bundled: uiFamily);

  /// Monospace text in the bundled Fira Code, or in [family] when given.
  ///
  /// This is also where tabular figures live: going monospace is what makes
  /// digits share one advance width, so every code/mono surface gets
  /// [CcTypography.numeralFeatures] and no proportional surface does. A call
  /// site that names its own [TextStyle.fontFeatures] (ligature toggles, for
  /// instance) keeps them verbatim.
  static TextStyle code({TextStyle? textStyle, String? family}) => _resolve(
    textStyle: textStyle,
    family: family,
    bundled: codeFamily,
    features: CcTypography.numeralFeatures,
  );

  /// Resolves a [family] to a [TextStyle]:
  ///  * `null` — the bundled host font ([bundled]); no network, ever.
  ///  * a family in [bundledFamilies] — applied by name, also no network. The
  ///    app names its UI family on the theme even when it is the DEFAULT one,
  ///    so this is the common path, not an edge case.
  ///  * any other family — handed to [CcFontRegistry], which applies the name
  ///    immediately and fetches the matching variant in the background if the
  ///    host advertises it. An OS-installed family therefore renders from its own
  ///    file and a downloadable one swaps in when its bytes register.
  ///
  /// [features] are the lane's default OpenType features, applied only when the
  /// caller set none of its own.
  static TextStyle _resolve({
    required TextStyle? textStyle,
    required String? family,
    required String bundled,
    List<FontFeature>? features,
  }) {
    var style = textStyle ?? const TextStyle();
    if (features != null && textStyle?.fontFeatures == null) {
      style = style.copyWith(fontFeatures: features);
    }
    if (family == null) {
      return style.copyWith(
        fontFamily: bundled,
        // The bundled family stays the PRIMARY font; the active locale's
        // script companion only catches glyphs it has no coverage for, and
        // a call site's own fallback list (an emoji font, say) survives
        // after it.
        fontFamilyFallback: [..._scriptFallbacks, ...?style.fontFamilyFallback],
      );
    }
    // A bundled family is already registered under its real name, so it is
    // applied directly and never routed through the registry — that named a
    // per-weight variant (`packages/cc_ui/Manrope 400`) that nothing
    // registers, which left the real font reachable only as a fallback. The
    // script fallbacks still ride along behind it, for the same reason as
    // above.
    if (bundledFamilies.contains(family)) {
      return style.copyWith(
        fontFamily: family,
        fontFamilyFallback: [..._scriptFallbacks, ...?style.fontFamilyFallback],
      );
    }
    // The surface's own bundled family is the fallback, so a code surface stays
    // monospaced while the selected family loads.
    return CcFontRegistry.instance.apply(
      family,
      style,
      fallbackFamily: bundled,
      extraFallbacks: _scriptFallbacks,
    );
  }
}
