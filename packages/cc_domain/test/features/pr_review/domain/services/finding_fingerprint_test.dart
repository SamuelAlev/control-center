import 'package:cc_domain/features/pr_review/domain/services/finding_fingerprint.dart';
import 'package:cc_domain/features/pr_review/domain/value_objects/review_node_payload.dart';
import 'package:test/test.dart';

const _fp = FindingFingerprinter();

FindingFingerprint print_({
  required String id,
  required String title,
  String? filePath = 'lib/auth.dart',
  ReviewNodeKind kind = ReviewNodeKind.bug,
  ReviewNodeStatus status = ReviewNodeStatus.open,
  String ruleId = '',
}) => FindingFingerprint(
  fingerprint: _fp.fingerprintOf(
    filePath: filePath,
    kind: kind,
    title: title,
    ruleId: ruleId,
  ),
  messageId: id,
  title: title,
  filePath: filePath,
  kind: kind,
  status: status,
  ruleId: ruleId,
);

void main() {
  group('normalizeTitle', () {
    test('drops stop words, punctuation and numbers', () {
      expect(normalizeTitle('The missing null check on line 42!'), {
        'missing',
        'null',
        'check',
        'line',
      });
    });

    test('drops inline code spans, which are usually identifiers', () {
      expect(normalizeTitle('Guard `authService.refresh` here'), {
        'guard',
        'here',
      });
    });

    test('is case-insensitive', () {
      expect(normalizeTitle('MISSING Check'), normalizeTitle('missing check'));
    });
  });

  group('fingerprintOf', () {
    test('ignores line numbers quoted in the title', () {
      final a = _fp.fingerprintOf(
        filePath: 'lib/a.dart',
        kind: ReviewNodeKind.bug,
        title: 'Missing null check at line 42',
      );
      final b = _fp.fingerprintOf(
        filePath: 'lib/a.dart',
        kind: ReviewNodeKind.bug,
        title: 'Missing null check at line 907',
      );
      expect(a, b);
    });

    test('separates different files', () {
      final a = _fp.fingerprintOf(
        filePath: 'lib/a.dart',
        kind: ReviewNodeKind.bug,
        title: 'Missing null check',
      );
      final b = _fp.fingerprintOf(
        filePath: 'lib/b.dart',
        kind: ReviewNodeKind.bug,
        title: 'Missing null check',
      );
      expect(a, isNot(b));
    });

    test('separates different kinds', () {
      final bug = _fp.fingerprintOf(
        filePath: 'lib/a.dart',
        kind: ReviewNodeKind.bug,
        title: 'Same words entirely',
      );
      final suggestion = _fp.fingerprintOf(
        filePath: 'lib/a.dart',
        kind: ReviewNodeKind.suggestion,
        title: 'Same words entirely',
      );
      expect(bug, isNot(suggestion));
    });

    test('a rule id replaces the title entirely', () {
      final a = _fp.fingerprintOf(
        filePath: 'lib/a.dart',
        kind: ReviewNodeKind.bug,
        title: 'Downloads and pipes a remote script',
        ruleId: 'curl_pipe_shell',
      );
      final b = _fp.fingerprintOf(
        filePath: 'lib/a.dart',
        kind: ReviewNodeKind.bug,
        title: 'Completely different wording',
        ruleId: 'curl_pipe_shell',
      );
      expect(a, b, reason: 'the rule is the identity, not the message');
    });

    test('an unanchored finding still fingerprints', () {
      final fp = _fp.fingerprintOf(
        kind: ReviewNodeKind.recommendation,
        title: 'Consider splitting this package',
      );
      expect(fp, isNotEmpty);
    });
  });

  group('classify', () {
    test('an empty previous pass makes everything new', () {
      final delta = _fp.classify(
        previous: const [],
        current: [print_(id: 'a', title: 'Missing null check')],
      );
      expect(delta.newFindings, hasLength(1));
      expect(delta.resolvedSinceLast, isEmpty);
    });

    test('an exact restatement is still-open, not new', () {
      final previous = [print_(id: 'a', title: 'Missing null check')];
      final delta = _fp.classify(
        previous: previous,
        current: [print_(id: 'b', title: 'Missing null check')],
      );
      expect(delta.stillOpen, hasLength(1));
      expect(delta.newFindings, isEmpty);
      expect(delta.stillOpenMessageIds, {'b'});
    });

    test('a lightly reworded finding matches fuzzily', () {
      final previous = [
        print_(id: 'a', title: 'Missing null check before dereference'),
      ];
      final delta = _fp.classify(
        previous: previous,
        current: [
          print_(id: 'b', title: 'Missing null check before the dereference'),
        ],
      );
      expect(delta.stillOpen, hasLength(1));
    });

    test('a heavily reworded finding is reported as new, not merged', () {
      final previous = [print_(id: 'a', title: 'Missing null check')];
      final delta = _fp.classify(
        previous: previous,
        current: [print_(id: 'b', title: 'Race condition in the token cache')],
      );
      expect(
        delta.newFindings,
        hasLength(1),
        reason: 'over-reporting new beats silently merging distinct findings',
      );
      expect(delta.resolvedSinceLast, hasLength(1));
    });

    test('a finding moved to another file counts as new', () {
      final previous = [
        print_(id: 'a', title: 'Missing null check', filePath: 'lib/a.dart'),
      ];
      final delta = _fp.classify(
        previous: previous,
        current: [
          print_(id: 'b', title: 'Missing null check', filePath: 'lib/b.dart'),
        ],
      );
      expect(delta.newFindings, hasLength(1));
    });

    test('a previous finding gone from this pass is resolved', () {
      final previous = [print_(id: 'a', title: 'Missing null check')];
      final delta = _fp.classify(previous: previous, current: const []);
      expect(delta.resolvedSinceLast, hasLength(1));
    });

    test('a carried finding now marked resolved counts as resolved', () {
      final previous = [print_(id: 'a', title: 'Missing null check')];
      final delta = _fp.classify(
        previous: previous,
        current: [
          print_(
            id: 'b',
            title: 'Missing null check',
            status: ReviewNodeStatus.resolved,
          ),
        ],
      );
      expect(delta.resolvedSinceLast, hasLength(1));
      expect(delta.stillOpen, isEmpty);
    });

    test('a previously dismissed finding is settled history', () {
      final previous = [
        print_(id: 'a', title: 'Style nit', status: ReviewNodeStatus.dismissed),
      ];
      final delta = _fp.classify(previous: previous, current: const []);
      expect(
        delta.resolvedSinceLast,
        isEmpty,
        reason: 'a finding already dismissed cannot be resolved again',
      );
    });

    test('each previous finding matches at most once', () {
      final previous = [print_(id: 'a', title: 'Missing null check')];
      final delta = _fp.classify(
        previous: previous,
        current: [
          print_(id: 'b', title: 'Missing null check'),
          print_(id: 'c', title: 'Missing null check'),
        ],
      );
      expect(delta.stillOpen, hasLength(1));
      expect(delta.newFindings, hasLength(1));
    });

    test('consensus-ready counts as open', () {
      final previous = [
        print_(
          id: 'a',
          title: 'Missing null check',
          status: ReviewNodeStatus.consensusReady,
        ),
      ];
      final delta = _fp.classify(previous: previous, current: const []);
      expect(delta.resolvedSinceLast, hasLength(1));
    });
  });

  group('FindingFingerprint JSON', () {
    test('round-trips', () {
      final original = print_(id: 'a', title: 'Missing null check');
      final restored = FindingFingerprint.fromJson(original.toJson())!;
      expect(restored.fingerprint, original.fingerprint);
      expect(restored.messageId, 'a');
      expect(restored.kind, ReviewNodeKind.bug);
      expect(restored.status, ReviewNodeStatus.open);
    });

    test('returns null without a fingerprint', () {
      expect(FindingFingerprint.fromJson(const {'title': 'x'}), isNull);
    });
  });
}
