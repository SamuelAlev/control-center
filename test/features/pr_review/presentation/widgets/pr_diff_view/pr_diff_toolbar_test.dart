import 'package:control_center/core/theme/font_settings.dart';
import 'package:control_center/features/pr_review/domain/entities/pr_commit.dart';
import 'package:control_center/features/pr_review/domain/entities/pr_user.dart';
import 'package:control_center/features/pr_review/presentation/widgets/pr_diff_view/pr_diff_toolbar.dart';
import 'package:control_center/features/pr_review/providers/pr_inline_comments_provider.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';

PrCommit _commit({required String sha, required String message}) {
  return PrCommit(
    sha: sha,
    message: message,
    author: const PrUser(login: 'Author', avatarUrl: ''),
    date: DateTime(2024, 1, 1),
  );
}

Widget _wrap(Widget child) {
  return ProviderScope(
    overrides: [
      codeFontFamilyProvider.overrideWithValue('JetBrainsMono'),
    ],
    child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
      home: FTheme(
        data: FThemes.zinc.light.desktop,
        child: Scaffold(body: child),
      ),
    ),
  );
}

void main() {
  group('PrDiffToolbar', () {
    testWidgets('renders basic file stats', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const PrDiffToolbar(
            fileCount: 5,
            additions: 10,
            deletions: 3,
            commentCount: 2,
          ),
        ),
      );
      await tester.pumpAndSettle(const Duration(seconds: 5));

      expect(find.text('5 files'), findsOneWidget);
      expect(
        find.byWidgetPredicate((w) => w is Text && (w.data ?? '') == '+10'),
        findsOneWidget,
      );
    });

    testWidgets('renders toolbar with zero values', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const PrDiffToolbar(
            fileCount: 0,
            additions: 0,
            deletions: 0,
            commentCount: 0,
          ),
        ),
      );
      await tester.pumpAndSettle(const Duration(seconds: 5));

      expect(find.text('0 files'), findsOneWidget);
    });

    testWidgets('renders toolbar with singular file', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const PrDiffToolbar(
            fileCount: 1,
            additions: 10,
            deletions: 3,
            commentCount: 0,
          ),
        ),
      );
      await tester.pumpAndSettle(const Duration(seconds: 5));

      expect(find.text('1 file'), findsOneWidget);
    });

    testWidgets('renders toolbar with commits', (tester) async {
      final commits = [_commit(sha: 'aaa11111111111111111111111111111111111111', message: 'Test')];

      await tester.pumpWidget(
        _wrap(
          PrDiffToolbar(
            fileCount: 1,
            additions: 1,
            deletions: 0,
            commentCount: 0,
            commits: commits,
          ),
        ),
      );
      await tester.pumpAndSettle(const Duration(seconds: 5));

      expect(find.text('All commits'), findsOneWidget);
    });

    testWidgets('renders toolbar with multiple commits', (tester) async {
      final commits = [
        _commit(sha: 'aaa11111111111111111111111111111111111111', message: 'First'),
        _commit(sha: 'bbb22222222222222222222222222222222222222', message: 'Second'),
      ];

      await tester.pumpWidget(
        _wrap(
          PrDiffToolbar(
            fileCount: 1,
            additions: 1,
            deletions: 0,
            commentCount: 0,
            commits: commits,
          ),
        ),
      );
      await tester.pumpAndSettle(const Duration(seconds: 5));

      expect(find.text('All commits'), findsOneWidget);
      expect(find.text('v2'), findsOneWidget);
    });

    testWidgets('renders toolbar with selected commits', (tester) async {
      final commits = [
        _commit(sha: 'aaa11111111111111111111111111111111111111', message: 'First'),
        _commit(sha: 'bbb22222222222222222222222222222222222222', message: 'Second'),
        _commit(sha: 'ccc33333333333333333333333333333333333333', message: 'Third'),
      ];

      await tester.pumpWidget(
        _wrap(
          PrDiffToolbar(
            fileCount: 1,
            additions: 1,
            deletions: 0,
            commentCount: 0,
            commits: commits,
            selectedCommitShas: const {
              'bbb22222222222222222222222222222222222222',
              'ccc33333333333333333333333333333333333333',
            },
          ),
        ),
      );
      await tester.pumpAndSettle(const Duration(seconds: 5));

      expect(find.text('2 commits'), findsOneWidget);
    });

    testWidgets('renders comment count chip', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const PrDiffToolbar(
            fileCount: 1,
            additions: 0,
            deletions: 0,
            commentCount: 5,
          ),
        ),
      );
      await tester.pumpAndSettle(const Duration(seconds: 5));

      expect(
        find.byWidgetPredicate((w) => w is Text && (w.data ?? '') == '5'),
        findsOneWidget,
      );
    });

    testWidgets('renders toolbar with inline comments controller', (tester) async {
      final controller = PrInlineCommentsController(1);

      await tester.pumpWidget(
        _wrap(
          PrDiffToolbar(
            fileCount: 1,
            additions: 0,
            deletions: 0,
            commentCount: 1,
            inlineCommentsController: controller,
          ),
        ),
      );
      await tester.pumpAndSettle(const Duration(seconds: 5));

      expect(find.text('1 file'), findsOneWidget);
    });

    testWidgets('renders view mode toggle when onSplitViewChanged provided', (tester) async {
      await tester.pumpWidget(
        _wrap(
          PrDiffToolbar(
            fileCount: 1,
            additions: 0,
            deletions: 0,
            commentCount: 0,
            onSplitViewChanged: (_) {},
          ),
        ),
      );
      await tester.pumpAndSettle(const Duration(seconds: 5));

      expect(
        find.byTooltip('Unified diff'),
        findsOneWidget,
      );
      expect(
        find.byTooltip('Split (side-by-side) diff'),
        findsOneWidget,
      );
    });

    testWidgets('view mode toggle calls onSplitViewChanged', (tester) async {
      bool? splitView;
      await tester.pumpWidget(
        _wrap(
          PrDiffToolbar(
            fileCount: 1,
            additions: 0,
            deletions: 0,
            commentCount: 0,
            onSplitViewChanged: (v) => splitView = v,
          ),
        ),
      );
      await tester.pumpAndSettle(const Duration(seconds: 5));

      final splitButton = find.byTooltip('Split (side-by-side) diff');
      await tester.tap(splitButton);
      await tester.pumpAndSettle(const Duration(seconds: 5));

      expect(splitView, isTrue);
    });

    testWidgets('renders deletion count with minus sign', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const PrDiffToolbar(
            fileCount: 2,
            additions: 3,
            deletions: 8,
            commentCount: 0,
          ),
        ),
      );
      await tester.pumpAndSettle(const Duration(seconds: 5));

      expect(
        find.byWidgetPredicate((w) => w is Text && (w.data ?? '') == '−8'),
        findsOneWidget,
      );
    });

    testWidgets('toolbar without commits does not show commit selector', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const PrDiffToolbar(
            fileCount: 1,
            additions: 0,
            deletions: 0,
            commentCount: 0,
          ),
        ),
      );
      await tester.pumpAndSettle(const Duration(seconds: 5));

      expect(find.text('All commits'), findsNothing);
    });

    testWidgets('commit selector opens overlay on tap', (tester) async {
      final commits = [
        _commit(sha: 'aaa11111111111111111111111111111111111111', message: 'Test'),
        _commit(sha: 'bbb22222222222222222222222222222222222222', message: 'Second'),
      ];

      await tester.pumpWidget(
        _wrap(
          PrDiffToolbar(
            fileCount: 1,
            additions: 1,
            deletions: 0,
            commentCount: 0,
            commits: commits,
          ),
        ),
      );
      await tester.pumpAndSettle(const Duration(seconds: 5));

      await tester.tap(find.text('All commits'));
      await tester.pumpAndSettle(const Duration(seconds: 5));

      expect(find.text('Test'), findsOneWidget);
      expect(find.text('Second'), findsOneWidget);
    });

    testWidgets('commit overlay shows version labels', (tester) async {
      final commits = [
        _commit(sha: 'aaa11111111111111111111111111111111111111', message: 'Fix'),
        _commit(sha: 'bbb22222222222222222222222222222222222222', message: 'Add'),
        _commit(sha: 'ccc33333333333333333333333333333333333333', message: 'Init'),
      ];

      await tester.pumpWidget(
        _wrap(
          PrDiffToolbar(
            fileCount: 1,
            additions: 1,
            deletions: 0,
            commentCount: 0,
            commits: commits,
          ),
        ),
      );
      await tester.pumpAndSettle(const Duration(seconds: 5));

      await tester.tap(find.text('All commits'));
      await tester.pumpAndSettle(const Duration(seconds: 5));

      expect(find.text('v3'), findsWidgets);
      expect(find.text('v2'), findsOneWidget);
      expect(find.text('v1'), findsOneWidget);
    });

    testWidgets('commit overlay can select a single commit', (tester) async {
      final commits = [
        _commit(sha: 'aaa11111111111111111111111111111111111111', message: 'First'),
        _commit(sha: 'bbb22222222222222222222222222222222222222', message: 'Second'),
      ];

      await tester.pumpWidget(
        _wrap(
          PrDiffToolbar(
            fileCount: 1,
            additions: 1,
            deletions: 0,
            commentCount: 0,
            commits: commits,
          ),
        ),
      );
      await tester.pumpAndSettle(const Duration(seconds: 5));

      await tester.tap(find.text('All commits'));
      await tester.pumpAndSettle(const Duration(seconds: 5));

      await tester.tap(find.text('Second'));
      await tester.pumpAndSettle(const Duration(seconds: 5));

      expect(find.text('Second'), findsWidgets);
    });

    testWidgets('commit with empty message shows short sha', (tester) async {
      final commits = [
        _commit(sha: 'aaa11111111111111111111111111111111111111', message: ''),
      ];

      await tester.pumpWidget(
        _wrap(
          PrDiffToolbar(
            fileCount: 1,
            additions: 1,
            deletions: 0,
            commentCount: 0,
            commits: commits,
          ),
        ),
      );
      await tester.pumpAndSettle(const Duration(seconds: 5));

      await tester.tap(find.text('All commits'));
      await tester.pumpAndSettle(const Duration(seconds: 5));

      expect(find.text('aaa1111'), findsOneWidget);
    });

    testWidgets('split view toggle shows correct icons', (tester) async {
      await tester.pumpWidget(
        _wrap(
          PrDiffToolbar(
            fileCount: 1,
            additions: 0,
            deletions: 0,
            commentCount: 0,
            splitView: true,
            onSplitViewChanged: (_) {},
          ),
        ),
      );
      await tester.pumpAndSettle(const Duration(seconds: 5));

      expect(find.byTooltip('Unified diff'), findsOneWidget);
      expect(find.byTooltip('Split (side-by-side) diff'), findsOneWidget);
    });

    testWidgets('renders commit selector tooltip text', (tester) async {
      final commits = [
        _commit(sha: 'aaa11111111111111111111111111111111111111', message: 'Test'),
      ];

      await tester.pumpWidget(
        _wrap(
          PrDiffToolbar(
            fileCount: 1,
            additions: 1,
            deletions: 0,
            commentCount: 0,
            commits: commits,
          ),
        ),
      );
      await tester.pumpAndSettle(const Duration(seconds: 5));

      expect(
        find.byTooltip('Scope diff to commits — Shift-click for range'),
        findsOneWidget,
      );
    });

    testWidgets('view mode toggle switches back to unified', (tester) async {
      bool? split;
      await tester.pumpWidget(
        _wrap(
          PrDiffToolbar(
            fileCount: 1,
            additions: 0,
            deletions: 0,
            commentCount: 0,
            splitView: true,
            onSplitViewChanged: (v) => split = v,
          ),
        ),
      );
      await tester.pumpAndSettle(const Duration(seconds: 5));

      await tester.tap(find.byTooltip('Unified diff'));
      await tester.pumpAndSettle(const Duration(seconds: 5));

      expect(split, isFalse);
    });
  });
}
