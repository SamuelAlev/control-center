import 'dart:async';

import 'package:cc_domain/core/domain/entities/repo.dart';
import 'package:cc_domain/core/domain/entities/workspace.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pr_user.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pull_request.dart';
import 'package:cc_domain/features/pr_review/domain/value_objects/review_level.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/pr_review/presentation/screens/pull_request_detail/pr_detail_actions.dart';
import 'package:control_center/features/pr_review/providers/ide_providers.dart';
import 'package:control_center/features/pr_review/providers/pr_filter_providers.dart';
import 'package:control_center/features/pr_review/providers/pr_review_providers.dart';
import 'package:control_center/features/pr_review/providers/pr_review_run_providers.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

PullRequest _pr() => PullRequest(
  id: 1,
  number: 42,
  title: 'Test PR',
  body: '',
  state: PrState.open,
  isDraft: false,
  // The viewer authored it, so the primary "Review" button is absent and the
  // row is just the refresh control plus the overflow menu.
  author: const PrUser(login: 'tester', avatarUrl: ''),
  createdAt: DateTime(2025),
  updatedAt: DateTime(2025),
  repoFullName: 'test/repo',
  htmlUrl: 'https://example.com',
);

Repo _repo() => Repo(
  id: 'repo-1',
  name: 'repo',
  path: '/tmp/repo',
  remoteOwner: 'test',
  remoteName: 'repo',
  createdAt: DateTime(2025),
  updatedAt: DateTime(2025),
);

/// Pins the active workspace without touching preferences or the bootstrap
/// workspace stream.
class _FixedWorkspaceId extends ActiveWorkspaceIdNotifier {
  @override
  String? build() => 'ws-1';
}

/// A starter whose call never answers — the real one does not either until the
/// PR's worktree has finished provisioning.
class _HangingStarter extends PrReviewStarter {
  final Completer<Map<String, dynamic>> completer = Completer();
  int starts = 0;

  @override
  Set<PrReviewKey> build() => const {};

  @override
  Future<Map<String, dynamic>> start({
    required PullRequest pr,
    ReviewLevel? level,
  }) {
    starts++;
    state = {
      ...state,
      (repoFullName: pr.repoFullName, prNumber: pr.number),
    };
    return completer.future;
  }
}

/// The PR identity PrDetailActions is keyed by in this suite.
const _prRef = (workspaceId: 'ws-1', repoFullName: 'test/repo', number: 42);

void main() {
  testWidgets('Ask AI opens the review tab immediately, not when the start '
      'call answers', (tester) async {
    final starter = _HangingStarter();
    var opened = 0;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          prReviewStarterProvider.overrideWith(() => starter),
          activeWorkspaceIdProvider.overrideWith(_FixedWorkspaceId.new),
          prRepoRowProvider(_prRef).overrideWith((ref) => _repo()),
          prDetailProvider(_prRef).overrideWith((ref) => Stream.value(null)),
          currentUserLoginProvider.overrideWithValue('tester'),
          currentUserLoginForPrProvider(_prRef).overrideWithValue('tester'),
          repoPermissionProvider((
            owner: 'test',
            repo: 'repo',
          )).overrideWith((ref) async => 'read'),
          // No detected editor, so the Open-in-IDE split button renders
          // nothing and the row is the refresh control + the overflow menu.
          installedEditorsProvider.overrideWith((ref) async => const []),
          prCheckRunsProvider(_prRef).overrideWith((ref) => Stream.value(const [])),
          prReviewsProvider(_prRef).overrideWith((ref) => Stream.value(const [])),
          activeWorkspaceProvider.overrideWithValue(
            Workspace(
              id: 'ws-1',
              name: 'Workspace',
              createdAt: DateTime(2025),
              updatedAt: DateTime(2025),
            ),
          ),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          builder: (context, child) =>
              CcTheme(data: CcThemeData.light(), child: child!),
          home: CcTheme(
            data: CcThemeData.light(),
            child: CcToastScope(
              child: Scaffold(
                body: Center(
                  child: PrDetailActions(
                    pr: _pr(),
                    prRef: _prRef,
                    onOpenReview: () => opened++,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final l10n = await AppLocalizations.delegate.load(const Locale('en'));
    await tester.tap(find.byType(CcIconButton).last);
    await tester.pumpAndSettle();

    await tester.tap(find.text(l10n.askAi));
    await tester.pump();

    expect(starter.starts, 1);
    expect(
      opened,
      1,
      reason:
          'the tab must open on the press: the start call does not answer '
          'until the PR worktree is provisioned, and the run it shows already '
          'exists by then',
    );
    expect(starter.completer.isCompleted, isFalse);

    starter.completer.complete({'status': 'started'});
    await tester.pumpAndSettle();
    expect(opened, 1, reason: 'the answer must not re-focus the tab');
  });
}
