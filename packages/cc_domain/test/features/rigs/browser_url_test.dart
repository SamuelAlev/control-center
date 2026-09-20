import 'package:cc_domain/features/rigs/domain/value_objects/browser_url.dart';
import 'package:test/test.dart';

void main() {
  group('isBrowserInternalUrl', () {
    test('empty, about:blank and chrome-error are furniture', () {
      expect(isBrowserInternalUrl(''), isTrue);
      expect(isBrowserInternalUrl('about:blank'), isTrue);
      expect(isBrowserInternalUrl('ABOUT:BLANK'), isTrue);
      expect(isBrowserInternalUrl('about:srcdoc'), isTrue);
      expect(isBrowserInternalUrl('chrome-error://chromewebdata/'), isTrue);
      expect(isBrowserInternalUrl('devtools://devtools/bundled/'), isTrue);
    });

    test('a real destination is not', () {
      expect(isBrowserInternalUrl('http://localhost:5173/'), isFalse);
      expect(isBrowserInternalUrl('https://example.test'), isFalse);
      expect(isBrowserInternalUrl('file:///tmp/home.html'), isFalse);
    });
  });

  group('visibleBrowserUrl', () {
    test('a real URL passes through', () {
      expect(
        visibleBrowserUrl('http://localhost:5173/'),
        'http://localhost:5173/',
      );
    });

    test('chrome-error prefers the unreachable destination', () {
      expect(
        visibleBrowserUrl(
          'chrome-error://chromewebdata/',
          fallback: 'http://localhost:5173/',
        ),
        'http://localhost:5173/',
        reason:
            'Chrome\'s omnibox shows the URL that failed, not the '
            'interstitial document. Without this the bar flickers between '
            'the two every time the error page is re-committed.',
      );
    });

    test('furniture without a fallback is empty, not the interstitial', () {
      expect(visibleBrowserUrl('chrome-error://chromewebdata/'), isEmpty);
      expect(visibleBrowserUrl('about:blank'), isEmpty);
    });

    test('a furniture fallback is ignored', () {
      expect(
        visibleBrowserUrl(
          'chrome-error://chromewebdata/',
          fallback: 'about:blank',
        ),
        isEmpty,
      );
    });
  });

  group('guestLoopbackUrl', () {
    test('rewrites localhost and ::1 to 127.0.0.1, leaves other hosts', () {
      expect(
        guestLoopbackUrl('http://localhost:5173/'),
        'http://127.0.0.1:5173/',
      );
      expect(guestLoopbackUrl('http://[::1]:3000/'), 'http://127.0.0.1:3000/');
      expect(guestLoopbackUrl('https://app.test/'), 'https://app.test/');
      expect(
        guestLoopbackUrl('http://vite.localhost:5173/'),
        'http://vite.localhost:5173/',
      );
    });
  });

  group('browserAddressBarText', () {
    test('blanks the guest home page and chrome-error', () {
      expect(browserAddressBarText('file:///tmp/home.html'), isEmpty);
      expect(browserAddressBarText('chrome-error://chromewebdata/'), isEmpty);
      expect(
        browserAddressBarText('http://localhost:5173/'),
        'http://localhost:5173/',
      );
    });
  });

  group('normalizeBrowserAddressInput', () {
    test('adds https and rewrites localhost', () {
      expect(normalizeBrowserAddressInput(''), isNull);
      expect(
        normalizeBrowserAddressInput('example.test'),
        'https://example.test',
      );
      expect(
        normalizeBrowserAddressInput('http://localhost:5173/'),
        'http://127.0.0.1:5173/',
      );
    });
  });
}
