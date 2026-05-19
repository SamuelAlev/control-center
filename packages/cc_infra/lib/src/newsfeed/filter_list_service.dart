import 'dart:convert';
import 'dart:io';

import 'package:cc_domain/core/domain/ports/key_value_store.dart';
import 'package:cc_domain/features/newsfeed/domain/filter_list_update_state.dart';
import 'package:cc_domain/features/newsfeed/domain/tracking_param_stripper.dart';
import 'package:cc_infra/src/newsfeed/abp_parser.dart';
import 'package:cc_infra/src/util/cc_paths.dart';
import 'package:dio/dio.dart';
import 'package:path/path.dart' as p;

/// Downloads community ABP filter lists, parses them, merges them with the
/// bundled defaults, and caches the results in the app support directory.
///
/// Also downloads and parses uBlock Origin's `privacy-removeparam.txt`
/// to maintain the set of tracking query parameters stripped from article URLs.
class FilterListService {
  /// Creates a new [FilterListService].
  FilterListService(this._dio, this._prefs, this._paths);

  final Dio _dio;
  final KeyValueStore _prefs;
  final CcPaths _paths;

  // ── Configuration ────────────────────────────────────────────────────────

  static const _kLastCheckKey = 'newsfeed.filterLists.lastCheck';
  static const _kLastSuccessKey = 'newsfeed.filterLists.lastSuccess';
  static const _kCookieHidingCountKey =
      'newsfeed.filterLists.cookieHidingCount';
  static const _kAdHidingCountKey = 'newsfeed.filterLists.adHidingCount';
  static const _kNetworkBlockCountKey =
      'newsfeed.filterLists.networkBlockCount';
  static const _kRemoveParamsListKey = 'newsfeed.removeParams.list';
  static const _kRemoveParamsCountKey = 'newsfeed.removeParams.count';

  static const _sources = [
    AbpSource(
      name: 'easylist',
      url: 'https://easylist.to/easylist/easylist.txt',
      category: FilterCategory.ads,
    ),
    AbpSource(
      name: 'idcac',
      url: 'https://www.i-dont-care-about-cookies.eu/abp/',
      category: FilterCategory.cookies,
    ),
    AbpSource(
      name: 'fanboy_cookie',
      url: 'https://secure.fanboy.co.nz/fanboy-cookiemonster.txt',
      category: FilterCategory.cookies,
    ),
    AbpSource(
      name: 'uassets_general',
      url:
          'https://raw.githubusercontent.com/uBlockOrigin/uAssets/refs/heads/master/filters/filters-general.txt',
      category: FilterCategory.ads,
    ),
    // uBO's main filter file — contains the bulk of per-site scriptlet
    // rules (set-constant globalPrivacyControl, abort-current-script,
    // etc.) that aren't in the narrower category-specific lists.
    AbpSource(
      name: 'uassets_main',
      url:
          'https://raw.githubusercontent.com/uBlockOrigin/uAssets/refs/heads/master/filters/filters.txt',
      category: FilterCategory.ads,
    ),
    AbpSource(
      name: 'uassets_badware',
      url:
          'https://raw.githubusercontent.com/uBlockOrigin/uAssets/refs/heads/master/filters/badware.txt',
      category: FilterCategory.ads,
    ),
    AbpSource(
      name: 'uassets_privacy',
      url:
          'https://raw.githubusercontent.com/uBlockOrigin/uAssets/refs/heads/master/filters/privacy.txt',
      category: FilterCategory.ads,
    ),
    AbpSource(
      name: 'uassets_annoyances',
      url:
          'https://raw.githubusercontent.com/uBlockOrigin/uAssets/refs/heads/master/filters/annoyances-cookies.txt',
      category: FilterCategory.cookies,
    ),
    // uBO's auto-dismiss/auto-accept rules for CMP banners
    // (Didomi, OneTrust, Sourcepoint, etc.) live here — these are the
    // `+js(trusted-click-element, ...)` scriptlet rules.
    AbpSource(
      name: 'uassets_quick_fixes',
      url:
          'https://raw.githubusercontent.com/uBlockOrigin/uAssets/refs/heads/master/filters/quick-fixes.txt',
      category: FilterCategory.cookies,
    ),
    // Broader annoyances list (the parent of annoyances-cookies). Adds
    // overlays, popups, newsletter prompts, etc.
    AbpSource(
      name: 'uassets_annoyances_general',
      url:
          'https://raw.githubusercontent.com/uBlockOrigin/uAssets/refs/heads/master/filters/annoyances.txt',
      category: FilterCategory.cookies,
    ),
  ];

