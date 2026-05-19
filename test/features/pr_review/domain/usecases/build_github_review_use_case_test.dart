import 'package:cc_domain/features/pr_review/domain/usecases/build_github_review_use_case.dart';
import 'package:cc_domain/features/pr_review/domain/value_objects/review_node_payload.dart';
import 'package:cc_domain/features/pr_review/domain/value_objects/review_verdict.dart';
import 'package:flutter_test/flutter_test.dart';

ReviewVerdict _verdict(
  ReviewVerdictOverall overall, {
  int p0 = 0,
  int p1 = 0,
  int p2 = 0,
  int p3 = 0,
  double confidence = 0.9,
}) {
  return ReviewVerdict(
    overall: overall,
    confidence: confidence,
    explanation: 'because',
    counts: {
      ReviewNodePriority.p0: p0,
      ReviewNodePriority.p1: p1,
      ReviewNodePriority.p2: p2,
      ReviewNodePriority.p3: p3,
    },
  );
}

ReviewFindingDraft _finding({
  ReviewNodeKind kind = ReviewNodeKind.bug,
  ReviewNodePriority priority = ReviewNodePriority.p1,
  double confidence = 0.8,
  String? filePath,
  int? lineNumber,
  int? lineEnd,
  String content = 'Something is wrong here.',
}) {
  return ReviewFindingDraft(
    payload: ReviewNodePayload(
      kind: kind,
      priority: priority,
      confidence: confidence,
      anchor: ReviewNodeAnchor(
        filePath: filePath,
        lineNumber: lineNumber,
        lineEnd: lineEnd,
      ),
      status: ReviewNodeStatus.open,
    ),
    content: content,
  );
}

void main() {
  const useCase = BuildGitHubReviewUseCase();

  group('event mapping', () {
    test('block verdict → REQUEST_CHANGES', () {
      final plan = useCase.execute(
        findings: const [],
        verdict: _verdict(ReviewVerdictOverall.block, p0: 1),
      );
      expect(plan.event, 'REQUEST_CHANGES');
    });

    test('hold verdict → COMMENT', () {
      final plan = useCase.execute(
        findings: const [],
        verdict: _verdict(ReviewVerdictOverall.hold, p1: 1),
      );
      expect(plan.event, 'COMMENT');
    });

    test('ship verdict → COMMENT by default, APPROVE when opted in', () {
      final ship = _verdict(ReviewVerdictOverall.ship);
      expect(
        useCase.execute(findings: const [], verdict: ship).event,
        'COMMENT',
      );
      expect(
        useCase
            .execute(findings: const [], verdict: ship, approveOnShip: true)
            .event,
        'APPROVE',
      );
    });
  });

  group('anchoring', () {
    test('finding with file + line becomes a single-line inline comment', () {
      final plan = useCase.execute(
        findings: [
          _finding(filePath: 'lib/a.dart', lineNumber: 12, content: 'Null deref'),
        ],
        verdict: _verdict(ReviewVerdictOverall.hold, p1: 1),
      );
      expect(plan.inlineComments, hasLength(1));
      final c = plan.inlineComments.single;
      expect(c.path, 'lib/a.dart');
      expect(c.line, 12);
      expect(c.startLine, isNull);
      expect(c.side, 'RIGHT');
      expect(c.body, contains('Null deref'));
      expect(c.body, contains('[P1]'));
      expect(c.body, contains(BuildGitHubReviewUseCase.inlineFooter));
    });

    test('finding with a line range maps line=end, start_line=start', () {
      final plan = useCase.execute(
        findings: [
          _finding(filePath: 'lib/a.dart', lineNumber: 10, lineEnd: 14),
        ],
        verdict: _verdict(ReviewVerdictOverall.hold, p1: 1),
      );
      final c = plan.inlineComments.single;
      expect(c.line, 14);
      expect(c.startLine, 10);
      expect(c.isMultiLine, isTrue);
      expect(c.toJson()['start_line'], 10);
      expect(c.toJson()['line'], 14);
    });

    test('finding without a line goes to the body, not inline', () {
      final plan = useCase.execute(
        findings: [
          _finding(filePath: 'lib/a.dart', content: 'Repo-wide concern'),
          _finding(content: 'No file at all'),
        ],
        verdict: _verdict(ReviewVerdictOverall.hold, p1: 2),
      );
      expect(plan.inlineComments, isEmpty);
      expect(plan.body, contains('Findings not tied to a line (2)'));
      expect(plan.body, contains('Repo-wide concern'));
      expect(plan.body, contains('lib/a.dart'));
    });

    test('body always carries the verdict banner', () {
      final plan = useCase.execute(
        findings: const [],
        verdict: _verdict(ReviewVerdictOverall.block, p0: 2, confidence: 0.95),
      );
      expect(plan.body, contains('Verdict'));
      expect(plan.body, contains('Block'));
      expect(plan.body, contains('95% confidence'));
      expect(plan.body, contains('P0: 2'));
    });
  });

  group('flattenedToBody fallback', () {
    test('folds inline comments into the body and clears them', () {
      final plan = useCase.execute(
        findings: [
          _finding(filePath: 'lib/a.dart', lineNumber: 5, content: 'Bug A'),
          _finding(filePath: 'lib/b.dart', lineNumber: 9, content: 'Bug B'),
        ],
        verdict: _verdict(ReviewVerdictOverall.block, p1: 2),
      );
      expect(plan.inlineComments, hasLength(2));

      final flat = plan.flattenedToBody();
      expect(flat.inlineComments, isEmpty);
      expect(flat.event, plan.event);
      expect(flat.body, contains('Inline findings'));
      expect(flat.body, contains('lib/a.dart:5'));
      expect(flat.body, contains('Bug A'));
      expect(flat.body, contains('lib/b.dart:9'));
      expect(flat.body, contains('Bug B'));
    });

    test('flattening an already-bodyonly plan is a no-op', () {
      final plan = useCase.execute(
        findings: const [],
        verdict: _verdict(ReviewVerdictOverall.ship),
      );
      expect(identical(plan.flattenedToBody(), plan), isTrue);
    });
  });
}
