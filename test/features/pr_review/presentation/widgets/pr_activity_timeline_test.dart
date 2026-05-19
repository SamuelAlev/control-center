import 'package:cc_domain/core/domain/entities/workspace.dart';
import 'package:cc_domain/features/pr_review/domain/entities/issue_comment.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pr_code_review_comment.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pr_commit.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pr_file.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pr_review_submission.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pr_timeline_event.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pr_user.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pull_request.dart';
import 'package:cc_domain/features/pr_review/domain/entities/reaction_group.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/core/theme/font_settings.dart';
import 'package:control_center/features/pr_review/presentation/widgets/pr_activity_timeline.dart';
import 'package:control_center/features/pr_review/providers/pr_review_providers.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:control_center/shared/widgets/github_user_mention.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

final _t0 = DateTime(2024, 6, 15, 12);

PullRequest _pr() => PullRequest(
  id: 7,
  number: 7,
  title: 'Add new feature',
  body: 'Body',
  state: PrState.open,
  isDraft: false,
  author: const PrUser(login: 'alice', avatarUrl: ''),
  createdAt: _t0,
  updatedAt: _t0,
  repoFullName: 'owner/repo',
  htmlUrl: 'https://github.com/owner/repo/pull/7',
  commitsCount: 2,
);

/// The PR identity the timeline (and its keyed provider overrides) uses.
const _prRef = (workspaceId: 'ws', repoFullName: 'owner/repo', number: 7);

class _NullWorkspaceIdNotifier extends ActiveWorkspaceIdNotifier {
  @override
  String? build() => null;
}

