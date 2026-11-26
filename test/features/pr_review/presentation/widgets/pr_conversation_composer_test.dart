import 'dart:async';

import 'package:cc_domain/core/domain/entities/github_user.dart';
import 'package:cc_domain/core/domain/entities/repo.dart';
import 'package:cc_domain/core/domain/entities/workspace.dart';
import 'package:cc_domain/features/pr_review/domain/entities/check_run.dart';
import 'package:cc_domain/features/pr_review/domain/entities/issue_comment.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pr_code_review_comment.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pr_commit.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pr_file.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pr_review_submission.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pr_reviewer.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pr_timeline_event.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pr_user.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pull_request.dart';
import 'package:cc_domain/features/pr_review/domain/providers/forge_capabilities.dart';
import 'package:cc_domain/features/pr_review/domain/repositories/pr_review_repository.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/core/theme/font_settings.dart';
import 'package:control_center/di/providers.dart' show githubUserProvider;
import 'package:control_center/features/forge/providers/forge_providers.dart';
import 'package:control_center/features/pr_review/presentation/screens/pull_request_detail/pr_overview_tab.dart';
import 'package:control_center/features/pr_review/presentation/widgets/pr_comment_field.dart';
import 'package:control_center/features/pr_review/presentation/widgets/pr_conversation_composer.dart';
import 'package:control_center/features/pr_review/providers/pr_comment_draft_provider.dart';
import 'package:control_center/features/pr_review/providers/pr_filter_providers.dart';
import 'package:control_center/features/pr_review/providers/pr_review_providers.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/l10n/localizations_loader.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:control_center/shared/widgets/github_user_avatar.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:riverpod/misc.dart';

const _prRef7 = (
  workspaceId: 'ws',
  repoFullName: 'acme/control-center',
  number: 7,
  forge: null,
);

const _prRef8 = (
  workspaceId: 'ws',
  repoFullName: 'acme/control-center',
  number: 8,
  forge: null,
);

final _repo = Repo(
  id: 'r1',
  name: 'control-center',
  path: '/tmp/cc',
  remoteOwner: 'acme',
  remoteName: 'control-center',
  createdAt: DateTime.utc(2026),
  updatedAt: DateTime.utc(2026),
);

PullRequest _pr({int number = 7}) => PullRequest(
  id: number,
  number: number,
  title: 'Add PR comment box',
  body: 'Description',
  state: PrState.open,
  isDraft: false,
  author: const PrUser(login: 'alice', avatarUrl: ''),
  createdAt: DateTime.utc(2026, 1, 2),
  updatedAt: DateTime.utc(2026, 1, 2),
  repoFullName: 'acme/control-center',
  htmlUrl: 'https://github.com/acme/control-center/pull/$number',
  headSha: 'deadbeef',
);

class _RecordingRepo extends EmptyPrReviewRepository {
  final List<({int prNumber, String body})> posted = [];
  Future<void> Function()? postAction;

  @override
  Future<void> postIssueComment({
    required int prNumber,
    required String body,
  }) async {
    posted.add((prNumber: prNumber, body: body));
    await postAction?.call();
  }
}

class _NullWorkspaceIdNotifier extends ActiveWorkspaceIdNotifier {
  @override
  String? build() => null;
}

List<Override> _sharedOverrides({
  String currentUserLogin = 'sam',
  GitHubUser? githubUser = const GitHubUser(
    login: 'sam',
    name: 'Sam',
    avatarUrl: '',
  ),
}) {
  return [
    codeFontFamilyProvider.overrideWithValue('Fira Code'),
    activeWorkspaceIdProvider.overrideWith(_NullWorkspaceIdNotifier.new),
    activeWorkspaceProvider.overrideWith((ref) => null),
    activeRepoProvider.overrideWith((ref) => null),
    workspacesProvider.overrideWith(
      (ref) => const Stream<List<Workspace>>.empty(),
    ),
    forgeCapabilitiesProvider.overrideWith((ref) async => kForgeCapabilities),
    githubUserProvider.overrideWith((ref) async => githubUser),
  ];
}

