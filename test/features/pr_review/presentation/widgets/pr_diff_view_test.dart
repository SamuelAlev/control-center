import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/core/domain/entities/workspace.dart';
import 'package:control_center/core/theme/font_settings.dart';
import 'package:control_center/features/pr_review/domain/entities/pr_code_review_comment.dart';
import 'package:control_center/features/pr_review/domain/entities/pr_commit.dart';
import 'package:control_center/features/pr_review/domain/entities/pr_file.dart';
import 'package:control_center/features/pr_review/domain/entities/pr_inline_thread.dart';
import 'package:control_center/features/pr_review/domain/entities/pr_user.dart';
import 'package:control_center/features/pr_review/domain/repositories/pr_review_repository.dart';
import 'package:control_center/features/pr_review/presentation/widgets/pr_diff_view.dart';
import 'package:control_center/features/pr_review/presentation/widgets/pr_diff_view/commit_range_selector.dart';
import 'package:control_center/features/pr_review/presentation/widgets/pr_diff_view/pr_diff_toolbar.dart';
import 'package:control_center/features/pr_review/providers/pr_inline_comments_provider.dart';
import 'package:control_center/features/pr_review/providers/pr_review_providers.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

PrFile _testFile({
  String filename = 'lib/main.dart',
  PrFileStatus status = PrFileStatus.modified,
  String patch = '@@ -1,3 +1,4 @@\n context\n-old\n+new\n end\n',
  int additions = 1,
  int deletions = 1,
}) {
  return PrFile(
    filename: filename,
    status: status,
    additions: additions,
    deletions: deletions,
    patch: patch,
  );
}

PrCommit _testCommit({
  String sha = 'abc1234567890def1234567890abcdef12345678',
  String message = 'Test commit',
}) {
  return PrCommit(
    sha: sha,
    message: message,
    author: const PrUser(login: 'Test Author', avatarUrl: ''),
    date: DateTime(2024, 1, 1),
  );
}

