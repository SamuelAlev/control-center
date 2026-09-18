import 'dart:io';

import 'package:cc_harness_runtime/src/oauth/browser_handoff_page.dart';
import 'package:test/test.dart';

void main() {
  test('success page uses design-system tokens and the brand mark', () {
    final html = browserHandoffPage(
      title: 'Signed in',
      body: 'You can close this tab and return to Control Center.',
    );
    expect(html, contains('color-scheme: light dark'));
    expect(html, contains('--bg: #fcfbf9'));
    expect(html, contains('--fg: #1f1f1f'));
    expect(html, contains('--bg: #171614'));
    expect(html, contains('prefers-color-scheme: dark'));
    expect(html, contains('prefers-reduced-motion'));
    expect(html, contains('class="mark"'));
    expect(html, contains('id="brandBg"'));
    expect(html, contains('viewBox="0 0 1024 1024"'));
    expect(html, contains('M1403.355 358.684'));
    expect(html, isNot(contains('nth-child')));
    expect(html, isNot(contains('repeat(3')));
    expect(html, contains('<h1>Signed in</h1>'));
    expect(html, isNot(contains('✓')));
    expect(html, contains('role="status"'));
    expect(html, contains('Connected'));
    expect(html, contains('Control Center'));
    expect(html, contains('border-radius: 9999px'));
    expect(html, isNot(contains('border-radius: .5rem')));
    expect(html, isNot(contains('system-ui;padding')));
  });

  test('failure page pairs color with a failed status', () {
    final html = browserHandoffPage(
      title: 'Sign-in failed',
      body: 'Return to Control Center and try again.',
      ok: false,
    );
    expect(html, contains('status bad'));
    expect(html, contains('Failed'));
    expect(html, contains('--danger-mark'));
    expect(html, contains('<h1>Sign-in failed</h1>'));
  });

  test('title, body, status and CTA are HTML-escaped', () {
    final html = browserHandoffPage(
      title: '<script>alert(1)</script>',
      body: 'signed in as "a&b"',
      statusLabel: '<x>',
      ctaLabel: 'Open <app>',
      ctaHref: 'https://example.test/?q="x"',
    );
    expect(html, isNot(contains('<script>alert(1)</script>')));
    expect(html, contains('&lt;script&gt;alert(1)&lt;/script&gt;'));
    expect(html, contains('signed in as &quot;a&amp;b&quot;'));
    expect(html, contains('&lt;x&gt;'));
    expect(html, contains('Open &lt;app&gt;'));
    expect(html, contains('href="https://example.test/?q=&quot;x&quot;"'));
    expect(html, contains('class="cta"'));
  });

  test('empty statusLabel hides the pill', () {
    final html = browserHandoffPage(
      title: 'Opening Control Center…',
      body: 'If nothing happened, try the button.',
      statusLabel: '',
      ctaLabel: 'Open Control Center',
      ctaHref: 'control-center://pair#abc',
    );
    expect(html, isNot(contains('role="status"')));
    expect(html, contains('class="cta"'));
    expect(html, contains('control-center://pair#abc'));
  });

  test('mcp_client copy stays byte-identical', () {
    final runtime = File(
      '${Directory.current.path}/lib/src/oauth/browser_handoff_page.dart',
    );
    final mcp = File(
      '${Directory.current.path}/../cc_mcp_client/lib/src/oauth/browser_handoff_page.dart',
    );
    expect(runtime.existsSync(), isTrue);
    expect(mcp.existsSync(), isTrue);
    expect(
      runtime.readAsStringSync(),
      mcp.readAsStringSync(),
      reason:
          'cc_mcp_client cannot depend on cc_harness_runtime; keep the '
          'handoff HTML copies in lockstep.',
    );
  });
}