List<Override> _prOverrides({
  required _RecordingRepo repo,
  PrRef prRef = _prRef7,
  String currentUserLogin = 'sam',
  bool hasWriteAccess = true,
  Stream<PullRequest?> Function(Ref ref)? detailStream,
  Stream<List<IssueComment>> Function(Ref ref)? issueCommentsStream,
  Stream<List<PrTimelineEvent>> Function(Ref ref)? timelineEventsStream,
}) {
  return [
    prRepoRowProvider(prRef).overrideWith((ref) => _repo),
    prRepositoryProvider(prRef).overrideWith((ref) => repo),
    prRepoWriteAccessProvider(prRef).overrideWith((ref) => hasWriteAccess),
    currentUserLoginForPrProvider(prRef).overrideWith((ref) => currentUserLogin),
    prDetailProvider(prRef).overrideWith(
      detailStream ?? (ref) => Stream.value(_pr(number: prRef.number)),
    ),
    prIssueCommentsProvider(prRef).overrideWith(
      issueCommentsStream ?? (ref) => Stream.value(const <IssueComment>[]),
    ),
    prTimelineEventsProvider(prRef).overrideWith(
      timelineEventsStream ??
          (ref) => Stream.value(const <PrTimelineEvent>[]),
    ),
  ];
}

List<Override> _baseOverrides({
  required _RecordingRepo repo,
  PrRef prRef = _prRef7,
  String currentUserLogin = 'sam',
  GitHubUser? githubUser = const GitHubUser(
    login: 'sam',
    name: 'Sam',
    avatarUrl: '',
  ),
  bool hasWriteAccess = true,
  List<Override> extra = const [],
}) {
  return [
    ..._sharedOverrides(
      currentUserLogin: currentUserLogin,
      githubUser: githubUser,
    ),
    ..._prOverrides(
      repo: repo,
      prRef: prRef,
      currentUserLogin: currentUserLogin,
      hasWriteAccess: hasWriteAccess,
    ),
    ...extra,
  ];
}

Widget _app(
  Widget child, {
  ProviderContainer? container,
  List<Override> overrides = const [],
  TextDirection textDirection = TextDirection.ltr,
}) {
  final content = MaterialApp(
    localizationsDelegates: [
      ...appLocalizationsDelegates,
      ...GlobalMaterialLocalizations.delegates,
    ],
    supportedLocales: AppLocalizations.supportedLocales,
    locale: const Locale('en'),
    home: Directionality(
      textDirection: textDirection,
      child: CcTheme(
        data: CcThemeData.light(),
        child: CcToastScope(child: Scaffold(body: child)),
      ),
    ),
  );
  if (container != null) {
    return UncontrolledProviderScope(container: container, child: content);
  }
  return ProviderScope(overrides: overrides, child: content);
}

