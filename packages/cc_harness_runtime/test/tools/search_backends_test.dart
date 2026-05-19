import 'package:cc_harness_runtime/cc_harness_runtime.dart';
import 'package:test/test.dart';

void main() {
  group('unwrapRedirect', () {
    test('unwraps a DuckDuckGo redirector', () {
      expect(
        unwrapRedirect('//duckduckgo.com/l/?uddg=https%3A%2F%2Fa.test%2Fx'),
        'https://a.test/x',
      );
    });

    test('leaves a plain URL alone', () {
      expect(unwrapRedirect('https://a.test/x'), 'https://a.test/x');
    });

    test('adds the scheme to a protocol-relative URL', () {
      expect(unwrapRedirect('//a.test/x'), 'https://a.test/x');
    });
  });

  group('looksBlocked', () {
    test('detects a challenge page', () {
      // The distinction that matters: "blocked" makes an agent try another
      // route, "no results" makes it conclude the thing does not exist.
      expect(looksBlocked('${'x' * 900} please complete the CAPTCHA'), isTrue);
      expect(looksBlocked('${'x' * 900} unusual traffic detected'), isTrue);
    });

    test('a suspiciously short body counts as blocked', () {
      expect(looksBlocked('<html></html>'), isTrue);
    });

    test('a long ordinary page does not', () {
      expect(looksBlocked('<html>${'content ' * 200}</html>'), isFalse);
    });
  });

  group('DuckDuckGoBackend', () {
    const backend = DuckDuckGoBackend();

    test('builds a query URL', () {
      expect(backend.queryUrl('dart streams').query, contains('dart'));
    });

    test('parses results and unwraps their URLs', () {
      const html = '''
<a class="result__a" href="//duckduckgo.com/l/?uddg=https%3A%2F%2Fa.test%2F1">First</a>
<a class="result__snippet">About the first.</a>
<a class="result__a" href="https://b.test/2">Second</a>
<a class="result__snippet">About the second.</a>''';
      final hits = backend.parse(html);
      expect(hits, hasLength(2));
      expect(hits.first.url, 'https://a.test/1');
      expect(hits.first.title, 'First');
      expect(hits.first.snippet, 'About the first.');
      expect(hits.last.url, 'https://b.test/2');
    });

    test('an unparseable page yields nothing rather than junk', () {
      expect(backend.parse('<html><body>nope</body></html>'), isEmpty);
    });
  });

  group('BingBackend', () {
    const backend = BingBackend();

    test('asks for the feed, which survives redesigns', () {
      expect(backend.queryUrl('x').queryParameters['format'], 'rss');
    });

    test('parses feed items', () {
      const rss = '''
<rss><channel>
<item><title>A result</title><link>https://a.test/1</link>
<description>Some text.</description></item>
<item><title>Another</title><link>https://b.test/2</link></item>
</channel></rss>''';
      final hits = backend.parse(rss);
      expect(hits, hasLength(2));
      expect(hits.first.title, 'A result');
      expect(hits.first.url, 'https://a.test/1');
      expect(hits.first.snippet, 'Some text.');
    });

    test('skips an item with no usable link', () {
      expect(
        backend.parse('<item><title>x</title><link>notaurl</link></item>'),
        isEmpty,
      );
    });
  });

  group('MojeekBackend', () {
    test('parses result anchors', () {
      final hits = const MojeekBackend().parse(
        '<a class="ob" href="https://a.test/1">Result</a>',
      );
      expect(hits.single.url, 'https://a.test/1');
      expect(hits.single.title, 'Result');
    });
  });

  group('the chain', () {
    test('is keyless end to end', () {
      // A chain that needs credentials is empty on a fresh install, which
      // defeats the point: the value is that search still works when the
      // first backend blocks.
      expect(searchBackends, hasLength(greaterThanOrEqualTo(3)));
      for (final backend in searchBackends) {
        expect(backend.queryUrl('x').toString(), startsWith('https://'));
        expect(backend.name, isNotEmpty);
      }
    });

    test('uses independent indexes, so they fail independently', () {
      expect(
        searchBackends.map((b) => b.queryUrl('x').host).toSet().length,
        searchBackends.length,
      );
    });
  });
}