  static const _removeParamsSource = _RemoveParamsSource(
    name: 'remove_params',
    url:
        'https://raw.githubusercontent.com/uBlockOrigin/uAssets/master/filters/privacy-removeparam.txt',
  );

  // ── Auto-update ────────────────────────────────────────────────────────

  /// Checks whether an update is due (≥ 24 h since last check) and, if so,
  /// performs a full refresh. Returns the current update state.
  Future<FilterListUpdateState> autoUpdate() async {
    final lastCheckStr = _prefs.getString(_kLastCheckKey);
    if (lastCheckStr != null) {
      final lastCheck = DateTime.tryParse(lastCheckStr);
      if (lastCheck != null) {
        final hoursSince = DateTime.now().difference(lastCheck).inHours;
        if (hoursSince < 24) {
          return readState();
        }
      }
    }
    return manualRefresh();
  }

  /// Forces a full refresh, ignoring the 24-hour cooldown.
  Future<FilterListUpdateState> manualRefresh() async {
    await _prefs.setString(_kLastCheckKey, DateTime.now().toIso8601String());

    final errors = <String>[];
    final adsSelectors = <String>[];
    final cookiesSelectors = <String>[];
    final domainHides = <DomainHide>[];
    final networkBlocks = <Map<String, dynamic>>[];
    final scriptlets = <ScriptletInjection>[];
    final removeParams = <String>{};

    // 1. Download and parse ABP sources.
    for (final source in _sources) {
      final raw = await _downloadWithEtag(source.url, source.name);
      if (raw == null) {
        // 304 Not Modified — try to use previously cached raw file.
        final cachedRaw = await _readCachedRaw(source.name);
        if (cachedRaw == null) {
          errors.add('${source.name}: no cached version available');
          continue;
        }
        parseSource(
          cachedRaw,
          source,
          adsSelectors,
          cookiesSelectors,
          domainHides,
          networkBlocks,
          scriptlets,
        );
        continue;
      }
      // 200 OK — save raw content and parse.
      await _writeCachedRaw(source.name, raw);
      parseSource(
        raw,
        source,
        adsSelectors,
        cookiesSelectors,
        domainHides,
        networkBlocks,
        scriptlets,
      );
    }

    // 2. Download and parse remove-params source.
    final rpRaw = await _downloadWithEtag(
      _removeParamsSource.url,
      _removeParamsSource.name,
    );
    if (rpRaw != null) {
      await _writeCachedRaw(_removeParamsSource.name, rpRaw);
      removeParams.addAll(parseRemoveParams(rpRaw));
    } else {
      final cachedRp = await _readCachedRaw(_removeParamsSource.name);
      if (cachedRp != null) {
        removeParams.addAll(parseRemoveParams(cachedRp));
      }
    }
    // Merge with hardcoded defaults.
    removeParams.addAll(defaultRemoveParams());

    // 3. Build the combined content rule list:
    //    - network blocks (`block` action)
    //    - universal CSS hiding (`css-display-none`, no `if-domain`)
    //    - domain-scoped CSS hiding (`css-display-none` + `if-domain`)
    // Selectors are chunked so a single malformed selector only drops
    // its chunk rather than the whole hide list.
    final ruleList = <Map<String, dynamic>>[
      ...networkBlocks,
      ...buildCssDisplayNoneRules(adsSelectors),
      ...buildCssDisplayNoneRules(cookiesSelectors),
      ...buildDomainScopedHideRules(domainHides),
      ...buildScriptletRules(scriptlets),
    ];

    final cacheDir = await _cacheDir();
    await File(
      p.join(cacheDir.path, 'blocklist_cached.json'),
    ).writeAsString(jsonEncode(ruleList));

    // 4. Persist remove-params metadata.
    await _prefs.setString(_kRemoveParamsListKey, removeParams.join(','));
    await _prefs.setInt(_kRemoveParamsCountKey, removeParams.length);

    // 5. Count parsed rules and persist. Domain-scoped hides are
    // bundled into whichever side of the count makes sense — they
    // originate from both ads and cookies sources, so count them
    // together under cookies (the more visible bucket in settings).
    final adHidingCount = adsSelectors.length;
    final cookieHidingCount = cookiesSelectors.length + domainHides.length;
    final networkBlockCount = networkBlocks.length;

    await _prefs.setInt(_kAdHidingCountKey, adHidingCount);
    await _prefs.setInt(_kCookieHidingCountKey, cookieHidingCount);
    await _prefs.setInt(_kNetworkBlockCountKey, networkBlockCount);
    await _prefs.setString(_kLastSuccessKey, DateTime.now().toIso8601String());

    return FilterListUpdateState(
      lastCheck: DateTime.now(),
      lastSuccess: DateTime.now(),
      isUpdating: false,
      errors: errors,
      cookieHidingRules: cookieHidingCount,
      adHidingRules: adHidingCount,
      networkBlockRules: networkBlockCount,
      removeParamsCount: removeParams.length,
    );
  }

