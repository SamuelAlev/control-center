import 'package:cc_domain/core/domain/entities/workspace.dart';
import 'package:cc_domain/features/pr_review/domain/entities/issue_comment.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pr_code_review_comment.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pr_commit.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pr_file.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pr_label.dart';
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

Widget _wrap(
  Widget child, {
  List<PrCodeReviewComment>? comments,
  List<PrReviewSubmission>? reviews,
  List<IssueComment>? issueComments,
  List<PrCommit>? commits,
  List<PrTimelineEvent>? events,
}) {
  return ProviderScope(
    overrides: [
      prReviewCommentIndexProvider(_prRef).overrideWith(
        (ref) => Stream.value(
          comments ??
              [
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
                // OUTDATED: no anchor line, so the diff cannot place it at all
                // and the timeline is the only place it can be read.
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
                // Resolved conversations start collapsed; preview only.
                PrCodeReviewComment(
                  id: 103,
                  body: 'already settled',
                  user: const PrUser(login: 'krishna', avatarUrl: ''),
                  path: 'lib/done.dart',
                  position: 1,
                  line: 4,
                  isResolved: true,
                  createdAt: _t0.add(const Duration(hours: 4)),
                  reviewId: 1,
                ),
              ],
        ),
      ),
      prFileIndexProvider(_prRef).overrideWith(
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
        (ref) => Stream.value(
          reviews ??
              [
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
                // A review that ONLY replied to an earlier conversation: it
                // starts no thread of its own, so without the reply reference
                // its entry is a bare "reviewed" row with the words nowhere
                // in sight.
                PrReviewSubmission(
                  id: 9,
                  state: PrReviewSubmissionState.commented,
                  author: const PrUser(login: 'alexandra', avatarUrl: ''),
                  body: '',
                  submittedAt: _t0.add(const Duration(hours: 5)),
                ),
              ],
        ),
      ),
      prIssueCommentsProvider(_prRef).overrideWith(
        (ref) => Stream.value(
          issueComments ??
              [
                IssueComment(
                  id: 22,
                  body: '## Quality Gate failed\n\n- 77.2% coverage on new code',
                  user: const PrUser(
                    login: 'sonarqubecloud[bot]',
                    avatarUrl: '',
                  ),
                  createdAt: _t0.add(const Duration(hours: 2)),
                ),
              ],
        ),
      ),
      prCommitsProvider(_prRef).overrideWith(
        (ref) => Stream.value(
          commits ??
              [
                PrCommit(
                  sha: '845facb1234',
                  message: 'refactor: introduce overrides in sidebar',
                  author: const PrUser(login: 'red', avatarUrl: ''),
                  date: _t0.add(const Duration(hours: 1)),
                ),
                // A contiguous same-author run — compacted to a
                // "pushed 2 commits" accordion.
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
              ],
        ),
      ),
      prTimelineEventsProvider(_prRef).overrideWith(
        (ref) => Stream.value(
          events ??
              [
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
                PrTimelineEvent(
                  kind: PrTimelineEventKind.labeled,
                  actor: const PrUser(login: 'renovate[bot]', avatarUrl: ''),
                  label: const PrLabel(
                    name: 'dependencies',
                    color: '0366d6',
                    description: 'Pull requests that update a dependency file',
                  ),
                  createdAt: _t0.add(const Duration(minutes: 8)),
                ),
              ],
        ),
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
        tester.view.physicalSize = const Size(800, 4000);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final controller = ScrollController();
        addTearDown(controller.dispose);
        final diffJumps = <int>[];
        await tester.pumpWidget(
          _wrap(
            CustomScrollView(
              controller: controller,
              cacheExtent: 8000,
              slivers: [
                PrActivityTimeline(
                  pr: _pr(),
                  prRef: _prRef,
                  onOpenFileInDiff: diffJumps.add,
                ),
              ],
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
        expect(_richTextContaining('added the'), findsOneWidget);
        expect(find.text('dependencies'), findsOneWidget);
        expect(find.byType(CcColorTag), findsOneWidget);
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
        // Unresolved conversations start open so the text and replies are
        // readable without a click.
        expect(find.text('3 code comments'), findsOneWidget);
        expect(find.text('lib/b.dart'), findsOneWidget);
        expect(find.text('inline note'), findsWidgets);
        expect(find.text('krishna'), findsWidgets);
        expect(_richTextContaining('inline note'), findsWidgets);
        expect(_richTextContaining('good catch'), findsWidgets);
        expect(find.text('2 comments'), findsOneWidget);
        expect(find.text('lib/gone.dart'), findsOneWidget);
        expect(find.text('Outdated'), findsOneWidget);
        expect(find.text('this code is gone now'), findsWidgets);
        expect(_richTextContaining('this code is gone now'), findsWidgets);
        expect(_richTextContaining('old line'), findsWidgets);
        expect(_richTextContaining('new line'), findsWidgets);
        expect(find.text('-old line'), findsNothing);
        expect(find.text('@@ -1,2 +1,2 @@'), findsNothing);
        // Resolved conversations start collapsed: preview only, no reply box.
        expect(find.text('lib/done.dart'), findsOneWidget);
        expect(find.text('already settled'), findsWidgets);
        expect(find.text('Resolved'), findsOneWidget);
        // The review that only REPLIED gets its own reference card, showing
        // what was said and pointing back at the conversation it answers.
        expect(find.text('In reply to lib/b.dart'), findsOneWidget);
        // The jump to the diff moved onto the conversation's file header, and
        // resolves the commented file's tree-order index (lib/b.dart is second
        // after lib/a.dart).
        final jump = find.byIcon(AppIcons.arrowRight);
        // Live file + the resolved conversation that still has a line.
        expect(jump, findsNWidgets(2));
        await tester.ensureVisible(jump.first);
        await tester.tap(jump.first);
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

    testWidgets(
      'only on-screen conversations build, even when they start open',
      (tester) async {
        tester.view.physicalSize = const Size(800, 400);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final comments = [
          for (var i = 0; i < 20; i++)
            PrCodeReviewComment(
              id: 200 + i,
              body: 'thread-body-$i',
              user: const PrUser(login: 'krishna', avatarUrl: ''),
              path: 'lib/f$i.dart',
              position: 1,
              line: 1,
              createdAt: _t0.add(Duration(minutes: i)),
              reviewId: 1,
            ),
        ];

        final controller = ScrollController();
        addTearDown(controller.dispose);
        await tester.pumpWidget(
          _wrap(
            CustomScrollView(
              controller: controller,
              cacheExtent: 0,
              slivers: [
                PrActivityTimeline(pr: _pr(), prRef: _prRef),
              ],
            ),
            comments: comments,
            reviews: [
              PrReviewSubmission(
                id: 1,
                state: PrReviewSubmissionState.commented,
                author: const PrUser(login: 'krishna', avatarUrl: ''),
                body: '',
                submittedAt: _t0,
              ),
            ],
            issueComments: const [],
            commits: const [],
            events: const [],
          ),
        );
        await tester.pumpAndSettle(const Duration(seconds: 5));

        expect(_richTextContaining('thread-body-0'), findsOneWidget);
        // Precalculation may have measured later threads; the invariant is
        // that scrolling them into view does not resize the thumb.

        // The list used to extrapolate extent from the visible average, so
        // the thumb shrank and grew as short rows and tall cards swapped.
        final before = controller.position.maxScrollExtent;
        await tester.drag(find.byType(CustomScrollView), const Offset(0, -240));
        await tester.pump();
        expect(
          controller.position.maxScrollExtent,
          closeTo(before, 8),
          reason: 'scroll extent must not jump when newly built rows appear',
        );
      },
    );

    testWidgets(
      'scroll extent stays stable when short events give way to tall cards',
      (tester) async {
        tester.view.physicalSize = const Size(800, 400);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        // Unique authors so commits stay one row each (same-author runs
        // compact to a single accordion).
        final commits = [
          for (var i = 0; i < 24; i++)
            PrCommit(
              sha: 'c${i.toString().padLeft(8, '0')}',
              message: 'commit $i',
              author: PrUser(login: 'dev$i', avatarUrl: ''),
              date: _t0.add(Duration(minutes: i)),
            ),
        ];
        final issueComments = [
          for (var i = 0; i < 6; i++)
            IssueComment(
              id: 300 + i,
              body: '${'paragraph $i. ' * 40}\n\n${'more text. ' * 40}',
              user: const PrUser(login: 'sonarqubecloud[bot]', avatarUrl: ''),
              createdAt: _t0.add(Duration(hours: 2, minutes: i)),
            ),
        ];

        final controller = ScrollController();
        addTearDown(controller.dispose);
        await tester.pumpWidget(
          _wrap(
            CustomScrollView(
              controller: controller,
              cacheExtent: 0,
              slivers: [
                PrActivityTimeline(pr: _pr(), prRef: _prRef),
              ],
            ),
            comments: const [],
            reviews: const [],
            issueComments: issueComments,
            commits: commits,
            events: const [],
          ),
        );
        await tester.pumpAndSettle(const Duration(seconds: 5));

        final before = controller.position.maxScrollExtent;
        expect(before, greaterThan(400));

        await tester.drag(find.byType(CustomScrollView), const Offset(0, -900));
        await tester.pump();
        await tester.drag(find.byType(CustomScrollView), const Offset(0, -900));
        await tester.pump();

        expect(
          controller.position.maxScrollExtent,
          closeTo(before, 8),
          reason: 'mixed short/tall rows must not resize the Overview thumb',
        );
      },
    );
  });
}
