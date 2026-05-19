import 'package:control_center/features/pr_review/domain/value_objects/github_review_plan.dart';
import 'package:flutter_test/flutter_test.dart';

// ─────────────────────────────────────────────────────────────────────────────
// GitHubInlineComment
// ─────────────────────────────────────────────────────────────────────────────

void main() {
  group('GitHubInlineComment', () {
    // ── constructor ──────────────────────────────────────────────────────

    test('constructs with required fields', () {
      const c = GitHubInlineComment(
        path: 'src/foo.dart',
        line: 42,
        body: 'nit: rename',
      );
      expect(c.path, 'src/foo.dart');
      expect(c.line, 42);
      expect(c.body, 'nit: rename');
      expect(c.side, 'RIGHT');
      expect(c.startLine, isNull);
      expect(c.startSide, isNull);
    });

    test('constructs with all fields', () {
      const c = GitHubInlineComment(
        path: 'src/bar.dart',
        line: 20,
        body: 'suggestion',
        side: 'LEFT',
        startLine: 15,
        startSide: 'LEFT',
      );
      expect(c.path, 'src/bar.dart');
      expect(c.line, 20);
      expect(c.body, 'suggestion');
      expect(c.side, 'LEFT');
      expect(c.startLine, 15);
      expect(c.startSide, 'LEFT');
    });

    // ── isMultiLine ──────────────────────────────────────────────────────

    test('isMultiLine is false when startLine is null', () {
      const c = GitHubInlineComment(path: 'a.dart', line: 1, body: 'hi');
      expect(c.isMultiLine, isFalse);
    });

    test('isMultiLine is false when startLine equals line', () {
      const c = GitHubInlineComment(
        path: 'a.dart',
        line: 5,
        body: 'hi',
        startLine: 5,
      );
      expect(c.isMultiLine, isFalse);
    });

    test('isMultiLine is true when startLine differs from line', () {
      const c = GitHubInlineComment(
        path: 'a.dart',
        line: 10,
        body: 'range',
        startLine: 5,
      );
      expect(c.isMultiLine, isTrue);
    });

    // ── toJson ───────────────────────────────────────────────────────────

    test('toJson single-line omits startLine and startSide', () {
      const c = GitHubInlineComment(
        path: 'main.dart',
        line: 3,
        body: 'todo',
      );
      final json = c.toJson();
      expect(json['path'], 'main.dart');
      expect(json['line'], 3);
      expect(json['side'], 'RIGHT');
      expect(json['body'], 'todo');
      expect(json.containsKey('start_line'), isFalse);
      expect(json.containsKey('start_side'), isFalse);
    });

    test('toJson multi-line includes start_line and start_side', () {
      const c = GitHubInlineComment(
        path: 'app.dart',
        line: 30,
        body: 'multi-line',
        startLine: 25,
        startSide: 'LEFT',
      );
      final json = c.toJson();
      expect(json['start_line'], 25);
      expect(json['start_side'], 'LEFT');
    });

    test('toJson multi-line defaults start_side to side when null', () {
      const c = GitHubInlineComment(
        path: 'lib.dart',
        line: 50,
        body: 'range',
        startLine: 40,
        side: 'RIGHT',
      );
      final json = c.toJson();
      expect(json['start_side'], 'RIGHT');
    });

    // ── equality ─────────────────────────────────────────────────────────

    test('identical instances are equal', () {
      const a = GitHubInlineComment(path: 'x', line: 1, body: 'b');
      const b = GitHubInlineComment(path: 'x', line: 1, body: 'b');
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('differs by path', () {
      const a = GitHubInlineComment(path: 'x', line: 1, body: 'b');
      const b = GitHubInlineComment(path: 'y', line: 1, body: 'b');
      expect(a, isNot(equals(b)));
    });

    test('differs by line', () {
      const a = GitHubInlineComment(path: 'x', line: 1, body: 'b');
      const b = GitHubInlineComment(path: 'x', line: 2, body: 'b');
      expect(a, isNot(equals(b)));
    });

    test('differs by body', () {
      const a = GitHubInlineComment(path: 'x', line: 1, body: 'b');
      const b = GitHubInlineComment(path: 'x', line: 1, body: 'c');
      expect(a, isNot(equals(b)));
    });

    test('differs by side', () {
      const a = GitHubInlineComment(path: 'x', line: 1, body: 'b');
      const b = GitHubInlineComment(
        path: 'x',
        line: 1,
        body: 'b',
        side: 'LEFT',
      );
      expect(a, isNot(equals(b)));
    });

    test('differs by startLine', () {
      const a = GitHubInlineComment(path: 'x', line: 1, body: 'b');
      const b = GitHubInlineComment(
        path: 'x',
        line: 1,
        body: 'b',
        startLine: 0,
      );
      expect(a, isNot(equals(b)));
    });

    test('differs by startSide', () {
      const a = GitHubInlineComment(path: 'x', line: 1, body: 'b');
      const b = GitHubInlineComment(
        path: 'x',
        line: 1,
        body: 'b',
        startSide: 'LEFT',
      );
      expect(a, isNot(equals(b)));
    });

    test('not equal to other types', () {
      const c = GitHubInlineComment(path: 'x', line: 1, body: 'b');
      expect(c, isNot(equals('string')));
      expect(c, isNot(equals(42)));
    });

    // ── hashCode ─────────────────────────────────────────────────────────

    test('hashCode is consistent across identical values with all fields', () {
      const a = GitHubInlineComment(
        path: 'f.dart',
        line: 99,
        body: 'review',
        side: 'LEFT',
        startLine: 90,
        startSide: 'RIGHT',
      );
      const b = GitHubInlineComment(
        path: 'f.dart',
        line: 99,
        body: 'review',
        side: 'LEFT',
        startLine: 90,
        startSide: 'RIGHT',
      );
      expect(a.hashCode, equals(b.hashCode));
    });
  });

  // ───────────────────────────────────────────────────────────────────────────
  // GitHubReviewPlan
  // ───────────────────────────────────────────────────────────────────────────

  group('GitHubReviewPlan', () {
    const sampleComment = GitHubInlineComment(
      path: 'src/main.dart',
      line: 10,
      body: 'Use const',
    );

    // ── constructor ──────────────────────────────────────────────────────

    test('constructs with required fields', () {
      const plan = GitHubReviewPlan(
        event: 'APPROVE',
        body: 'LGTM',
        inlineComments: [sampleComment],
      );
      expect(plan.event, 'APPROVE');
      expect(plan.body, 'LGTM');
      expect(plan.inlineComments, [sampleComment]);
    });

    test('constructs with empty inline comments', () {
      const plan = GitHubReviewPlan(
        event: 'COMMENT',
        body: 'Just a note',
        inlineComments: [],
      );
      expect(plan.inlineComments, isEmpty);
    });

    // ── flattenedToBody ──────────────────────────────────────────────────

    test('flattenedToBody returns self when no inline comments', () {
      const plan = GitHubReviewPlan(
        event: 'APPROVE',
        body: 'Looks great',
        inlineComments: [],
      );
      final flat = plan.flattenedToBody();
      expect(identical(flat, plan), isTrue);
    });

    test('flattenedToBody folds inline comments into body', () {
      const c1 = GitHubInlineComment(
        path: 'src/a.dart',
        line: 5,
        body: 'Fix this',
      );
      const c2 = GitHubInlineComment(
        path: 'src/b.dart',
        line: 10,
        body: 'And this',
        startLine: 8,
      );
      const plan = GitHubReviewPlan(
        event: 'REQUEST_CHANGES',
        body: 'Two issues found.',
        inlineComments: [c1, c2],
      );
      final flat = plan.flattenedToBody();
      expect(flat.event, 'REQUEST_CHANGES');
      expect(flat.inlineComments, isEmpty);
      expect(flat.body, contains('## Inline findings'));
      expect(flat.body, contains('src/a.dart:5'));
      expect(flat.body, contains('src/b.dart:8-10'));
      expect(flat.body, contains('Fix this'));
      expect(flat.body, contains('And this'));
    });

    test('flattenedToBody preserves original event', () {
      const plan = GitHubReviewPlan(
        event: 'COMMENT',
        body: 'Preview',
        inlineComments: [sampleComment],
      );
      final flat = plan.flattenedToBody();
      expect(flat.event, 'COMMENT');
    });

    group('flattenedToBody header behavior', () {
      test(
          'does not deduplicate "Inline findings" header '
          'when body already contains it', () {
        const plan = GitHubReviewPlan(
          event: 'COMMENT',
          body: 'Something\n## Inline findings',
          inlineComments: [sampleComment],
        );
        final flat = plan.flattenedToBody();
        // The body already had the header AND the method appends its own
        final count = '## Inline findings'.allMatches(flat.body).length;
        expect(count, 2);
      });
    });

    // ── equality ─────────────────────────────────────────────────────────

    test('identical instances are equal', () {
      const a = GitHubReviewPlan(
        event: 'APPROVE',
        body: 'LGTM',
        inlineComments: [sampleComment],
      );
      const b = GitHubReviewPlan(
        event: 'APPROVE',
        body: 'LGTM',
        inlineComments: [sampleComment],
      );
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('differs by event', () {
      const a = GitHubReviewPlan(
        event: 'APPROVE',
        body: 'x',
        inlineComments: [],
      );
      const b = GitHubReviewPlan(
        event: 'REQUEST_CHANGES',
        body: 'x',
        inlineComments: [],
      );
      expect(a, isNot(equals(b)));
    });

    test('differs by body', () {
      const a = GitHubReviewPlan(
        event: 'COMMENT',
        body: 'a',
        inlineComments: [],
      );
      const b = GitHubReviewPlan(
        event: 'COMMENT',
        body: 'b',
        inlineComments: [],
      );
      expect(a, isNot(equals(b)));
    });

    test('differs by inlineComments contents', () {
      const a = GitHubReviewPlan(
        event: 'COMMENT',
        body: 'x',
        inlineComments: [sampleComment],
      );
      const diffComment = GitHubInlineComment(
        path: 'src/other.dart',
        line: 1,
        body: 'different',
      );
      const b = GitHubReviewPlan(
        event: 'COMMENT',
        body: 'x',
        inlineComments: [diffComment],
      );
      expect(a, isNot(equals(b)));
    });

    test('differs by inlineComments length', () {
      const a = GitHubReviewPlan(
        event: 'COMMENT',
        body: 'x',
        inlineComments: [sampleComment],
      );
      const b = GitHubReviewPlan(
        event: 'COMMENT',
        body: 'x',
        inlineComments: [sampleComment, sampleComment],
      );
      expect(a, isNot(equals(b)));
    });

    test('not equal to other types', () {
      const plan = GitHubReviewPlan(
        event: 'COMMENT',
        body: 'x',
        inlineComments: [],
      );
      expect(plan, isNot(equals('COMMENT')));
      expect(plan, isNot(equals([])));
    });

    // ── hashCode ─────────────────────────────────────────────────────────

    test('hashCode is consistent across identical values', () {
      const a = GitHubReviewPlan(
        event: 'APPROVE',
        body: 'Ship it',
        inlineComments: [
          GitHubInlineComment(path: 'x', line: 1, body: 'nit'),
          GitHubInlineComment(path: 'y', line: 2, body: 'bug'),
        ],
      );
      const b = GitHubReviewPlan(
        event: 'APPROVE',
        body: 'Ship it',
        inlineComments: [
          GitHubInlineComment(path: 'x', line: 1, body: 'nit'),
          GitHubInlineComment(path: 'y', line: 2, body: 'bug'),
        ],
      );
      expect(a.hashCode, equals(b.hashCode));
    });

    test('empty comments vs non-empty produce different hashCodes', () {
      const a = GitHubReviewPlan(
        event: 'COMMENT',
        body: 'x',
        inlineComments: [],
      );
      const b = GitHubReviewPlan(
        event: 'COMMENT',
        body: 'x',
        inlineComments: [sampleComment],
      );
      expect(a.hashCode, isNot(equals(b.hashCode)));
    });
  });
}