  // ── Read cached ────────────────────────────────────────────────────────

  /// Returns the merged content rule list (network blocks +
  /// `css-display-none` entries), or an empty list if no cache exists
  /// yet (e.g. before the first successful [manualRefresh]).
  Future<List<Map<String, dynamic>>> readBlocklist() async {
    final cached = await _readCachedFile('blocklist_cached.json');
    if (cached == null) {
      return const [];
    }
    try {
      final decoded = jsonDecode(cached) as List<dynamic>;
      return decoded.map((e) => e as Map<String, dynamic>).toList();
    } on Object {
      return const [];
    }
  }

  /// Returns the set of tracking query parameters to strip from URLs.
  /// Reads the cached set from AppPreferences, falling back to the
  /// hard-coded [defaultRemoveParams].
  Set<String> readRemoveParams() {
    final raw = _prefs.getString(_kRemoveParamsListKey);
    if (raw != null && raw.isNotEmpty) {
      return raw.split(',').where((s) => s.isNotEmpty).toSet();
    }
    return defaultRemoveParams();
  }

  // ── Private helpers ────────────────────────────────────────────────────

  Future<String?> _readCachedFile(String name) async {
    try {
      // ignore: avoid_slow_async_io
      final file = File(p.join((await _cacheDir()).path, name));
      // ignore: avoid_slow_async_io
      if (await file.exists()) {
        // ignore: avoid_slow_async_io
        return await file.readAsString();
      }
    } on Object {
      // ignore
    }
    return null;
  }

  Future<String?> _readCachedRaw(String sourceName) async {
    return _readCachedFile('$sourceName.txt');
  }

  Future<void> _writeCachedRaw(String sourceName, String content) async {
    final file = File(p.join((await _cacheDir()).path, '$sourceName.txt'));
    await file.writeAsString(content);
  }

  Future<Directory> _cacheDir() async {
    // Cache under the app-support ROOT (`<root>/filter_lists`). The desktop
    // previously reached this via `getApplicationSupportDirectory()`, which the
    // app font-redirects to `<root>/fonts`, so the cache used to nest under
    // `fonts/`; rooting at CcPaths puts it at the intended top level (a one-time
    // re-download for existing installs).
    final support = await _paths.root();
    final dir = Directory(p.join(support.path, 'filter_lists'));
    // ignore: avoid_slow_async_io
    if (!await dir.exists()) {
      // ignore: avoid_slow_async_io
      await dir.create(recursive: true);
    }
    return dir;
  }

