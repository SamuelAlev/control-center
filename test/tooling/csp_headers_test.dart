import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Ratchet over the Content-Security-Policies we SHIP.
///
/// Four surfaces carry one: the Cloudflare Worker that stamps a per-request
/// policy for the web client, the self-hosted nginx image for that same client,
/// and the equivalent pair for the cc_remote phone PWA. They deliberately differ
/// (cc_remote has no `ws:`, and only the Worker can name the connected cc-server
/// origin from a cookie), so this does NOT demand they be identical — it pins the
/// two directives every font in the product depends on, which had already drifted
/// in three of the four files before this test existed.
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
  /// files explain themselves at length, and a directive named in prose is not a
  /// policy.
  String? directive(String source, String name) {
    for (final line in source.split('\n')) {
      final code = line.trim();
      if (code.startsWith('//') || code.startsWith('#')) {
        continue;
      }
      // Terminates on the directive separator or whichever string delimiter the
      // host file uses (the Worker writes one directive per JS string, and its
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

    test('the web-client policies admit remote media playback', () {
      // Audio/video load through a real <audio>/<video> element, which media-src
      // governs — NOT img-src (thumbnails) and NOT connect-src (XHR). Omit the
      // directive and it falls back to `default-src 'self'`, which blocks the
      // soundscape stream, meeting playback, and proxied video attachments in
      // one go. The failure is silent (the player simply never starts), which is
      // exactly how it shipped unnoticed.
      //
      // Only the web client is checked: cc_remote plays no media at all today,
      // so `default-src 'self'` is correctly tighter there. Add it to the phone
      // policies at the same time as the first player.
      for (final path in const ['worker/csp.js', 'docker/web/nginx.conf']) {
        final mediaSrc = directive(policies[path]!, 'media-src');
        expect(
          mediaSrc,
          isNotNull,
          reason:
              '$path declares no media-src, so remote audio/video is '
              "blocked by default-src 'self'",
        );
        expect(mediaSrc, contains("'self'"), reason: '$path: bundled sounds');
        // The paired cc-server: an interpolated origin in the Worker (which
        // alone can read it from the cookie), a broad scheme in static nginx.
        expect(
          mediaSrc,
          anyOf(contains(r'${proxy}'), contains('https:')),
          reason: '$path cannot play media from the connected cc-server',
        );
      }
    });

    test('every policy admits the cc-server lane a user font rides', () {
      // A user-selected family is fetched from the host's `/proxy/font` with an
      // XHR, so it is connect-src, NOT font-src (the bytes are then registered
      // from memory, and `new FontFace(family, bytes)` performs no fetch).
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
      // `/deploy.json` is the ENTIRE web + PWA update mechanism: the clients
      // poll it and compare its gitSha against the running build
      // (lib/core/update/deployed_version.dart,
      // apps/cc_remote/lib/update/remote_update.dart). If any one surface lets
      // it be cached, that origin's users poll a frozen manifest and the
      // refresh banner either never appears or never clears — silently, on one
      // origin only, which is the hardest shape of bug to notice.
      //
      // The other four entries are the same class of problem for the bundle
      // itself: Flutter's main.dart.js is not content-hashed, so a cached
      // index.html / bootstrap / service worker pins an old build after a
      // deploy.
      //
      // Five independently-maintained lists say this, in four syntaxes. They
      // agree today; nothing made them, which is why this exists. (The gallery
      // is deliberately absent — it ships no updater and no deploy.json.)
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
