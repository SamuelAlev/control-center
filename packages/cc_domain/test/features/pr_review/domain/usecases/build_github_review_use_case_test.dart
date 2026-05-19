import 'package:cc_domain/features/pr_review/domain/services/diff_anchor_index.dart';
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
  String? messageId,
  ReviewFindingCategory? category,
  ReviewFindingSeverity? severity,
  ReviewFindingEffort? effort,
  String? fixDiff,
  String? aiPrompt,
  String? fixSuggestion,
  int? lineEnd,
}) => ReviewFindingDraft(
  payload: ReviewNodePayload(
    kind: ReviewNodeKind.bug,
    priority: severity?.toPriority() ?? priority,
    confidence: 0.8,
    anchor: ReviewNodeAnchor(
      filePath: filePath,
      lineNumber: line,
      lineEnd: lineEnd,
    ),
    status: ReviewNodeStatus.open,
    category: category,
    severity: severity,
    effort: effort,
    fixDiff: fixDiff,
    fixSuggestion: fixSuggestion,
    aiPrompt: aiPrompt,
  ),
  content: content,
  messageId: messageId,
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
    'renders the walkthrough summary before findings',
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
    // Severity names, not P-tags: the published review speaks one vocabulary.
    // p0 renders as Critical, p1 as Major — and Critical must come first.
    expect(
      aSection.indexOf('Critical'),
      lessThan(aSection.indexOf('Major')),
    );
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

  group('structured finding bodies', () {
    test('leads with the three-axis triage line', () {
      final plan = useCase.execute(
        findings: [
          _draft(
            filePath: 'lib/a.dart',
            line: 10,
            category: ReviewFindingCategory.security,
            severity: ReviewFindingSeverity.critical,
            effort: ReviewFindingEffort.quickWin,
          ),
        ],
        verdict: verdict,
      );
      final body = plan.inlineComments.single.body;
      expect(body.split('\n').first, contains('Security'));
      expect(body.split('\n').first, contains('Critical'));
      expect(body.split('\n').first, contains('Quick win'));
      expect(body.split('\n').first, contains('|'));
    });

    test('a legacy finding still renders a severity from its priority', () {
      // Category and effort are omitted rather than guessed; severity always
      // renders because every finding has an effective one.
      final plan = useCase.execute(
        findings: [
          _draft(
            filePath: 'lib/a.dart',
            line: 10,
            priority: ReviewNodePriority.p0,
          ),
        ],
        verdict: verdict,
      );
      final first = plan.inlineComments.single.body.split('\n').first;
      expect(first, contains('Critical'));
      expect(first, isNot(contains('|')));
    });

    test('renders a proposed fix as a collapsed diff block', () {
      final plan = useCase.execute(
        findings: [
          _draft(
            filePath: 'lib/a.dart',
            line: 10,
            fixDiff: '- await x;\n+ await x.close();',
          ),
        ],
        verdict: verdict,
      );
      final body = plan.inlineComments.single.body;
      expect(body, contains('<summary>Proposed fix</summary>'));
      expect(body, contains('```diff'));
      expect(body, contains('+ await x.close();'));
    });

    test('strips a fence the reviewer wrapped the diff in', () {
      // Otherwise the nested fence closes our block early and spills raw
      // markdown into the comment.
      final plan = useCase.execute(
        findings: [
          _draft(
            filePath: 'lib/a.dart',
            line: 10,
            fixDiff: '```diff\n- a\n+ b\n```',
          ),
        ],
        verdict: verdict,
      );
      final body = plan.inlineComments.single.body;
      expect('```'.allMatches(body).length, 2);
    });

    test('wraps the agent prompt in the standing guard preamble', () {
      final plan = useCase.execute(
        findings: [
          _draft(
            filePath: 'lib/a.dart',
            line: 10,
            lineEnd: 14,
            aiPrompt: 'Close the client before returning.',
          ),
        ],
        verdict: verdict,
      );
      final body = plan.inlineComments.single.body;
      expect(body, contains('<summary>Prompt for AI agents</summary>'));
      expect(body, contains(kAiAgentPromptGuardPreamble));
      // The location comes from the stored anchor, not from the model's text.
      expect(body, contains('In `lib/a.dart` around lines 10-14:'));
      expect(body, contains('Close the client before returning.'));
    });

    test('omits both blocks when the reviewer supplied neither', () {
      final plan = useCase.execute(
        findings: [_draft(filePath: 'lib/a.dart', line: 10)],
        verdict: verdict,
      );
      final body = plan.inlineComments.single.body;
      expect(body, isNot(contains('<details>')));
      expect(body, contains(BuildGitHubReviewUseCase.inlineFooter));
    });
  });

  group('nitpick demotion', () {
    List<ReviewFindingDraft> drafts() => [
      _draft(filePath: 'lib/a.dart', line: 10, messageId: 'keep'),
      _draft(
        filePath: 'lib/b.dart',
        line: 20,
        messageId: 'nit',
        content: 'Rename the local for clarity.',
        severity: ReviewFindingSeverity.trivial,
      ),
    ];

    test('keeps demoted findings out of the inline comments', () {
      // An inline comment is the most intrusive thing a review can do to a
      // diff; the level decides what earns one.
      final plan = useCase.execute(
        findings: drafts(),
        verdict: verdict,
        nitpickMessageIds: const {'nit'},
      );
      expect(plan.inlineComments, hasLength(1));
      expect(plan.inlineComments.single.path, 'lib/a.dart');
    });

    test('renders them in a collapsed, counted group in the body', () {
      final plan = useCase.execute(
        findings: drafts(),
        verdict: verdict,
        nitpickMessageIds: const {'nit'},
      );
      expect(plan.body, contains('<summary>Nitpicks (1)</summary>'));
      // Published in full — demoted, not dropped.
      expect(plan.body, contains('Rename the local for clarity.'));
      expect(plan.body, contains('lib/b.dart:20'));
    });

    test('demoted findings are excluded from the by-file listing', () {
      final plan = useCase.execute(
        findings: drafts(),
        verdict: verdict,
        nitpickMessageIds: const {'nit'},
      );
      expect(plan.body, contains('Findings by file (1)'));
    });

    test('publishes everything inline when nothing is demoted', () {
      final plan = useCase.execute(findings: drafts(), verdict: verdict);
      expect(plan.inlineComments, hasLength(2));
      expect(plan.body, isNot(contains('Nitpicks')));
    });

    test('a finding with no message id is never demoted', () {
      // Matching on rendered text instead of the id is how the two surfaces
      // would drift apart, so an unidentified finding stays promoted.
      final plan = useCase.execute(
        findings: [_draft(filePath: 'lib/a.dart', line: 10)],
        verdict: verdict,
        nitpickMessageIds: const {'nit'},
      );
      expect(plan.inlineComments, hasLength(1));
    });
  });

  group('published body', () {
    test('carries the narrative and the effort line, not a files table', () {
      // GitHub already lists the changed files directly above this comment. A
      // second copy in prose is the restatement that makes bot output read as
      // filler, so the table stays on the review tab.
      final plan = useCase.execute(
        findings: [_draft(filePath: 'lib/a.dart', line: 10)],
        verdict: verdict,
        walkthrough: const ReviewWalkthroughSummary(
          headline: 'Adds token refresh',
          effortScore: 3,
          effortMinutes: 25,
          areas: [
            ReviewWalkthroughArea(
              cohortKey: 'auth',
              title: 'Auth flow',
              bullets: ['Refreshes the token before expiry.'],
              files: ['lib/auth.dart', 'lib/token.dart'],
            ),
          ],
        ),
      );
      expect(plan.body, contains('Adds token refresh'));
      expect(plan.body, contains('Auth flow'));
      expect(plan.body, contains('Refreshes the token before expiry.'));
      expect(plan.body, contains('Estimated review effort'));
      expect(plan.body, isNot(contains('| Area | Files | Summary |')));
      expect(plan.body, isNot(contains('lib/token.dart')));
    });

    test('a clean, shipping review is one line', () {
      // The most-read review is the clean one. A reader who has to scroll to
      // learn nothing was found stops opening them.
      final plan = useCase.execute(
        findings: const [],
        verdict: const ReviewVerdict(
          overall: ReviewVerdictOverall.ship,
          confidence: 0.9,
          explanation: 'Nothing outstanding.',
          counts: {},
        ),
      );
      final lines = plan.body
          .split('\n')
          .where((l) => l.trim().isNotEmpty)
          .toList();
      expect(plan.body, contains('No issues found.'));
      expect(plan.body, isNot(contains('Verdict')));
      expect(plan.body, isNot(contains('Findings by file')));
      expect(lines, hasLength(2)); // the line, and the attribution footer
    });

    test('a blocked review with no findings still explains itself', () {
      // The block came from a failing gate. "No issues found" over the top of
      // a blocked pull request is the one shortening that would be a lie.
      final plan = useCase.execute(
        findings: const [],
        verdict: const ReviewVerdict(
          overall: ReviewVerdictOverall.block,
          confidence: 0.9,
          explanation: 'The API contract axis is failing.',
          counts: {},
        ),
      );
      expect(plan.body, contains('Verdict'));
      expect(plan.body, contains('The API contract axis is failing.'));
      expect(plan.body, isNot(contains('No issues found')));
    });

    test('a review with only nitpicks still renders in full', () {
      final plan = useCase.execute(
        findings: [_draft(filePath: 'lib/b.dart', line: 2, messageId: 'nit')],
        verdict: verdict,
        nitpickMessageIds: const {'nit'},
      );
      expect(plan.body, contains('Verdict'));
      expect(plan.body, contains('Nitpicks (1)'));
    });
  });

  group('committable suggestion', () {
    test('renders the reviewer\'s exact replacement lines last', () {
      final plan = useCase.execute(
        findings: [
          _draft(
            filePath: 'lib/a.dart',
            line: 10,
            aiPrompt: 'Close the client.',
            fixSuggestion: '      await client.close();',
          ),
        ],
        verdict: verdict,
      );
      final body = plan.inlineComments.single.body;
      expect(body, contains('```suggestion'));
      expect(body, contains('await client.close();'));
      // Prose first, patch second: the suggestion comes after the collapsed
      // agent prompt.
      expect(
        body.indexOf('```suggestion'),
        greaterThan(body.indexOf('Prompt for AI agents')),
      );
    });

    test('omits the block when the reviewer supplied no replacement', () {
      final plan = useCase.execute(
        findings: [_draft(filePath: 'lib/a.dart', line: 10)],
        verdict: verdict,
      );
      expect(plan.inlineComments.single.body, isNot(contains('```suggestion')));
    });

    test('records the confidence as machine-readable metadata', () {
      // Invisible to a reader, mineable later — the only way to tune the
      // confidence gate on evidence rather than taste.
      final plan = useCase.execute(
        findings: [_draft(filePath: 'lib/a.dart', line: 10)],
        verdict: verdict,
      );
      expect(
        plan.inlineComments.single.body,
        contains('<!-- cc-review: confidence=0.80'),
      );
    });
  });

  group('anchors verified against the current diff', () {
    // Publishing can happen long after the review ran. A comment on a line the
    // author has since rewritten is the most trust-destroying thing a reviewer
    // can leave — and GitHub would reject it at submit time anyway.
    final anchors = DiffAnchorIndex.fromPatches({
      'lib/a.dart': '@@ -8,2 +8,3 @@\n   keep();\n+  added();\n',
    });

    test('a finding on a changed line still posts inline', () {
      final plan = useCase.execute(
        findings: [_draft(filePath: 'lib/a.dart', line: 9)],
        verdict: verdict,
        anchors: anchors,
      );
      expect(plan.inlineComments, hasLength(1));
    });

    test('a finding on an untouched line moves into the body', () {
      final plan = useCase.execute(
        findings: [_draft(filePath: 'lib/a.dart', line: 400)],
        verdict: verdict,
        anchors: anchors,
      );
      expect(plan.inlineComments, isEmpty);
      // Moved, not dropped — it may still be true.
      expect(plan.body, contains('Findings not tied to a line (1)'));
    });

    test('a finding on a file the PR never touched moves into the body', () {
      final plan = useCase.execute(
        findings: [_draft(filePath: 'lib/elsewhere.dart', line: 9)],
        verdict: verdict,
        anchors: anchors,
      );
      expect(plan.inlineComments, isEmpty);
      expect(plan.body, contains('Findings not tied to a line (1)'));
    });

    test('everything posts inline when the diff could not be read', () {
      // One failed API call must not turn into a review that looks empty.
      final plan = useCase.execute(
        findings: [_draft(filePath: 'lib/elsewhere.dart', line: 400)],
        verdict: verdict,
        anchors: DiffAnchorIndex.permissive,
      );
      expect(plan.inlineComments, hasLength(1));
    });
  });
}
