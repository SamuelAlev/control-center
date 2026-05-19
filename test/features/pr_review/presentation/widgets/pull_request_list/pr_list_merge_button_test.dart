import 'package:cc_domain/core/domain/entities/repo.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pr_user.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pull_request.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/pr_review/presentation/widgets/pull_request_list/pr_list_merge_button.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Creates a [PullRequest] with defaults for merge button testing.
PullRequest _pr({
  int number = 42,
  String title = 'Add widget tests',
  String body = 'This PR adds comprehensive widget tests.',
  PrChecksStatus checksStatus = PrChecksStatus.none,
  PrMergeableState mergeableState = PrMergeableState.clean,
}) {
  return PullRequest(
    id: number,
    number: number,
    title: title,
    body: body,
    state: PrState.open,
    isDraft: false,
    author: const PrUser(login: 'test-user', avatarUrl: ''),
    createdAt: DateTime(2024, 1, 1),
    updatedAt: DateTime(2024, 6, 10),
    repoFullName: 'owner/repo',
    htmlUrl: 'https://github.com/owner/repo/pull/$number',
    checksStatus: checksStatus,
    mergeableState: mergeableState,
  );
}

/// Creates a test [Repo].
Repo _repo() {
  return Repo(
    id: 'repo-1',
    name: 'owner/repo',
    path: '/home/user/repo',
    githubOwner: 'owner',
    githubRepoName: 'repo',
    createdAt: DateTime(2024, 1, 1),
    updatedAt: DateTime(2024, 6, 10),
  );
}

/// Like `testWrap` but adds a `Material` ancestor above the `Navigator` so that
/// dialog routes (which use [RawDialogRoute]) have a [Material] ancestor
/// for Material widgets like [TextField].
Widget _dialogTestWrap(Widget child) {
  return ProviderScope(
    overrides: [
      activeRepoProvider.overrideWith((ref) => null),
      activeWorkspaceProvider.overrideWith((ref) => null),
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
      builder: (context, child) {
        return Material(
          child: CcTheme(
            data: CcThemeData.light(),
            child: child ?? const SizedBox.shrink(),
          ),
        );
      },
      home: Scaffold(body: child),
    ),
  );
}

