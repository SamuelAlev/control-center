import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Ratchet over the Content-Security-Policies we SHIP.
///
/// Four surfaces carry one: the Cloudflare Worker for the web client, the
/// self-hosted nginx image for that client, and the equivalent pair for the
/// cc_remote phone PWA. They deliberately differ (cc_remote has no `ws:`), so
/// this does not demand identical policies. Executable Worker policy coverage
/// lives in `tool/csp.test.mjs`; decrypted media uses same-origin resources.
void main() {
  final root = Directory.current.path;

  /// Each shipped policy, by the file a reader would go fix.
  final policies = <String, String>{
    for (final path in const [
      'worker/csp.js',
      'docker/web/nginx.conf',
      'apps/cc_remote/web/_headers',
      'docker/cc_remote/nginx.conf',
    ])
      path: File('$root/$path').readAsStringSync(),
  };

  /// Every hosted Wasm surface. The root/remote entries appear twice because
  /// Cloudflare and self-hosted nginx must both unlock threaded SkWasm.
  final isolationHeaders = <String, String>{
    for (final path in const [
      'web/_headers',
      'worker/csp.js',
      'docker/web/nginx.conf',
      'apps/cc_remote/web/_headers',
      'docker/cc_remote/nginx.conf',
      'apps/cc_gallery/web/_headers',
    ])
      path: File('$root/$path').readAsStringSync(),
  };

  /// The directive's value as written, from any of the four syntaxes (a JS array
  /// entry, an nginx `add_header`, a `_headers` line). Uncommented only: the
  /// files explain themselves at length and a directive named in prose is not a
  /// policy.
  String? directive(String source, String name) {
    for (final line in source.split('\n')) {
      final code = line.trim();
      if (code.startsWith('//') || code.startsWith('#')) {
        continue;
      }
      // Terminates on the directive separator or whichever string delimiter the
      // host file uses (the Worker writes one directive per JS string and its
      // connect-src is a template literal). Single quotes are VALUE syntax
      // (`'self'`), so they must not terminate.
      final match = RegExp(
        '$name '
        r'''([^;"\n`]+)''',
      ).firstMatch(code);
      if (match != null) {
        return match.group(1)!.trim();
      }
    }
    return null;
  }

  group('shipped CSPs', () {
    test('every policy admits the engine fallback-font origin', () {
      // CanvasKit downloads Noto (emoji, CJK — any glyph the bundled Manrope /
      // Fira Code lack) with a real `url()` font fetch, which font-src governs.
      // Omit it and those glyphs are tofu on the deployed app only, which is a
      // miserable thing to discover in production.
      for (final MapEntry(key: path, value: source) in policies.entries) {
        final fontSrc = directive(source, 'font-src');
        expect(fontSrc, isNotNull, reason: '$path declares no font-src');
        expect(
          fontSrc,
          contains('https://fonts.gstatic.com'),
          reason: '$path would render emoji as tofu',
        );
        expect(fontSrc, contains("'self'"), reason: '$path: bundled fonts');
      }
    });

    test('every policy admits the cc-server lane a user font rides', () {
      // A user-selected family is fetched from the host's `/proxy/font` with an
      // XHR, so it is connect-src, NOT font-src (the bytes are then registered
      // from memory and `new FontFace(family, bytes)` performs no fetch).
      // Tightening the HTTP schemes here stops the font picker working — the
      // failure looks like "my font silently does nothing".
      for (final MapEntry(key: path, value: source) in policies.entries) {
        final connectSrc = directive(source, 'connect-src');
        expect(connectSrc, isNotNull, reason: '$path declares no connect-src');
        expect(
          connectSrc,
          contains('https:'),
          reason: '$path cannot reach a TLS cc-server',
        );
      }
    });

    test('every delivery surface serves the entry files no-cache', () {
      // `/deploy.json` and unhashed Flutter bootstrap assets must be no-store
      // across every web surface's header list (cached manifest/index pins a
      // stale build). Gallery intentionally omitted (no updater).
      const routes = [
        '/index.html',
        '/flutter_bootstrap.js',
        '/flutter_service_worker.js',
        '/manifest.json',
        '/deploy.json',
      ];
      const surfaces = [
        'web/_headers',
        'apps/cc_remote/web/_headers',
        'worker/csp.js',
        'docker/web/nginx.conf',
        'docker/cc_remote/nginx.conf',
      ];

      for (final path in surfaces) {
        final lines = File('$root/$path')
            .readAsLinesSync()
            .map((l) => l.trim())
            .where((l) => !l.startsWith('//') && !l.startsWith('#'))
            .toList();
        for (final route in routes) {
          final reason =
              '$path does not serve $route no-cache — a stale copy there '
              'freezes that origin on an old build';
          if (path.endsWith('_headers')) {
            // Cloudflare `_headers`: the route, then its indented directives.
            final at = lines.indexOf(route);
            expect(at, isNot(-1), reason: reason);
            expect(
              lines.skip(at + 1).takeWhile((l) => !l.startsWith('/')),
              contains('Cache-Control: no-cache'),
              reason: reason,
            );
          } else if (path.endsWith('.js')) {
            // The Worker's NO_CACHE_PATHS set.
            expect(lines, contains('"$route",'), reason: reason);
          } else {
            // nginx `map $uri $cc_cache_control` entry.
            expect(
              lines.any(
                (l) => RegExp(
                  '^${RegExp.escape(route)}\\s+"no-cache";',
                ).hasMatch(l),
              ),
              isTrue,
              reason: reason,
            );
          }
        }
      }
    });

    test('every Wasm surface is cross-origin isolated for threaded SkWasm', () {
      for (final MapEntry(key: path, value: source)
          in isolationHeaders.entries) {
        final active = source
            .split('\n')
            .where((line) {
              final trimmed = line.trim();
              return !trimmed.startsWith('//') && !trimmed.startsWith('#');
            })
            .join('\n');
        expect(
          active,
          matches(RegExp(r'Cross-Origin-Opener-Policy[^\n]*same-origin')),
          reason: '$path does not isolate the top-level browsing context',
        );
        expect(
          active,
          matches(RegExp(r'Cross-Origin-Embedder-Policy[^\n]*credentialless')),
          reason:
              '$path leaves SkWasm in single-threaded mode or blocks '
              'cross-origin resources',
        );
      }
    });
  });
}