  /// Downloads [url] with conditional request using the stored ETag.
  /// Returns `null` on 304 (not modified). Throws on hard errors.
  Future<String?> _downloadWithEtag(String url, String etagKey) async {
    final etag = _prefs.getString('newsfeed.filterLists.etag.\$etagKey');
    final headers = <String, dynamic>{};
    if (etag != null && etag.isNotEmpty) {
      headers['If-None-Match'] = etag;
    }

    try {
      final response = await _dio.get<String>(
        url,
        options: Options(
          headers: headers,
          responseType: ResponseType.plain,
          validateStatus: (status) =>
              status != null && (status == 200 || status == 304),
        ),
      );

      if (response.statusCode == 304) {
        return null;
      }

      final newEtag = response.headers.value('etag');
      if (newEtag != null && newEtag.isNotEmpty) {
        await _prefs.setString('newsfeed.filterLists.etag.\$etagKey', newEtag);
      }
      return response.data;
    } on DioException catch (e) {
      if (e.response?.statusCode == 304) {
        return null;
      }
      rethrow;
    }
  }

  /// Parses a raw filter list source and distributes the results into the
  /// provided collections.
  void parseSource(
    String raw,
    AbpSource source,
    List<String> adsSelectors,
    List<String> cookiesSelectors,
    List<DomainHide> domainHides,
    List<Map<String, dynamic>> networkBlocks,
    List<ScriptletInjection> scriptlets,
  ) {
    final result = AbpParser.parse(raw);
    if (source.category == FilterCategory.ads) {
      adsSelectors.addAll(result.cssSelectors);
      networkBlocks.addAll(result.blocklist);
    } else {
      cookiesSelectors.addAll(result.cssSelectors);
    }
    // Domain-scoped hides apply regardless of whether the source is
    // categorised as ads or cookies — both can target CMP banners.
    domainHides.addAll(result.domainHides);
    scriptlets.addAll(result.scriptlets);
  }

  /// Serialises scriptlet entries into the same blocklist JSON as
  /// network blocks + css-display-none rules. Action type is `scriptlet`
  /// with `name` and `args` payload; the mapper / content blocker
  /// pipeline skips this type and the AdBlockerWebView picks them up
  /// for runtime JS injection.
  static List<Map<String, dynamic>> buildScriptletRules(
    List<ScriptletInjection> scriptlets,
  ) {
    final rules = <Map<String, dynamic>>[];
    for (final s in scriptlets) {
      final trigger = <String, dynamic>{'url-filter': '.*'};
      if (s.domains.isNotEmpty) {
        trigger['if-domain'] = s.domains;
      }
      rules.add(<String, dynamic>{
        'trigger': trigger,
        'action': <String, dynamic>{
          'type': 'scriptlet',
          'name': s.name,
          'args': s.args,
        },
      });
    }
    return rules;
  }

  /// Number of selectors combined into a single `css-display-none` rule.
  /// Smaller chunks compile faster and limit the blast radius if one
  /// selector turns out to be invalid; larger chunks reduce the total
  /// rule count. 25 is a balance.
  static const cssChunkSize = 25;

  /// Wraps [selectors] into chunked `css-display-none` content-blocker
  /// entries: each chunk is one rule with a comma-joined selector list.
  static List<Map<String, dynamic>> buildCssDisplayNoneRules(
    List<String> selectors,
  ) {
    final rules = <Map<String, dynamic>>[];
    for (var i = 0; i < selectors.length; i += cssChunkSize) {
      final end = (i + cssChunkSize < selectors.length)
          ? i + cssChunkSize
          : selectors.length;
      rules.add(<String, dynamic>{
        'trigger': <String, dynamic>{'url-filter': '.*'},
        'action': <String, dynamic>{
          'type': 'css-display-none',
          'selector': selectors.sublist(i, end).join(', '),
        },
      });
    }
    return rules;
  }

