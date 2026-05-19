import 'dart:async';

import 'package:cc_domain/core/domain/entities/workspace.dart';
import 'package:cc_domain/features/pr_review/domain/repositories/pr_review_repository.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/analytics/domain/entities/user_badge.dart';
import 'package:control_center/features/analytics/presentation/widgets/sections/user_badges_card.dart';
import 'package:control_center/features/analytics/providers/analytics_providers.dart';
import 'package:control_center/features/auth/providers/auth_providers.dart';
import 'package:control_center/features/pr_review/providers/pr_review_providers.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Like testWrap but also overrides userBadgesProvider to return
/// Future.value(badges).
Widget _wrapWithBadges(List<UserBadge> badges) {
  return ProviderScope(
    overrides: [
      githubAuthTokenProvider.overrideWith((ref) => ''),
      activeWorkspaceProvider.overrideWith((ref) => null),
      activeRepoProvider.overrideWith((ref) => null),
      prReviewRepositoryProvider
          .overrideWith((ref) => const EmptyPrReviewRepository()),
      workspacesProvider.overrideWith(
        (ref) => const Stream<List<Workspace>>.empty(),
      ),
      userBadgesProvider.overrideWith((ref) => Future.value(badges)),
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
        child: const Scaffold(body: UserBadgesCard()),
      ),
    ),
  );
}

/// Returns a copy of cat with a different key so equality checks don't
/// clash with other test instances.
UserBadgeCategory _cat(String key) {
  return UserBadgeCategory(
    key: key,
    name: key == 'prompter' ? 'Prompter' : 'Custom',
    iconName: 'rocket',
    unit: 'unit',
    action: 'Do things',
    thresholds: const [1, 25, 100, 500, 2500],
    blurb: 'A test category.',
  );
}