void main() {
  group('PrListMergeButton', () {
    testWidgets('renders merge button with text and icon', (tester) async {
      await tester.pumpWidget(_dialogTestWrap(
        PrListMergeButton(pr: _pr(), repo: _repo()),
      ));

      expect(find.text('Merge'), findsOneWidget);
      expect(find.byIcon(LucideIcons.gitMerge), findsOneWidget);
    });

    testWidgets('opens merge dialog on tap', (tester) async {
      await tester.pumpWidget(_dialogTestWrap(
        PrListMergeButton(pr: _pr(), repo: _repo()),
      ));

      await tester.tap(find.text('Merge'));
      await tester.pumpAndSettle();

      expect(find.text('Merge pull request'), findsOneWidget);
    });

    testWidgets('dialog shows PR title with number', (tester) async {
      const title = 'Fix login bug';
      await tester.pumpWidget(_dialogTestWrap(
        PrListMergeButton(
          pr: _pr(number: 42, title: title),
          repo: _repo(),
        ),
      ));

      await tester.tap(find.text('Merge'));
      await tester.pumpAndSettle();

      // The title appears in the PrTitleText widget.
      expect(find.text(title), findsAtLeastNWidgets(1));
    });

    testWidgets('dialog shows method selector with all three options',
        (tester) async {
      await tester.pumpWidget(_dialogTestWrap(
        PrListMergeButton(pr: _pr(), repo: _repo()),
      ));

      await tester.tap(find.text('Merge'));
      await tester.pumpAndSettle();

      expect(find.text('Squash and merge'), findsOneWidget);
      expect(find.text('Create a merge commit'), findsOneWidget);
      expect(find.text('Rebase and merge'), findsOneWidget);
    });

    testWidgets('default method is squash with commit fields visible',
        (tester) async {
      await tester.pumpWidget(_dialogTestWrap(
        PrListMergeButton(pr: _pr(), repo: _repo()),
      ));

      await tester.tap(find.text('Merge'));
      await tester.pumpAndSettle();

      // Commit title and description fields should be visible for squash.
      expect(find.byType(TextField), findsNWidgets(2));
    });

    testWidgets('switching to rebase hides commit fields', (tester) async {
      await tester.pumpWidget(_dialogTestWrap(
        PrListMergeButton(pr: _pr(), repo: _repo()),
      ));

      await tester.tap(find.text('Merge'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Rebase and merge'));
      await tester.pumpAndSettle();

      expect(find.byType(TextField), findsNothing);
    });

    testWidgets('switching to merge shows commit fields again', (tester) async {
      await tester.pumpWidget(_dialogTestWrap(
        PrListMergeButton(pr: _pr(), repo: _repo()),
      ));

      await tester.tap(find.text('Merge'));
      await tester.pumpAndSettle();

      // Switch to rebase first.
      await tester.tap(find.text('Rebase and merge'));
      await tester.pumpAndSettle();
      // Then back to merge.
      await tester.tap(find.text('Create a merge commit'));
      await tester.pumpAndSettle();

      expect(find.byType(TextField), findsNWidgets(2));
    });

    testWidgets('shows checks warning when failing', (tester) async {
      await tester.pumpWidget(_dialogTestWrap(
        PrListMergeButton(
          pr: _pr(checksStatus: PrChecksStatus.failing),
          repo: _repo(),
        ),
      ));

      await tester.tap(find.text('Merge'));
      await tester.pumpAndSettle();

      expect(find.text('Checks failing'), findsOneWidget);
    });

    testWidgets('shows checks warning when pending', (tester) async {
      await tester.pumpWidget(_dialogTestWrap(
        PrListMergeButton(
          pr: _pr(checksStatus: PrChecksStatus.pending),
          repo: _repo(),
        ),
      ));

      await tester.tap(find.text('Merge'));
      await tester.pumpAndSettle();

      expect(find.text('Checks running'), findsOneWidget);
    });

    testWidgets('no checks warning when passing', (tester) async {
      await tester.pumpWidget(_dialogTestWrap(
        PrListMergeButton(
          pr: _pr(checksStatus: PrChecksStatus.passing),
          repo: _repo(),
        ),
      ));

      await tester.tap(find.text('Merge'));
      await tester.pumpAndSettle();

      expect(find.text('Checks failing'), findsNothing);
      expect(find.text('Checks running'), findsNothing);
    });

    testWidgets('no checks warning when none', (tester) async {
      await tester.pumpWidget(_dialogTestWrap(
        PrListMergeButton(
          pr: _pr(checksStatus: PrChecksStatus.none),
          repo: _repo(),
        ),
      ));

      await tester.tap(find.text('Merge'));
      await tester.pumpAndSettle();

      expect(find.text('Checks failing'), findsNothing);
      expect(find.text('Checks running'), findsNothing);
    });

    testWidgets('force-merge label when checks are failing', (tester) async {
      await tester.pumpWidget(_dialogTestWrap(
        PrListMergeButton(
          pr: _pr(checksStatus: PrChecksStatus.failing),
          repo: _repo(),
        ),
      ));

      await tester.tap(find.text('Merge'));
      await tester.pumpAndSettle();

      expect(find.text('Force merge pull request'), findsOneWidget);
    });

    testWidgets('force-merge label when checks are pending', (tester) async {
      await tester.pumpWidget(_dialogTestWrap(
        PrListMergeButton(
          pr: _pr(checksStatus: PrChecksStatus.pending),
          repo: _repo(),
        ),
      ));

      await tester.tap(find.text('Merge'));
      await tester.pumpAndSettle();

      expect(find.text('Force merge pull request'), findsOneWidget);
    });

    testWidgets('normal merge label when checks are passing', (tester) async {
      await tester.pumpWidget(_dialogTestWrap(
        PrListMergeButton(
          pr: _pr(checksStatus: PrChecksStatus.passing),
          repo: _repo(),
        ),
      ));

      await tester.tap(find.text('Merge'));
      await tester.pumpAndSettle();

      expect(find.text('Force merge pull request'), findsNothing);
      // The initial button and the dialog action both say "Merge".
      expect(find.text('Merge'), findsNWidgets(2));
    });

    testWidgets('cancel button dismisses dialog', (tester) async {
      await tester.pumpWidget(_dialogTestWrap(
        PrListMergeButton(pr: _pr(), repo: _repo()),
      ));

      await tester.tap(find.text('Merge'));
      await tester.pumpAndSettle();

      expect(find.text('Merge pull request'), findsOneWidget);

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(find.text('Merge pull request'), findsNothing);
    });
  });
}
