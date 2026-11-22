import 'package:cc_domain/core/domain/services/redaction/secret_scanner.dart';
import 'package:cc_domain/core/domain/services/redaction/token_patterns.dart';
import 'package:test/test.dart';

/// Synthetic credentials of every shape the table knows; none is real.
final Map<String, String> _synthetic = {
  'bearer token': 'Bearer ${'a' * 24}',
  'Anthropic API key': 'sk-ant-${'a' * 24}',
  'API key': 'sk-${'a' * 24}',
  'Google API key': 'AIza${'a' * 24}',
  'AWS access key': 'AKIA${'A' * 16}',
  'GitHub token': 'ghs_${'a' * 30}.${'b' * 10}',
  'GitLab token': 'glpat-${'a' * 20}',
  'Atlassian token': 'ATATT${'a' * 24}',
  'Slack token': 'xoxb-${'1' * 12}-${'a' * 12}',
  'Linear token': 'lin_oauth_${'a' * 24}',
  'Google OAuth token': 'ya29.${'a' * 24}',
  'JSON web token': 'eyJ${'a' * 10}.eyJ${'b' * 10}.${'c' * 10}',
  'private key':
      '-----BEGIN PRIVATE KEY-----\n${'A' * 40}\n-----END PRIVATE KEY-----',
};

void main() {
  test('every label in the table has a synthetic example here', () {
    expect({for (final p in kTokenPatterns) p.label}, _synthetic.keys.toSet());
  });

  for (final MapEntry(key: label, value: token) in _synthetic.entries) {
    test('$label is redacted and flagged', () {
      final line = 'calling with $token, then done.';
      final redacted = redactTokens(line);
      expect(redacted, isNot(contains(token)));
      expect(redacted, startsWith('calling with '));
      expect(redacted, endsWith(', then done.'));
      expect(
        const SecretScanner().scan(line).map((f) => f.reason),
        contains(label),
      );
    });
  }

  test('an sk- key is caught from 20 characters, not below', () {
    final shortest = 'sk-${'a' * 20}';
    expect(redactTokens('key $shortest.'), isNot(contains(shortest)));
    final tooShort = 'sk-${'a' * 19}';
    expect(redactTokens('key $tooShort.'), contains(tooShort));
  });

  test('a distinctive prefix is found glued to the letter or digit before '
      'it, in the vendor\'s own shape of the token', () {
    for (final token in [
      'sk-ant-api03-${'a1B2' * 23}AA',
      'sk-ant-admin01-${'a1B2' * 8}',
      'sk-ant-oat01-${'a1B2' * 8}',
      'ghp_${'A1' * 18}',
      'ghs_${'a1' * 18}',
      // The third smoke pass's token (F): 35 characters after `ghp_`.
      'ghp_Z08150QwErTyUiOpAsDfGhJkLzXcVbNm012',
      'github_pat_${'A1' * 11}_${'b2' * 29}c',
      'glpat-${'aB3-' * 5}',
      'gldt-${'aB3_' * 5}',
      'glpat-${'aB3-' * 7}.01${'a1' * 3}b',
      'glpat-${'aB3-' * 7}.01.${'a1' * 4}b',
      'xoxb-${'1' * 12}-${'2' * 13}-${'aB3' * 8}',
      'xoxp-${'1' * 11}-${'2' * 11}-${'3' * 13}-${'f0' * 16}',
      'xoxe.xoxp-1-${'A1' * 80}',
      'xoxe-1-${'A1' * 73}',
      'ya29.${'a0_B-' * 30}',
      // The reviewer's seventh round (MISS7): an installation token with its
      // app id and JWT, GitLab's own-length bodies, a legacy Slack app token
      // and a service account's Google token.
      'ghs_1234567_eyJ${'a1B2' * 9}.eyJ${'c3D4' * 20}.${'e5F_' * 50}',
      'glptt-${'0a1b' * 10}',
      'gloas-${'aB3-' * 16}',
      'glagent-${'aB3_' * 12}aB',
      'glimt-${'aB3-' * 6}a',
      'glcbt-64_${'aB3_' * 5}',
      'glrt-t1_${'aB3-' * 5}',
      'xoxa-2-${'aB3' * 13}a',
      'ya29.c.c0${'a0_B-' * 12}.${'a1' * 50}',
      'ya29.c.${'b2-' * 70}',
    ]) {
      for (final glue in ['x', '1', 'X_']) {
        final line = 'out $glue$token end';
        expect(redactTokens(line), 'out $glue[REDACTED] end', reason: line);
        expect(const SecretScanner().scan(line), isNotEmpty, reason: line);
      }
    }
  });

  test('glued to a word, a prefix followed by anything but the token\'s '
      'shape is an identifier, and stays', () {
    // The reviewer's sixth round: each was redacted by the seventh pass and
    // not at HEAD.
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
      'graphs_of_the_quarterly_numbers_v2',
      'const xoxo_messages_with_hugs = 1;',
      'xgithub_pat_like_a_variable_name_of_some_length_here',
      'xsk-ant-api03-short',
      'xglpat-${'a' * 21}',
      'xxoxe-1-${'A' * 99}',
      'xya29.${'a' * 63}',
      // One character short of each glued body the ninth pass added, or
      // not its alphabet.
      'xghs_1_eyJ${'a' * 7}.${'b' * 20}',
      'path/to/myghs_12_eyJ_notes.txt',
      'xglptt-${'g' * 40}',
      'xglptt-${'a' * 39}',
      'xgloas-${'a' * 63}',
      'xglagent-${'a' * 49}',
      'xglimt-${'a' * 24}',
      'xglcbt-64_${'a' * 19}',
      'xglrt-t1_${'a' * 19}',
      'xxoxa-2-${'a' * 29}',
      'xya29.c.${'a' * 63}',
    ]) {
      expect(redactTokens(text), text, reason: text);
      expect(const SecretScanner().scan(text), isEmpty, reason: text);
    }
  });

  test('after a word boundary every family matches as it did before the '
      'glued shapes', () {
    // HEAD's own matches, which the glued shapes must not narrow: a loose
    // body after a boundary is still taken.
    for (final token in [
      'sk-ant-${'a' * 20}',
      'ghs_${'a' * 30}.${'b' * 10}',
      'github_pat_like_is_not_a_secret_here_ok',
      'glpat-${'a' * 16}',
      'xoxb-${'a' * 8}',
      'xapp-${'1' * 8}',
      'ya29.${'a' * 20}',
    ]) {
      final line = 'npx changeset; $token end';
      expect(redactTokens(line), 'npx changeset; [REDACTED] end', reason: line);
    }
  });

  test('a short or separator-less prefix keeps its word boundary: glued, it '
      'is ordinary text or base64', () {
    for (final text in [
      'run the risk-assessment-framework-v2 task',
      'base64 QUJDAKIAABCDEFGHIJKLMNOP and xAIza${'a' * 24}',
      'flexapp-settings-panel',
      'kotlin_api_${'a' * 20}',
      'aBearer ${'a' * 24}',
      'xATATT${'a' * 24}',
    ]) {
      expect(redactTokens(text), text, reason: text);
    }
  });

  test('ordinary text is untouched', () {
    const text = 'gh pr view 42 --json title; see https://1.example/path';
    expect(redactTokens(text), text);
    expect(const SecretScanner().scan(text), isEmpty);
  });
}
