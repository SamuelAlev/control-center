import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/core/domain/entities/workspace.dart';
import 'package:control_center/core/theme/font_settings.dart';
import 'package:control_center/features/pr_review/domain/entities/pr_user.dart';
import 'package:control_center/features/pr_review/domain/entities/pull_request.dart';
import 'package:control_center/features/pr_review/domain/repositories/pr_review_repository.dart';
import 'package:control_center/features/pr_review/presentation/screens/pull_request_detail/pr_files_tab.dart';
import 'package:control_center/features/pr_review/presentation/widgets/pr_detail_skeleton.dart';
import 'package:control_center/features/pr_review/providers/pr_review_providers.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

PullRequest _pr() => PullRequest(
  id: 1,
  number: 42,
  title: 'Test PR',
  body: '',
  state: PrState.open,
  isDraft: false,
  headSha: '',
  author: const PrUser(login: 'author', avatarUrl: ''),
  createdAt: DateTime(2024),
  updatedAt: DateTime(2024),
  repoFullName: 'owner/repo',
  htmlUrl: 'https://github.com/owner/repo/pull/42',
);

class _NullWorkspaceIdNotifier extends ActiveWorkspaceIdNotifier {
  @override
  String? build() => null;
}

Widget _wrap(Widget child) {
  return ProviderScope(
    overrides: [
      codeFontFamilyProvider.overrideWithValue('JetBrainsMono'),
      activeWorkspaceIdProvider.overrideWith(_NullWorkspaceIdNotifier.new),
      activeWorkspaceProvider.overrideWith((ref) => null),
      activeRepoProvider.overrideWith((ref) => null),
      prReviewRepositoryProvider.overrideWith((ref) => const EmptyPrReviewRepository()),
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

Widget _wrapSliver(Widget child) {
  return _wrap(CustomScrollView(slivers: [child]));
}

void main() {
  group('FilesTab', () {
    testWidgets('renders loading state', (tester) async {
      final pr = _pr();

      await tester.pumpWidget(
        _wrapSliver(FilesTab(
          pr: pr,
          allFiles: const [],
          commits: const [],
          comments: const [],
          isLoading: true,
          error: null,
          diffKey: GlobalKey(),
        )),
      );
      await tester.pump();

      expect(find.byType(PrDiffSkeleton), findsOneWidget);
      await tester.pumpWidget(Container());
      await tester.pump(const Duration(milliseconds: 100));
    });

    testWidgets('renders error state', (tester) async {
      final pr = _pr();

      await tester.pumpWidget(
        _wrapSliver(FilesTab(
          pr: pr,
          allFiles: const [],
          commits: const [],
          comments: const [],
          isLoading: false,
          error: 'Network error',
          diffKey: GlobalKey(),
        )),
      );
      await tester.pump();

      expect(find.text('Failed to load'), findsOneWidget);
      await tester.pumpWidget(Container());
      await tester.pump(const Duration(milliseconds: 100));
    });
  });

  group('SectionError', () {
    testWidgets('renders error message', (tester) async {
      await tester.pumpWidget(
        _wrap(const SectionError(error: 'Something went wrong')),
      );
      await tester.pumpAndSettle(const Duration(seconds: 5));

      expect(find.text('Failed to load'), findsOneWidget);
    });

    testWidgets('renders error details', (tester) async {
      await tester.pumpWidget(
        _wrap(const SectionError(error: 'Custom error message')),
      );
      await tester.pumpAndSettle(const Duration(seconds: 5));

      expect(find.text('Custom error message'), findsOneWidget);
    });
  });
}
