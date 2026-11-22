import 'dart:math';

import 'package:cc_domain/core/domain/services/redaction/token_patterns.dart';
import 'package:cc_domain/features/dispatch/domain/entities/agent_process_event.dart';
import 'package:cc_infra/src/dispatch/nested_call_rows.dart';
import 'package:cc_infra/src/util/command_redaction.dart';
import 'package:test/test.dart';

/// The patterns the linear ones replaced, as `git show HEAD:` has them
/// (`command_redaction.dart` and `token_patterns.dart` before the fifth
/// pass). Quadratic on long input, fine on these few KiB.
final _oldAccessToken = RegExp(
  r'(x-access-token:)[^@\s]+(@)',
  caseSensitive: false,
);
final _oldUrl = RegExp(
  r'([a-zA-Z][a-zA-Z0-9+.-]*://[^/@\s]+:)[^@/\s]+(@)',
  caseSensitive: false,
);
final _oldJwt = RegExp(
  r'\beyJ[A-Za-z0-9_-]{8,}\.eyJ[A-Za-z0-9_-]{8,}\.[A-Za-z0-9_-]*',
);

/// The token shapes that had a word boundary before them at HEAD (they
/// also match glued to the text before them now, in the vendor's shape).
final _oldBoundedTokens = [
  RegExp(r'\bsk-ant-[A-Za-z0-9_-]{20,}'),
  RegExp(r'\bgh[pousr]_[A-Za-z0-9_-][A-Za-z0-9._-]{18,}[A-Za-z0-9_-]'),
  RegExp(r'\bgithub_pat_[A-Za-z0-9_]{22,}'),
  RegExp(
    r'\bgl(?:pat|oas|dt|rt|cbt|ptt|ft|imt|agent|soat|ffct|wt)-'
    r'[A-Za-z0-9_-]{16,}',
  ),
  RegExp(r'\b(?:xox[abeoprs]|xoxe\.xox[abprs]|xapp)-[A-Za-z0-9-]{8,}'),
  RegExp(
    r'\bya29\.[A-Za-z0-9._-]{20,}|(?<![A-Za-z0-9/:._-])1//[A-Za-z0-9_-]{20,}',
  ),
];

/// Pieces of those shapes, glued and separated, for [_tokenInput].
const _tokenPieces = [
  'a', 'Z', '1', '_', '-', '.', ' ', 'x', 'aaaaaaaa', 'AB12cd34', //
  'sk-ant-', 'ghp_', 'ghs_', 'github_pat_', 'glpat-', 'gldt-', 'xoxb-',
  'xoxe.xoxp-', 'xapp-', 'ya29.', '1//', 'lin_api_', 'AKIA', 'sk-',
  'api03-',
  '1234567890-',
  'xoxe-1-',
  '.01.abcdefghi',
  '.01abcdefg',
  'A1b2C3d4E5f6G7h8',
];

String _tokenInput(Random random) {
  final out = StringBuffer();
  final count = random.nextInt(200);
  for (var i = 0; i < count; i++) {
    out.write(_tokenPieces[random.nextInt(_tokenPieces.length)]);
  }
  return out.toString();
}

final _newJwt = kTokenPatterns
    .singleWhere((p) => p.label == 'JSON web token')
    .pattern;

/// The indices [pattern] replaces in [input], as [redactSecrets] replaces
/// them: between the two groups of a two-group pattern, else the match.
Set<int> _redacted(RegExp pattern, String input) {
  final out = <int>{};
  for (final m in pattern.allMatches(input)) {
    final twoGroups = m.groupCount >= 2 && m[2] != null;
    final start = twoGroups ? m.start + m[1]!.length : m.start;
    final end = twoGroups ? m.end - m[2]!.length : m.end;
    for (var i = start; i < end; i++) {
      out.add(i);
    }
  }
  return out;
}

/// Pieces that make the patterns match, half-match and fail, joined at
/// random into inputs of up to about 3 KiB.
const _pieces = [
  'a', 'Z', '1', '9', '_', '-', '.', ':', '@', '/', ' ', '\n', '+', //
  'x-access-token:', 'X-Access-Token:', '://', 'https', 'git+ssh',
  'eyJ', 'eyJabcdefgh', 'eyJhbGciOiJ', 'user', 'pass', 'ghp_abc',
];

String _input(Random random) {
  final out = StringBuffer();
  final count = random.nextInt(400);
  for (var i = 0; i < count; i++) {
    out.write(_pieces[random.nextInt(_pieces.length)]);
  }
  return out.toString();
}

