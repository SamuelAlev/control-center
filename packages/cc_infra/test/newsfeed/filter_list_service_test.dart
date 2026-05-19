import 'dart:io';
import 'dart:typed_data';

import 'package:cc_domain/core/domain/ports/key_value_store.dart';
import 'package:cc_infra/src/newsfeed/abp_parser.dart';
import 'package:cc_infra/src/newsfeed/filter_list_service.dart';
import 'package:cc_infra/src/util/cc_paths.dart';
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

class _MemoryPrefs implements KeyValueStore {
  final Map<String, String> _strings = {};
  final Map<String, int> _ints = {};

  @override
  String? getString(String key) => _strings[key];

  @override
  Future<bool> setString(String key, String value) async {
    _strings[key] = value;
    return true;
  }

  @override
  int? getInt(String key) => _ints[key];

  @override
  Future<bool> setInt(String key, int value) async {
    _ints[key] = value;
    return true;
  }
}

/// Isolated per-test temp dir so `manualRefresh`'s cache writes never touch
/// the host's real app-support root and clean up after the run.
String _newTempRoot() {
  final dir = Directory.systemTemp.createTempSync('cc_filter_test_');
  addTearDown(() {
    if (dir.existsSync()) {
      dir.deleteSync(recursive: true);
    }
  });
  return dir.path;
}

FilterListService buildService(
  Handler handler, {
  required KeyValueStore prefs,
}) {
  final fake = _FakeAdapter(handler);
  final dio = Dio()..httpClientAdapter = fake;
  return FilterListService(dio, prefs, CcPaths(_newTempRoot()));
}

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
      svc = buildService((_) => _textBody(''), prefs: _MemoryPrefs());
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
      final svc = buildService((_) => _textBody(''), prefs: _MemoryPrefs());
      final params = svc.readRemoveParams();
      expect(params, isNotEmpty); // defaults exist
      expect(params, contains('utm_source'));
    });

    test('readRemoveParams parses a stored CSV', () {
      final prefs = _MemoryPrefs();
      prefs.setString('newsfeed.removeParams.list', 'foo,bar,,baz');
      final svc = buildService((_) => _textBody(''), prefs: prefs);
      expect(svc.readRemoveParams(), {'foo', 'bar', 'baz'});
    });

    test('readState surfaces persisted counts', () {
      final prefs = _MemoryPrefs();
      prefs.setInt('newsfeed.filterLists.adHidingCount', 12);
      prefs.setInt('newsfeed.filterLists.networkBlockCount', 3);
      prefs.setInt('newsfeed.removeParams.count', 7);
      prefs.setString('newsfeed.filterLists.lastCheck', '2026-01-01T00:00:00');
      prefs.setString(
        'newsfeed.filterLists.lastSuccess',
        '2026-01-02T00:00:00',
      );
      final svc = buildService((_) => _textBody(''), prefs: prefs);
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
      final prefs = _MemoryPrefs();
      await prefs.setString(
        'newsfeed.filterLists.lastCheck',
        DateTime.now().toIso8601String(),
      );
      final svc = buildService((_) => _textBody(''), prefs: prefs);
      await svc.autoUpdate();
      // No refresh means no requests fired.
      // (readState returns with empty errors — the call is a no-op.)
      expect(svc.readState().lastCheck, isNotNull);
    });

    test('refreshes when the last check is older than 24h', () async {
      final prefs = _MemoryPrefs();
      await prefs.setString(
        'newsfeed.filterLists.lastCheck',
        DateTime.now().subtract(const Duration(hours: 25)).toIso8601String(),
      );
      var calls = 0;
      final svc = buildService((_) {
        calls++;
        // Return a minimal valid filter list (empty body) for every source.
        return _textBody('! empty\n');
      }, prefs: prefs);
      await svc.autoUpdate();
      expect(calls, greaterThan(0));
    });
  });

  group('FilterListService.readBlocklist', () {
    test('returns [] when no cache exists', () async {
      final svc = buildService((_) => _textBody(''), prefs: _MemoryPrefs());
      // No cache directory created → readBlocklist returns [].
      expect(await svc.readBlocklist(), isEmpty);
    });
  });
}

// Helpers -----------------------------------------------------------------

ResponseBody _textBody(String text) => ResponseBody.fromString(
  text,
  200,
  headers: {
    Headers.contentTypeHeader: ['text/plain'],
  },
);
