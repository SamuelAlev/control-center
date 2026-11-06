import 'package:control_center/features/messaging/presentation/ide/editor/browser_pane.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('blank input is no address', () {
    expect(normalizeBrowserPaneAddress('   '), isNull);
  });

  test('a loopback host gets http, port or not', () {
    expect(
      normalizeBrowserPaneAddress('localhost:5173'),
      'http://localhost:5173',
    );
    expect(normalizeBrowserPaneAddress('localhost'), 'http://localhost');
    expect(
      normalizeBrowserPaneAddress('127.0.0.1:8080/health'),
      'http://127.0.0.1:8080/health',
    );
  });

  test('a *.localhost name gets http', () {
    expect(
      normalizeBrowserPaneAddress('web--fix-login--shop.localhost:4100/a?b=1'),
      'http://web--fix-login--shop.localhost:4100/a?b=1',
    );
    expect(
      normalizeBrowserPaneAddress('app.localhost'),
      'http://app.localhost',
    );
  });

  test('a host with a port is not read as a scheme', () {
    expect(
      normalizeBrowserPaneAddress('myapp.test:8443'),
      'https://myapp.test:8443',
    );
  });

  test('an explicit scheme is left alone', () {
    expect(
      normalizeBrowserPaneAddress('http://example.test'),
      'http://example.test',
    );
    expect(normalizeBrowserPaneAddress('about:blank'), 'about:blank');
  });

  test('a bare domain gets https', () {
    expect(normalizeBrowserPaneAddress('example.test'), 'https://example.test');
  });
}