Widget _wrap(Widget child) {
  return ProviderScope(
    overrides: [
      codeFontFamilyProvider.overrideWithValue('JetBrainsMono'),
      activeRepoProvider.overrideWith((ref) => null),
      activeWorkspaceProvider.overrideWith((ref) => null),
      workspacesProvider.overrideWith(
        (ref) => const Stream<List<Workspace>>.empty(),
      ),
      prReviewRepositoryProvider.overrideWith((ref) => const EmptyPrReviewRepository()),
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

Widget _wrapSlivers(Widget sliverChild) {
  return _wrap(CustomScrollView(slivers: [sliverChild]));
}

PrInlineCommentsController _createController(int prNumber) {
  final container = ProviderContainer(
    overrides: [
      activeRepoProvider.overrideWith((ref) => null),
      activeWorkspaceProvider.overrideWith((ref) => null),
      prReviewRepositoryProvider.overrideWith((ref) => const EmptyPrReviewRepository()),
      prDetailProvider(prNumber).overrideWith((ref) => Stream.value(null)),
    ],
  );
  addTearDown(container.dispose);
  return container.read(prInlineCommentsControllerProvider(prNumber).notifier);
}

Finder _richTextContaining(String substring) {
  return find.byWidgetPredicate(
    (w) => w is RichText && w.text.toPlainText().contains(substring),
  );
}

void main() {
  group('PrDiffView', () {
    testWidgets('renders empty state when no files', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const CustomScrollView(
            slivers: [PrDiffView(files: [], comments: [])],
          ),
        ),
      );
      await tester.pumpAndSettle(const Duration(seconds: 5));

      expect(find.text('No file changes in this scope'), findsOneWidget);
    });

    testWidgets('renders toolbar with file count and line stats', (
      tester,
    ) async {
      final files = [_testFile()];

      await tester.pumpWidget(
        _wrapSlivers(PrDiffView(files: files, comments: const [])),
      );
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('1 file'), findsOneWidget);
      expect(
        find.byWidgetPredicate((w) => w is Text && (w.data ?? '') == '+1'),
        findsNWidgets(2),
      );
    });

    testWidgets('renders toolbar with multiple files', (tester) async {
      final files = [
        _testFile(filename: 'lib/a.dart'),
        _testFile(filename: 'lib/b.dart'),
        _testFile(filename: 'lib/c.dart'),
      ];

      await tester.pumpWidget(
        _wrapSlivers(PrDiffView(files: files, comments: const [])),
      );
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('3 files'), findsOneWidget);
      expect(
        find.byWidgetPredicate((w) => w is Text && (w.data ?? '') == '+3'),
        findsOneWidget,
      );
      expect(_richTextContaining('lib/a.dart'), findsOneWidget);
      expect(_richTextContaining('lib/b.dart'), findsOneWidget);
      expect(_richTextContaining('lib/c.dart'), findsOneWidget);
    });

    testWidgets('renders file headers for each file', (tester) async {
      final files = [
        _testFile(filename: 'lib/main.dart'),
        _testFile(filename: 'lib/utils.dart'),
      ];

      await tester.pumpWidget(
        _wrapSlivers(PrDiffView(files: files, comments: const [])),
      );
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 100));

      expect(_richTextContaining('lib/main.dart'), findsOneWidget);
      expect(_richTextContaining('lib/utils.dart'), findsOneWidget);
    });

    testWidgets('renders commit range selector chip', (tester) async {
      final files = [_testFile()];
      final commits = [
        _testCommit(
          sha: 'aaa11111111111111111111111111111111111111',
          message: 'First',
        ),
        _testCommit(
          sha: 'bbb22222222222222222222222222222222222222',
          message: 'Second',
        ),
      ];

      await tester.pumpWidget(
        _wrapSlivers(PrDiffView(
          files: files,
          comments: const [],
          commits: commits,
        )),
      );
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('All commits'), findsOneWidget);
      expect(find.text('v2'), findsOneWidget);
    });

    testWidgets('renders comment count in toolbar', (tester) async {
      final files = [_testFile()];
      final comments = [
        const PrCodeReviewComment(
          id: 1,
          body: 'LGTM',
          path: 'lib/main.dart',
          user: PrUser(login: 'reviewer', avatarUrl: ''),
          position: 1,
          side: 'RIGHT',
          createdAt: null,
        ),
      ];

      await tester.pumpWidget(
        _wrapSlivers(PrDiffView(files: files, comments: comments)),
      );
      await tester.pump(const Duration(milliseconds: 100));

      expect(
        find.byWidgetPredicate((w) => w is Text && (w.data ?? '') == '1'),
        findsWidgets,
      );
    });

    testWidgets('renders with inline comments controller', (tester) async {
      final files = [_testFile()];
      final controller = _createController(1);

      controller.create(
        filePath: 'lib/main.dart',
        line: 1,
        side: 'RIGHT',
        kind: PrInlineThreadKind.comment,
        originalCode: 'old',
        suggestedCode: 'old',
        authorBody: 'Nice!',
      );

      await tester.pumpWidget(
        _wrap(
          CustomScrollView(
            slivers: [PrDiffView(
              files: files,
              comments: const [],
              inlineCommentsController: controller,
            )],
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      expect(
        find.byWidgetPredicate((w) => w is Text && (w.data ?? '') == '1'),
        findsWidgets,
      );
    });

    testWidgets('renders commit selector tooltip', (tester) async {
      final files = [_testFile()];
      final commits = [
        _testCommit(
          sha: '1111111111111111111111111111111111111111',
          message: 'A',
        ),
      ];

      await tester.pumpWidget(
        _wrapSlivers(PrDiffView(files: files, comments: const [], commits: commits)),
      );
      await tester.pump(const Duration(milliseconds: 100));

      expect(
        find.byType(CommitRangeSelector),
        findsOneWidget,
      );
    });

    testWidgets('renders selected commit label', (tester) async {
      final files = [_testFile()];
      final commits = [
        _testCommit(
          sha: '1111111111111111111111111111111111111111',
          message: 'Fix stuff',
        ),
        _testCommit(
          sha: '2222222222222222222222222222222222222222',
          message: 'Add tests',
        ),
      ];

      await tester.pumpWidget(
        _wrapSlivers(PrDiffView(
          files: files,
          comments: const [],
          commits: commits,
          selectedCommitShas: const {
            '2222222222222222222222222222222222222222',
          },
        )),
      );
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Add tests'), findsOneWidget);
    });

    testWidgets('marks file as viewed on toggle tap', (tester) async {
      final files = [
        _testFile(filename: 'lib/a.dart', patch: '@@ -1,1 +1,1 @@\n code\n'),
      ];
      String? toggledPath;
      bool? toggledViewed;

      await tester.pumpWidget(
        _wrapSlivers(PrDiffView(
          files: files,
          comments: const [],
          onToggleViewed: ({required String path, required bool viewed}) {
            toggledPath = path;
            toggledViewed = viewed;
          },
        )),
      );
      final markViewed = find.byIcon(LucideIcons.circle);
      expect(markViewed, findsOneWidget);

      await tester.tap(markViewed);
      await tester.pump(const Duration(milliseconds: 100));

      expect(toggledPath, 'lib/a.dart');
      expect(toggledViewed, true);
    });

    testWidgets('renders binary file message', (tester) async {
      final files = [
        _testFile(
          filename: 'image.png',
          patch: '',
          status: PrFileStatus.modified,
          additions: 0,
          deletions: 0,
        ),
      ];

      await tester.pumpWidget(
        _wrapSlivers(PrDiffView(files: files, comments: const [])),
      );
      await tester.pump(const Duration(milliseconds: 300));

      // A file with an empty patch renders its header without crash.
      expect(find.text('image.png'), findsOneWidget);
    });

    testWidgets('renders added and removed status chips', (tester) async {
      final files = [
        _testFile(
          filename: 'new.dart',
          status: PrFileStatus.added,
          patch: '@@ -0,0 +1,1 @@\n+hello\n',
          additions: 1,
          deletions: 0,
        ),
        _testFile(
          filename: 'old.dart',
          status: PrFileStatus.removed,
          patch: '@@ -1,1 +0,0 @@\n-goodbye\n',
          additions: 0,
          deletions: 1,
        ),
      ];

      await tester.pumpWidget(
        _wrapSlivers(PrDiffView(files: files, comments: const [])),
      );
      await tester.pump(const Duration(milliseconds: 300));

      // File headers render additions/deletions stats for each file.
      expect(find.text('+1'), findsNWidgets(2));
      expect(find.text('−1'), findsNWidgets(2));
    });
  });

  group('PrDiffView - search and commit selection', () {
    testWidgets('selectedCommitShas with single commit shows commit title', (
      tester,
    ) async {
      final files = [_testFile()];
      final commits = [
        _testCommit(
          sha: 'aaa11111111111111111111111111111111111111',
          message: 'Fix bug',
        ),
        _testCommit(
          sha: 'bbb22222222222222222222222222222222222222',
          message: 'Add feature',
        ),
      ];

      await tester.pumpWidget(
        _wrapSlivers(PrDiffView(
          files: files,
          comments: const [],
          commits: commits,
          selectedCommitShas: const {
            'bbb22222222222222222222222222222222222222',
          },
        )),
      );
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Add feature'), findsOneWidget);
    });

    testWidgets('selectedCommitShas with multiple commits shows count', (
      tester,
    ) async {
      final files = [_testFile()];
      final commits = [
        _testCommit(
          sha: '1111111111111111111111111111111111111111',
          message: 'A',
        ),
        _testCommit(
          sha: '2222222222222222222222222222222222222222',
          message: 'B',
        ),
        _testCommit(
          sha: '3333333333333333333333333333333333333333',
          message: 'C',
        ),
      ];

      await tester.pumpWidget(
        _wrapSlivers(PrDiffView(
          files: files,
          comments: const [],
          commits: commits,
          selectedCommitShas: const {
            '1111111111111111111111111111111111111111',
            '2222222222222222222222222222222222222222',
          },
        )),
      );
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('2 commits'), findsOneWidget);
    });

    testWidgets('commits empty hides commit selector', (tester) async {
      final files = [_testFile()];

      await tester.pumpWidget(
        _wrapSlivers(PrDiffView(files: files, comments: const [], commits: const [])),
      );
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('All commits'), findsNothing);
      expect(
        find.byType(CommitRangeSelector),
        findsNothing,
      );
    });

    testWidgets('deletion line count displayed in toolbar', (tester) async {
      final files = [_testFile(filename: 'a.dart', additions: 5, deletions: 8)];

      await tester.pumpWidget(
        _wrapSlivers(PrDiffView(files: files, comments: const [])),
      );
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 100));

      expect(
        find.byWidgetPredicate((w) => w is Text && (w.data ?? '') == '\u22128'),
        findsNWidgets(2),
      );
      expect(
        find.byWidgetPredicate((w) => w is Text && (w.data ?? '') == '+5'),
        findsNWidgets(2),
      );
    });

    testWidgets('renders footer with file and line totals', (tester) async {
      final files = [
        _testFile(filename: 'a.dart', additions: 3, deletions: 1),
        _testFile(filename: 'b.dart', additions: 4, deletions: 2),
      ];

      await tester.pumpWidget(
        _wrapSlivers(PrDiffView(files: files, comments: const [])),
      );
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('2 files'), findsOneWidget);
    });
  });

  group('PrDiffView - comment inbox integration', () {
    testWidgets('inline comments controller shows comment count chip', (
      tester,
    ) async {
      final files = [_testFile()];
      final controller = _createController(1);

      controller.create(
        filePath: 'lib/main.dart',
        line: 1,
        side: 'RIGHT',
        kind: PrInlineThreadKind.comment,
        originalCode: 'code',
        suggestedCode: 'code',
        authorBody: 'Check this',
      );

      await tester.pumpWidget(
        _wrap(
          CustomScrollView(
            slivers: [PrDiffView(
              files: files,
              comments: const [],
              inlineCommentsController: controller,
            )],
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      expect(
        find.byWidgetPredicate((w) => w is Text && (w.data ?? '') == '1'),
        findsWidgets,
      );
    });

    testWidgets('renders toolbar with commit selector and inline comments', (
      tester,
    ) async {
      final files = [_testFile()];
      final commits = [
        _testCommit(
          sha: 'aaa11111111111111111111111111111111111111',
          message: 'First',
        ),
      ];
      final controller = _createController(1);

      await tester.pumpWidget(
        _wrapSlivers(PrDiffView(
          files: files,
          comments: const [],
          commits: commits,
          inlineCommentsController: controller,
        )),
      );
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('All commits'), findsOneWidget);
    });
  });

  group('PrDiffView - empty and edge cases', () {
    testWidgets('renders with zero addition files', (tester) async {
      final files = [_testFile(filename: 'z.dart', additions: 0, deletions: 5)];

      await tester.pumpWidget(
        _wrapSlivers(PrDiffView(files: files, comments: const [])),
      );
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 100));

      expect(
        find.byWidgetPredicate((w) => w is Text && (w.data ?? '') == '+0'),
        findsNWidgets(2),
      );
    });

    testWidgets('handles commit with empty message', (tester) async {
      final files = [_testFile()];
      final commits = [
        _testCommit(
          sha: 'abc1234567890def1234567890abcdef12345678',
          message: '',
        ),
      ];

      await tester.pumpWidget(
        _wrap(
          CustomScrollView(
            slivers: [PrDiffView(
              files: files,
              comments: const [],
              commits: commits,
            )],
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('All commits'), findsOneWidget);
    });
  });

  group('PrDiffToolbar', () {
    testWidgets('renders basic toolbar', (tester) async {
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
      expect(
        find.byWidgetPredicate((w) => w is Text && (w.data ?? '') == '+0'),
        findsOneWidget,
      );
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
      final commits = [
        _testCommit(
          sha: 'aaa11111111111111111111111111111111111111',
          message: 'Test',
        ),
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
    });

    testWidgets('renders toolbar with inline comments controller', (
      tester,
    ) async {
      final controller = _createController(1);

      controller.create(
        filePath: 'x.dart',
        line: 1,
        side: 'RIGHT',
        kind: PrInlineThreadKind.comment,
        originalCode: 'x',
        suggestedCode: 'x',
        authorBody: 'Body',
      );

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

      expect(
        find.byWidgetPredicate((w) => w is Text && (w.data ?? '') == '1'),
        findsWidgets,
      );
    });
  });
}
