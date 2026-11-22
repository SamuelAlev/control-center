import 'package:cc_domain/features/pr_review/domain/entities/pull_request.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/messaging/presentation/widgets/pr_sidebar_status.dart';
import 'package:control_center/features/messaging/presentation/widgets/space_pr_subtitle.dart';
import 'package:control_center/features/pr_review/providers/pr_space_provider.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/test_wrap.dart';

PullRequest _pr(
  int number, {
  PrState state = PrState.open,
  bool isDraft = false,
  PrChecksStatus checks = PrChecksStatus.none,
  String repo = 'acme/shop-ui',
  String? head,
  String base = 'main',
}) => PullRequest(
  id: number,
  number: number,
  title: 'PR $number',
  body: '',
  state: state,
  isDraft: isDraft,
  author: null,
  createdAt: DateTime.utc(2026),
  updatedAt: DateTime.utc(2026),
  repoFullName: repo,
  htmlUrl: 'https://example.invalid/$repo/pull/$number',
  headRef: head ?? 'space/$number',
  baseRef: base,
  checksStatus: checks,
);

void main() {
  Future<void> pump(
    WidgetTester tester,
    List<PullRequest> prs, {
    bool selected = false,
  }) => tester.pumpWidget(
    ProviderScope(
      overrides: [spacePullRequestsProvider('space-1').overrideWithValue(prs)],
      child: testWrap(
        Consumer(
          builder: (context, ref, _) {
            final rows = ref.watch(spaceRowPrsProvider('space-1'));
            if (rows.isEmpty) {
              return const Text('none');
            }
            return DefaultTextStyle(
              style: CcTypography.caption,
              child: SpacePrSubtitle(prs: rows, selected: selected),
            );
          },
        ),
      ),
    ),
  );

  String plain(WidgetTester tester) => tester
      .widget<RichText>(
        find
            .descendant(
              of: find.byType(SpacePrSubtitle),
              matching: find.byType(RichText),
            )
            .first,
      )
      .text
      .toPlainText(includePlaceholders: false);

  testWidgets('a space with no PR has no subtitle', (tester) async {
    await pump(tester, const []);

    expect(find.text('none'), findsOneWidget);
    expect(find.byType(SpacePrSubtitle), findsNothing);
  });

  testWidgets('one PR shows its state glyph, number and checks', (
    tester,
  ) async {
    await pump(tester, [_pr(761, checks: PrChecksStatus.passing)]);

    expect(plain(tester), contains('761'));
    final tokens = DesignSystemTokens.light();
    expect(
      tester.widget<Icon>(find.byIcon(AppIcons.gitPullRequest)).color,
      PrSidebarStatus.open.color,
    );
    expect(
      tester.widget<Icon>(find.byIcon(AppIcons.checkCircle)).color,
      tokens.success,
    );
    final l10n = AppLocalizations.of(
      tester.element(find.byType(SpacePrSubtitle)),
    );
    final tooltip = tester.widget<CcTooltip>(find.byType(CcTooltip));
    expect(tooltip.message, contains('acme/shop-ui#761'));
    expect(tooltip.message, contains(l10n.openStatus));
    expect(tooltip.message, contains(l10n.checksPassing));
  });

  testWidgets('unrelated PRs list in order; finished ones drop checks', (
    tester,
  ) async {
    await pump(tester, [
      _pr(764, isDraft: true, checks: PrChecksStatus.pending),
      _pr(762, state: PrState.merged, checks: PrChecksStatus.failing),
      _pr(763, checks: PrChecksStatus.failing),
    ]);

    final text = plain(tester);
    expect(text.indexOf('762'), lessThan(text.indexOf('763')));
    expect(text.indexOf('763'), lessThan(text.indexOf('764')));
    expect(find.byIcon(AppIcons.gitMerge), findsOneWidget);
    expect(find.byIcon(AppIcons.gitPullRequest), findsOneWidget);
    expect(find.byIcon(AppIcons.gitPullRequestDraft), findsOneWidget);
    expect(find.byIcon(AppIcons.layers), findsNothing);
    // The merged PR's failing checks no longer matter; the open one's do.
    expect(find.byIcon(AppIcons.xCircle), findsOneWidget);
    expect(find.byIcon(AppIcons.clock3), findsOneWidget);
  });

  testWidgets('a stack folds into one entry with its worst open checks', (
    tester,
  ) async {
    await pump(tester, [
      _pr(
        18320,
        isDraft: true,
        head: 'l3',
        base: 'l2',
        checks: PrChecksStatus.pending,
      ),
      _pr(18318, isDraft: true, head: 'l1', checks: PrChecksStatus.passing),
      _pr(
        18319,
        isDraft: true,
        head: 'l2',
        base: 'l1',
        checks: PrChecksStatus.passing,
      ),
      _pr(480, checks: PrChecksStatus.passing),
    ]);

    final text = plain(tester);
    expect(text, contains('18318–18320'));
    expect(text, isNot(contains('18319')));
    expect(text.indexOf('480'), lessThan(text.indexOf('18318')));
    expect(find.byIcon(AppIcons.layers), findsOneWidget);
    expect(
      tester.widget<Icon>(find.byIcon(AppIcons.layers)).color,
      PrSidebarStatus.draft.color,
    );
    // The stack's running layer wins over its passing ones.
    expect(find.byIcon(AppIcons.clock3), findsOneWidget);
    expect(find.byIcon(AppIcons.checkCircle), findsOneWidget);
    // The tooltip still names every layer.
    final tooltip = tester.widget<CcTooltip>(find.byType(CcTooltip));
    for (final number in [18318, 18319, 18320]) {
      expect(tooltip.message, contains('acme/shop-ui#$number'));
    }
  });

  test('stacks group per repository and by base chain', () {
    final groups = groupSpaceRowPrs([
      _pr(3, head: 'c', base: 'b'),
      _pr(1, head: 'a'),
      _pr(2, head: 'b', base: 'a'),
      // Same branch names in another repository stay apart.
      _pr(9, head: 'b', base: 'a', repo: 'acme/api-server'),
      // A base cycle never loses a PR.
      _pr(7, head: 'x', base: 'y'),
      _pr(8, head: 'y', base: 'x'),
    ]);

    expect(
      [for (final g in groups) g.prs.map((pr) => pr.number).toList()],
      [
        [9],
        [1, 2, 3],
        [7, 8],
      ],
    );
  });

  testWidgets('on the solid selected fill every glyph takes accentOn', (
    tester,
  ) async {
    await pump(tester, [
      _pr(761, checks: PrChecksStatus.passing),
    ], selected: true);

    final accentOn = DesignSystemTokens.light().accentOn;
    for (final icon in [AppIcons.gitPullRequest, AppIcons.checkCircle]) {
      expect(tester.widget<Icon>(find.byIcon(icon)).color, accentOn);
    }
  });

  test('an unchanged inventory compares equal across refreshes', () {
    final container = ProviderContainer(
      overrides: [
        spacePullRequestsProvider(
          'space-1',
        ).overrideWith((ref) => [_pr(2), _pr(1)]),
      ],
    );
    addTearDown(container.dispose);
    final first = container.read(spaceRowPrsProvider('space-1'));
    container.invalidate(spacePullRequestsProvider('space-1'));
    final second = container.read(spaceRowPrsProvider('space-1'));

    expect(second, first);
    expect(first.groups.map((group) => group.prs.single.number), [1, 2]);
  });
}
