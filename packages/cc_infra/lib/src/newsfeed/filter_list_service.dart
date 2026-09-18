import 'dart:convert';
import 'dart:io';

import 'package:cc_domain/features/newsfeed/domain/filter_list_update_state.dart';
import 'package:cc_domain/features/newsfeed/domain/helpers/abp_parser.dart';
import 'package:cc_domain/features/newsfeed/domain/tracking_param_stripper.dart';
import 'package:dio/dio.dart';
import 'package:path/path.dart' as p;

/// Downloads community ABP filter lists, parses them, and caches the merged
/// rule list under the server data dir.
///
/// Thin clients never dial these URLs — they read the cached document over
/// `newsfeed.filterLists.*`. State and blocklist reads never fetch; [refresh]
/// does, so boot stays off the ready-banner path.
class FilterListService {
  /// Creates a [FilterListService] whose cache lives at [cacheDir].
  ///
  /// [allowNetwork] gates fetching entirely, for tests, the demo, and
  /// restricted environments.
  FilterListService({
    required this.cacheDir,
    Dio? dio,
    this.allowNetwork = true,
    this.ttl = const Duration(hours: 24),
  }) : _dio = dio ?? Dio();

  /// Directory under the server data dir (`<dataDir>/filter_lists`).
  final String cacheDir;

  /// Whether network fetches are permitted.
  final bool allowNetwork;

  /// Freshness window for [refresh] when `force` is false.
  final Duration ttl;

  static const _userAgent =
      'ControlCenter/1.0 (+https://github.com/SamuelAlev/control-center)';

  static const _stateFile = 'state.json';
  static const _etagsFile = 'etags.json';
  static const _blocklistFile = 'blocklist_cached.json';

  final Dio _dio;

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
    AbpSource(
      name: 'uassets_quick_fixes',
      url:
          'https://raw.githubusercontent.com/uBlockOrigin/uAssets/refs/heads/master/filters/quick-fixes.txt',
      category: FilterCategory.cookies,
    ),
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

  /// Returns the current update state from the on-disk cache.
  FilterListUpdateState readState() {
    final stored = _readStateFile();
    return stored?.state ?? FilterListUpdateState.empty;
  }

  /// Checks whether an update is due and, if so, performs a full refresh.
  Future<FilterListUpdateState> autoUpdate() => refresh(force: false);

  /// Refreshes the lists. When [force] is false, a cache younger than [ttl]
  /// is returned as-is.
  Future<FilterListUpdateState> refresh({bool force = true}) async {
    if (!force) {
      final stored = _readStateFile();
      final lastCheck = stored?.state.lastCheck;
      if (lastCheck != null && DateTime.now().difference(lastCheck) < ttl) {
        return stored!.state;
      }
    }
    return _refresh();
  }

  Future<FilterListUpdateState> _refresh() async {
    final errors = <String>[];
    final adsSelectors = <String>[];
    final cookiesSelectors = <String>[];
    final domainHides = <DomainHide>[];
    final networkBlocks = <Map<String, dynamic>>[];
    final scriptlets = <ScriptletInjection>[];
    final removeParams = <String>{};
    final now = DateTime.now();

    for (final source in _sources) {
      final raw = await _downloadWithEtag(source.url, source.name);
      if (raw == null) {
        final cachedRaw = _readCachedRaw(source.name);
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
      _writeCachedRaw(source.name, raw);
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

    final rpRaw = await _downloadWithEtag(
      _removeParamsSource.url,
      _removeParamsSource.name,
    );
    if (rpRaw != null) {
      _writeCachedRaw(_removeParamsSource.name, rpRaw);
      removeParams.addAll(parseRemoveParams(rpRaw));
    } else {
      final cachedRp = _readCachedRaw(_removeParamsSource.name);
      if (cachedRp != null) {
        removeParams.addAll(parseRemoveParams(cachedRp));
      }
    }
    removeParams.addAll(defaultRemoveParams());

    final ruleList = <Map<String, dynamic>>[
      ...networkBlocks,
      ...buildCssDisplayNoneRules(adsSelectors),
      ...buildCssDisplayNoneRules(cookiesSelectors),
      ...buildDomainScopedHideRules(domainHides),
      ...buildScriptletRules(scriptlets),
    ];

    _writeFile(_blocklistFile, jsonEncode(ruleList));

    final adHidingCount = adsSelectors.length;
    final cookieHidingCount = cookiesSelectors.length + domainHides.length;
    final networkBlockCount = networkBlocks.length;

    final state = FilterListUpdateState(
      lastCheck: now,
      lastSuccess: now,
      isUpdating: false,
      errors: errors,
      cookieHidingRules: cookieHidingCount,
      adHidingRules: adHidingCount,
      networkBlockRules: networkBlockCount,
      removeParamsCount: removeParams.length,
    );
    _writeStateFile(_StoredState(state: state, removeParams: removeParams));
    return state;
  }

  /// Returns the merged content rule list, or an empty list if no cache exists.
  Future<List<Map<String, dynamic>>> readBlocklist() async {
    final cached = _readFile(_blocklistFile);
    if (cached == null) {
      return const [];
    }
    try {
      final decoded = jsonDecode(cached);
      if (decoded is! List) {
        return const [];
      }
      return [
        for (final entry in decoded)
          if (entry is Map)
            {for (final e in entry.entries) e.key.toString(): e.value},
      ];
    } on Object {
      return const [];
    }
  }

  /// Returns the set of tracking query parameters to strip from URLs.
  Set<String> readRemoveParams() {
    final stored = _readStateFile()?.removeParams;
    if (stored != null && stored.isNotEmpty) {
      return stored;
    }
    return defaultRemoveParams();
  }

  String? _readCachedRaw(String sourceName) => _readFile('$sourceName.txt');

  void _writeCachedRaw(String sourceName, String content) =>
      _writeFile('$sourceName.txt', content);

  Future<String?> _downloadWithEtag(String url, String etagKey) async {
    if (!allowNetwork) {
      return null;
    }
    final etags = _readEtags();
    final headers = <String, dynamic>{'User-Agent': _userAgent};
    final etag = etags[etagKey];
    if (etag != null && etag.isNotEmpty) {
      headers['If-None-Match'] = etag;
    }

    try {
      final response = await _dio.get<String>(
        url,
        options: Options(
          headers: headers,
          responseType: ResponseType.plain,
          sendTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 30),
          validateStatus: (status) =>
              status != null && (status == 200 || status == 304),
        ),
      );

      if (response.statusCode == 304) {
        return null;
      }

      final newEtag = response.headers.value('etag');
      if (newEtag != null && newEtag.isNotEmpty) {
        etags[etagKey] = newEtag;
        _writeEtags(etags);
      }
      return response.data;
    } on Object {
      return null;
    }
  }

  Directory _ensureCacheDir() {
    final dir = Directory(cacheDir);
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }
    return dir;
  }

