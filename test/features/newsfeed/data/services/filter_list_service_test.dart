import 'package:control_center/features/newsfeed/data/services/filter_list_service.dart';
import 'package:control_center/features/newsfeed/domain/filter_list_update_state.dart';
import 'package:control_center/features/newsfeed/domain/helpers/abp_parser.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart' show SharedPreferences;

/// Helpers to instantiate [FilterListService] for testing instance methods.
late FilterListService _service;

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    // ignore: invalid_use_of_visible_for_testing_member
    _service = FilterListService(Dio(), prefs);
  });
  // ── FilterListUpdateState ─────────────────────────────────────────────────

  group('FilterListUpdateState', () {
    const state = FilterListUpdateState(
      isUpdating: false,
      errors: [],
      cookieHidingRules: 10,
      adHidingRules: 20,
      networkBlockRules: 5,
      removeParamsCount: 30,
    );

    test('copyWith preserves unchanged fields', () {
      final copy = state.copyWith(isUpdating: true);
      expect(copy.isUpdating, isTrue);
      expect(copy.cookieHidingRules, 10);
      expect(copy.adHidingRules, 20);
      expect(copy.networkBlockRules, 5);
      expect(copy.removeParamsCount, 30);
      expect(copy.errors, isEmpty);
    });

    test('copyWith replaces specified fields', () {
      final copy = state.copyWith(
        errors: ['network error'],
        removeParamsCount: 35,
      );
      expect(copy.errors, ['network error']);
      expect(copy.removeParamsCount, 35);
      expect(copy.cookieHidingRules, 10);
    });
  });

  // ── buildCssDisplayNoneRules (element hiding rules) ───────────────────────

  group('FilterListService.buildCssDisplayNoneRules', () {
    test('returns empty list for empty input', () {
      expect(FilterListService.buildCssDisplayNoneRules([]), isEmpty);
    });

    test('single selector produces one rule', () {
      final rules = FilterListService.buildCssDisplayNoneRules(['.ad-banner']);
      expect(rules, hasLength(1));
      final rule = rules.single;
      expect(rule['trigger'], {'url-filter': '.*'});
      expect(
        rule['action'],
        {'type': 'css-display-none', 'selector': '.ad-banner'},
      );
    });

    test('multiple selectors joined with comma-space', () {
      final rules = FilterListService.buildCssDisplayNoneRules([
        '.foo',
        '.bar',
        '.baz',
      ]);
      expect(rules, hasLength(1));
      expect((rules.single['action'] as Map<String, dynamic>)['selector'], '.foo, .bar, .baz');
    });

    test('url-filter is always wildcard', () {
      final rules = FilterListService.buildCssDisplayNoneRules(['.x']);
      expect((rules.single['trigger'] as Map<String, dynamic>)['url-filter'], '.*');
    });

    test('action type is css-display-none', () {
      final rules = FilterListService.buildCssDisplayNoneRules(['.a']);
      expect((rules.single['action'] as Map<String, dynamic>)['type'], 'css-display-none');
    });

    test(
      'exactly chunkSize selectors produce one rule',
      () {
        final selectors = List.generate(
          FilterListService.cssChunkSize,
          (i) => '.sel-$i',
        );
        expect(FilterListService.buildCssDisplayNoneRules(selectors),
            hasLength(1));
      },
    );

    test(
      'chunkSize + 1 selectors produce two rules',
      () {
        final selectors = List.generate(
          FilterListService.cssChunkSize + 1,
          (i) => '.sel-$i',
        );
        expect(FilterListService.buildCssDisplayNoneRules(selectors),
            hasLength(2));
      },
    );

    test(
      'first chunk has chunkSize selectors, second has remainder',
      () {
        final selectors = List.generate(
          FilterListService.cssChunkSize + 3,
          (i) => '.sel-$i',
        );
        final rules = FilterListService.buildCssDisplayNoneRules(selectors);
        final firstSelector = (rules[0]['action'] as Map<String, dynamic>)['selector'] as String;
        final secondSelector = (rules[1]['action'] as Map<String, dynamic>)['selector'] as String;
        expect(firstSelector.split(', '), hasLength(FilterListService.cssChunkSize));
        expect(secondSelector.split(', '), hasLength(3));
      },
    );

    test(
      'large list produces correct number of chunks',
      () {
        const total = 100;
        final selectors = List.generate(total, (i) => '.sel-$i');
        final rules = FilterListService.buildCssDisplayNoneRules(selectors);
        expect(rules.length, (total / FilterListService.cssChunkSize).ceil());
      },
    );

    test('does not insert if-domain trigger key', () {
      final rules = FilterListService.buildCssDisplayNoneRules(['.x']);
      expect(rules.single['trigger'], isNot(contains('if-domain')));
    });

    test('selector order is preserved within chunks', () {
      final selectors = List.generate(10, (i) => '.sel-$i');
      final rules = FilterListService.buildCssDisplayNoneRules(selectors);
      final joined = (rules[0]['action'] as Map<String, dynamic>)['selector'] as String;
      final parts = joined.split(', ');
      for (var i = 0; i < 10; i++) {
        expect(parts[i], '.sel-$i');
      }
    });
  });

  // ── buildDomainScopedHideRules (domain blocking) ──────────────────────────

  group('FilterListService.buildDomainScopedHideRules', () {
    test('returns empty list for empty input', () {
      expect(FilterListService.buildDomainScopedHideRules([]), isEmpty);
    });

    test('single DomainHide produces one rule with if-domain', () {
      final rules = FilterListService.buildDomainScopedHideRules([
        const DomainHide(domains: ['*example.com'], selector: '.cookie'),
      ]);
      expect(rules, hasLength(1));
      expect(rules.single['trigger'], {
        'url-filter': '.*',
        'if-domain': ['*example.com'],
      });
      expect(
        rules.single['action'],
        {'type': 'css-display-none', 'selector': '.cookie'},
      );
    });

    test('two hides with same domain set are grouped in one rule', () {
      final rules = FilterListService.buildDomainScopedHideRules([
        const DomainHide(domains: ['*a.com'], selector: '.sel1'),
        const DomainHide(domains: ['*a.com'], selector: '.sel2'),
      ]);
      expect(rules, hasLength(1));
      expect((rules.single['action'] as Map<String, dynamic>)['selector'], '.sel1, .sel2');
      expect((rules.single['trigger'] as Map<String, dynamic>)['if-domain'], ['*a.com']);
    });

    test('two hides with different domain sets produce two rules', () {
      final rules = FilterListService.buildDomainScopedHideRules([
        const DomainHide(domains: ['*a.com'], selector: '.x'),
        const DomainHide(domains: ['*b.com'], selector: '.y'),
      ]);
      expect(rules, hasLength(2));
      final domainA = rules.any((r) {
        final d = (r['trigger'] as Map)['if-domain'] as List;
        return d.length == 1 && d[0] == '*a.com';
      });
      final domainB = rules.any((r) {
        final d = (r['trigger'] as Map)['if-domain'] as List;
        return d.length == 1 && d[0] == '*b.com';
      });
      expect(domainA, isTrue);
      expect(domainB, isTrue);
    });

    test(
      'domain order invariance: same set in different order → grouped',
      () {
        final rules = FilterListService.buildDomainScopedHideRules([
          const DomainHide(domains: ['*a.com', '*b.com'], selector: '.x'),
          const DomainHide(domains: ['*b.com', '*a.com'], selector: '.y'),
        ]);
        expect(rules, hasLength(1));
        expect((rules.single['action'] as Map<String, dynamic>)['selector'], '.x, .y');
      },
    );

    test(
      'multi-domain hide rule has sorted if-domain list',
      () {
        final rules = FilterListService.buildDomainScopedHideRules([
          const DomainHide(domains: ['*z.com', '*a.com'], selector: '.x'),
        ]);
        final domainList = (rules.single['trigger'] as Map<String, dynamic>)['if-domain'] as List;
        expect(domainList, ['*a.com', '*z.com']);
      },
    );

    test(
      'multiple domain groups each chunk independently',
      () {
        final hides = <DomainHide>[];
        // Group A: chunkSize + 1 selectors → 2 rules
        for (var i = 0; i < FilterListService.cssChunkSize + 1; i++) {
          hides.add(const DomainHide(domains: ['*a.com'], selector: '.a'));
        }
        // Group B: 3 selectors → 1 rule
        for (var i = 0; i < 3; i++) {
          hides.add(const DomainHide(domains: ['*b.com'], selector: '.b'));
        }
        final rules = FilterListService.buildDomainScopedHideRules(hides);
        // 2 rules for group A + 1 for group B = 3
        expect(rules, hasLength(3));
      },
    );

    test(
      'action type is css-display-none',
      () {
        final rules = FilterListService.buildDomainScopedHideRules([
          const DomainHide(domains: ['*x.com'], selector: '.a'),
        ]);
        expect((rules.single['action'] as Map<String, dynamic>)['type'], 'css-display-none');
      },
    );

    test('url-filter is always wildcard for domain-scoped rules', () {
      final rules = FilterListService.buildDomainScopedHideRules([
        const DomainHide(domains: ['*x.com'], selector: '.a'),
      ]);
      expect((rules.single['trigger'] as Map<String, dynamic>)['url-filter'], '.*');
    });

    test(
      'selector order preserved within each domain group',
      () {
        final rules = FilterListService.buildDomainScopedHideRules([
          const DomainHide(domains: ['*a.com'], selector: '.first'),
          const DomainHide(domains: ['*a.com'], selector: '.second'),
          const DomainHide(domains: ['*a.com'], selector: '.third'),
        ]);
        expect(
          (rules.single['action'] as Map<String, dynamic>)['selector'],
          '.first, .second, .third',
        );
      },
    );
  });

  // ── buildScriptletRules (scriptlet injection) ────────────────────────────

  group('FilterListService.buildScriptletRules', () {
    test('returns empty list for empty input', () {
      expect(FilterListService.buildScriptletRules([]), isEmpty);
    });

    test('universal scriptlet (no domains) has url-filter only', () {
      final rules = FilterListService.buildScriptletRules([
        const ScriptletInjection(
          domains: [],
          name: 'noeval',
          args: [],
        ),
      ]);
      expect(rules, hasLength(1));
      expect(rules.single['trigger'], {'url-filter': '.*'});
      expect(rules.single['trigger'], isNot(contains('if-domain')));
    });

    test('domain-scoped scriptlet includes if-domain', () {
      final rules = FilterListService.buildScriptletRules([
        const ScriptletInjection(
          domains: ['*example.com'],
          name: 'set-constant',
          args: ['property', 'value'],
        ),
      ]);
      expect(rules, hasLength(1));
      expect(rules.single['trigger'], {
        'url-filter': '.*',
        'if-domain': ['*example.com'],
      });
    });

    test('action type is scriptlet', () {
      final rules = FilterListService.buildScriptletRules([
        const ScriptletInjection(
          domains: [],
          name: 'noop',
          args: [],
        ),
      ]);
      expect((rules.single['action'] as Map<String, dynamic>)['type'], 'scriptlet');
    });

    test('action includes name and args', () {
      final rules = FilterListService.buildScriptletRules([
        const ScriptletInjection(
          domains: [],
          name: 'abort-current-script',
          args: ['pattern1', 'pattern2'],
        ),
      ]);
      final action = rules.single['action'] as Map;
      expect(action['name'], 'abort-current-script');
      expect(action['args'], ['pattern1', 'pattern2']);
    });

    test('empty args list is preserved', () {
      final rules = FilterListService.buildScriptletRules([
        const ScriptletInjection(
          domains: [],
          name: 'noeval',
          args: [],
        ),
      ]);
      expect((rules.single['action'] as Map)['args'], isEmpty);
    });

    test('multiple scriptlets produce multiple rules', () {
      final rules = FilterListService.buildScriptletRules([
        const ScriptletInjection(
          domains: ['*a.com'],
          name: 's1',
          args: [],
        ),
        const ScriptletInjection(
          domains: ['*b.com'],
          name: 's2',
          args: ['a'],
        ),
      ]);
      expect(rules, hasLength(2));
      expect((rules[0]['action'] as Map)['name'], 's1');
      expect((rules[1]['action'] as Map)['name'], 's2');
    });

    test(
      'scriptlet with multi-domain if-domain preserves domain list',
      () {
        final rules = FilterListService.buildScriptletRules([
          const ScriptletInjection(
            domains: ['*a.com', '*b.com'],
            name: 'trusted-click-element',
            args: ['button.accept'],
          ),
        ]);
        expect(
          (rules.single['trigger'] as Map<String, dynamic>)['if-domain'],
          ['*a.com', '*b.com'],
        );
      },
    );

    test('url-filter is always wildcard for scriptlets', () {
      final rules = FilterListService.buildScriptletRules([
        const ScriptletInjection(
          domains: ['*x.com'],
          name: 'test',
          args: [],
        ),
      ]);
      expect((rules.single['trigger'] as Map<String, dynamic>)['url-filter'], '.*');
    });
  });

  group('FilterListService.parseRemoveParams', () {
    late FilterListService svc;
    setUp(() { svc = _service; });
    test('extracts simple universal removeparam rules', () {
      final result =
          svc.parseRemoveParams('*\$removeparam=utm_source');
      expect(result, contains('utm_source'));
    });

    test('extracts multi-param rules', () {
      final result = svc.parseRemoveParams(
        '*\$removeparam=utm_source|utm_medium|utm_campaign',
      );
      expect(result, contains('utm_source'));
      expect(result, contains('utm_medium'));
      expect(result, contains('utm_campaign'));
    });

    test('skips domain-specific rules', () {
      final result = svc.parseRemoveParams(
        'example.com\$removeparam=tracking',
      );
      expect(result, isEmpty);
    });

    test('skips regex patterns', () {
      final result = svc.parseRemoveParams(
        '*\$removeparam=/utm_.*/',
      );
      expect(result, isEmpty);
    });

    test('skips comments and headers', () {
      final result = svc.parseRemoveParams('''
! Title: Privacy — Remove URL Parameters
! Expires: 4 days
! Homepage: https://github.com/uBlockOrigin/uAssets
*\$removeparam=utm_source
''');
      expect(result, contains('utm_source'));
      expect(result, hasLength(1));
    });

    test('handles mixed content', () {
      final result = svc.parseRemoveParams('''
! Comment
*\$removeparam=fbclid
example.com\$removeparam=tracking
*\$removeparam=gclid|gclsrc
! Another comment
*\$removeparam=/regex_.*/
*\$removeparam=utm_campaign
''');
      expect(result, contains('fbclid'));
      expect(result, contains('gclid'));
      expect(result, contains('gclsrc'));
      expect(result, contains('utm_campaign'));
      expect(result, isNot(contains('tracking')));
      expect(result, isNot(contains('/regex_/')));
    });

    test('converts param names to lowercase', () {
      final result = svc.parseRemoveParams('*\$removeparam=UTM_SOURCE');
      expect(result, contains('utm_source'));
    });

    test('ignores empty lines and whitespace', () {
      final result = svc.parseRemoveParams('''

  *\$removeparam=utm_source  

''');
      expect(result, contains('utm_source'));
    });

    test('allows wildcard prefix before removeparam', () {
      final result =
          svc.parseRemoveParams('*\$removeparam=fbclid');
      expect(result, contains('fbclid'));
    });

    // ── Edge cases ──

    test('empty input returns empty set', () {
      expect(svc.parseRemoveParams(''), isEmpty);
    });

    test('only whitespace returns empty set', () {
      expect(svc.parseRemoveParams('  \n  \t  '), isEmpty);
    });

    test('only comments returns empty set', () {
      expect(svc.parseRemoveParams('! comment 1\n! comment 2'), isEmpty);
    });

    test('line with removeparam but no value is skipped', () {
      final result = svc.parseRemoveParams('*\$removeparam=');
      expect(result, isEmpty);
    });

    test('removeparam with leading spaces after = produces no match', () {
      final result =
          svc.parseRemoveParams('*\$removeparam=  utm_source  ');
      // Regex ([^,\s]+) requires non-whitespace immediately after =.
      expect(result, isEmpty);
    });

    test('removeparam with surrounding spaces in parts', () {
      final result =
          svc.parseRemoveParams('*\$removeparam= utm_source|  fbclid ');
      // Leading space after = breaks the match — no result.
      expect(result, isEmpty);
    });

    test('multi-param with empty parts ignores empty', () {
      final result =
          svc.parseRemoveParams('*\$removeparam=utm_source||utm_medium');
      expect(result, contains('utm_source'));
      expect(result, contains('utm_medium'));
      expect(result, hasLength(2));
    });

    test('multi-param values are trimmed after split', () {
      final result = svc.parseRemoveParams(
        '*\$removeparam= a | b | c ',
      );
      // Leading space after = breaks the regex — no match.
      expect(result, isEmpty);
    });

    test('wildcard domain followed by domain-specific comma', () {
      // `*$removeparam=foo,~script` — the regex stops at comma.
      final result = svc.parseRemoveParams(
        '*\$removeparam=foo,~script',
      );
      expect(result, contains('foo'));
    });

    test('uppercase mixed with lowercase normalizes', () {
      final result =
          svc.parseRemoveParams('*\$removeparam=UtM_SoUrCe');
      expect(result, contains('utm_source'));
    });

    test('does not extract from non-removeparam options', () {
      final result = svc.parseRemoveParams(
        '||example.com^\$script,removeparam=tracking',
      );
      // `$removeparam=tracking` appears but after `$script,`, the regex
      // for `$removeparam=` matches the first occurrence — but this
      // line has domain prefix with dot, so it should be skipped.
      expect(result, isEmpty);
    });
  });

  // ── parseSource (categorization) ──────────────────────────────────────────

  group('FilterListService.parseSource', () {
    late FilterListService svc;
    setUp(() { svc = _service; });
    test('ads source routes selectors to ads list and blocks to network', () {
      final adsSelectors = <String>[];
      final cookiesSelectors = <String>[];
      final domainHides = <DomainHide>[];
      final networkBlocks = <Map<String, dynamic>>[];
      final scriptlets = <ScriptletInjection>[];

      const raw = '##.ad-banner\n||doubleclick.net^\n';
      svc.parseSource(
        raw,
        const AbpSource(
          name: 'test',
          url: '',
          category: FilterCategory.ads,
        ),
        adsSelectors,
        cookiesSelectors,
        domainHides,
        networkBlocks,
        scriptlets,
      );

      expect(adsSelectors, contains('.ad-banner'));
      expect(cookiesSelectors, isEmpty);
      expect(networkBlocks, isNotEmpty);
      expect((networkBlocks.single['action'] as Map<String, dynamic>)['type'], 'block');
    });

    test('cookies source routes selectors to cookies list only', () {
      final adsSelectors = <String>[];
      final cookiesSelectors = <String>[];
      final domainHides = <DomainHide>[];
      final networkBlocks = <Map<String, dynamic>>[];
      final scriptlets = <ScriptletInjection>[];

      const raw = '##.cookie-banner\n##.gdpr-popup\n';
      svc.parseSource(
        raw,
        const AbpSource(
          name: 'test',
          url: '',
          category: FilterCategory.cookies,
        ),
        adsSelectors,
        cookiesSelectors,
        domainHides,
        networkBlocks,
        scriptlets,
      );

      expect(adsSelectors, isEmpty);
      expect(cookiesSelectors, contains('.cookie-banner'));
      expect(networkBlocks, isEmpty);
    });

    test('domain hides are routed regardless of category', () {
      final domainHides = <DomainHide>[];

      svc.parseSource(
        'example.com##.overlay\n',
        const AbpSource(
          name: 'test',
          url: '',
          category: FilterCategory.ads,
        ),
        <String>[],
        <String>[],
        domainHides,
        <Map<String, dynamic>>[],
        <ScriptletInjection>[],
      );
      expect(domainHides, hasLength(1));
      domainHides.clear();

      svc.parseSource(
        'example.com##.overlay\n',
        const AbpSource(
          name: 'test',
          url: '',
          category: FilterCategory.cookies,
        ),
        <String>[],
        <String>[],
        domainHides,
        <Map<String, dynamic>>[],
        <ScriptletInjection>[],
      );
      expect(domainHides, hasLength(1));
    });

    test('scriptlets are routed regardless of category', () {
      final scriptlets = <ScriptletInjection>[];

      svc.parseSource(
        'example.com##+js(noeval)\n',
        const AbpSource(
          name: 'test',
          url: '',
          category: FilterCategory.ads,
        ),
        <String>[],
        <String>[],
        <DomainHide>[],
        <Map<String, dynamic>>[],
        scriptlets,
      );
      expect(scriptlets, hasLength(1));
      scriptlets.clear();

      svc.parseSource(
        'example.com##+js(noeval)\n',
        const AbpSource(
          name: 'test',
          url: '',
          category: FilterCategory.cookies,
        ),
        <String>[],
        <String>[],
        <DomainHide>[],
        <Map<String, dynamic>>[],
        scriptlets,
      );
      expect(scriptlets, hasLength(1));
    });

    test('network blocks from cookies source are NOT added to blocklist', () {
      final networkBlocks = <Map<String, dynamic>>[];
      final adsSelectors = <String>[];
      final cookiesSelectors = <String>[];

      svc.parseSource(
        '||tracker.com^\n',
        const AbpSource(
          name: 'test',
          url: '',
          category: FilterCategory.cookies,
        ),
        adsSelectors,
        cookiesSelectors,
        <DomainHide>[],
        networkBlocks,
        <ScriptletInjection>[],
      );

      expect(networkBlocks, isEmpty);
    });

    test('empty raw produces no changes', () {
      final adsSelectors = <String>[];
      final cookiesSelectors = <String>[];
      final networkBlocks = <Map<String, dynamic>>[];

      svc.parseSource(
        '',
        const AbpSource(
          name: 'test',
          url: '',
          category: FilterCategory.ads,
        ),
        adsSelectors,
        cookiesSelectors,
        <DomainHide>[],
        networkBlocks,
        <ScriptletInjection>[],
      );

      expect(adsSelectors, isEmpty);
      expect(cookiesSelectors, isEmpty);
      expect(networkBlocks, isEmpty);
    });
  });

  // ── Exception / whitelist rules ───────────────────────────────────────────

  group('Exception / whitelist rules', () {
    test('@@ exception rule produces no blocks or selectors', () {
      const raw = '@@||example.com^\n';
      final result = AbpParser.parse(raw);
      expect(result.cssSelectors, isEmpty);
      expect(result.domainHides, isEmpty);
      expect(result.blocklist, isEmpty);
      expect(result.scriptlets, isEmpty);
    });

    test('#@# element-hide unhide is skipped', () {
      const raw = 'example.com#@#.cookie-banner\n';
      final result = AbpParser.parse(raw);
      expect(result.cssSelectors, isEmpty);
      expect(result.domainHides, isEmpty);
    });

    test('exception rules do not affect adjacent active rules', () {
      const raw = '@@||whitelist.com^\n||blocked.com^\n##.hide-me\n';
      final result = AbpParser.parse(raw);
      expect(result.blocklist, hasLength(1));
      final trigger = result.blocklist.single['trigger'] as Map<String, dynamic>;
      expect(trigger['if-domain'], ['*blocked.com']);
      expect(result.cssSelectors, contains('.hide-me'));
    });

    test('@@ with domain-specific element hide exception is skipped', () {
      const raw = '@@||example.com^\$generichide\n';
      final result = AbpParser.parse(raw);
      expect(result.blocklist, isEmpty);
    });
  });

  // ── URL pattern matching (network block rules shape) ──────────────────────

  group('Network block rule shape', () {
    test('simple domain block has correct trigger shape', () {
      const raw = '||doubleclick.net^\n';
      final result = AbpParser.parse(raw);
      expect(result.blocklist, hasLength(1));
      final rule = result.blocklist.single;
      final trigger = rule['trigger'] as Map<String, dynamic>;
      expect(trigger['url-filter'], '.*');
      expect(trigger['if-domain'], ['*doubleclick.net']);
      expect((rule['action'] as Map<String, dynamic>)['type'], 'block');
    });

    test('subdomain block prefix is normalized', () {
      const raw = '||*.example.com^\n';
      final result = AbpParser.parse(raw);
      expect(
        (result.blocklist.single['trigger'] as Map<String, dynamic>)['if-domain'],
        ['*example.com'],
      );
    });

    test('domain with script resource type restriction', () {
      const raw = '||example.com^\$script\n';
      final result = AbpParser.parse(raw);
      final trigger = result.blocklist.single['trigger'] as Map;
      expect(trigger['resource-type'], ['script']);
      expect(trigger['if-domain'], ['*example.com']);
    });

    test('network block output merges correctly with hide rules', () {
      final adsSelectors = <String>['.ad'];
      final blocklist = AbpParser.parse('||tracker.com^\n').blocklist;
      final merged = <Map<String, dynamic>>[
        ...blocklist,
        ...FilterListService.buildCssDisplayNoneRules(adsSelectors),
      ];
      expect(merged, hasLength(2));
      // First entry is the block
      expect((merged[0]['action'] as Map<String, dynamic>)['type'], 'block');
      // Second entry is the css-display-none
      expect((merged[1]['action'] as Map<String, dynamic>)['type'], 'css-display-none');
    });
  });

  // ── Edge cases ────────────────────────────────────────────────────────────

  group('Edge cases', () {
    test('buildCssDisplayNoneRules with chunkSize = 1 boundary', () {
      // When list size equals chunkSize exactly
      final selectors =
          List.generate(FilterListService.cssChunkSize, (i) => '.s$i');
      final rules = FilterListService.buildCssDisplayNoneRules(selectors);
      expect(rules, hasLength(1));
    });

    test('buildDomainScopedHideRules with identical duplicate hides', () {
      final rules = FilterListService.buildDomainScopedHideRules([
        const DomainHide(domains: ['*a.com'], selector: '.dup'),
        const DomainHide(domains: ['*a.com'], selector: '.dup'),
      ]);
      // Both .dup selectors are kept (no deduplication at this level)
      expect(rules, hasLength(1));
      expect((rules.single['action'] as Map<String, dynamic>)['selector'], '.dup, .dup');
    });

    test('buildDomainScopedHideRules with empty domains (should not happen)', () {
      // DomainHide with empty domains list would have been filtered by
      // _parseDomainHide, but if it reaches this method it should still
      // produce a rule (no crash).
      final rules = FilterListService.buildDomainScopedHideRules([
        const DomainHide(domains: [], selector: '.x'),
      ]);
      // Empty domain key '|' creates one group
      expect(rules, isNotEmpty);
    });

    test('buildScriptletRules with empty name does not crash', () {
      final rules = FilterListService.buildScriptletRules([
        const ScriptletInjection(domains: [], name: '', args: []),
      ]);
      expect(rules, hasLength(1));
      expect((rules.single['action'] as Map)['name'], '');
    });

    test('parseRemoveParams handles DOS-style line endings', () {
      final result =
          _service.parseRemoveParams('*\$removeparam=foo\r\n*\$removeparam=bar');
      expect(result, contains('foo'));
      expect(result, contains('bar'));
    });

    test('rule list merging preserves order: blocks before hides', () {
      final networkBlocks = [
        {'trigger': {'url-filter': '.*', 'if-domain': ['*a.com']},
         'action': {'type': 'block'}},
      ];
      final cssRules =
          FilterListService.buildCssDisplayNoneRules(['.ad']);
      final merged = [...networkBlocks, ...cssRules];
      expect((merged[0]['action'] as Map<String, dynamic>)['type'], 'block');
      expect((merged[1]['action'] as Map<String, dynamic>)['type'], 'css-display-none');
    });

    test('all filter content types coexist in single rule list', () {
      final networkBlocks =
          AbpParser.parse('||blocked.com^\n').blocklist;
      final cssRules =
          FilterListService.buildCssDisplayNoneRules(['.ad-banner']);
      final domainRules =
          FilterListService.buildDomainScopedHideRules([
        const DomainHide(domains: ['*example.com'], selector: '.cookie'),
      ]);
      final scriptletRules = FilterListService.buildScriptletRules([
        const ScriptletInjection(
          domains: [],
          name: 'noeval',
          args: [],
        ),
      ]);

      final merged = [
        ...networkBlocks,
        ...cssRules,
        ...domainRules,
        ...scriptletRules,
      ];

      final types = merged.map((r) => (r['action'] as Map<String, dynamic>)['type'] as String).toList();
      expect(types, ['block', 'css-display-none', 'css-display-none', 'scriptlet']);
      // Domain rule has if-domain
      expect(merged[2]['trigger'], contains('if-domain'));
      // Scriptlet rule has name
      expect(merged[3]['action'], contains('name'));
    });
  });

  group('parseSource mixed content', () {
    late FilterListService svc;
    setUp(() { svc = _service; });

    test('routes all rule types from a single raw block', () {
      final adsSelectors = <String>[];
      final cookiesSelectors = <String>[];
      final domainHides = <DomainHide>[];
      final networkBlocks = <Map<String, dynamic>>[];
      final scriptlets = <ScriptletInjection>[];

      const raw = '##.ad-banner\n'
          'example.com##.cookie-overlay\n'
          '||tracker.net^\n'
          'site.com##+js(abort-current-script.js, pattern)\n';

      svc.parseSource(
        raw,
        const AbpSource(name: 'mix', url: '', category: FilterCategory.ads),
        adsSelectors,
        cookiesSelectors,
        domainHides,
        networkBlocks,
        scriptlets,
      );

      expect(adsSelectors, hasLength(1));
      expect(domainHides, hasLength(1));
      expect(networkBlocks, hasLength(1));
      expect(scriptlets, hasLength(1));
      expect(cookiesSelectors, isEmpty);
    });

    test('cookies category routes selectors to cookies list', () {
      final adsSelectors = <String>[];
      final cookiesSelectors = <String>[];

      const raw = '##.cookie-consent\n##.gdpr-banner\n';

      svc.parseSource(
        raw,
        const AbpSource(name: 'c', url: '', category: FilterCategory.cookies),
        adsSelectors,
        cookiesSelectors,
        <DomainHide>[],
        <Map<String, dynamic>>[],
        <ScriptletInjection>[],
      );

      expect(cookiesSelectors, hasLength(2));
      expect(adsSelectors, isEmpty);
    });

    test('network block with third-party option preserved', () {
      final networkBlocks = <Map<String, dynamic>>[];
      const raw = '||ad-server.com^\$third-party\n';

      svc.parseSource(
        raw,
        const AbpSource(name: 'tp', url: '', category: FilterCategory.ads),
        <String>[],
        <String>[],
        <DomainHide>[],
        networkBlocks,
        <ScriptletInjection>[],
      );

      expect(networkBlocks, hasLength(1));
    });
  });

  group('parseRemoveParams extra edge cases', () {
    late FilterListService svc;
    setUp(() { svc = _service; });

    test('all domain-specific rules are filtered out', () {
      const raw = 'example.com\$removeparam=tracking\n'
          'google.com\$removeparam=gclid\n'
          'yahoo.com\$removeparam=utm_source\n';
      final result = svc.parseRemoveParams(raw);
      expect(result, isEmpty);
    });

    test('trailing comma in removeparam value', () {
      final result = svc.parseRemoveParams('*\$removeparam=foo,');
      expect(result, contains('foo'));
    });
  });

  // ── readState (instance method) ──────────────────────────────────────────

  group('FilterListService readState', () {
    late FilterListService svc;
    setUp(() { svc = _service; });

    test('returns zeros and nulls when no data cached', () {
      final state = svc.readState();
      expect(state.isUpdating, isFalse);
      expect(state.errors, isEmpty);
      expect(state.cookieHidingRules, 0);
      expect(state.adHidingRules, 0);
      expect(state.networkBlockRules, 0);
      expect(state.removeParamsCount, 0);
      expect(state.lastCheck, isNull);
      expect(state.lastSuccess, isNull);
    });

    test('returns persisted counts when cache exists', () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'newsfeed.filterLists.lastCheck',
        '2025-06-01T12:00:00.000',
      );
      await prefs.setString(
        'newsfeed.filterLists.lastSuccess',
        '2025-06-01T13:00:00.000',
      );
      await prefs.setInt('newsfeed.filterLists.adHidingCount', 42);
      await prefs.setInt('newsfeed.filterLists.cookieHidingCount', 7);
      await prefs.setInt('newsfeed.filterLists.networkBlockCount', 13);
      await prefs.setInt('newsfeed.removeParams.count', 99);

      final state = svc.readState();
      expect(state.adHidingRules, 42);
      expect(state.cookieHidingRules, 7);
      expect(state.networkBlockRules, 13);
      expect(state.removeParamsCount, 99);
      expect(state.lastCheck, DateTime(2025, 6, 1, 12));
      expect(state.lastSuccess, DateTime(2025, 6, 1, 13));
    });
  });

  // ── readRemoveParams (instance method) ───────────────────────────────────

  group('FilterListService readRemoveParams', () {
    late FilterListService svc;
    setUp(() { svc = _service; });

    test('returns default params when nothing cached', () {
      final params = svc.readRemoveParams();
      expect(params, isNotEmpty);
      expect(params, contains('utm_source'));
      expect(params, contains('fbclid'));
      expect(params, contains('gclid'));
    });

    test('returns cached params when available', () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'newsfeed.removeParams.list',
        'custom_a,custom_b',
      );
      final params = svc.readRemoveParams();
      expect(params, contains('custom_a'));
      expect(params, contains('custom_b'));
      expect(params, isNot(contains('utm_source')));
    });

    test('handles empty cached string gracefully', () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('newsfeed.removeParams.list', '');
      final params = svc.readRemoveParams();
      expect(params, contains('utm_source'));
      expect(params, contains('fbclid'));
    });
  });

  // ── FilterListUpdateState copyWith comprehensive ─────────────────────────

  group('FilterListUpdateState copyWith comprehensive', () {
    test('overrides all fields simultaneously', () {
      const state = FilterListUpdateState(
        isUpdating: true,
        errors: ['err1'],
        cookieHidingRules: 5,
        adHidingRules: 10,
        networkBlockRules: 15,
        removeParamsCount: 20,
      );
      final now = DateTime(2025, 1, 1);
      final copy = state.copyWith(
        isUpdating: false,
        errors: ['err2', 'err3'],
        cookieHidingRules: 100,
        adHidingRules: 200,
        networkBlockRules: 300,
        removeParamsCount: 400,
        lastCheck: now,
        lastSuccess: now,
      );
      expect(copy.isUpdating, isFalse);
      expect(copy.errors, ['err2', 'err3']);
      expect(copy.cookieHidingRules, 100);
      expect(copy.adHidingRules, 200);
      expect(copy.networkBlockRules, 300);
      expect(copy.removeParamsCount, 400);
      expect(copy.lastCheck, now);
      expect(copy.lastSuccess, now);
    });

    test('copyWith preserves fields not mentioned', () {
      final now = DateTime(2025, 6, 1);
      const state = FilterListUpdateState(
        isUpdating: true,
        errors: ['original'],
        cookieHidingRules: 10,
        adHidingRules: 20,
        networkBlockRules: 30,
        removeParamsCount: 40,
        lastCheck: null,
        lastSuccess: null,
      );
      final copy = state.copyWith(lastCheck: now);
      expect(copy.lastCheck, now);
      expect(copy.isUpdating, isTrue);
      expect(copy.errors, ['original']);
      expect(copy.cookieHidingRules, 10);
    });
  });

  // ── parseRemoveParams additional edge cases ──────────────────────────────

  group('parseRemoveParams additional edge cases', () {
    late FilterListService svc;
    setUp(() { svc = _service; });

    test('trailing pipe in multi-param value', () {
      final result = svc.parseRemoveParams('*\$removeparam=utm_source|');
      expect(result, contains('utm_source'));
      expect(result, hasLength(1));
    });

    test('leading pipe in multi-param value', () {
      final result = svc.parseRemoveParams('*\$removeparam=|utm_source');
      expect(result, contains('utm_source'));
      expect(result, hasLength(1));
    });

    test('wildcard domain with dot is NOT filtered out', () {
      // Prefix contains '.' but starts with '*' → allowed (universal wildcard).
      final result = svc.parseRemoveParams(
        '*example.com\$removeparam=foo',
      );
      expect(result, contains('foo'));
    });

    test('bare wildcard domain with dot is NOT filtered out', () {
      final result = svc.parseRemoveParams(
        '*.example.com\$removeparam=bar',
      );
      expect(result, contains('bar'));
    });

    test('single character param name', () {
      final result = svc.parseRemoveParams('*\$removeparam=x');
      expect(result, contains('x'));
    });

    test('param with hyphens and numbers', () {
      final result = svc.parseRemoveParams(
        '*\$removeparam=utm-campaign-2024|ref_id',
      );
      expect(result, contains('utm-campaign-2024'));
      expect(result, contains('ref_id'));
    });

    test('regex starting with / but not ending with / is NOT skipped', () {
      // Only /regex/ (both start and end with /) are skipped.
      final result = svc.parseRemoveParams('*\$removeparam=/regex');
      expect(result, contains('/regex'));
    });

    test('param value after comma (modifier) is captured alone', () {
      final result = svc.parseRemoveParams(
        '*\$removeparam=foo,domain=bar.com|baz.com',
      );
      // Regex stops at comma: captures 'foo'. Rest is modifiers.
      expect(result, contains('foo'));
      expect(result, hasLength(1));
    });
  });

  // ── buildCssDisplayNoneRules chunking boundaries ─────────────────────────

  group('buildCssDisplayNoneRules chunking boundaries', () {
    test('exactly 2*chunkSize selectors produce 2 rules', () {
      final selectors = List.generate(
        FilterListService.cssChunkSize * 2,
        (i) => '.sel-$i',
      );
      final rules = FilterListService.buildCssDisplayNoneRules(selectors);
      expect(rules, hasLength(2));
    });

    test('each chunk has exactly chunkSize selectors when total is multiple',
        () {
      final selectors = List.generate(
        FilterListService.cssChunkSize * 3,
        (i) => '.sel-$i',
      );
      final rules = FilterListService.buildCssDisplayNoneRules(selectors);
      expect(rules, hasLength(3));
      for (final rule in rules) {
        final selector = (rule['action'] as Map<String, dynamic>)['selector'] as String;
        expect(
          selector.split(', '),
          hasLength(FilterListService.cssChunkSize),
        );
      }
    });
  });

  // ── buildDomainScopedHideRules advanced grouping ─────────────────────────

  group('buildDomainScopedHideRules advanced grouping', () {
    test('multiple domain groups with exactly chunkSize selectors each', () {
      final hides = <DomainHide>[];
      for (var g = 0; g < 3; g++) {
        for (var i = 0; i < FilterListService.cssChunkSize; i++) {
          hides.add(DomainHide(domains: ['*g$g.com'], selector: '.s$i'));
        }
      }
      final rules = FilterListService.buildDomainScopedHideRules(hides);
      expect(rules, hasLength(3));
    });

    test('single domain group spanning 2 chunks', () {
      final hides = List.generate(
        FilterListService.cssChunkSize * 2,
        (i) => const DomainHide(domains: ['*a.com'], selector: '.x'),
      );
      final rules = FilterListService.buildDomainScopedHideRules(hides);
      expect(rules, hasLength(2));
      // Both rules share the same if-domain
      expect((rules[0]['trigger'] as Map<String, dynamic>)['if-domain'], ['*a.com']);
      expect((rules[1]['trigger'] as Map<String, dynamic>)['if-domain'], ['*a.com']);
    });

    test('empty domains across multiple entries form one group', () {
      final rules = FilterListService.buildDomainScopedHideRules([
        const DomainHide(domains: [], selector: '.a'),
        const DomainHide(domains: [], selector: '.b'),
        const DomainHide(domains: [], selector: '.c'),
      ]);
      expect(rules, hasLength(1));
      // Empty domain group still includes if-domain key (empty list)
      expect((rules.single['trigger'] as Map<String, dynamic>)['if-domain'], isEmpty);
    });
  });

  // ── buildScriptletRules advanced ─────────────────────────────────────────

  group('buildScriptletRules advanced', () {
    test('multiple scriptlets with identical domain set each get own rule',
        () {
      final rules = FilterListService.buildScriptletRules([
        const ScriptletInjection(
          domains: ['*a.com'],
          name: 's1',
          args: [],
        ),
        const ScriptletInjection(
          domains: ['*a.com'],
          name: 's2',
          args: ['arg'],
        ),
        const ScriptletInjection(
          domains: ['*a.com'],
          name: 's3',
          args: ['a', 'b'],
        ),
      ]);
      expect(rules, hasLength(3));
      expect((rules[0]['action'] as Map)['name'], 's1');
      expect((rules[1]['action'] as Map)['name'], 's2');
      expect((rules[2]['action'] as Map)['name'], 's3');
      // All share the same if-domain
      for (final r in rules) {
        expect((r['trigger'] as Map<String, dynamic>)['if-domain'], ['*a.com']);
      }
    });

    test('mixed universal and domain-scoped scriptlets', () {
      final rules = FilterListService.buildScriptletRules([
        const ScriptletInjection(domains: [], name: 'universal', args: []),
        const ScriptletInjection(
          domains: ['*x.com', '*y.com'],
          name: 'scoped',
          args: ['v'],
        ),
      ]);
      expect(rules, hasLength(2));
      // Universal: no if-domain
      expect(rules[0]['trigger'], isNot(contains('if-domain')));
      // Scoped: has if-domain
      expect((rules[1]['trigger'] as Map<String, dynamic>)['if-domain'], ['*x.com', '*y.com']);
      expect((rules[1]['action'] as Map)['args'], ['v']);
    });
  });

  // ── parseSource advanced ─────────────────────────────────────────────────

  group('parseSource advanced', () {
    late FilterListService svc;
    setUp(() { svc = _service; });

    test('ads source: only domain hides and scriptlets (no CSS selectors)', () {
      final adsSelectors = <String>[];
      final domainHides = <DomainHide>[];
      final scriptlets = <ScriptletInjection>[];

      const raw = 'example.com##.overlay\n'
          'site.com##+js(noeval)\n';

      svc.parseSource(
        raw,
        const AbpSource(name: 't', url: '', category: FilterCategory.ads),
        adsSelectors,
        <String>[],
        domainHides,
        <Map<String, dynamic>>[],
        scriptlets,
      );

      expect(adsSelectors, isEmpty);
      expect(domainHides, hasLength(1));
      expect(scriptlets, hasLength(1));
    });

    test(
        'cookies source: network blocks are excluded but hiding/scriptlets '
        'are kept', () {
      final cookiesSelectors = <String>[];
      final domainHides = <DomainHide>[];
      final networkBlocks = <Map<String, dynamic>>[];
      final scriptlets = <ScriptletInjection>[];

      const raw = '##.cookie-banner\n'
          '||tracker.com^\n'
          'example.com##.overlay\n'
          'site.com##+js(set-constant, gpc, 1)\n';

      svc.parseSource(
        raw,
        const AbpSource(name: 'c', url: '', category: FilterCategory.cookies),
        <String>[],
        cookiesSelectors,
        domainHides,
        networkBlocks,
        scriptlets,
      );

      // Cookie CSS selectors → cookies list
      expect(cookiesSelectors, hasLength(1));
      expect(cookiesSelectors, contains('.cookie-banner'));
      // Domain hides → always collected
      expect(domainHides, hasLength(1));
      // Scriptlets → always collected
      expect(scriptlets, hasLength(1));
      // Network blocks → EXCLUDED for cookies sources
      expect(networkBlocks, isEmpty);
    });

    test('all five output lists populated from mixed ads source', () {
      final adsSelectors = <String>[];
      final cookiesSelectors = <String>[];
      final domainHides = <DomainHide>[];
      final networkBlocks = <Map<String, dynamic>>[];
      final scriptlets = <ScriptletInjection>[];

      const raw = '##.ad-banner\n'
          '##.popup-ad\n'
          '||ad-server.com^\n'
          '||tracker.net^\n'
          'example.com##.cookie-overlay\n'
          'site.com##+js(abort-current-script, adsbygoogle)\n'
          'other.com##+js(set-constant, gpc, 1)\n';

      svc.parseSource(
        raw,
        const AbpSource(name: 'full', url: '', category: FilterCategory.ads),
        adsSelectors,
        cookiesSelectors,
        domainHides,
        networkBlocks,
        scriptlets,
      );

      expect(adsSelectors, hasLength(2));
      expect(cookiesSelectors, isEmpty);
      expect(domainHides, hasLength(1));
      expect(networkBlocks, hasLength(2));
      expect(scriptlets, hasLength(2));
    });
  });
}