void main() {
  test('on generated inputs, everything the old patterns redacted is '
      'redacted now', () {
    final random = Random(20261118);
    var oldHits = 0;
    var widened = 0;
    for (var n = 0; n < 4000; n++) {
      final input = _input(random);
      for (final (old, now) in [
        (_oldAccessToken, kAccessTokenUrlPattern),
        (_oldUrl, kUrlCredentialPattern),
        (_oldJwt, _newJwt),
      ]) {
        final before = _redacted(old, input);
        final after = _redacted(now, input);
        oldHits += before.isEmpty ? 0 : 1;
        expect(
          after.containsAll(before),
          isTrue,
          reason:
              '${now.pattern} keeps what ${old.pattern} redacted in '
              '"$input"',
        );
        if (identical(old, _oldAccessToken)) {
          // The x-access-token pattern redacts exactly what it did.
          expect(after, before, reason: input);
        }
        if (after.length > before.length) {
          widened++;
        }
      }
    }
    // The generator reaches the patterns, and the new ones only widen.
    expect(oldHits, greaterThan(1000));
    // ignore: avoid_print
    print('EQUIVALENCE old hits $oldHits, widened $widened');
  });

  test('on generated inputs, everything the bounded token shapes redacted '
      'is redacted now', () {
    final random = Random(20261118);
    var oldHits = 0;
    var widened = 0;
    for (var n = 0; n < 4000; n++) {
      final input = _tokenInput(random);
      final before = {
        for (final old in _oldBoundedTokens) ..._redacted(old, input),
      };
      final after = {
        for (final token in kTokenPatterns) ..._redacted(token.pattern, input),
      };
      oldHits += before.isEmpty ? 0 : 1;
      widened += after.length > before.length ? 1 : 0;
      expect(after.containsAll(before), isTrue, reason: input);
    }
    expect(oldHits, greaterThan(1000));
    // ignore: avoid_print
    print('TOKEN EQUIVALENCE old hits $oldHits, widened $widened');
  });

  test('identifiers holding a token prefix are not redacted, in command '
      'output either', () {
    for (final text in [
      'highs_and_lows_of_the_market_report',
      'def fetch_ghs_token_for_installation_id(app): pass',
      'thighs_and_calves_workout_plan_2024',
      'path/to/highghs_and_more_words_here.txt',
      'task-ant-colony-optimization-solver-v2',
      'mask-ant-design-system-components-x',
      'boxoxb-123456789-abcdefgh',
      'Mya29.zone_identifier_value_for_testing',
      'shiglpat-like-name-for-a-variable-ok',
      'id: 7ghp_fixture_value_for_unit_tests_only_x',
    ]) {
      expect(redactSecrets(text), text, reason: text);
    }
  });

  test('a token glued to the text before it shows no prefix at the row '
      'cut, at any offset', () {
    // The smoke pass's case: padding run into the token (`x…xghp_…`), the
    // token straddling the 8 KiB cut of a nested call's result row.
    const token = 'ghp_Z08150QwErTyUiOpAsDfGhJkLzXcVbNm1234';
    const cut = NestedCallRows.maxResultBytes;
    for (var at = cut - token.length - 64; at <= cut + 8; at++) {
      final text = '${'x' * at}$token ${'y ' * 12000}';
      final event =
          NestedCallRows().bound(
                ToolResultEvent(
                  toolCallId: 'p/1',
                  outputs: text,
                  parentToolCallId: 'p',
                ),
              )!
              as ToolResultEvent;
      final kept = event.outputs;
      expect(kept, contains('bytes, truncated]'), reason: 'cut at $at');
      for (final fragment in ['ghp', 'Z081']) {
        expect(kept, isNot(contains(fragment)), reason: 'token at $at');
        expect(
          redactSecrets(kept),
          isNot(contains(fragment)),
          reason: 'run log, token at $at',
        );
      }
    }
  });

  test('where the URL pattern widens: no scheme, or an unusual one', () {
    for (final url in ['://u:p@h', '9://u:p@h', 'x${'1' * 40}://u:p@h']) {
      expect(redactSecrets(url), endsWith('://u:***REDACTED***@h'));
    }
    expect(
      redactSecrets('${'x' * 60}://u:p@h'),
      '${'x' * 60}://u:***REDACTED***@h',
    );
  });

  test('where the JWT pattern widens: a `-`-joined prefix of its run', () {
    const jwt = 'eyJabcdefgh.eyJabcdefgh.sig';
    expect(redactSecrets('see x-$jwt now'), 'see ***REDACTED*** now');
    expect(redactSecrets('see $jwt now'), 'see ***REDACTED*** now');
  });

  test('long real secrets are still redacted whole', () {
    // A JWT of several KiB, a long token after `x-access-token:`, a
    // password of a few hundred characters: no length bound applies.
    final jwt = 'eyJ${'a' * 2000}.eyJ${'b' * 6000}.${'c' * 600}';
    expect(redactSecrets('t=$jwt;'), 't=***REDACTED***;');
    final token = 'ghs_${'x' * 3000}';
    expect(
      redactSecrets('https://x-access-token:$token@github.com/o/r'),
      'https://x-access-token:***REDACTED***@github.com/o/r',
    );
    final password = 'p' * 400;
    expect(
      redactSecrets('postgres://admin:$password@db:5432/x'),
      'postgres://admin:***REDACTED***@db:5432/x',
    );
  });
}