  /// Buckets [hides] by their domain set so selectors sharing the same
  /// `if-domain` list compile into one rule each (then chunked the
  /// same way universal selectors are). Without this, easylist's
  /// thousands of domain-scoped hide rules would emit one
  /// content-blocker entry per selector — pushing WKContentRuleList
  /// past its rule cap.
  static List<Map<String, dynamic>> buildDomainScopedHideRules(
    List<DomainHide> hides,
  ) {
    final byDomainKey = <String, List<String>>{};
    final domainSets = <String, List<String>>{};
    for (final h in hides) {
      // Use a sorted-domain key so `[a.com, b.com]` and `[b.com, a.com]`
      // bucket together.
      final sorted = [...h.domains]..sort();
      final key = sorted.join('|');
      byDomainKey.putIfAbsent(key, () => <String>[]).add(h.selector);
      domainSets[key] = sorted;
    }
    final rules = <Map<String, dynamic>>[];
    for (final entry in byDomainKey.entries) {
      final selectors = entry.value;
      final domains = domainSets[entry.key]!;
      for (var i = 0; i < selectors.length; i += cssChunkSize) {
        final end = (i + cssChunkSize < selectors.length)
            ? i + cssChunkSize
            : selectors.length;
        rules.add(<String, dynamic>{
          'trigger': <String, dynamic>{
            'url-filter': '.*',
            'if-domain': domains,
          },
          'action': <String, dynamic>{
            'type': 'css-display-none',
            'selector': selectors.sublist(i, end).join(', '),
          },
        });
      }
    }
    return rules;
  }

  /// Parses uBlock `$removeparam=` rules into a set of parameter names.
  /// Package-visible so it can be unit-tested without spinning up the
  /// full service.
  Set<String> parseRemoveParams(String raw) {
    final params = <String>{};
    final lines = const LineSplitter().convert(raw);
    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) {
        continue;
      }
      if (trimmed.startsWith('!')) {
        continue;
      }

      final match = RegExp(r'\$removeparam=([^,\s]+)').firstMatch(trimmed);
      if (match == null) {
        continue;
      }

      final value = match.group(1)!;

      // Skip domain-specific rules (anything before $removeparam that looks
      // like a domain name contains a dot).
      final dollarIdx = trimmed.indexOf('\$removeparam');
      if (dollarIdx > 0) {
        final prefix = trimmed.substring(0, dollarIdx).trim();
        if (prefix.contains('.') && !prefix.startsWith('*')) {
          continue;
        }
      }

      // Skip regex patterns.
      if (value.startsWith('/') && value.endsWith('/')) {
        continue;
      }

      // Handle multi-param: foo|bar|baz
      final parts = value.split('|');
      for (final part in parts) {
        final p = part.trim();
        if (p.isNotEmpty) {
          params.add(p.toLowerCase());
        }
      }
    }
    return params;
  }

  /// Returns the current update state from persisted metadata.
  FilterListUpdateState readState() {
    return FilterListUpdateState(
      lastCheck: DateTime.tryParse(_prefs.getString(_kLastCheckKey) ?? ''),
      lastSuccess: DateTime.tryParse(_prefs.getString(_kLastSuccessKey) ?? ''),
      isUpdating: false,
      errors: const [],
      cookieHidingRules: _prefs.getInt(_kCookieHidingCountKey) ?? 0,
      adHidingRules: _prefs.getInt(_kAdHidingCountKey) ?? 0,
      networkBlockRules: _prefs.getInt(_kNetworkBlockCountKey) ?? 0,
      removeParamsCount: _prefs.getInt(_kRemoveParamsCountKey) ?? 0,
    );
  }
}

// ── Supporting types ─────────────────────────────────────────────────────

/// Category of an ABP filter list (ads or cookie/privacy).
enum FilterCategory {
  /// Filters targeting advertisement content.
  ads,

  /// Filters targeting cookie/consent banners.
  cookies,
}

/// Metadata for an ABP filter list remote source.
class AbpSource {
  /// Creates a new ABP source with the given [name], [url], and [category].
  const AbpSource({
    required this.name,
    required this.url,
    required this.category,
  });

  /// Storage key for this source (used in ETag and cache filenames).
  final String name;

  /// Remote URL to download from.
  final String url;

  /// Whether this source contributes to ads or cookies CSS.
  final FilterCategory category;
}

/// Metadata for the `$removeparam` remote source.
class _RemoveParamsSource {
  const _RemoveParamsSource({required this.name, required this.url});

  /// Storage key for this source.
  final String name;

  /// Remote URL to download from.
  final String url;
}
