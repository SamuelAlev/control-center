import 'package:cc_harness_runtime/cc_harness_runtime.dart';
import 'package:test/test.dart';

void main() {
  group('stripTags', () {
    test('decodes entities and drops markup', () {
      expect(
        stripTags('<p>a &amp; b &lt;c&gt; &#39;d&#39;</p>'),
        "a & b <c> 'd'",
      );
    });

    test('drops script and style content entirely', () {
      expect(
        stripTags('<script>evil()</script><p>real</p><style>x{}</style>'),
        'real',
      );
    });
  });

  group('preserveCodeBlocks', () {
    test('fences a pre/code block', () {
      // The most valuable thing on an answer page is the code; stripping tags
      // alone turns it into prose that reads like the author wrote syntax.
      final out = preserveCodeBlocks('<pre><code>final x = 1;</code></pre>');
      expect(out, contains('```'));
      expect(out, contains('final x = 1;'));
    });
  });

  group('extractSiteContent', () {
    test('returns null for an unknown host', () {
      expect(
        extractSiteContent(Uri.parse('https://example.test/a'), '<p>hi</p>'),
        isNull,
      );
    });

    test('GitHub: pulls the issue body and comments', () {
      const html = '''
<html><head>
<meta property="og:title" content="Fix the flaky test">
<meta property="og:description" content="It fails on CI only.">
</head><body>
<td class="comment-body"><p>The test races the timer.</p><pre><code>await pump();</code></pre></td>
<td class="comment-body"><p>Confirmed on main.</p></td>
</body></html>''';
      final out = extractSiteContent(
        Uri.parse('https://github.com/o/r/issues/1'),
        html,
      );
      expect(out, isNotNull);
      expect(out!, contains('# Fix the flaky test'));
      expect(out, contains('## Description'));
      expect(out, contains('races the timer'));
      expect(out, contains('## Comment 1'));
      expect(out, contains('Confirmed on main'));
      expect(out, contains('await pump();'), reason: 'code must survive');
    });

    test('GitHub: a page with no body returns null, not a bare title', () {
      // Title alone is what the generic path already gives, so claiming a
      // structured extraction here would be a lie.
      const html = '<html><head><title>o/r</title></head><body></body></html>';
      expect(
        extractSiteContent(Uri.parse('https://github.com/o/r'), html),
        isNull,
      );
    });

    test('Stack Overflow: separates question from answers', () {
      const html = '''
<html><head><title>How do I await a stream?</title></head><body>
<div class="s-prose js-post-body"><p>I have a stream.</p></div>
<div class="s-prose js-post-body"><p>Use await for.</p></div>
</body></html>''';
      final out = extractSiteContent(
        Uri.parse('https://stackoverflow.com/questions/1'),
        html,
      );
      expect(out, isNotNull);
      expect(out!, contains('## Question'));
      expect(out, contains('I have a stream'));
      expect(out, contains('## Answer 1'));
      expect(out, contains('Use await for'));
    });

    test('pub.dev: leads with the version and the install line', () {
      const html = '''
<html><head><meta name="description" content="A fast HTTP client."></head>
<body><h1 class="title">http 1.2.0</h1>
<section class="detail-tab-readme-content"><p>Usage docs.</p></section>
</body></html>''';
      final out = extractSiteContent(
        Uri.parse('https://pub.dev/packages/http'),
        html,
      );
      expect(out, isNotNull);
      expect(out!, contains('# http'));
      expect(out, contains('1.2.0'), reason: 'the version is the point');
      expect(out, contains('dart pub add http'));
      expect(out, contains('Usage docs'));
    });

    test('npm: name, description and install line', () {
      const html =
          '<meta property="og:description" content="Promise utilities.">';
      final out = extractSiteContent(
        Uri.parse('https://www.npmjs.com/package/p-limit'),
        html,
      );
      expect(out, contains('# p-limit'));
      expect(out, contains('npm install p-limit'));
    });

    test('arXiv: title, authors and abstract', () {
      const html = '''
<h1 class="title"><span>Title:</span>Scaling Laws</h1>
<div class="authors"><span>Authors:</span>A. Person</div>
<blockquote class="abstract"><span>Abstract:</span>We show that…</blockquote>''';
      final out = extractSiteContent(
        Uri.parse('https://arxiv.org/abs/2604.10739'),
        html,
      );
      expect(out, isNotNull);
      expect(out!, contains('Scaling Laws'));
      expect(out, contains('A. Person'));
      expect(out, contains('## Abstract'));
      expect(out, contains('We show that'));
    });

    test('a matched host with moved markup degrades to null', () {
      // A layout change must fall back to generic text, never error.
      expect(
        extractSiteContent(
          Uri.parse('https://arxiv.org/abs/1'),
          '<html><body>totally different now</body></html>',
        ),
        isNull,
      );
    });
  });
}
