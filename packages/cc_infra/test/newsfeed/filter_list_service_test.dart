import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:cc_domain/features/newsfeed/domain/filter_list_update_state.dart';
import 'package:cc_infra/src/newsfeed/abp_parser.dart';
import 'package:cc_infra/src/newsfeed/filter_list_service.dart';
import 'package:dio/dio.dart';
import 'package:test/test.dart';

/// Exercises the pure, package-visible static helpers and the
/// `parseRemoveParams` instance method of [FilterListService], plus its
/// `readState`/`readRemoveParams` cache readers and the 24h autoUpdate guard.
/// The static rule builders drive the WKContentRuleList pipeline; this pins
/// their chunking + domain-bucketing so a malformed selector can't tank the
/// whole hide list.

class _FakeAdapter implements HttpClientAdapter {
  _FakeAdapter(this.handler);
  final ResponseBody Function(RequestOptions options) handler;
  final List<RequestOptions> requests = [];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    return handler(options);
  }

  @override
  void close({bool force = false}) {}
}

/// Isolated per-test temp dir so refresh cache writes never touch a real
/// data dir and clean up after the run.
String _newTempRoot() {
  final dir = Directory.systemTemp.createTempSync('cc_filter_test_');
  addTearDown(() {
    if (dir.existsSync()) {
      dir.deleteSync(recursive: true);
    }
  });
  return dir.path;
}

({FilterListService svc, _FakeAdapter adapter}) _build(
  Handler handler, {
  bool allowNetwork = true,
  String? cacheDir,
}) {
  final adapter = _FakeAdapter(handler);
  final dio = Dio()..httpClientAdapter = adapter;
  return (
    svc: FilterListService(
      cacheDir: cacheDir ?? _newTempRoot(),
      dio: dio,
      allowNetwork: allowNetwork,
    ),
    adapter: adapter,
  );
}

FilterListService buildService(
  Handler handler, {
  bool allowNetwork = true,
  String? cacheDir,
}) => _build(handler, allowNetwork: allowNetwork, cacheDir: cacheDir).svc;

void _seedState(
  String cacheDir, {
  required FilterListUpdateState state,
  Set<String> removeParams = const {},
}) {
  Directory(cacheDir).createSync(recursive: true);
  File('$cacheDir/state.json').writeAsStringSync(
    jsonEncode({...state.toJson(), 'removeParams': removeParams.toList()}),
  );
}

FilterListUpdateState _meta({
  DateTime? lastCheck,
  DateTime? lastSuccess,
  int adHidingRules = 0,
  int cookieHidingRules = 0,
  int networkBlockRules = 0,
  int removeParamsCount = 0,
}) => FilterListUpdateState(
  lastCheck: lastCheck,
  lastSuccess: lastSuccess,
  isUpdating: false,
  errors: const [],
  cookieHidingRules: cookieHidingRules,
  adHidingRules: adHidingRules,
  networkBlockRules: networkBlockRules,
  removeParamsCount: removeParamsCount,
);

typedef Handler = ResponseBody Function(RequestOptions o);

