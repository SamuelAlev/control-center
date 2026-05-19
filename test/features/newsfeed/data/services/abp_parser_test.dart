import 'package:control_center/features/newsfeed/data/services/abp_parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AbpParser.parse', () {
    test('parses universal element-hiding rules into selectors', () {
      const raw = '''
! Comment line
[Adblock Plus 2.0]
##.ad-banner
##div[id^="ad-"]
##.sidebar-ad
''';
      final result = AbpParser.parse(raw);
      expect(
        result.cssSelectors,
        ['.ad-banner', 'div[id^="ad-"]', '.sidebar-ad'],
      );
      expect(result.blocklist, isEmpty);
    });

    test('domain-specific hide does not appear in universal selectors', () {
      const raw = 'example.com##.ad-banner';
      final result = AbpParser.parse(raw);
      expect(result.cssSelectors, isEmpty);
      expect(result.domainHides, hasLength(1));
      expect(result.domainHides.first.domains, ['*example.com']);
      expect(result.domainHides.first.selector, '.ad-banner');
    });

    group('domain hides', () {
      test('parses single-domain rule', () {
        const raw = 'techcrunch.com##.tp-modal';
        final result = AbpParser.parse(raw);
        expect(result.domainHides, hasLength(1));
        expect(result.domainHides.first.domains, ['*techcrunch.com']);
        expect(result.domainHides.first.selector, '.tp-modal');
      });

      test('parses multi-domain rule', () {
        const raw = 'd1.com,d2.com##.banner';
        final result = AbpParser.parse(raw);
        expect(result.domainHides, hasLength(1));
        expect(result.domainHides.first.domains, ['*d1.com', '*d2.com']);
        expect(result.domainHides.first.selector, '.banner');
      });

      test('strips negated domains', () {
        const raw = '~no.com,yes.com##.banner';
        final result = AbpParser.parse(raw);
        expect(result.domainHides, hasLength(1));
        expect(result.domainHides.first.domains, ['*yes.com']);
      });

      test('drops rules with only negated domains', () {
        const raw = '~example.com##.banner';
        final result = AbpParser.parse(raw);
        expect(result.domainHides, isEmpty);
      });

      test('skips unhide exception rules', () {
        const raw = 'example.com#@#.banner';
        final result = AbpParser.parse(raw);
        expect(result.domainHides, isEmpty);
      });

      test('skips rules with invalid domains', () {
        const raw = 'ads.*##.banner';
        final result = AbpParser.parse(raw);
        expect(result.domainHides, isEmpty);
      });

      test('skips ABP proprietary pseudo-classes in domain rules', () {
        const raw = 'example.com##div:has-text(Ads)';
        final result = AbpParser.parse(raw);
        expect(result.domainHides, isEmpty);
      });
    });

    test('skips exception rules', () {
      const raw = '@@||example.com^';
      final result = AbpParser.parse(raw);
      expect(result.blocklist, isEmpty);
    });

    test('skips regex filters', () {
      const raw = '/ad[0-9]+/';
      final result = AbpParser.parse(raw);
      expect(result.cssSelectors, isEmpty);
      expect(result.blocklist, isEmpty);
    });

    test('skips comments and headers', () {
      const raw = '''
! This is a comment
[Adblock Plus 2.0]
##.ad
''';
      final result = AbpParser.parse(raw);
      expect(result.cssSelectors, ['.ad']);
    });

    test('skips scriptlet injection rules', () {
      const raw = '##+js(scriptlet)';
      final result = AbpParser.parse(raw);
      expect(result.cssSelectors, isEmpty);
    });

    test('skips ABP proprietary pseudo-classes', () {
      const raw = '''
##div:style(display: none)
##div:has-text(Ads)
##div:contains(Ad)
##.valid-selector
''';
      final result = AbpParser.parse(raw);
      expect(result.cssSelectors, ['.valid-selector']);
    });

    group('network rules', () {
      test('parses simple domain block', () {
        const raw = '||doubleclick.net^';
        final result = AbpParser.parse(raw);
        expect(result.blocklist, hasLength(1));
        final entry = result.blocklist.first;
        expect((entry['trigger'] as Map<String, dynamic>)['if-domain'], ['*doubleclick.net']);
        expect((entry['action'] as Map<String, dynamic>)['type'], 'block');
      });

      test('parses domain with wildcard prefix', () {
        const raw = '||*.doubleclick.net^';
        final result = AbpParser.parse(raw);
        expect((result.blocklist.first['trigger'] as Map<String, dynamic>)['if-domain'], [
          '*doubleclick.net',
        ]);
      });

      test('parses script-specific block', () {
        const raw = '||tracker.com^\$script';
        final result = AbpParser.parse(raw);
        final trigger =
            result.blocklist.first['trigger'] as Map<String, dynamic>;
        expect(trigger['if-domain'], ['*tracker.com']);
        expect(trigger['resource-type'], ['script']);
      });

      test('parses image-specific block', () {
        const raw = '||ads.com^\$image';
        final result = AbpParser.parse(raw);
        final trigger =
            result.blocklist.first['trigger'] as Map<String, dynamic>;
        expect(trigger['resource-type'], ['image']);
      });

      test('parses multi-option block', () {
        const raw = '||cdn.com^\$script,image';
        final result = AbpParser.parse(raw);
        final trigger =
            result.blocklist.first['trigger'] as Map<String, dynamic>;
        expect(trigger['resource-type'], ['script', 'image']);
      });

      test('parses third-party option as domain-only', () {
        const raw = '||example.com^\$third-party';
        final result = AbpParser.parse(raw);
        final trigger =
            result.blocklist.first['trigger'] as Map<String, dynamic>;
        expect(trigger.containsKey('resource-type'), isFalse);
      });

      test('skips rules with path or query in domain', () {
        // ABP allows patterns like `||cacheserve.*/promodisplay/` and
        // `||online.*/promoredirect?key=`. These produce invalid
        // `if-domain` values for WKContentRuleList, which fails the
        // entire rule list compile.
        const raw = '''
||cacheserve.*/promodisplay/^
||online.*/promoredirect?key=^
||beehiiv.com^*/ad_network/
||valid.com^
''';
        final result = AbpParser.parse(raw);
        expect(result.blocklist, hasLength(1));
        expect(
          (result.blocklist.first['trigger']
              as Map<String, dynamic>)['if-domain'],
          ['*valid.com'],
        );
      });

      test('skips rules with non-leading wildcards in domain', () {
        const raw = '''
||ads.*^
||cas.*.criteo.com^
||valid.com^
''';
        final result = AbpParser.parse(raw);
        expect(result.blocklist, hasLength(1));
        expect(
          (result.blocklist.first['trigger']
              as Map<String, dynamic>)['if-domain'],
          ['*valid.com'],
        );
      });

      test('lowercases uppercase domains', () {
        const raw = '||DoubleClick.NET^';
        final result = AbpParser.parse(raw);
        expect(
          (result.blocklist.first['trigger']
              as Map<String, dynamic>)['if-domain'],
          ['*doubleclick.net'],
        );
      });

      test('skips unsupported options', () {
        const raw = '''
||example.com^\$document
||example.com^\$popup
||example.com^\$websocket
||example.com^\$important
||valid.com^
''';
        final result = AbpParser.parse(raw);
        expect(result.blocklist, hasLength(1));
        expect((result.blocklist.first['trigger'] as Map<String, dynamic>)['if-domain'], ['*valid.com']);
      });
    });

    group('isValidIfDomain', () {
      test('accepts plain hostnames', () {
        expect(AbpParser.isValidIfDomain('example.com'), isTrue);
        expect(AbpParser.isValidIfDomain('sub.example.com'), isTrue);
        expect(AbpParser.isValidIfDomain('xn--bcher-kva.example'), isTrue);
      });

      test('accepts leading-wildcard hostnames', () {
        expect(AbpParser.isValidIfDomain('*example.com'), isTrue);
        expect(AbpParser.isValidIfDomain('*doubleclick.net'), isTrue);
      });

      test('rejects empty / wildcard-only', () {
        expect(AbpParser.isValidIfDomain(''), isFalse);
        expect(AbpParser.isValidIfDomain('*'), isFalse);
      });

      test('rejects non-leading wildcards', () {
        expect(AbpParser.isValidIfDomain('*ads.*'), isFalse);
        expect(AbpParser.isValidIfDomain('*cas.*.criteo.com'), isFalse);
      });

      test('rejects paths and query strings', () {
        expect(
          AbpParser.isValidIfDomain('*cacheserve.*/promodisplay/'),
          isFalse,
        );
        expect(
          AbpParser.isValidIfDomain('*online.*/promoredirect?key='),
          isFalse,
        );
      });

      test('rejects uppercase', () {
        expect(AbpParser.isValidIfDomain('Example.com'), isFalse);
      });
    });

    test('parses mixed content correctly', () {
      const raw = '''
! Comment
##.ad-banner
||tracking.com^
example.com##.skip-me
@@||whitelist.com^
||badware.com^\$script
##+js(noop)
''';
      final result = AbpParser.parse(raw);
      expect(result.cssSelectors, contains('.ad-banner'));
      expect(result.cssSelectors, isNot(contains('.skip-me')));
      expect(result.blocklist, hasLength(2));
      expect(
        result.blocklist.any(
          (b) => ((b['trigger'] as Map<String, dynamic>)['if-domain'] as List).contains('*tracking.com'),
        ),
        isTrue,
      );
      expect(
        result.blocklist.any(
          (b) => ((b['trigger'] as Map<String, dynamic>)['if-domain'] as List).contains('*badware.com'),
        ),
        isTrue,
      );
    });

    test('parses domain-scoped scriptlet rules', () {
      const raw =
          'techcrunch.com##+js(prevent-addEventListener, load, .indexOf)';
      final result = AbpParser.parse(raw);
      expect(result.cssSelectors, isEmpty);
      expect(result.domainHides, isEmpty);
      expect(result.scriptlets, hasLength(1));
      final s = result.scriptlets.first;
      expect(s.name, 'prevent-addEventListener');
      expect(s.args, ['load', '.indexOf']);
      expect(s.domains, ['*techcrunch.com']);
    });

    test('parses universal (no-domain) scriptlet rules', () {
      const raw = '##+js(set-constant, window.foo, true)';
      final result = AbpParser.parse(raw);
      expect(result.scriptlets, hasLength(1));
      final s = result.scriptlets.first;
      expect(s.name, 'set-constant');
      expect(s.args, ['window.foo', 'true']);
      expect(s.domains, isEmpty);
    });

    test('parses multi-domain scriptlet rules', () {
      const raw =
          'a.com,b.org##+js(no-setInterval-if, /ad-poll/)';
      final result = AbpParser.parse(raw);
      expect(result.scriptlets, hasLength(1));
      final s = result.scriptlets.first;
      expect(s.name, 'no-setInterval-if');
      expect(s.args, ['/ad-poll/']);
      expect(s.domains, containsAll(['*a.com', '*b.org']));
    });

    test('scriptlet rules do not pollute domainHides or cssSelectors', () {
      const raw = '''
example.com##.ad
example.com##+js(set-constant, window.x, true)
##.universal
##+js(aopr, navigator.foo)
''';
      final result = AbpParser.parse(raw);
      expect(result.cssSelectors, ['.universal']);
      expect(result.domainHides, hasLength(1));
      expect(result.scriptlets, hasLength(2));
    });

    test('scriptlet args support backslash-escaped commas outside quotes', () {
      const raw = r'example.com##+js(set-constant, foo, bar\,baz)';
      final result = AbpParser.parse(raw);
      expect(result.scriptlets, hasLength(1));
      expect(result.scriptlets.first.args, ['foo', 'bar,baz']);
    });

    test('scriptlet args strip surrounding double/single/backtick quotes', () {
      for (final raw in <String>[
        'a.com##+js(set, foo, "bar baz, qux")',
        "a.com##+js(set, foo, 'bar baz, qux')",
        'a.com##+js(set, foo, `bar baz, qux`)',
      ]) {
        final result = AbpParser.parse(raw);
        expect(result.scriptlets, hasLength(1), reason: raw);
        expect(
          result.scriptlets.first.args,
          ['foo', 'bar baz, qux'],
          reason: raw,
        );
      }
    });

    test('backtick-quoted regex args preserve commas + escapes', () {
      // Real-world rule shape from uBlock Origin (TechCrunch in this case):
      // the regex contains literal commas and regex-escape backslashes
      // that must survive the splitter unmolested.
      const raw =
          r'techcrunch.com##+js(remove-node-text, script, `/"a"|""\)\.split\(","\)\[4\]/`)';
      final result = AbpParser.parse(raw);
      expect(result.scriptlets, hasLength(1));
      final s = result.scriptlets.first;
      expect(s.name, 'remove-node-text');
      expect(s.args, hasLength(2));
      expect(s.args[0], 'script');
      // The regex content: surrounding backticks gone, slashes + body
      // intact, commas preserved, backslash escapes preserved.
      expect(s.args[1], r'/"a"|""\)\.split\(","\)\[4\]/');
    });
  });
}
