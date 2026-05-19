import 'package:cc_domain/features/pr_review/domain/usecases/build_github_review_use_case.dart';
import 'package:cc_domain/features/pr_review/domain/value_objects/review_node_payload.dart';
import 'package:cc_domain/features/pr_review/domain/value_objects/review_verdict.dart';
import 'package:cc_domain/features/pr_review/domain/value_objects/review_walkthrough_summary.dart';
import 'package:test/test.dart';

ReviewFindingDraft _draft({
  String? filePath,
  int? line,
  ReviewNodePriority priority = ReviewNodePriority.p2,
  String content = 'Missing null check on the parsed payload.',
}) => ReviewFindingDraft(
  payload: ReviewNodePayload(
    kind: ReviewNodeKind.bug,
    priority: priority,
    confidence: 0.8,
    anchor: ReviewNodeAnchor(filePath: filePath, lineNumber: line),
    status: ReviewNodeStatus.open,
  ),
  content: content,
);

void main() {
  const useCase = BuildGitHubReviewUseCase();

  const verdict = ReviewVerdict(
    overall: ReviewVerdictOverall.hold,
    confidence: 0.9,
    explanation: 'One P1 finding.',
    counts: {},
  );

  test(
    'renders the CodeRabbit-style summary + walkthrough before findings',
    () {
      const walkthrough = ReviewWalkthroughSummary(
        headline: 'Adds token refresh',
        areas: [
          ReviewWalkthroughArea(
            cohortKey: 'auth',
            title: 'Auth flow',
            bullets: ['New refresh endpoint'],
          ),
        ],
        riskNotes: ['Refresh token is now long-lived'],
      );

      final plan = useCase.execute(
        findings: [_draft(filePath: 'lib/auth.dart', line: 10)],
        verdict: verdict,
        walkthrough: walkthrough,
      );

      expect(plan.body, contains('## Summary'));
      expect(plan.body, contains('Adds token refresh'));
      expect(plan.body, contains('**Auth flow**'));
      expect(plan.body, contains('- New refresh endpoint'));
      expect(plan.body, contains('**Risks**'));
      expect(plan.body, contains('- Refresh token is now long-lived'));
      // Verdict banner still leads the body.
      expect(
        plan.body.indexOf('## Verdict'),
        lessThan(plan.body.indexOf('## Summary')),
      );
    },
  );

  test('groups findings by file, most severe first', () {
    final plan = useCase.execute(
      findings: [
        _draft(
          filePath: 'lib/b.dart',
          line: 3,
          priority: ReviewNodePriority.p2,
        ),
        _draft(
          filePath: 'lib/a.dart',
          line: 1,
          priority: ReviewNodePriority.p1,
        ),
        _draft(
          filePath: 'lib/a.dart',
          line: 9,
          priority: ReviewNodePriority.p0,
        ),
      ],
      verdict: verdict,
    );

    expect(plan.body, contains('## Findings by file (3)'));
    expect(plan.body, contains('### `lib/a.dart`'));
    expect(plan.body, contains('### `lib/b.dart`'));
    final aSection = plan.body.substring(
      plan.body.indexOf('### `lib/a.dart`'),
      plan.body.indexOf('### `lib/b.dart`'),
    );
    expect(aSection.indexOf('P0'), lessThan(aSection.indexOf('P1')));
  });

  test('unanchored findings stay in their own section, out of by-file', () {
    final plan = useCase.execute(
      findings: [
        _draft(filePath: 'lib/a.dart', line: 1),
        _draft(content: 'Repository-wide architecture note.'),
      ],
      verdict: verdict,
    );

    expect(plan.body, contains('## Findings not tied to a line (1)'));
    expect(plan.body, contains('Repository-wide architecture note.'));
    expect(plan.body, contains('## Findings by file (2)'));
  });

  test('inline comments are unaffected by the walkthrough', () {
    final plan = useCase.execute(
      findings: [_draft(filePath: 'lib/a.dart', line: 10)],
      verdict: verdict,
      walkthrough: const ReviewWalkthroughSummary(headline: 'h'),
    );

    expect(plan.inlineComments, hasLength(1));
    expect(plan.inlineComments.single.path, 'lib/a.dart');
    expect(plan.event, 'COMMENT');
  });
}
