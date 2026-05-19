import 'package:cc_domain/core/domain/entities/workspace.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pr_review_submission.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pr_user.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pull_request.dart';
import 'package:cc_domain/features/pr_review/domain/repositories/pr_review_repository.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/core/theme/font_settings.dart';
import 'package:control_center/features/pr_review/presentation/screens/pull_request_detail/pr_header_section.dart';
import 'package:control_center/features/pr_review/presentation/widgets/pr_sidebar.dart';
import 'package:control_center/features/pr_review/providers/pr_review_providers.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

PullRequest _pr({int number = 42, String body = '## Description\nSome content'}) {
  return PullRequest(
    id: number,
    number: number,
    title: 'Add new feature',
    body: body,
    state: PrState.open,
    isDraft: false,
    author: const PrUser(login: 'test-author', avatarUrl: ''),
    createdAt: DateTime(2024, 6, 15),
    updatedAt: DateTime(2024, 6, 15),
    repoFullName: 'owner/repo',
    htmlUrl: 'https://github.com/owner/repo/pull/$number',
  );
}

class _NullWorkspaceIdNotifier extends ActiveWorkspaceIdNotifier {
  @override
  String? build() => null;
}

class _EmptyOptimisticReviewNotifier extends PrOptimisticReviewStateNotifier {
  @override
  Map<int, PrReviewSubmissionState?> build() => {};
}

Widget _wrap(Widget child) {
  return ProviderScope(
    overrides: [
      codeFontFamilyProvider.overrideWithValue('Fira Code'),
      activeWorkspaceIdProvider.overrideWith(_NullWorkspaceIdNotifier.new),
      activeWorkspaceProvider.overrideWith((ref) => null),
      activeRepoProvider.overrideWith((ref) => null),
      prReviewRepositoryProvider.overrideWith((ref) => const EmptyPrReviewRepository()),
      prOptimisticReviewStateProvider.overrideWith(_EmptyOptimisticReviewNotifier.new),
      workspacesProvider.overrideWith(
        (ref) => const Stream<List<Workspace>>.empty(),
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
  return find.byWidgetPredicate(
    (w) => w is RichText && w.text.toPlainText().contains(substring),
  );
}

void main() {
  group('PrHeaderSection', () {
    testWidgets('renders body in wide layout', (tester) async {
      final pr = _pr();
      await tester.pumpWidget(
        _wrap(PrHeaderSection(pr: pr, prNumber: 42, isWide: true)),
      );
      await tester.pumpAndSettle(const Duration(seconds: 5));

      expect(find.byType(PrBodyMarkdown), findsOneWidget);
      await tester.pumpWidget(Container());
      await tester.pump(const Duration(milliseconds: 100));
    });

    testWidgets('renders body in narrow layout', (tester) async {
      final pr = _pr();
      await tester.pumpWidget(
        _wrap(PrHeaderSection(pr: pr, prNumber: 42, isWide: false)),
      );
      await tester.pumpAndSettle(const Duration(seconds: 5));

      expect(find.byType(PrBodyMarkdown), findsOneWidget);
      await tester.pumpWidget(Container());
      await tester.pump(const Duration(milliseconds: 100));
    });

    testWidgets('renders empty body message when body is empty', (tester) async {
      final pr = _pr(body: '');
      await tester.pumpWidget(
        _wrap(PrHeaderSection(pr: pr, prNumber: 42, isWide: false)),
      );
      await tester.pumpAndSettle(const Duration(seconds: 5));

      expect(find.text('No description provided.'), findsOneWidget);
      await tester.pumpWidget(Container());
      await tester.pump(const Duration(milliseconds: 100));
    });

    testWidgets('renders empty body message when body is whitespace', (tester) async {
      final pr = _pr(body: '   \n  ');
      await tester.pumpWidget(
        _wrap(PrHeaderSection(pr: pr, prNumber: 42, isWide: false)),
      );
      await tester.pumpAndSettle(const Duration(seconds: 5));

      expect(find.text('No description provided.'), findsOneWidget);
      await tester.pumpWidget(Container());
      await tester.pump(const Duration(milliseconds: 100));
    });

    testWidgets('renders with markdown body content', (tester) async {
      final pr = _pr(body: '## Summary\nThis is a PR body with **bold** text.');
      await tester.pumpWidget(
        _wrap(PrHeaderSection(pr: pr, prNumber: 42, isWide: true)),
      );
      await tester.pumpAndSettle(const Duration(seconds: 5));

      expect(find.byType(PrBodyMarkdown), findsOneWidget);
      await tester.pumpWidget(Container());
      await tester.pump(const Duration(milliseconds: 100));
    });

    testWidgets('wide layout uses Row with Expanded', (tester) async {
      final pr = _pr();
      await tester.pumpWidget(
        _wrap(PrHeaderSection(pr: pr, prNumber: 42, isWide: true)),
      );
      await tester.pumpAndSettle(const Duration(seconds: 5));

      expect(
        find.descendant(
          of: find.byType(PrHeaderSection),
          matching: find.byType(Row),
        ),
        findsAtLeastNWidgets(1),
      );
      await tester.pumpWidget(Container());
      await tester.pump(const Duration(milliseconds: 100));
    });

    testWidgets('narrow layout uses Column', (tester) async {
      final pr = _pr();
      await tester.pumpWidget(
        _wrap(PrHeaderSection(pr: pr, prNumber: 42, isWide: false)),
      );
      await tester.pumpAndSettle(const Duration(seconds: 5));

      expect(find.byType(PrSidebar), findsOneWidget);
      await tester.pumpWidget(Container());
      await tester.pump(const Duration(milliseconds: 100));
    });
  });

  group('PrTitle', () {
    testWidgets('renders PR number and title', (tester) async {
      final pr = _pr(number: 42, body: 'Test');
      await tester.pumpWidget(
        _wrap(PrTitle(pr: pr)),
      );
      await tester.pumpAndSettle(const Duration(seconds: 5));

      expect(_richTextContaining('#42'), findsOneWidget);
      expect(_richTextContaining('Add new feature'), findsOneWidget);
      await tester.pumpWidget(Container());
      await tester.pump(const Duration(milliseconds: 100));
    });

    testWidgets('renders with different PR number', (tester) async {
      final pr = _pr(number: 999);
      await tester.pumpWidget(
        _wrap(PrTitle(pr: pr)),
      );
      await tester.pumpAndSettle(const Duration(seconds: 5));

      expect(_richTextContaining('#999'), findsOneWidget);
      await tester.pumpWidget(Container());
      await tester.pump(const Duration(milliseconds: 100));
    });
  });

  group('PrBodyMarkdown', () {
    testWidgets('renders markdown body', (tester) async {
      await tester.pumpWidget(
        _wrap(const PrBodyMarkdown(body: '**bold** text', repoFullName: 'owner/repo')),
      );
      await tester.pumpAndSettle(const Duration(seconds: 5));

      expect(find.byType(MarkdownBody), findsOneWidget);
      await tester.pumpWidget(Container());
      await tester.pump(const Duration(milliseconds: 100));
    });

    testWidgets('renders empty state for empty body', (tester) async {
      await tester.pumpWidget(
        _wrap(const PrBodyMarkdown(body: '', repoFullName: 'owner/repo')),
      );
      await tester.pumpAndSettle(const Duration(seconds: 5));

      expect(find.text('No description provided.'), findsOneWidget);
      await tester.pumpWidget(Container());
      await tester.pump(const Duration(milliseconds: 100));
    });
  });
}
