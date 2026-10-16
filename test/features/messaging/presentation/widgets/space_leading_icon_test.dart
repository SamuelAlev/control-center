import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:cc_domain/features/pr_review/domain/entities/pull_request.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/messaging/presentation/widgets/pr_status_badge.dart';
import 'package:control_center/features/messaging/presentation/widgets/space_row_adornments.dart';
import 'package:control_center/features/pr_review/providers/pr_review_providers.dart';
import 'package:control_center/features/pr_review/providers/pr_space_provider.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/rendering.dart' show RenderRepaintBoundary;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:riverpod/src/framework.dart' show Override;

import '../../../../helpers/test_wrap.dart';

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
  bool selected = false,
  bool running = false,
  int unreadConversationCount = 0,
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
              running: running,
              selected: selected,
              unreadConversationCount: unreadConversationCount,
              absent: absent,
            ),
          ),
        ),
      ),
    ),
  );
}

void main() {
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

  testWidgets('only a complete all-merged inventory shows a full merge icon', (
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
    expect(find.byIcon(AppIcons.gitMerge), findsOneWidget);
    expect(find.byIcon(AppIcons.gitPullRequest), findsOneWidget);
    expect(find.byType(ClipPath), findsNWidgets(2));

    snapshots.add((matches: [merged], complete: true));
    await tester.pumpAndSettle();
    expect(find.byIcon(AppIcons.gitPullRequest), findsNothing);
    expect(find.byType(ClipPath), findsNothing);
    final context = tester.element(find.byType(SpaceLeadingIcon));
    expect(
      tester.widget<CcTooltip>(find.byType(CcTooltip)).message,
      AppLocalizations.of(context).spaceAllPrsMergedLabel,
    );
  });

  for (final (state, draft, icon) in [
    (PrState.closed, false, AppIcons.gitPullRequestClosed),
    (PrState.open, true, AppIcons.gitPullRequestDraft),
  ]) {
    testWidgets('merged plus $state draft=$draft shows both glyphs', (
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
      expect(find.byIcon(AppIcons.gitMerge), findsOneWidget);
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

  for (final count in [2, 3, 4]) {
    testWidgets(
      '$count distinct states get equal sectors, not PR-weighted ones',
      (tester) async {
        final prs = [
          _pr(state: PrState.closed, isDraft: true),
          for (var i = 0; i < 5; i++) _pr(number: i + 2, state: PrState.merged),
          if (count >= 3) _pr(number: 7),
          if (count == 4) _pr(number: 8, isDraft: true),
        ];
        await _pump(
          tester,
          selected: true,
          unreadConversationCount: 2,
          overrides: [
            spacePullRequestsProvider('space-1').overrideWithValue(prs),
          ],
        );
        final paths = tester
            .widgetList<ClipPath>(find.byType(ClipPath))
            .map((clip) => clip.clipper!.getClip(const Size.square(18)))
            .toList();
        expect(paths, hasLength(count));
        final samples = List.filled(count, 0);
        for (var degree = 0; degree < 360; degree++) {
          final angle = (degree + 0.5) * math.pi / 180;
          final point = Offset(
            9 + 8 * math.cos(angle),
            9 + 8 * math.sin(angle),
          );
          final coveringSectors = [
            for (var i = 0; i < paths.length; i++)
              if (paths[i].contains(point)) i,
          ];
          expect(coveringSectors, hasLength(1));
          samples[coveringSectors.single]++;
        }
        expect(samples, everyElement(360 ~/ count));
        for (final state in PrSidebarStatus.values) {
          final present = PrSidebarStatus.aggregate(prs) & state.mask != 0;
          if (present) {
            expect(
              tester.widget<Icon>(find.byIcon(state.icon)).color,
              state.color,
            );
          } else {
            expect(find.byIcon(state.icon), findsNothing);
          }
        }
        final context = tester.element(find.byType(SpaceLeadingIcon));
        final l10n = AppLocalizations.of(context);
        final tooltip = tester.widget<CcTooltip>(
          find.descendant(
            of: find.byType(PrStatusBadge),
            matching: find.byType(CcTooltip),
          ),
        );
        for (final state in PrSidebarStatus.values) {
          if (PrSidebarStatus.aggregate(prs) & state.mask != 0) {
            expect(tooltip.message, contains(state.label(l10n)));
          }
        }
        expect(tooltip.message, isNot(l10n.spaceAllPrsMergedLabel));
        expect(find.text('2'), findsOneWidget);
      },
    );
  }

  testWidgets('running keeps its spinner and unread count instead of the pie', (
    tester,
  ) async {
    await _pump(
      tester,
      running: true,
      unreadConversationCount: 2,
      overrides: [
        spacePullRequestsProvider('space-1').overrideWithValue([
          _pr(state: PrState.closed),
          _pr(state: PrState.merged, number: 2),
        ]),
      ],
    );
    expect(find.byType(CcSpinner), findsOneWidget);
    expect(find.byIcon(AppIcons.gitMerge), findsNothing);
    expect(find.byIcon(AppIcons.gitPullRequestClosed), findsNothing);
    expect(find.text('2'), findsOneWidget);
  });

  for (final count in [1, 2, 3, 4]) {
    testWidgets('$count states paint dividers only at mixed-state boundaries', (
      tester,
    ) async {
      final boundary = GlobalKey();
      for (final theme in [CcThemeData.light(), CcThemeData.dark()]) {
        await tester.pumpWidget(
          testWrap(
            CcTheme(
              data: theme,
              child: RepaintBoundary(
                key: boundary,
                child: SizedBox.square(
                  dimension: 18,
                  child: ColoredBox(
                    color: theme.tokens.bgPrimary,
                    child: PrStatusBadge(statusMask: (1 << count) - 1),
                  ),
                ),
              ),
            ),
          ),
        );
        final samples = await tester.runAsync(() async {
          final render =
              boundary.currentContext!.findRenderObject()!
                  as RenderRepaintBoundary;
          final image = await render.toImage(pixelRatio: 4);
          final data = await image.toByteData(
            format: ui.ImageByteFormat.rawRgba,
          );
          final colors = <Color>[];
          for (var i = 0; i < count; i++) {
            final angle = -math.pi / 2 + 2 * math.pi * i / count;
            final x = (36 + 18 * math.cos(angle)).floor();
            final y = (36 + 18 * math.sin(angle)).floor();
            final offset = (y * image.width + x) * 4;
            colors.add(
              Color.fromARGB(
                data!.getUint8(offset + 3),
                data.getUint8(offset),
                data.getUint8(offset + 1),
                data.getUint8(offset + 2),
              ),
            );
          }
          image.dispose();
          return colors;
        });
        expect(
          samples,
          everyElement(
            count == 1
                ? isNot(theme.tokens.borderPrimary)
                : theme.tokens.borderPrimary,
          ),
        );
      }
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    });
  }
}
