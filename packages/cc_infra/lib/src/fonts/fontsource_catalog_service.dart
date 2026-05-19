import 'dart:convert';
import 'dart:io';

import 'package:cc_domain/features/fonts/fonts.dart';
import 'package:dio/dio.dart';

/// The Fontsource catalogue endpoint — key-less and CORS-open, unlike Google's
/// own Developer API (`webfonts/v1`), which requires an API key.
const String kFontsourceCatalogUrl = 'https://api.fontsource.org/v1/fonts';

/// Base of the Fontsource CDN that serves the font files.
const String kFontsourceCdnBase = 'https://cdn.jsdelivr.net/fontsource/fonts';

/// The host-side font catalogue: which families exist, and where one variant's
/// bytes live.
///
/// WHY THE HOST OWNS THIS: Flutter's font loader hands bytes to Skia, which
/// decodes `ttf`/`otf` but not `woff2` — and Google's `css2` endpoint picks the
/// format from the request's `User-Agent`, serving `woff2` to anything that
/// looks like a browser. A client `fetch()` cannot set `User-Agent`, so a client
/// can never obtain usable bytes itself. The host can, which is also what the
/// architecture already requires: clients never dial an upstream directly.
///
/// The catalogue is fetched once per [ttl] and persisted to [cacheFilePath], so
/// a restart or a second client costs nothing. Every failure degrades instead of
/// throwing: a stale cache is preferred to nothing, and nothing is an empty
/// catalogue (the picker still offers bundled + system fonts).
class FontsourceCatalogService implements FontCatalogRepository {
  /// Creates a [FontsourceCatalogService].
  ///
  /// [cacheFilePath] is where the catalogue JSON is persisted (the host picks a
  /// writable path under its data dir). [allowNetwork] gates fetching entirely,
  /// for tests and restricted environments.
  FontsourceCatalogService({
    required this.cacheFilePath,
    Dio? dio,
    this.url = kFontsourceCatalogUrl,
    this.ttl = const Duration(days: 1),
    this.allowNetwork = true,
  }) : _dio = dio ?? Dio();

  /// Path of the on-disk catalogue cache.
  final String cacheFilePath;

  /// The catalogue endpoint.
  final String url;

  /// Freshness window for the disk cache.
  final Duration ttl;

  /// Whether network fetches are permitted.
  final bool allowNetwork;

  /// Identifies this app to the catalogue host, mirroring the newsfeed fetcher.
  static const _userAgent =
      'ControlCenter/1.0 (+https://github.com/SamuelAlev/control-center)';

  final Dio _dio;

  List<FontFamilyInfo>? _memo;
  Future<List<FontFamilyInfo>>? _inflight;

  @override
  Future<List<FontFamilyInfo>> catalog() {
    final memo = _memo;
    if (memo != null) {
      return Future.value(memo);
    }
    // Concurrent callers (several clients asking at once, plus the proxy route
    // resolving a variant) share one load.
    return _inflight ??= _load().whenComplete(() => _inflight = null);
  }

  /// The family whose display name is [family], or null when unknown.
  ///
  /// This is the ownership check for the fonts proxy: a client names a family,
  /// and only a family in the catalogue can resolve to a URL.
  Future<FontFamilyInfo?> familyByName(String family) async {
    for (final entry in await catalog()) {
      if (entry.family == family) {
        return entry;
      }
    }
    return null;
  }

  /// The upstream `ttf` URL for one variant of [family], or null when the family
  /// is not catalogued.
  ///
  /// [weight] and [subset] are SNAPPED to what the family actually offers
  /// (nearest weight, default subset) rather than rejected, so a client can ask
  /// for weight 650 of a family that only ships 400/700 and still get bytes. An
  /// unoffered [italic] falls back to upright. Because the URL is derived here
  /// from a catalogued id, a client cannot steer the host at an arbitrary host —
  /// there is no client-supplied URL anywhere in this path.
  Future<Uri?> resolveFileUrl({
    required String family,
    int weight = 400,
    bool italic = false,
    String subset = 'latin',
  }) async {
    final info = await familyByName(family);
    if (info == null) {
      return null;
    }
    final style = italic && info.hasStyle('italic') ? 'italic' : 'normal';
    final resolvedSubset = info.resolveSubset(subset);
    final resolvedWeight = info.nearestWeight(weight);
    return Uri.parse(
      '$kFontsourceCdnBase/${info.id}@latest/'
      '$resolvedSubset-$resolvedWeight-$style.ttf',
    );
  }