void main() {
  group('FilterListService.buildCssDisplayNoneRules', () {
    test('chunks selectors at cssChunkSize (25)', () {
      final selectors = <String>[for (var i = 0; i < 60; i++) '.s'];
      final rules = FilterListService.buildCssDisplayNoneRules(selectors);
      // 60 / 25 → 3 rules.
      expect(rules, hasLength(3));
      for (final r in rules) {
        expect((r['action'] as Map)['type'], 'css-display-none');
        expect((r['trigger'] as Map)['url-filter'], '.*');
      }
      // The chunks are joined by ', '.
      final firstSelector = (rules[0]['action'] as Map)['selector'] as String;
      expect(firstSelector.split(', ').length, 25);
      final lastSelector = (rules[2]['action'] as Map)['selector'] as String;
      expect(lastSelector.split(', ').length, 10); // 60 - 50
    });

    test('empty input produces no rules', () {
      expect(FilterListService.buildCssDisplayNoneRules(const []), isEmpty);
    });

    test('a single short list yields exactly one rule', () {
      final rules = FilterListService.buildCssDisplayNoneRules(const [
        '.a',
        '.b',
      ]);
      expect(rules, hasLength(1));
      expect((rules[0]['action'] as Map)['selector'], '.a, .b');
    });
  });

  group('FilterListService.buildDomainScopedHideRules', () {
    test('buckets by sorted domain key and chunks each bucket', () {
      final rules = FilterListService.buildDomainScopedHideRules([
        const DomainHide(domains: ['a.com', 'b.com'], selector: '.x'),
        const DomainHide(
          domains: ['b.com', 'a.com'],
          selector: '.y',
        ), // same bucket
        const DomainHide(domains: ['c.com'], selector: '.z'),
      ]);
      // Two buckets, one rule each (1 selector each < 25).
      expect(rules, hasLength(2));
      final domainSets = rules
          .map((r) => (r['trigger'] as Map)['if-domain'])
          .toSet();
      expect(domainSets, hasLength(2));
    });

    test('universal selector when domains empty is NOT added here', () {
      // Empty domains still bucket under an empty-sorted key.
      final rules = FilterListService.buildDomainScopedHideRules(const [
        DomainHide(domains: [], selector: '.x'),
      ]);
      expect(rules, hasLength(1));
      expect((rules[0]['trigger'] as Map)['if-domain'], isEmpty);
    });
  });

  group('FilterListService.buildScriptletRules', () {
    test(
      'emits one scriptlet rule per injection, with domains when present',
      () {
        final rules = FilterListService.buildScriptletRules(const [
          ScriptletInjection(
            domains: ['a.com'],
            name: 'set-constant',
            args: ['foo', '1'],
          ),
          ScriptletInjection(
            domains: [],
            name: 'abort-current-inline-script',
            args: [],
          ),
        ]);
        expect(rules, hasLength(2));
        expect((rules[0]['action'] as Map)['type'], 'scriptlet');
        expect((rules[0]['action'] as Map)['name'], 'set-constant');
        expect((rules[0]['trigger'] as Map)['if-domain'], ['a.com']);
        expect(rules[1]['trigger'] as Map, isNot(contains('if-domain')));
      },
    );

    test('empty input → no rules', () {
      expect(FilterListService.buildScriptletRules(const []), isEmpty);
    });
  });

  group('FilterListService.parseRemoveParams', () {
    late FilterListService svc;

    setUp(() {
      svc = buildService((_) => _textBody(''));
    });

    test('extracts removeparam= names, lowercased', () {
      // Universal rules use a `*` prefix (no domain-specific dot before $).
      final params = svc.parseRemoveParams('''
*\$removeparam=UTM_Source
*\$removeparam=utm_medium|utm_campaign
''');
      expect(params, containsAll(['utm_source', 'utm_medium', 'utm_campaign']));
    });

    test('skips comments and blank lines', () {
      expect(svc.parseRemoveParams('! comment\n\n  \n'), isEmpty);
    });

    test('skips regex patterns (/.../)', () {
      expect(svc.parseRemoveParams(r'||x.com$removeparam=/^utm_/'), isEmpty);
    });

    test('skips domain-specific rules (prefix contains a dot)', () {
      expect(
        svc.parseRemoveParams('||tracking.example.com\$removeparam=foo'),
        isEmpty,
      );
    });

    test('keeps wildcard-prefixed rules (* starts)', () {
      expect(
        svc.parseRemoveParams('*\$removeparam=fbclid'),
        contains('fbclid'),
      );
    });

    test('ignores lines without a removeparam directive', () {
      expect(svc.parseRemoveParams('||ads.example.com^'), isEmpty);
    });
  });

  group('FilterListService.readRemoveParams / readState', () {
    test('readRemoveParams falls back to defaults when unset', () {
      final svc = buildService((_) => _textBody(''));
      final params = svc.readRemoveParams();
      expect(params, isNotEmpty);
      expect(params, contains('utm_source'));
    });

    test('readRemoveParams returns a stored list', () {
      final cacheDir = _newTempRoot();
      _seedState(
        cacheDir,
        state: _meta(removeParamsCount: 3),
        removeParams: {'foo', 'bar', 'baz'},
      );
      final svc = buildService((_) => _textBody(''), cacheDir: cacheDir);
      expect(svc.readRemoveParams(), {'foo', 'bar', 'baz'});
    });

    test('readState surfaces persisted counts', () {
      final cacheDir = _newTempRoot();
      _seedState(
        cacheDir,
        state: _meta(
          lastCheck: DateTime.parse('2026-01-01T00:00:00'),
          lastSuccess: DateTime.parse('2026-01-02T00:00:00'),
          adHidingRules: 12,
          networkBlockRules: 3,
          removeParamsCount: 7,
        ),
      );
      final svc = buildService((_) => _textBody(''), cacheDir: cacheDir);
      final state = svc.readState();
      expect(state.adHidingRules, 12);
      expect(state.networkBlockRules, 3);
      expect(state.removeParamsCount, 7);
      expect(state.lastCheck, DateTime.parse('2026-01-01T00:00:00'));
      expect(state.lastSuccess, DateTime.parse('2026-01-02T00:00:00'));
      expect(state.isUpdating, isFalse);
    });
  });

  group('FilterListService.autoUpdate cooldown', () {
    test('skips the refresh when the last check was < 24h ago', () async {
      final cacheDir = _newTempRoot();
      _seedState(cacheDir, state: _meta(lastCheck: DateTime.now()));
      var calls = 0;
      final svc = buildService((_) {
        calls++;
        return _textBody('! empty\n');
      }, cacheDir: cacheDir);
      await svc.autoUpdate();
      expect(calls, 0);
    });

    test('refreshes when the last check is older than 24h', () async {
      final cacheDir = _newTempRoot();
      _seedState(
        cacheDir,
        state: _meta(
          lastCheck: DateTime.now().subtract(const Duration(hours: 25)),
        ),
      );
      var calls = 0;
      final svc = buildService((_) {
        calls++;
        return _textBody('! empty\n');
      }, cacheDir: cacheDir);
      await svc.autoUpdate();
      expect(calls, greaterThan(0));
    });
  });

  group('FilterListService.readBlocklist', () {
    test('returns [] when no cache exists', () async {
      final svc = buildService((_) => _textBody(''));
      expect(await svc.readBlocklist(), isEmpty);
    });
  });

  group('FilterListService.refresh cache', () {
    test('writes blocklist and state under the cache dir', () async {
      final cacheDir = _newTempRoot();
      final svc = buildService(
        (_) => _textBody('! empty\n'),
        cacheDir: cacheDir,
      );
      await svc.refresh(force: true);
      expect(File('$cacheDir/blocklist_cached.json').existsSync(), isTrue);
      expect(File('$cacheDir/state.json').existsSync(), isTrue);
      expect(svc.readState().lastSuccess, isNotNull);
    });

    test('allowNetwork: false never dials out', () async {
      var calls = 0;
      final svc = buildService((_) {
        calls++;
        return _textBody('! empty\n');
      }, allowNetwork: false);
      await svc.refresh(force: true);
      expect(calls, 0);
    });

    test(
      'stores ETags keyed by source name, not a literal \$etagKey',
      () async {
        final cacheDir = _newTempRoot();
        final built = _build(
          (_) => _textBody('! empty\n', etag: '"abc"'),
          cacheDir: cacheDir,
        );
        await built.svc.refresh(force: true);
        final raw = File('$cacheDir/etags.json').readAsStringSync();
        final etags = jsonDecode(raw) as Map<String, dynamic>;
        expect(etags.keys, contains('easylist'));
        expect(etags.keys, isNot(contains(r'$etagKey')));
        expect(etags['easylist'], '"abc"');

        built.adapter.requests.clear();
        await built.svc.refresh(force: true);
        expect(built.adapter.requests, isNotEmpty);
        expect(
          built.adapter.requests.every(
            (r) => r.headers['If-None-Match'] == '"abc"',
          ),
          isTrue,
        );
      },
    );
  });
}

// Helpers -----------------------------------------------------------------

ResponseBody _textBody(String text, {String? etag}) => ResponseBody.fromString(
  text,
  200,
  headers: {
    Headers.contentTypeHeader: ['text/plain'],
    if (etag != null) 'etag': [etag],
  },
);