  String? _readFile(String name) {
    try {
      final file = File(p.join(_ensureCacheDir().path, name));
      if (!file.existsSync()) {
        return null;
      }
      return file.readAsStringSync();
    } on Object {
      return null;
    }
  }

  void _writeFile(String name, String content) {
    try {
      final file = File(p.join(_ensureCacheDir().path, name));
      file.writeAsStringSync(content);
    } on Object {
      // A read-only cache dir is non-fatal; the in-memory result still serves.
    }
  }

  Map<String, String> _readEtags() {
    final raw = _readFile(_etagsFile);
    if (raw == null) {
      return {};
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) {
        return {};
      }
      return {
        for (final e in decoded.entries)
          if (e.value is String) e.key.toString(): e.value as String,
      };
    } on Object {
      return {};
    }
  }

  void _writeEtags(Map<String, String> etags) =>
      _writeFile(_etagsFile, jsonEncode(etags));

  _StoredState? _readStateFile() {
    final raw = _readFile(_stateFile);
    if (raw == null) {
      return null;
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) {
        return null;
      }
      final map = {for (final e in decoded.entries) e.key.toString(): e.value};
      final paramsRaw = map['removeParams'];
      final params = <String>{
        if (paramsRaw is List)
          for (final p in paramsRaw)
            if (p is String && p.isNotEmpty) p,
      };
      return _StoredState(
        state: FilterListUpdateState.fromJson(map),
        removeParams: params,
      );
    } on Object {
      return null;
    }
  }

  void _writeStateFile(_StoredState stored) {
    _writeFile(
      _stateFile,
      jsonEncode({
        ...stored.state.toJson(),
        'removeParams': stored.removeParams.toList()..sort(),
      }),
    );
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
    domainHides.addAll(result.domainHides);
    scriptlets.addAll(result.scriptlets);
  }

  /// Serialises scriptlet entries into the same blocklist JSON as
  /// network blocks + css-display-none rules.
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
  static const cssChunkSize = 25;

  /// Wraps [selectors] into chunked `css-display-none` content-blocker entries.
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
  /// `if-domain` list compile into one rule each.
  static List<Map<String, dynamic>> buildDomainScopedHideRules(
    List<DomainHide> hides,
  ) {
    final byDomainKey = <String, List<String>>{};
    final domainSets = <String, List<String>>{};
    for (final h in hides) {
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
  Set<String> parseRemoveParams(String raw) {
    final params = <String>{};
    final lines = const AbpLineSplitter().convert(raw);
    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty || trimmed.startsWith('!')) {
        continue;
      }

      final match = RegExp(r'\$removeparam=([^,\s]+)').firstMatch(trimmed);
      if (match == null) {
        continue;
      }

      final value = match.group(1)!;
      final dollarIdx = trimmed.indexOf(r'$removeparam');
      if (dollarIdx > 0) {
        final prefix = trimmed.substring(0, dollarIdx).trim();
        if (prefix.contains('.') && !prefix.startsWith('*')) {
          continue;
        }
      }

      if (value.startsWith('/') && value.endsWith('/')) {
        continue;
      }

      for (final part in value.split('|')) {
        final param = part.trim();
        if (param.isNotEmpty) {
          params.add(param.toLowerCase());
        }
      }
    }
    return params;
  }
}

class _StoredState {
  const _StoredState({required this.state, required this.removeParams});

  final FilterListUpdateState state;
  final Set<String> removeParams;
}

/// Category of an ABP filter list (ads or cookie/privacy).
enum FilterCategory {
  /// Filters targeting advertisement content.
  ads,

  /// Filters targeting cookie/consent banners.
  cookies,
}

/// Metadata for an ABP filter list remote source.
class AbpSource {
  /// Creates a new ABP source with the given [name], [url] and [category].
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

class _RemoveParamsSource {
  const _RemoveParamsSource({required this.name, required this.url});

  final String name;
  final String url;
}
