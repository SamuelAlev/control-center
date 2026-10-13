import 'dart:async';

import 'package:cc_domain/features/pr_review/domain/entities/pull_request.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/messaging/presentation/widgets/space_row_adornments.dart';
import 'package:control_center/features/pr_review/providers/pr_review_providers.dart';
import 'package:control_center/features/pr_review/providers/pr_space_provider.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:riverpod/src/framework.dart' show Override;

PullRequest _pr({
  PrState state = PrState.open,
  int number = 33982,
  bool isDraft = false,
}) {
  return PullRequest(
    id: number,
    number: number,
    title: 'feat: add saml logout links endpoint',
    body: '',
    state: state,
    isDraft: isDraft,
    author: null,
    createdAt: DateTime.utc(2026),
    updatedAt: DateTime.utc(2026),
    repoFullName: 'control-center/control-center',
    htmlUrl: 'https://example.invalid/control-center/control-center/pull/33982',
    headRef: 'space/6b2256bb',
    baseRef: 'main',
  );
}

Future<void> _pump(
  WidgetTester tester, {
  required List<Override> overrides,
  Widget? absent,
  bool linkedResolved = true,
}) {
  return tester.pumpWidget(
    ProviderScope(
      overrides: [
        spacePrsResolvedProvider('space-1').overrideWithValue(linkedResolved),
        ...overrides,
      ],
      child: CcTheme(
        data: CcThemeData.light(),
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: SpaceLeadingIcon(
              spaceId: 'space-1',
              running: false,
              selected: false,
              absent: absent,
            ),
          ),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('an open PR on the space branch badges the row with 1', (
    tester,
  ) async {
    await _pump(
      tester,
      overrides: [
        spacePrsProvider('space-1').overrideWithValue(const []),
        spaceBranchPullRequestsProvider('space-1').overrideWith(
          (ref) => Stream.value((
            complete: true,
            matches: [
              (
                repoId: 'repo-1',
                repoFullName: 'control-center/control-center',
                branch: 'space/6b2256bb',
                pr: _pr(),
              ),
            ],
          )),
        ),
      ],
    );
    await tester.pump();

    expect(find.byIcon(AppIcons.gitPullRequest), findsOneWidget);
    expect(find.text('1'), findsOneWidget);
    expect(find.byIcon(AppIcons.pencil), findsNothing);
  });

  testWidgets('a space with no PR keeps the pencil', (tester) async {
    await _pump(
      tester,
      overrides: [
        spacePrsProvider('space-1').overrideWithValue(const []),
        spaceBranchPullRequestsProvider('space-1').overrideWith(
          (ref) => Stream.value((complete: true, matches: const [])),
        ),
      ],
    );
    await tester.pump();

    expect(find.byIcon(AppIcons.pencil), findsOneWidget);
    expect(find.byIcon(AppIcons.gitPullRequest), findsNothing);
    expect(find.text('1'), findsNothing);
  });

  testWidgets('an absent mark replaces the pencil when the space has no PR', (
    tester,
  ) async {
    await _pump(
      tester,
      absent: const Text('empty'),
      overrides: [
        spacePrsProvider('space-1').overrideWithValue(const []),
        spaceBranchPullRequestsProvider('space-1').overrideWith(
          (ref) => Stream.value((complete: true, matches: const [])),
        ),
      ],
    );
    await tester.pump();

    expect(find.text('empty'), findsOneWidget);
    expect(find.byIcon(AppIcons.pencil), findsNothing);
  });

  testWidgets('an open PR still badges the row when an absent mark is set', (
    tester,
  ) async {
    await _pump(
      tester,
      absent: const Text('empty'),
      overrides: [
        spacePrsProvider('space-1').overrideWithValue(const []),
        spaceBranchPullRequestsProvider('space-1').overrideWith(
          (ref) => Stream.value((
            complete: true,
            matches: [
              (
                repoId: 'repo-1',
                repoFullName: 'control-center/control-center',
                branch: 'space/6b2256bb',
                pr: _pr(),
              ),
            ],
          )),
        ),
      ],
    );
    await tester.pump();

    expect(find.byIcon(AppIcons.gitPullRequest), findsOneWidget);
    expect(find.text('1'), findsOneWidget);
    expect(find.text('empty'), findsNothing);
  });

  testWidgets('only a complete merged inventory shows the purple merge icon', (
    tester,
  ) async {
    final snapshots = StreamController<SpaceBranchPrSnapshot>();
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox());
      await snapshots.close();
    });
    await _pump(
      tester,
      overrides: [
        spacePrsProvider('space-1').overrideWithValue(const []),
        spaceBranchPullRequestsProvider(
          'space-1',
        ).overrideWith((ref) => snapshots.stream),
      ],
    );
    final merged = (
      repoId: 'repo-1',
      repoFullName: 'control-center/control-center',
      branch: 'space/6b2256bb',
      pr: _pr(state: PrState.merged),
    );
    snapshots.add((matches: [merged], complete: false));
    await tester.pumpAndSettle();
    expect(find.byIcon(AppIcons.gitMerge), findsNothing);

    snapshots.add((matches: [merged], complete: true));
    await tester.pumpAndSettle();
    expect(find.byIcon(AppIcons.gitMerge), findsOneWidget);
    expect(
      tester.widget<Icon>(find.byIcon(AppIcons.gitMerge)).color,
      DesignSystemPalette.purple600,
    );
    expect(find.text('1'), findsNothing);

    snapshots.add((
      matches: [
        merged,
        (
          repoId: 'repo-1',
          repoFullName: merged.repoFullName,
          branch: merged.branch,
          pr: _pr(number: 33983),
        ),
      ],
      complete: true,
    ));
    await tester.pumpAndSettle();
    expect(find.byIcon(AppIcons.gitMerge), findsNothing);
    expect(find.byIcon(AppIcons.gitPullRequest), findsOneWidget);
    expect(find.text('1'), findsOneWidget);
  });

  for (final (state, draft, icon) in [
    (PrState.closed, false, AppIcons.gitPullRequestClosed),
    (PrState.open, true, AppIcons.gitPullRequestDraft),
  ]) {
    testWidgets('merged plus $state draft=$draft is not fully merged', (
      tester,
    ) async {
      await _pump(
        tester,
        overrides: [
          spacePrsProvider('space-1').overrideWithValue([
            _pr(state: PrState.merged),
            _pr(number: 33983, state: state, isDraft: draft),
          ]),
          spaceBranchPullRequestsProvider('space-1').overrideWith(
            (ref) => Stream.value((matches: const [], complete: true)),
          ),
        ],
      );
      await tester.pump();
      expect(find.byIcon(AppIcons.gitMerge), findsNothing);
      expect(find.byIcon(icon), findsOneWidget);
    });
  }

  testWidgets('unresolved linked PRs cannot produce a merged badge', (
    tester,
  ) async {
    await _pump(
      tester,
      linkedResolved: false,
      overrides: [
        spacePrsProvider(
          'space-1',
        ).overrideWithValue([_pr(state: PrState.merged)]),
        spaceBranchPullRequestsProvider('space-1').overrideWith(
          (ref) => Stream.value((matches: const [], complete: true)),
        ),
      ],
    );
    await tester.pump();
    expect(find.byIcon(AppIcons.gitMerge), findsNothing);
  });
}