Widget _wrap(Widget child) {
  return ProviderScope(
    overrides: [
      prReviewCommentsProvider(_prRef).overrideWith(
        (ref) => Stream.value([
          PrCodeReviewComment(
            id: 100,
            body: 'inline note',
            user: const PrUser(login: 'krishna', avatarUrl: ''),
            path: 'lib/b.dart',
            position: 1,
            line: 1,
            createdAt: _t0.add(const Duration(hours: 4)),
            reviewId: 1,
          ),
          // A reply, submitted with a LATER review: it belongs to the
          // conversation above, not to a timeline entry of its own.
          PrCodeReviewComment(
            id: 101,
            body: 'good catch',
            user: const PrUser(login: 'alexandra', avatarUrl: ''),
            path: 'lib/b.dart',
            position: 1,
            line: 1,
            inReplyToId: 100,
            createdAt: _t0.add(const Duration(hours: 5)),
            reviewId: 9,
          ),
          // OUTDATED: no anchor line, so the diff cannot place it at all and
          // the timeline is the only place it can be read.
          PrCodeReviewComment(
            id: 102,
            body: 'this code is gone now',
            user: const PrUser(login: 'krishna', avatarUrl: ''),
            path: 'lib/gone.dart',
            position: null,
            diffHunk: '@@ -1,2 +1,2 @@\n-old line\n+new line',
            createdAt: _t0.add(const Duration(hours: 4)),
            reviewId: 1,
          ),
        ]),
      ),
      prFilesProvider(_prRef).overrideWith(
        (ref) => Stream.value([
          PrFile(
            filename: 'lib/a.dart',
            status: PrFileStatus.modified,
            additions: 1,
            deletions: 0,
            patch: '',
          ),
          PrFile(
            filename: 'lib/b.dart',
            status: PrFileStatus.modified,
            additions: 1,
            deletions: 0,
            patch: '',
          ),
        ]),
      ),
      codeFontFamilyProvider.overrideWithValue('Fira Code'),
      activeWorkspaceIdProvider.overrideWith(_NullWorkspaceIdNotifier.new),
      activeWorkspaceProvider.overrideWith((ref) => null),
      activeRepoProvider.overrideWith((ref) => null),
      workspacesProvider.overrideWith(
        (ref) => const Stream<List<Workspace>>.empty(),
      ),
      prReviewsProvider(_prRef).overrideWith(
        (ref) => Stream.value([
          PrReviewSubmission(
            id: 1,
            state: PrReviewSubmissionState.approved,
            author: const PrUser(login: 'krishna', avatarUrl: ''),
            body: 'looks good!',
            submittedAt: _t0.add(const Duration(hours: 4)),
            // A reaction joined in from GraphQL: the review summary is a
            // comment card on GitHub and carries reactions like one.
            reactions: const [
              ReactionGroup(
                content: '+1',
                emoji: '👍',
                count: 2,
                userReacted: false,
                usernames: ['matias', 'sam'],
              ),
            ],
          ),
          PrReviewSubmission(
            id: 2,
            state: PrReviewSubmissionState.approved,
            author: const PrUser(login: 'matias', avatarUrl: ''),
            body: '',
            submittedAt: _t0.add(const Duration(hours: 16)),
          ),
          // A review that ONLY replied to an earlier conversation: it starts no
          // thread of its own, so without the reply reference its entry is a
          // bare "reviewed" row with the words nowhere in sight.
          PrReviewSubmission(
            id: 9,
            state: PrReviewSubmissionState.commented,
            author: const PrUser(login: 'alexandra', avatarUrl: ''),
            body: '',
            submittedAt: _t0.add(const Duration(hours: 5)),
          ),
        ]),
      ),
      prIssueCommentsProvider(_prRef).overrideWith(
        (ref) => Stream.value([
          IssueComment(
            id: 22,
            body: '## Quality Gate failed\n\n- 77.2% coverage on new code',
            user: const PrUser(login: 'sonarqubecloud[bot]', avatarUrl: ''),
            createdAt: _t0.add(const Duration(hours: 2)),
          ),
        ]),
      ),
      prCommitsProvider(_prRef).overrideWith(
        (ref) => Stream.value([
          PrCommit(
            sha: '845facb1234',
            message: 'refactor: introduce overrides in sidebar',
            author: const PrUser(login: 'red', avatarUrl: ''),
            date: _t0.add(const Duration(hours: 1)),
          ),
          // A contiguous same-author run — compacted to a "pushed 2 commits"
          // accordion.
          PrCommit(
            sha: 'e07bcc41234',
            message: 'upd',
            author: const PrUser(login: 'sam', avatarUrl: ''),
            date: _t0.add(const Duration(hours: 1, minutes: 10)),
          ),
          PrCommit(
            sha: 'f797b6c1234',
            message: 'upd',
            author: const PrUser(login: 'sam', avatarUrl: ''),
            date: _t0.add(const Duration(hours: 1, minutes: 20)),
          ),
        ]),
      ),
      prTimelineEventsProvider(_prRef).overrideWith(
        (ref) => Stream.value([
          PrTimelineEvent(
            kind: PrTimelineEventKind.reviewRequested,
            actor: const PrUser(login: 'alice', avatarUrl: ''),
            reviewerName: 'krishna',
            createdAt: _t0.add(const Duration(minutes: 5)),
          ),
          PrTimelineEvent(
            kind: PrTimelineEventKind.reviewRequested,
            actor: const PrUser(login: 'alice', avatarUrl: ''),
            reviewerName: 'Brand Fundamentals',
            reviewerIsTeam: true,
            createdAt: _t0.add(const Duration(minutes: 5, seconds: 10)),
          ),
          PrTimelineEvent(
            kind: PrTimelineEventKind.reviewRequestRemoved,
            actor: const PrUser(login: 'alice', avatarUrl: ''),
            reviewerName: 'krishna',
            createdAt: _t0.add(const Duration(minutes: 5, seconds: 20)),
          ),
          PrTimelineEvent(
            kind: PrTimelineEventKind.reviewRequested,
            actor: const PrUser(login: 'alice', avatarUrl: ''),
            reviewerName: 'matias',
            createdAt: _t0.add(const Duration(minutes: 5, seconds: 30)),
          ),
        ]),
      ),
    ],
    child: MaterialApp(
      localizationsDelegates: [
        ...AppLocalizations.localizationsDelegates,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      home: CcTheme(
        data: CcThemeData.light(),
        child: Scaffold(body: child),
      ),
    ),
  );
}

Finder _richTextContaining(String substring) {
  return find.byWidgetPredicate((w) {
    if (w is! RichText) {
      return false;
    }
    final plain = w.text.toPlainText().replaceAll('\uFFFC', '');
    return plain.contains(substring);
  });
}

void main() {
  group('PrActivityTimeline', () {
    testWidgets(
      // Regression: the tiles once used IntrinsicHeight, whose dry layout
      // blows up on the LayoutBuilder inside markdown comment cards
      // ("_RenderLayoutBuilder does not support dry layout").
      'renders event rows and markdown comment cards inside a scroll view '
      'without layout exceptions',
      (tester) async {
        final controller = ScrollController();
        addTearDown(controller.dispose);
        final diffJumps = <int>[];
        await tester.pumpWidget(
          _wrap(
            SingleChildScrollView(
              controller: controller,
              child: PrActivityTimeline(
                pr: _pr(),
                prRef: _prRef,
                onOpenFileInDiff: diffJumps.add,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle(const Duration(seconds: 5));

        expect(tester.takeException(), isNull);
        expect(find.text('Activity'), findsOneWidget);
        expect(find.byType(GitHubUserMention), findsWidgets);
        // Opened event with commit count. The author is a mention chip
        // (WidgetSpan), so the RichText's remaining copy is the verb phrase.
        expect(find.text('alice'), findsWidgets);
        expect(
          _richTextContaining('opened this pull request with 2 commits'),
          findsOneWidget,
        );
        // Grouped review request/remove burst (same actor, mixed actions).
        expect(_richTextContaining('requested review from'), findsOneWidget);
        expect(find.text('Brand Fundamentals'), findsOneWidget);
        expect(find.text('krishna'), findsWidgets);
        expect(
          _richTextContaining('and removed the review request for'),
          findsOneWidget,
        );
        // Single commit stays a plain row: sha + message title.
        expect(find.text('red'), findsOneWidget);
        expect(_richTextContaining('committed 845facb'), findsOneWidget);
        // A contiguous same-author run compacts to an accordion, collapsed by
        // default; tapping it reveals the individual commits.
        final group = _richTextContaining('pushed 2 commits');
        expect(group, findsOneWidget);
        expect(find.text('sam'), findsOneWidget);
        expect(_richTextContaining('e07bcc4'), findsNothing);
        await tester.tap(group);
        await tester.pump();
        expect(_richTextContaining('e07bcc4 upd'), findsOneWidget);
        expect(_richTextContaining('f797b6c upd'), findsOneWidget);
        await tester.tap(_richTextContaining('pushed 2 commits'));
        await tester.pump();
        expect(_richTextContaining('e07bcc4'), findsNothing);
        // Verdict-only review renders as a compact sentence.
        expect(find.text('matias'), findsWidgets);
        expect(_richTextContaining('approved these changes'), findsOneWidget);
        // Review with a summary renders as a card with the verdict chip.
        expect(find.text('Approved'), findsOneWidget);
        expect(_richTextContaining('looks good!'), findsOneWidget);
        // ...and with its reaction bar: the 👍 left on the summary renders
        // (only the review carries reactions in this fixture, so one chip),
        // next to the add-reaction pill every comment card has.
        expect(find.text('👍'), findsOneWidget);
        expect(find.text('2'), findsOneWidget);
        // The review's inline conversations render in full here — body, author
        // and all — because an OUTDATED one (its line gone from the diff) can
        // be read nowhere else.
        expect(find.text('2 code comments'), findsOneWidget);
        expect(find.text('lib/b.dart'), findsOneWidget);
        expect(_richTextContaining('inline note'), findsWidgets);
        expect(find.text('krishna'), findsWidgets);
        // A reply submitted with a LATER review still belongs to the
        // conversation it answers, not to a timeline entry of its own.
        expect(_richTextContaining('good catch'), findsWidgets);
        expect(find.text('2 comments'), findsOneWidget);
        // The review that only REPLIED gets its own reference card, showing
        // what was said and pointing back at the conversation it answers.
        expect(find.text('In reply to lib/b.dart'), findsOneWidget);
        // The outdated conversation is here, badged, with the hunk it was left
        // against — and offers no jump, because there is no row to jump to.
        expect(find.text('lib/gone.dart'), findsOneWidget);
        expect(find.text('Outdated'), findsOneWidget);
        expect(_richTextContaining('this code is gone now'), findsWidgets);
        // The hunk renders as a real diff: markers stripped, content
        // syntax-highlighted, old/new line numbers in a gutter.
        expect(_richTextContaining('old line'), findsWidgets);
        expect(_richTextContaining('new line'), findsWidgets);
        expect(find.text('-old line'), findsNothing);
        expect(find.text('@@ -1,2 +1,2 @@'), findsNothing);
        // The jump to the diff moved onto the conversation's file header, and
        // resolves the commented file's tree-order index (lib/b.dart is second
        // after lib/a.dart).
        final jump = find.byIcon(AppIcons.arrowRight);
        expect(jump, findsOneWidget);
        await tester.ensureVisible(jump);
        await tester.tap(jump);
        expect(diffJumps, [1]);
        // Bot comment: badge + stripped display login + markdown body.
        expect(find.text('bot'), findsOneWidget);
        expect(find.text('sonarqubecloud'), findsOneWidget);
        expect(_richTextContaining('Quality Gate failed'), findsOneWidget);

        // Following the reference opens the conversation it answers, even
        // though that thread lives under a DIFFERENT timeline entry — and the
        // conversation may have been collapsed (a resolved one arrives that
        // way), so it has to be reopened rather than merely scrolled to.
        final backLink = find.text('In reply to lib/b.dart');
        await tester.ensureVisible(backLink);
        await tester.tap(backLink);
        await tester.pumpAndSettle();
        expect(_richTextContaining('inline note'), findsWidgets);

        // The scrollable's extent must be the content's real height — the
        // broken dry layout used to inflate it wildly.
        expect(
          controller.position.maxScrollExtent,
          lessThan(2000),
          reason: 'scroll extent should match the rendered content',
        );

        await tester.pumpWidget(Container());
        await tester.pump(const Duration(milliseconds: 100));
      },
    );
  });
}
