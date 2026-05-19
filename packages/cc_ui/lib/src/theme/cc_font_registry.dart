import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show FontLoader;
import 'package:flutter/widgets.dart';

/// Fetches the bytes of one font variant, or null when they cannot be had.
///
/// The app installs this (see [CcFontRegistry.install]); cc_ui never performs
/// I/O of its own. In the app it is a GET against the host's font proxy — the
/// host, not the client, talks to any upstream.
typedef CcFontBytesLoader =
    Future<Uint8List?> Function({
      required String family,
      required int weight,
      required bool italic,
    });

/// Registers user-selected font families with Flutter's font system, on demand.
///
/// HOW A FONT ARRIVES: [apply] is synchronous, because it is called from
/// [TextStyle] construction during build. It returns a style naming the variant
/// immediately and, the first time it sees that variant, starts a background
/// fetch. When the bytes land, [FontLoader.load] registers them and Flutter
/// invalidates its text layout caches and repaints — so the text swaps itself in
/// with no notifier, no rebuild plumbing and no `await` at the call site. Until
/// then the style falls back to the bundled family, so text is always readable
/// and never a tofu row.
///
/// WHY ONE FAMILY NAME PER VARIANT: Skia matches a weight within a registered
/// family, so registering only the 400 file and asking for w700 yields synthetic
/// (smeared) bold. Registering each `(weight, italic)` under its own derived
/// family name — `Inter 700 italic` — makes every weight the real cut. This is
/// what `package:google_fonts` does internally and the reason this class is not
/// simply one [FontLoader] per family.
///
/// This replaced `package:google_fonts`, whose compiled-in manifest of ~1900
/// families cost 14 MB of the web bundle (over half of `main.dart.js`, enough to
/// break a 25 MiB per-asset deploy limit). Here the catalogue is data fetched at
/// runtime, so the bundle carries none of it.
class CcFontRegistry {
  CcFontRegistry._();

  /// The process-wide registry. A font registration is global to the Flutter
  /// engine, so there is deliberately one.
  static final CcFontRegistry instance = CcFontRegistry._();

  /// Fallback family used until a variant's bytes register and for any glyph
  /// the loaded subset lacks. Set by the app to its bundled UI family.
  String? _fallbackFamily;

  CcFontBytesLoader? _loader;
  Set<String> _catalogued = const {};
  final Set<String> _attempted = {};
  final Set<String> _loaded = {};

  /// Installs the byte [loader] used to fetch variants.
  ///
  /// Called when a host connection is established (and again if it changes).
  /// Before this, [apply] still returns a usable style — it just cannot fetch,
  /// which is exactly the right behavior for an unconnected client: bundled and
  /// OS-installed families render, downloadable ones fall back.
  ///
  /// [fallbackFamily] is rendered while a variant loads.
  void install({required CcFontBytesLoader loader, String? fallbackFamily}) {
    _loader = loader;
    _fallbackFamily = fallbackFamily ?? _fallbackFamily;
    // A new connection may serve a different catalogue; variants already
    // registered with the engine stay valid, but failed attempts are worth
    // retrying against the new host.
    _attempted.removeWhere((key) => !_loaded.contains(key));
  }

  /// Declares which families the host can serve bytes for.
  ///
  /// Fed from the font catalogue once it loads. Its only job is to stop [apply]
  /// from firing a doomed request for an OS-installed family the host has never
  /// heard of. While it is empty, requests are attempted optimistically — a
  /// not-yet-loaded catalogue must not silently disable font loading.
  void setCatalogue(Iterable<String> families) {
    _catalogued = families.toSet();
    _attempted.removeWhere((key) => !_loaded.contains(key));
  }

  /// Whether the host advertises [family] (see [setCatalogue]).
  bool isCatalogued(String family) => _catalogued.contains(family);

  /// Whether [family]'s catalogue is known and non-empty.
  bool get hasCatalogue => _catalogued.isNotEmpty;

  /// Applies [family] to [base], fetching the matching variant if needed.
  ///
  /// The weight and slant come from [base] (defaulting to upright w400), so a
  /// caller that already styles its text gets the right cut without naming it
  /// twice.
  ///
  /// [fallbackFamily] is what renders until the bytes land; pass the bundled
  /// family appropriate to the SURFACE (a monospace surface must not fall back
  /// to a proportional font — that would reflow code mid-load), else the default
  /// from [install] is used.
  TextStyle apply(String family, TextStyle? base, {String? fallbackFamily}) {
    final style = base ?? const TextStyle();
    if (family.isEmpty) {
      return style;
    }
    final weight = (style.fontWeight ?? FontWeight.w400).value;
    final italic = style.fontStyle == FontStyle.italic;
    final variant = variantFamily(family, weight: weight, italic: italic);
    _ensure(family, variant, weight: weight, italic: italic);

    final fallback = fallbackFamily ?? _fallbackFamily;
    return style.copyWith(
      fontFamily: variant,
      // Three jobs: let an OS-installed family (registered under its real name)
      // resolve, render in the app's own font while bytes are in flight and
      // cover glyphs outside the loaded subset (a Latin cut has no Cyrillic)
      // instead of showing tofu.
      fontFamilyFallback: [
        family,
        ?fallback,
        ...?style.fontFamilyFallback,
      ],
    );
  }

  /// The engine-facing family name for one variant of [family] — the name each
  /// cut is registered under. Public so tests can assert against it.
  static String variantFamily(
    String family, {
    required int weight,
    required bool italic,
  }) => italic ? '$family $weight italic' : '$family $weight';

  void _ensure(
    String family,
    String variant, {
    required int weight,
    required bool italic,
  }) {
    final loader = _loader;
    if (loader == null || !_attempted.add(variant)) {
      return;
    }
    // An OS-installed family renders from its own file; asking the host for it
    // would just 404. With no catalogue yet, try anyway (see [setCatalogue]).
    if (hasCatalogue && !isCatalogued(family)) {
      return;
    }
    // Deliberately fire-and-forget: registration triggers Flutter's own
    // font-change repaint, so there is nothing for the caller to await.
    unawaited(
      _load(loader, family, variant, weight: weight, italic: italic),
    );
  }

  Future<void> _load(
    CcFontBytesLoader loader,
    String family,
    String variant, {
    required int weight,
    required bool italic,
  }) async {
    try {
      final bytes = await loader(
        family: family,
        weight: weight,
        italic: italic,
      );
      if (bytes == null || bytes.isEmpty) {
        return;
      }
      await (FontLoader(variant)
            ..addFont(Future.value(ByteData.sublistView(bytes))))
          .load();
      _loaded.add(variant);
    } catch (e) {
      // A font is cosmetic: a failed fetch, a corrupt file, or a host that has
      // gone away must never break a build. The fallback family already renders
      // the text. Left in `_attempted` so it is not retried every frame.
      debugPrint('cc_ui: could not load font variant "$variant": $e');
    }
  }

  /// Forgets all loader/catalogue state. For tests only — fonts already
  /// registered with the engine cannot be unregistered.
  @visibleForTesting
  void resetForTests() {
    _loader = null;
    _fallbackFamily = null;
    _catalogued = const {};
    _attempted.clear();
    _loaded.clear();
  }
}