  Future<List<FontFamilyInfo>> _load() async {
    final fresh = await _readCache(requireFresh: true);
    if (fresh != null) {
      return _memo = fresh;
    }
    final fetched = await _fetch();
    if (fetched != null) {
      return _memo = fetched;
    }
    final stale = await _readCache(requireFresh: false);
    // An empty catalogue is a valid answer (offline, first run): the picker
    // falls back to bundled + system fonts. Not memoised, so a later call
    // retries the network.
    return stale ?? const [];
  }

  Future<List<FontFamilyInfo>?> _readCache({required bool requireFresh}) async {
    try {
      final file = File(cacheFilePath);
      if (!file.existsSync()) {
        return null;
      }
      if (requireFresh &&
          DateTime.now().difference(file.lastModifiedSync()) > ttl) {
        return null;
      }
      final decoded = jsonDecode(await file.readAsString());
      if (decoded is! List) {
        return null;
      }
      final parsed = _parse(decoded);
      return parsed.isEmpty ? null : parsed;
    } catch (_) {
      return null;
    }
  }

  Future<List<FontFamilyInfo>?> _fetch() async {
    if (!allowNetwork) {
      return null;
    }
    try {
      final res = await _dio.getUri<Object?>(
        Uri.parse(url),
        options: Options(
          responseType: ResponseType.plain,
          sendTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 20),
          headers: const {'User-Agent': _userAgent},
        ),
      );
      final body = res.data;
      final decoded = body is String ? jsonDecode(body) : body;
      if (decoded is! List) {
        return null;
      }
      final parsed = _parse(decoded);
      if (parsed.isEmpty) {
        return null;
      }
      await _writeCache(decoded);
      return parsed;
    } catch (_) {
      // Network / parse failure → caller falls back to a stale cache, then to
      // an empty catalogue.
      return null;
    }
  }

  /// Keeps only what a picker can use: Google-origin families (the ones whose
  /// files the CDN path below serves) minus the icon pseudo-families, which are
  /// glyph sets rather than text faces.
  List<FontFamilyInfo> _parse(List<Object?> raw) {
    final out = <FontFamilyInfo>[];
    for (final row in raw) {
      if (row is! Map) {
        continue;
      }
      final json = row.cast<String, Object?>();
      if (json['type'] != 'google' || json['category'] == 'icons') {
        continue;
      }
      final id = json['id'];
      final family = json['family'];
      if (id is! String || family is! String || id.isEmpty || family.isEmpty) {
        continue;
      }
      final weights = _ints(json['weights']);
      final styles = _strings(json['styles']);
      final subsets = _strings(json['subsets']);
      if (weights.isEmpty || styles.isEmpty || subsets.isEmpty) {
        continue;
      }
      final defSubset = json['defSubset'];
      out.add(
        FontFamilyInfo(
          id: id,
          family: family,
          category: json['category'] as String? ?? 'sans-serif',
          weights: weights..sort(),
          styles: styles,
          subsets: subsets,
          defSubset: defSubset is String && subsets.contains(defSubset)
              ? defSubset
              : subsets.first,
          variable: json['variable'] == true,
        ),
      );
    }
    out.sort((a, b) => a.family.compareTo(b.family));
    return out;
  }

  static List<int> _ints(Object? value) => value is! List
      ? <int>[]
      : value.whereType<num>().map((n) => n.toInt()).toList();

  static List<String> _strings(Object? value) => value is! List
      ? <String>[]
      : value.whereType<String>().toList(growable: false);

  Future<void> _writeCache(List<Object?> raw) async {
    try {
      final file = File(cacheFilePath);
      await file.parent.create(recursive: true);
      await file.writeAsString(jsonEncode(raw));
    } catch (_) {
      // A read-only cache dir is non-fatal; the fetched catalogue still serves.
    }
  }
}