void main() {
  group('PrConversationComposer', () {
    testWidgets(
      'collapsed state shows placeholder and viewer avatar without mounting editor',
      (tester) async {
        final repo = _RecordingRepo();
        await tester.pumpWidget(
          _app(
            PrConversationComposer(pr: _pr(), prRef: _prRef7),
            overrides: _baseOverrides(repo: repo),
          ),
        );
        await tester.pump();

        expect(find.text('Leave a comment…'), findsOneWidget);
        expect(find.byType(GitHubUserAvatar), findsOneWidget);
        expect(find.byType(PrCommentField), findsNothing);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets('unauthenticated viewer shows fallback icon instead of avatar', (
      tester,
    ) async {
      final repo = _RecordingRepo();
      await tester.pumpWidget(
        _app(
          PrConversationComposer(pr: _pr(), prRef: _prRef7),
          overrides: _baseOverrides(
            repo: repo,
            currentUserLogin: '',
            githubUser: null,
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(GitHubUserAvatar), findsNothing);
      expect(find.byIcon(AppIcons.messageSquare), findsNWidgets(2));
      expect(tester.takeException(), isNull);
    });

    testWidgets('tapping expands into PrCommentField and typing enables Comment', (
      tester,
    ) async {
      final repo = _RecordingRepo();
      await tester.pumpWidget(
        _app(
          PrConversationComposer(pr: _pr(), prRef: _prRef7),
          overrides: _baseOverrides(repo: repo),
        ),
      );
      await tester.pump();

      await tester.tap(find.text('Leave a comment…'));
      await tester.pump();

      expect(find.byType(PrCommentField), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Comment'), findsOneWidget);

      CcButton commentButton() => tester.widget<CcButton>(
        find.ancestor(
          of: find.text('Comment'),
          matching: find.byType(CcButton),
        ),
      );

      expect(commentButton().onPressed, isNull);

      await tester.enterText(find.byType(EditableText), '   ');
      await tester.pump();
      expect(commentButton().onPressed, isNull);

      await tester.enterText(find.byType(EditableText), 'Looks good');
      await tester.pump();
      expect(commentButton().onPressed, isNotNull);
    });

    testWidgets('expanding at the bottom of a scroll view reveals the actions', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final scroll = ScrollController();
      addTearDown(scroll.dispose);
      await tester.pumpWidget(
        _app(
          SingleChildScrollView(
            controller: scroll,
            child: Column(
              children: [
                const SizedBox(height: 900),
                PrConversationComposer(pr: _pr(), prRef: _prRef7),
              ],
            ),
          ),
          overrides: _baseOverrides(repo: _RecordingRepo()),
        ),
      );
      await tester.pump();
      scroll.jumpTo(scroll.position.maxScrollExtent);
      await tester.pump();

      await tester.tap(find.text('Leave a comment…'));
      await tester.pumpAndSettle();

      expect(scroll.offset, scroll.position.maxScrollExtent);
      expect(
        tester.getRect(find.text('Comment')).bottom,
        lessThanOrEqualTo(400),
      );
    });

    testWidgets(
      'submit trims body, shows loading in flight, clears, collapses, and invalidates PR streams',
      (tester) async {
        final repo = _RecordingRepo();
        final gate = Completer<void>();
        repo.postAction = () => gate.future;

        var issueCommentsReads = 0;
        var timelineReads = 0;
        var detailReads = 0;

        final container = ProviderContainer(
          overrides: [
            ..._sharedOverrides(),
            ..._prOverrides(
              repo: repo,
              prRef: _prRef7,
              detailStream: (ref) {
                detailReads++;
                return Stream.value(_pr());
              },
              issueCommentsStream: (ref) {
                issueCommentsReads++;
                return Stream.value(const <IssueComment>[]);
              },
              timelineEventsStream: (ref) {
                timelineReads++;
                return Stream.value(const <PrTimelineEvent>[]);
              },
            ),
          ],
        );
        addTearDown(container.dispose);

        // Prime streams so we can observe invalidation re-fetches.
        container.listen(prIssueCommentsProvider(_prRef7), (_, _) {});
        container.listen(prTimelineEventsProvider(_prRef7), (_, _) {});
        container.listen(prDetailProvider(_prRef7), (_, _) {});

        await tester.pumpWidget(
          _app(
            PrConversationComposer(pr: _pr(), prRef: _prRef7),
            container: container,
          ),
        );
        await tester.pump();

        final beforeIssue = issueCommentsReads;
        final beforeTimeline = timelineReads;
        final beforeDetail = detailReads;

        await tester.tap(find.text('Leave a comment…'));
        await tester.pump();
        await tester.enterText(find.byType(EditableText), '  Looks good!  ');
        await tester.pump();

        await tester.tap(find.text('Comment'));
        await tester.pump();

        expect(repo.posted, [(prNumber: 7, body: 'Looks good!')]);
        final btnDuring = tester.widget<CcButton>(
          find.ancestor(
            of: find.text('Comment'),
            matching: find.byType(CcButton),
          ),
        );
        expect(btnDuring.loading, isTrue);
        expect(btnDuring.onPressed, isNull);

        gate.complete();
        await tester.pump();
        await tester.pump();

        expect(find.byType(PrCommentField), findsNothing);
        expect(find.text('Leave a comment…'), findsOneWidget);
        expect(issueCommentsReads, greaterThan(beforeIssue));
        expect(timelineReads, greaterThan(beforeTimeline));
        expect(detailReads, greaterThan(beforeDetail));
      },
    );

    testWidgets('Cmd+Enter or Ctrl+Enter submits the comment', (tester) async {
      final repo = _RecordingRepo();
      await tester.pumpWidget(
        _app(
          PrConversationComposer(pr: _pr(), prRef: _prRef7),
          overrides: _baseOverrides(repo: repo),
        ),
      );
      await tester.pump();

      await tester.tap(find.text('Leave a comment…'));
      await tester.pump();
      await tester.enterText(find.byType(EditableText), 'Shortcut comment');
      await tester.pump();

      final useMeta = defaultTargetPlatform == TargetPlatform.macOS;
      final modifier = useMeta
          ? LogicalKeyboardKey.metaLeft
          : LogicalKeyboardKey.controlLeft;
      await tester.sendKeyDownEvent(modifier);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.enter);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.enter);
      await tester.sendKeyUpEvent(modifier);
      await tester.pump();
      await tester.pump();

      expect(repo.posted, [(prNumber: 7, body: 'Shortcut comment')]);
      expect(find.byType(PrCommentField), findsNothing);
    });

    testWidgets(
      'draft persists across unmount/remount and is isolated per PR',
      (tester) async {
        final repo = _RecordingRepo();
        final currentPr = ValueNotifier<PrRef>(_prRef7);
        final visible = ValueNotifier<bool>(true);
        addTearDown(currentPr.dispose);
        addTearDown(visible.dispose);

        final container = ProviderContainer(
          overrides: [
            ..._sharedOverrides(),
            ..._prOverrides(repo: repo, prRef: _prRef7),
            ..._prOverrides(repo: repo, prRef: _prRef8),
          ],
        );
        addTearDown(container.dispose);

        await tester.pumpWidget(
          _app(
            ValueListenableBuilder<bool>(
              valueListenable: visible,
              builder: (_, show, _) => show
                  ? ValueListenableBuilder<PrRef>(
                      valueListenable: currentPr,
                      builder: (_, ref, _) => PrConversationComposer(
                        pr: _pr(number: ref.number),
                        prRef: ref,
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
            container: container,
          ),
        );
        await tester.pump();

        await tester.tap(find.text('Leave a comment…'));
        await tester.pump();
        await tester.enterText(find.byType(EditableText), 'WIP draft');
        await tester.pump();

        // Unmount then remount on same PR -> stays expanded with saved draft.
        visible.value = false;
        await tester.pump();
        visible.value = true;
        await tester.pump();

        expect(find.byType(PrCommentField), findsOneWidget);
        expect(find.text('WIP draft'), findsOneWidget);

        // Switch to PR #8 -> collapsed, clean draft.
        currentPr.value = _prRef8;
        await tester.pump();

        expect(find.byType(PrCommentField), findsNothing);
        expect(find.text('Leave a comment…'), findsOneWidget);
      },
    );

    testWidgets('failed submit preserves draft, stops loading, and shows error toast', (
      tester,
    ) async {
      final repo = _RecordingRepo()
        ..postAction = () async => throw StateError('network down');

      await tester.pumpWidget(
        _app(
          PrConversationComposer(pr: _pr(), prRef: _prRef7),
          overrides: _baseOverrides(repo: repo),
        ),
      );
      await tester.pump();

      await tester.tap(find.text('Leave a comment…'));
      await tester.pump();
      await tester.enterText(find.byType(EditableText), 'Retry me');
      await tester.pump();

      await tester.tap(find.text('Comment'));
      await tester.pump();
      await tester.pump();

      expect(find.byType(PrCommentField), findsOneWidget);
      expect(find.text('Retry me'), findsOneWidget);
      expect(find.textContaining('Could not post the comment'), findsOneWidget);
      final btn = tester.widget<CcButton>(
        find.ancestor(
          of: find.text('Comment'),
          matching: find.byType(CcButton),
        ),
      );
      expect(btn.loading, isFalse);
      expect(btn.onPressed, isNotNull);
    });

    testWidgets(
      'Cancel collapses immediately when empty and confirms discard when non-empty',
      (tester) async {
        final repo = _RecordingRepo();
        final container = ProviderContainer(
          overrides: _baseOverrides(repo: repo),
        );
        addTearDown(container.dispose);

        await tester.pumpWidget(
          _app(
            PrConversationComposer(pr: _pr(), prRef: _prRef7),
            container: container,
          ),
        );
        await tester.pump();

        // Empty -> collapses without dialog.
        await tester.tap(find.text('Leave a comment…'));
        await tester.pump();
        await tester.tap(find.text('Cancel'));
        await tester.pump();
        expect(find.byType(PrCommentField), findsNothing);

        // Non-empty -> prompts discard confirmation.
        await tester.tap(find.text('Leave a comment…'));
        await tester.pump();
        await tester.enterText(find.byType(EditableText), 'Unsaved text');
        await tester.pump();

        await tester.tap(find.text('Cancel'));
        await tester.pumpAndSettle();
        expect(find.text('Discard your changes?'), findsOneWidget);

        // Dismiss dialog keeping draft.
        await tester.tap(find.text('Cancel').last);
        await tester.pumpAndSettle();
        expect(find.byType(PrCommentField), findsOneWidget);
        expect(find.text('Unsaved text'), findsOneWidget);

        // Confirm discard clears and collapses.
        await tester.tap(find.text('Cancel'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Discard'));
        await tester.pumpAndSettle();
        expect(find.byType(PrCommentField), findsNothing);
        expect(
          container
              .read(
                prCommentDraftControllerProvider((
                  workspaceId: 'ws',
                  surface: 'pr-conversation-comment',
                  destination: ('acme/control-center', 7),
                )),
              )
              .text,
          isEmpty,
        );
      },
    );

    testWidgets('Preview tab keeps Cancel and Comment buttons visible and active', (
      tester,
    ) async {
      final repo = _RecordingRepo();
      await tester.pumpWidget(
        _app(
          PrConversationComposer(pr: _pr(), prRef: _prRef7),
          overrides: _baseOverrides(repo: repo),
        ),
      );
      await tester.pump();

      await tester.tap(find.text('Leave a comment…'));
      await tester.pump();
      await tester.enterText(find.byType(EditableText), '**Bold** note');
      await tester.pump();

      await tester.tap(find.text('Preview'));
      await tester.pump();

      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Comment'), findsOneWidget);

      await tester.tap(find.text('Comment'));
      await tester.pump();
      await tester.pump();

      expect(repo.posted, [(prNumber: 7, body: '**Bold** note')]);
      expect(find.byType(PrCommentField), findsNothing);
    });

    testWidgets('renders cleanly under RTL directionality', (tester) async {
      final repo = _RecordingRepo();
      await tester.pumpWidget(
        _app(
          PrConversationComposer(pr: _pr(), prRef: _prRef7),
          overrides: _baseOverrides(repo: repo),
          textDirection: TextDirection.rtl,
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);

      await tester.tap(find.text('Leave a comment…'));
      await tester.pump();
      expect(find.byType(PrCommentField), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
      'PrOverviewTab renders PrConversationComposer below timeline in wide and narrow widths',
      (tester) async {
        final repo = _RecordingRepo();
        final overrides = [
          ..._baseOverrides(repo: repo),
          prCheckRunsProvider(
            _prRef7,
          ).overrideWith((ref) => Stream.value(const <CheckRun>[])),
          prReviewsProvider(
            _prRef7,
          ).overrideWith((ref) => Stream.value(const <PrReviewSubmission>[])),
          prCommitsProvider(
            _prRef7,
          ).overrideWith((ref) => Stream.value(const <PrCommit>[])),
          prReviewCommentIndexProvider(
            _prRef7,
          ).overrideWith((ref) => Stream.value(const <PrCodeReviewComment>[])),
          prFileIndexProvider(
            _prRef7,
          ).overrideWith((ref) => Stream.value(const <PrFile>[])),
          prReviewersProvider(
            _prRef7,
          ).overrideWith((ref) => Stream.value(const <PrReviewer>[])),
        ];

        for (final width in [1200.0, 600.0]) {
          tester.view.physicalSize = Size(width, 900);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);

          await tester.pumpWidget(
            _app(
              PrOverviewTab(
                pr: _pr(),
                prRef: _prRef7,
                onOpenFileInDiff: (_) {},
                onOpenCommentInDiff: (_) {},
                onOpenCommit: (_) {},
                onOpenReview: () {},
              ),
              overrides: overrides,
            ),
          );
          await tester.pumpAndSettle();

          final composerFinder = find.byType(PrConversationComposer);
          expect(composerFinder, findsOneWidget);
          await tester.ensureVisible(composerFinder);
          await tester.pumpAndSettle();
          expect(find.text('Leave a comment…'), findsOneWidget);
          expect(tester.takeException(), isNull);
        }
      },
    );
  });
}
