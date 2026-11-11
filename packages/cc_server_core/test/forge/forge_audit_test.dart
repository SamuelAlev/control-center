import 'dart:convert';

import 'package:cc_server_core/src/forge/forge_audit.dart';
import 'package:crypto/crypto.dart' show sha256;
import 'package:test/test.dart';

/// A stateless GitHub installation token: `ghs_<APPID>_<JWT>`, about 520
/// characters, with dots.
final String _stateless =
    'ghs_4242_${'eyJ0eXAiOiJKV1QiLCJhbGciOiJSUzI1NiJ9' * 5}.'
    '${'eyJpc3MiOiI0MjQyIiwiaWF0IjoxNzYyNzQ1NjAwfQ' * 5}.'
    '${'c2lnbmF0dXJlLWJ5dGVzLWhlcmUtX2xvbmc' * 4}';

/// One credential of every shape a forge hands out.
final Map<String, String> _tokens = {
  'ghs_': _stateless,
  'ghs_ classic': 'ghs_${'A1b2C3d4E5' * 4}',
  'ghu_': 'ghu_${'Zz9Yy8Xx7W' * 4}',
  'ghp_': 'ghp_${'Q' * 36}',
  'github_pat_': 'github_pat_11AAAAAAA0${'b' * 70}',
  'gho_': 'gho_${'c' * 36}',
  'ghr_': 'ghr_${'d' * 76}',
  'glpat-': 'glpat-${'e' * 20}',
  'gloas-': 'gloas-${'f' * 40}',
  'ATCTT': 'ATCTT3xFfGN0${'g' * 180}=ABCD1234',
  'ATATT': 'ATATT3xFfGF0${'h' * 180}=EFGH5678',
  'bitbucket email:token': 'ada@example.com:ATATT3xFfGF0${'i' * 60}',
  'jwt': '${'eyJhbGciOiJSUzI1NiJ9'}.${'eyJpc3MiOiIxIn0'}.${'j' * 40}',
  // Not forge credentials, but a forge event's text can carry one (a
  // Connect error naming a Slack or Google grant): the shared table covers
  // them.
  'xoxe.xoxp-': 'xoxe.xoxp-1-${'k' * 40}',
  'lin_oauth_': 'lin_oauth_${'l' * 40}',
  'ya29.': 'ya29.${'m' * 60}',
  'private key':
      '-----BEGIN PRIVATE KEY-----\n${'n' * 64}\n-----END PRIVATE KEY-----',
};

void main() {
  test('hashed_token is computed exactly as GitHub’s audit log does', () {
    // echo -n TOKEN | openssl dgst -sha256 -binary | base64
    expect(
      forgeHashedToken(_stateless),
      base64.encode(sha256.convert(utf8.encode(_stateless)).bytes),
    );
    expect(_stateless.length, greaterThan(500));
    expect(_stateless, contains('.'));
  });

  test('a stateless installation token is still recognised as ghs_', () {
    expect(forgeTokenKind(_stateless), 'github_installation');
  });

  for (final event in ForgeAuditEvent.values) {
    test('${event.wire}: no line ever carries a credential', () {
      for (final MapEntry(key: kind, value: token) in _tokens.entries) {
        final lines = [
          // Named as the event's token: only its hash and kind appear.
          forgeAuditLine(event, {'workspace_id': 'ws'}, token: token),
          // Smuggled into ordinary fields, alone, quoted, in a header or a
          // URL, and under a field name an event never carries.
          forgeAuditLine(event, {
            'message': 'GitHub refused $token for acme/api',
            'error': 'Exception: {"token":"$token"}',
            'header': 'Authorization: Bearer $token',
            'basic': 'Basic ${base64.encode(utf8.encode('x:$token'))}',
            'url': 'https://x-access-token:$token@github.com/acme/api.git',
            'detail': token,
            'access_token': token,
            'refresh_token': token,
            'seal': token,
            'list': [token],
          }),
        ];
        for (final line in lines) {
          expect(line, startsWith('forge.audit {"event":"${event.wire}"'));
          expect(line, isNot(contains(token)), reason: '$kind in $line');
          // Nor a fragment long enough to be the token's body.
          final body = token.substring(
            token.length ~/ 3,
            token.length ~/ 3 * 2,
          );
          expect(
            line,
            isNot(contains(body)),
            reason: '$kind fragment in $line',
          );
        }
        expect(
          jsonDecode(lines.first.substring('forge.audit '.length)),
          containsPair('hashed_token', forgeHashedToken(token)),
        );
      }
    });
  }
}