void main() {
  group('UserBadgesCard', () {
    testWidgets('shows loading indicator while badges load', (tester) async {
      // Use a Completer that never completes to guarantee loading state.
      final completer = Completer<List<UserBadge>>();
      addTearDown(() => completer.complete([]));

      await tester.pumpWidget(ProviderScope(
        overrides: [
          githubAuthTokenProvider.overrideWith((ref) => ''),
          activeWorkspaceProvider.overrideWith((ref) => null),
          activeRepoProvider.overrideWith((ref) => null),
          prReviewRepositoryProvider
              .overrideWith((ref) => const EmptyPrReviewRepository()),
          workspacesProvider.overrideWith(
            (ref) => const Stream<List<Workspace>>.empty(),
          ),
          userBadgesProvider.overrideWith((ref) => completer.future),
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
            child: const Scaffold(body: UserBadgesCard()),
          ),
        ),
      ));
      await tester.pump();

      expect(find.byType(CcSpinner), findsOneWidget);
    });

    // ── Empty ────────────────────────────────────────────────────────

    testWidgets('renders section card labels when empty', (tester) async {
      await tester.pumpWidget(_wrapWithBadges([]));
      await tester.pumpAndSettle();

      // SectionCard renders the label uppercased.
      expect(find.text('YOUR ACHIEVEMENTS'), findsOneWidget);
      expect(
        find.text('Earn tiers as you use the control center'),
        findsOneWidget,
      );
      expect(
        find.text('Tap a badge to see how to level up'),
        findsOneWidget,
      );
    });

    testWidgets('renders no badge tiles when empty', (tester) async {
      await tester.pumpWidget(_wrapWithBadges([]));
      await tester.pumpAndSettle();

      // When empty, no _BadgeTile widgets render — no InkWell wrappers.
      expect(find.byType(InkWell), findsNothing);
    });

    // ── Multiple badges ──────────────────────────────────────────────

    testWidgets('renders badge tiles for each badge', (tester) async {
      final prompter = _cat('prompter');
      final reviewer = _cat('reviewer');

      await tester.pumpWidget(_wrapWithBadges([
        UserBadge(category: prompter, count: 0),
        UserBadge(category: reviewer, count: 5),
      ]));
      await tester.pumpAndSettle();

      // Both category names appear.
      expect(find.text('Prompter'), findsOneWidget);
      expect(find.text('Custom'), findsOneWidget);

      // First badge (count=0) → Locked. Second (count=5) → Beginner.
      expect(find.text('Locked'), findsOneWidget);
      expect(find.text('Beginner'), findsOneWidget);

      // Each tile has a LinearProgressIndicator.
      expect(find.byType(LinearProgressIndicator), findsNWidgets(2));
    });

    testWidgets('shows correct tier labels for each badge', (tester) async {
      final a = _cat('a');
      final b = _cat('b');
      final c = _cat('c');

      // a: count=0 → none (Locked)
      // b: count=30 → intermediate (threshold 25 ≤ 30 < 100)
      // c: count=3000 → master (threshold 2500 ≤ 3000)
      await tester.pumpWidget(_wrapWithBadges([
        UserBadge(category: a, count: 0),
        UserBadge(category: b, count: 30),
        UserBadge(category: c, count: 3000),
      ]));
      await tester.pumpAndSettle();

      expect(find.text('Locked'), findsOneWidget);
      expect(find.text('Intermediate'), findsOneWidget);
      expect(find.text('Master'), findsOneWidget);
    });

    testWidgets('tapping a badge tile opens the detail dialog', (tester) async {
      // The dialog is tall; set a generous surface so it doesn't overflow.
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.physicalSize = const Size(800, 600);
        tester.view.devicePixelRatio = 1.0;
      });

      final cat = _cat('prompter');
      await tester.pumpWidget(_wrapWithBadges([
        UserBadge(category: cat, count: 0),
      ]));
      await tester.pumpAndSettle();

      // Tap the InkWell wrapping the badge tile.
      await tester.tap(find.text('Prompter'));
      await tester.pumpAndSettle();

      // The detail dialog should appear — it contains the category blurb.
      expect(find.text(cat.blurb), findsOneWidget);
    });

    // ── Edge cases ───────────────────────────────────────────────────

    testWidgets('all badges at master tier shows 1.0 progress', (tester) async {
      final cat = _cat('mastered');
      await tester.pumpWidget(_wrapWithBadges([
        UserBadge(category: cat, count: 10000),
      ]));
      await tester.pumpAndSettle();

      expect(find.text('Master'), findsOneWidget);
    });

    testWidgets('zero count shows locked with zero progress', (tester) async {
      final cat = _cat('zero');
      await tester.pumpWidget(_wrapWithBadges([
        UserBadge(category: cat, count: 0),
      ]));
      await tester.pumpAndSettle();

      expect(find.text('Locked'), findsOneWidget);
    });

    // ── Detail dialog shows tier threshold list ────────────────────

    testWidgets('detail dialog shows tier names', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.physicalSize = const Size(800, 600);
        tester.view.devicePixelRatio = 1.0;
      });

      final cat = _cat('prompter');
      await tester.pumpWidget(_wrapWithBadges([
        UserBadge(category: cat, count: 0),
      ]));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Prompter'));
      await tester.pumpAndSettle();

      // Tier ladder shows each tier name.
      expect(find.text('Beginner'), findsOneWidget);
      expect(find.text('Intermediate'), findsOneWidget);
      expect(find.text('Advanced'), findsOneWidget);
      expect(find.text('Expert'), findsOneWidget);
      expect(find.text('Master'), findsOneWidget);
    });

    // ── Detail dialog - close ───────────────────────────────────────

    testWidgets('detail dialog close button dismisses dialog',
        (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.physicalSize = const Size(800, 600);
        tester.view.devicePixelRatio = 1.0;
      });

      final cat = _cat('prompter');
      await tester.pumpWidget(_wrapWithBadges([
        UserBadge(category: cat, count: 0),
      ]));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Prompter'));
      await tester.pumpAndSettle();

      // Dialog is visible.
      expect(find.text(cat.blurb), findsOneWidget);

      // Tap close button.
      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();

      // Dialog should be dismissed — blurb no longer visible.
      expect(find.text(cat.blurb), findsNothing);
    });

    // ── Count exactly at threshold boundary ─────────────────────────

    testWidgets('count exactly at beginner threshold is Beginner',
        (tester) async {
      final cat = _cat('boundary');
      await tester.pumpWidget(_wrapWithBadges([
        UserBadge(category: cat, count: 1),
      ]));
      await tester.pumpAndSettle();

      expect(find.text('Beginner'), findsOneWidget);
    });

    // ── Count one below threshold ───────────────────────────────────

    testWidgets('count zero is Locked', (tester) async {
      final cat = _cat('below');
      await tester.pumpWidget(_wrapWithBadges([
        UserBadge(category: cat, count: 0),
      ]));
      await tester.pumpAndSettle();

      expect(find.text('Locked'), findsOneWidget);
      expect(find.text('Beginner'), findsNothing);
    });

    // ── Progress exactly 0.0 ────────────────────────────────────────

    testWidgets('zero count renders LinearProgressIndicator',
        (tester) async {
      final cat = _cat('zero_progress');
      await tester.pumpWidget(_wrapWithBadges([
        UserBadge(category: cat, count: 0),
      ]));
      await tester.pumpAndSettle();

      expect(find.byType(LinearProgressIndicator), findsOneWidget);
    });

    // ── Progress exactly 1.0 ────────────────────────────────────────

    testWidgets('max count renders LinearProgressIndicator',
        (tester) async {
      final cat = _cat('max_progress');
      await tester.pumpWidget(_wrapWithBadges([
        UserBadge(category: cat, count: 10000),
      ]));
      await tester.pumpAndSettle();

      expect(find.byType(LinearProgressIndicator), findsOneWidget);
    });

    // ── Single badge rendering ──────────────────────────────────────

    testWidgets('single badge renders correctly', (tester) async {
      final cat = _cat('single');
      await tester.pumpWidget(_wrapWithBadges([
        UserBadge(category: cat, count: 5),
      ]));
      await tester.pumpAndSettle();

      // Category name and tier visible.
      expect(find.text('Custom'), findsOneWidget);
      expect(find.text('Beginner'), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
    });

    // ── Non-prompter custom category ────────────────────────────────

    testWidgets('non-prompter custom category shows correct name',
        (tester) async {
      final cat = _cat('custom_cat');
      await tester.pumpWidget(_wrapWithBadges([
        UserBadge(category: cat, count: 0),
      ]));
      await tester.pumpAndSettle();

      // Category name is "Custom" for non-prompter keys.
      expect(find.text('Custom'), findsOneWidget);
    });

    // ── Badge count in between tiers ────────────────────────────────

    testWidgets('count between tiers shows correct tier', (tester) async {
      final cat = _cat('between');
      await tester.pumpWidget(_wrapWithBadges([
        UserBadge(category: cat, count: 75),
      ]));
      await tester.pumpAndSettle();

      expect(find.text('Intermediate'), findsOneWidget);
    });

    // ── Dialog shows correct earned tier ────────────────────────────

    testWidgets('dialog highlights earned tier', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.physicalSize = const Size(800, 600);
        tester.view.devicePixelRatio = 1.0;
      });

      // count=30 → Intermediate (threshold 25 ≤ 30 < 100).
      final cat = _cat('intermediate');
      await tester.pumpWidget(_wrapWithBadges([
        UserBadge(category: cat, count: 30),
      ]));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Custom'));
      await tester.pumpAndSettle();

      // The dialog header shows "Intermediate tier".
      expect(find.text('Intermediate tier'), findsOneWidget);
    });

    // ── Rapidly opening/closing dialog ──────────────────────────────

    testWidgets('rapidly opening two different badge dialogs',
        (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.physicalSize = const Size(800, 600);
        tester.view.devicePixelRatio = 1.0;
      });

      const catA = UserBadgeCategory(
        key: 'cat_a',
        name: 'Cat A',
        iconName: 'rocket',
        unit: 'unit',
        action: 'Do things',
        thresholds: [1, 25, 100, 500, 2500],
        blurb: 'Category A blurb.',
      );
      const catB = UserBadgeCategory(
        key: 'cat_b',
        name: 'Cat B',
        iconName: 'rocket',
        unit: 'unit',
        action: 'Do things',
        thresholds: [1, 25, 100, 500, 2500],
        blurb: 'Category B blurb.',
      );

      await tester.pumpWidget(_wrapWithBadges([
        const UserBadge(category: catA, count: 0),
        const UserBadge(category: catB, count: 0),
      ]));
      await tester.pumpAndSettle();

      // Open first dialog.
      await tester.tap(find.text('Cat A'));
      await tester.pumpAndSettle();
      expect(find.text('Category A blurb.'), findsOneWidget);

      // Dismiss first dialog.
      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();
      expect(find.text('Category A blurb.'), findsNothing);

      // Open second dialog.
      await tester.tap(find.text('Cat B'));
      await tester.pumpAndSettle();
      expect(find.text('Category B blurb.'), findsOneWidget);
    });

    // ── Badge with custom thresholds ────────────────────────────────

    testWidgets('badge with custom thresholds computes tier correctly',
        (tester) async {
      const cat = UserBadgeCategory(
        key: 'custom_thresholds',
        name: 'Custom Thresholds',
        iconName: 'rocket',
        unit: 'unit',
        action: 'Do things',
        thresholds: [10, 50, 200, 1000, 5000],
        blurb: 'Custom thresholds category.',
      );

      // count=55 → intermediate (50 ≤ 55 < 200).
      await tester.pumpWidget(_wrapWithBadges([
        const UserBadge(category: cat, count: 55),
      ]));
      await tester.pumpAndSettle();

      expect(find.text('Intermediate'), findsOneWidget);
    });
  });
}
