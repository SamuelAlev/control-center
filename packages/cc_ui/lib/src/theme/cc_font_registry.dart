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

/// On-demand registration of user-selected font families. [apply] is sync
/// (called from [TextStyle] during build): returns [family] immediately,
/// fetches the requested cut in the background, and registers it under the
/// unified [family] name via [FontLoader.load], which invalidates layout. Until
/// then falls back to the bundled family.
///
/// All cuts (weights + italics) of a family register under the same engine
/// family name so `DefaultTextStyle` and parent `TextSpan` inheritance resolve
/// real bold/semibold/italic cuts everywhere in the widget tree. Catalogue is
/// fetched at runtime (no google_fonts manifest in the web bundle).
class CcFontRegistry {
  CcFontRegistry._();

  /// The process-wide registry. A font registration is global to the Flutter
  /// engine, so there is deliberately one.
  static final CcFontRegistry instance = CcFontRegistry._();

  /// Standard weights and slants preloaded when a family becomes the active
  /// app theme font.
  static const List<(int weight, bool italic)> standardCuts = [
    (400, false),
    (500, false),
    (600, false),
    (700, false),
    (400, true),
    (700, true),
  ];

  /// Fallback family used until a cut's bytes register and for any glyph
  /// the loaded subset lacks. Set by the app to its bundled UI family.
  String? _fallbackFamily;

  CcFontBytesLoader? _loader;
  Set<String> _catalogued = const {};
  final Set<String> _attempted = {};
  final Set<String> _loaded = {};
  final Set<String> _preloadedFamilies = {};
  final Map<String, List<Uint8List>> _loadedBytes = {};

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
    // A new connection may serve a different catalogue; cuts already
    // registered with the engine stay valid, but failed attempts are worth
    // retrying against the new host.
    _attempted.removeWhere((key) => !_loaded.contains(key));
    for (final family in List.of(_preloadedFamilies)) {
      preloadFamily(family);
    }
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
    for (final family in List.of(_preloadedFamilies)) {
      preloadFamily(family);
    }
  }

  /// Whether the host advertises [family] (see [setCatalogue]).
  bool isCatalogued(String family) => _catalogued.contains(family);

  /// Whether [family]'s catalogue is known and non-empty.
  bool get hasCatalogue => _catalogued.isNotEmpty;

  /// Preloads [standardCuts] for [family] under the unified [family] name so
  /// bold, semibold, medium, and italic cuts are registered alongside regular.
  void preloadFamily(String family) {
    if (family.isEmpty) {
      return;
    }
    _preloadedFamilies.add(family);
    final loader = _loader;
    if (loader == null) {
      return;
    }
    if (hasCatalogue && !isCatalogued(family)) {
      return;
    }
    final pending = <(int, bool)>[];
    for (final cut in standardCuts) {
      final (weight, italic) = cut;
      if (_attempted.add(_cutKey(family, weight: weight, italic: italic))) {
        pending.add(cut);
      }
    }
    if (pending.isEmpty) {
      return;
    }
    unawaited(_loadBatch(loader, family, pending));
  }

  /// Applies [family] to [base], fetching the matching cut if needed.
  ///
  /// The weight and slant come from [base] (defaulting to upright w400), so a
  /// caller that already styles its text gets the right cut fetched into the
  /// unified [family] registration.
  ///
  /// [fallbackFamily] is what renders until the bytes land; pass the bundled
  /// family appropriate to the SURFACE (a monospace surface must not fall back
  /// to a proportional font — that would reflow code mid-load), else the default
  /// from [install] is used.
  TextStyle apply(
    String family,
    TextStyle? base, {
    String? fallbackFamily,
    Iterable<String> extraFallbacks = const [],
  }) {
    final style = base ?? const TextStyle();
    if (family.isEmpty) {
      return style;
    }
    final weight = (style.fontWeight ?? FontWeight.w400).value;
    final italic = style.fontStyle == FontStyle.italic;
    _ensure(family, weight: weight, italic: italic);

    final fallback = fallbackFamily ?? _fallbackFamily;
    return style.copyWith(
      fontFamily: family,
      // Two jobs: render in the app's own font while bytes are in flight and
      // cover glyphs outside the loaded subset (a Latin cut has no Cyrillic)
      // instead of showing tofu. [extraFallbacks] (the script fallbacks, see
      // CcFonts.scriptFallbackFamilies) slot in ahead of the caller's own
      // list.
      fontFamilyFallback: [
        ?fallback,
        ...extraFallbacks,
        ...?style.fontFamilyFallback,
      ],
    );
  }

  static String _cutKey(
    String family, {
    required int weight,
    required bool italic,
  }) => '$family/$weight/$italic';

  void _ensure(
    String family, {
    required int weight,
    required bool italic,
  }) {
    final loader = _loader;
    if (loader == null) {
      return;
    }
    // An OS-installed family renders from its own file; asking the host for it
    // would just 404. With no catalogue yet, try anyway (see [setCatalogue]).
    if (hasCatalogue && !isCatalogued(family)) {
      return;
    }
    final key = _cutKey(family, weight: weight, italic: italic);
    if (!_attempted.add(key)) {
      return;
    }
    // Deliberately fire-and-forget: registration triggers Flutter's own
    // font-change repaint, so there is nothing for the caller to await.
    unawaited(_loadBatch(loader, family, [(weight, italic)]));
  }

  Future<void> _loadBatch(
    CcFontBytesLoader loader,
    String family,
    List<(int weight, bool italic)> cuts,
  ) async {
    try {
      final results = await Future.wait([
        for (final (weight, italic) in cuts)
          loader(family: family, weight: weight, italic: italic),
      ]);
      final knownBytes = _loadedBytes.putIfAbsent(family, () => []);
      final batchBytes = <Uint8List>[];
      final fontLoader = FontLoader(family);
      final loadedKeys = <String>[];
      for (var i = 0; i < cuts.length; i++) {
        final bytes = results[i];
        if (bytes == null || bytes.isEmpty) {
          continue;
        }
        final (weight, italic) = cuts[i];
        loadedKeys.add(_cutKey(family, weight: weight, italic: italic));
        final duplicate =
            knownBytes.any((existing) => listEquals(existing, bytes)) ||
            batchBytes.any((existing) => listEquals(existing, bytes));
        if (duplicate) {
          continue;
        }
        batchBytes.add(bytes);
        fontLoader.addFont(Future.value(ByteData.sublistView(bytes)));
      }
      if (batchBytes.isNotEmpty) {
        await fontLoader.load();
        knownBytes.addAll(batchBytes);
      }
      _loaded.addAll(loadedKeys);
    } catch (e) {
      // A font is cosmetic: a failed fetch, a corrupt file, or a host that has
      // gone away must never break a build. The fallback family already renders
      // the text. Left in `_attempted` so it is not retried every frame.
      debugPrint('cc_ui: could not load font family "$family": $e');
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
    _preloadedFamilies.clear();
    _loadedBytes.clear();
  }
}
