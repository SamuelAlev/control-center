import 'dart:convert';

import 'package:cc_server_core/src/evals/skill_evaluation_evidence.dart';
import 'package:test/test.dart';

void main() {
  const evidence = SkillEvaluationEvidence();

  test(
    'multibyte text and huge containers stay bounded and mark omissions',
    () {
      final projected = evidence.attempt({
        'attemptId': 'trial-1',
        'completed': true,
        'spentMicros': null,
        'unknowns': ['not observed'],
        'notes': '𐐀' * 4000,
        'toolEvents': List.generate(5000, (index) => {'name': 'tool-$index'}),
        'skillEvents': List.generate(5000, (index) => index),
      });
      expect(projected['attemptId'], 'trial-1');
      expect(projected['completed'], true);
      expect(projected['spentMicros'], isNull);
      expect(projected['unknowns'], ['not observed']);
      expect(projected['traceTruncated'], true);
      expect((projected['toolEvents'] as List).length, lessThan(5000));
      expect(
        utf8.encode(jsonEncode(projected)).length,
        lessThanOrEqualTo(SkillEvaluationEvidence.maxAttemptBytes),
      );

      final manyFields = evidence.project({
        'coverageComplete': false,
        'unknowns': ['unpriced'],
        for (var i = 0; i < 10000; i++) 'field$i': i,
      });
      expect(manyFields['coverageComplete'], false);
      expect(manyFields['unknowns'], ['unpriced']);
      expect(manyFields['traceTruncated'], true);
      expect(manyFields.length, lessThan(10000));
    },
  );

  test(
    'private material and absolute host paths never enter public evidence',
    () {
      final projected = evidence.project({
        'Prompt': 'private instruction',
        'hidden_oracle': 'expected secret answer',
        'inlineFiles': {'private.txt': 'confidential'},
        'message':
            'look at /opt/internal/config and /srv/private/keys, '
            '/Applications/Tools/private and C:\\Users\\private\\token',
        'artifact': 'artifacts/trials/answer.json',
        'url': 'https://example.test/relative/path',
        'long': 'top-secret-prompt-' * 1000,
        'diagnostic': 'password=hunter2',
        'credential': 'sk-test-secret',
      });
      final text = jsonEncode(projected);
      for (final secret in [
        'private instruction',
        'expected secret answer',
        'confidential',
        '/opt/internal',
        '/srv/private',
        '/Applications/Tools',
        r'C:\Users\private',
        'top-secret-prompt-',
        'sk-test-secret',
        'hunter2',
      ]) {
        expect(text, isNot(contains(secret)));
      }
      expect(projected['message'], contains('[HOST_PATH]'));
      expect(projected['message'], isNot(contains(r'C:\Users')));
      expect(projected['artifact'], 'artifacts/trials/answer.json');
      expect(projected['url'], 'https://example.test/relative/path');
      expect(projected['traceTruncated'], true);
    },
  );

  test(
    'partial export is valid bounded JSON with campaign and attempt coverage',
    () {
      final content = evidence.export({
        'campaign': {
          'id': 'campaign-1',
          'status': 'failed',
          'spentMicros': null,
          'completedAttempts': 57,
          'plannedAttempts': 60,
          'report': {
            'coverageComplete': false,
            'unknowns': ['cost unknown'],
          },
        },
        'attempts': List.generate(
          57,
          (index) => {
            'id': 'attempt-$index',
            'ordinal': index,
            'evidence': {
              'completed': index < 50,
              'spentMicros': null,
              'toolEvents': List.generate(100, (n) => {'name': 'call-$n'}),
            },
          },
        ),
      });
      final parsed = jsonDecode(content) as Map<String, dynamic>;
      expect(
        utf8.encode(content).length,
        lessThanOrEqualTo(SkillEvaluationEvidence.maxExportBytes),
      );
      expect((parsed['campaign'] as Map)['id'], 'campaign-1');
      expect((parsed['campaign'] as Map)['status'], 'failed');
      expect((parsed['campaign'] as Map)['completedAttempts'], 57);
      expect((parsed['campaign'] as Map)['spentMicros'], isNull);
      expect(parsed['attemptCount'], 57);
      expect(parsed['detailsOmitted'], true);
      expect(parsed['omittedAttemptCount'], 0);
      expect(
        (parsed['attempts'] as List).length + parsed['omittedAttemptCount'],
        57,
      );
      expect((parsed['attempts'] as List).first['id'], 'attempt-0');
    },
  );

  test(
    'lazy attempt and nested evidence iterables stop at projection limits',
    () {
      var converted = 0;
      final rows = Iterable.generate(1000000, (index) => index).map((index) {
        converted++;
        return {
          'id': 'attempt-$index',
          'evidence': {'completed': true},
        };
      });
      final exported =
          jsonDecode(
                evidence.export({
                  'campaign': {'id': 'campaign-lazy', 'status': 'completed'},
                  'attemptCount': 1000000,
                  'attempts': rows,
                }),
              )
              as Map<String, dynamic>;
      expect(converted, lessThanOrEqualTo(2048));
      expect(exported['attemptCount'], 1000000);
      expect(exported['omittedAttemptCount'], 1000000 - converted);
      expect((exported['attempts'] as List).length, converted);

      var visited = 0;
      final nested = evidence.project({
        'unknowns': Iterable.generate(100000, (index) {
          visited++;
          return 'unknown-$index';
        }),
        'coverageComplete': false,
      });
      expect(visited, lessThanOrEqualTo(65));
      expect(nested['traceTruncated'], true);
      expect(nested['coverageComplete'], false);
    },
  );

  test(
    'large campaigns retain every outcome and unknown charge by shortening traces',
    () {
      final trace = List.filled(16, 'explanation ${'x' * 7000}');
      final exported =
          jsonDecode(
                evidence.export({
                  'campaign': {
                    'id': 'large',
                    'completedAttempts': 960,
                    'spentMicros': null,
                  },
                  'attemptCount': 960,
                  'attempts': Iterable.generate(
                    960,
                    (index) => <String, dynamic>{
                      'id': 'attempt-$index',
                      'ordinal': index,
                      'evidence': {
                        'completed': true,
                        'verifiedSuccess': index.isEven,
                        'cost': {'known': false, 'executionMicros': null},
                        'tokens': {'uncachedInput': 12, 'output': 7},
                        'notes': trace,
                      },
                    },
                  ),
                }),
              )
              as Map<String, dynamic>;
      final attempts = exported['attempts'] as List;
      expect(attempts.map((row) => row['id']), [
        for (var i = 0; i < 960; i++) 'attempt-$i',
      ]);
      expect(exported['omittedAttemptCount'], 0);
      expect(exported['summarizedAttemptCount'], greaterThan(0));
      expect(exported['detailsOmitted'], true);
      expect(attempts.last['evidence']['verifiedSuccess'], false);
      expect(attempts.last['evidence']['cost']['known'], false);
      expect(attempts.last['evidence']['cost']['executionMicros'], isNull);
      expect(attempts.last['evidence']['tokens']['output'], 7);
      expect(
        utf8.encode(jsonEncode(exported)).length,
        lessThanOrEqualTo(SkillEvaluationEvidence.maxExportBytes),
      );
    },
  );

  test(
    'usage counters survive redaction while authentication tokens do not',
    () {
      final projected = evidence.attempt({
        'tokens': {'uncachedInput': 17, 'output': 5},
        'metrics': {'contextWindowTokens': 32000, 'promptTokens': 17},
        'refreshToken': 'private-refresh-value',
      });
      expect(projected['tokens'], {'uncachedInput': 17, 'output': 5});
      expect(projected['metrics'], {
        'contextWindowTokens': 32000,
        'promptTokens': 17,
      });
      expect(jsonEncode(projected), isNot(contains('private-refresh-value')));
    },
  );

  test(
    'export signals a shortened report even when every attempt is present',
    () {
      final exported =
          jsonDecode(
                evidence.export({
                  'campaign': {
                    'id': 'campaign-2',
                    'report': {
                      'coverageComplete': false,
                      'unknowns': ['not observed'],
                      'caveats': List.generate(200, (i) => 'caveat-$i'),
                    },
                  },
                  'attempts': [
                    {
                      'id': 'attempt-1',
                      'evidence': {'spentMicros': null},
                    },
                  ],
                }),
              )
              as Map<String, dynamic>;
      expect(exported['attemptCount'], 1);
      expect(exported['omittedAttemptCount'], 0);
      expect(exported['detailsOmitted'], true);
      expect(
        (exported['campaign'] as Map)['report']['coverageComplete'],
        false,
      );
      expect((exported['campaign'] as Map)['report']['unknowns'], [
        'not observed',
      ]);
    },
  );
}
