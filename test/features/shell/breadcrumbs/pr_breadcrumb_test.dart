import 'package:cc_domain/features/pr_review/domain/entities/pr_user.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pull_request.dart';
import 'package:cc_domain/features/pr_review/domain/repositories/pr_review_repository.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/pr_review/providers/pr_review_providers.dart';
import 'package:control_center/features/shell/presentation/widgets/title_bar_breadcrumb.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/router/app_router.dart';
import 'package:control_center/router/routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

PullRequest _pr() => PullRequest(
  id: 7,
  number: 7,
  title: 'Ship the suite',
  body: '',
  state: PrState.open,
  isDraft: false,
  author: const PrUser(login: 'ada', avatarUrl: ''),
  createdAt: DateTime(2024, 6, 15),
  updatedAt: DateTime(2024, 6, 15),
  repoFullName: 'acme/alpha',
  htmlUrl: 'https://github.com/acme/alpha/pull/7',
  requestedReviewers: const [],
  assignees: const [],
);

void main() {
  testWidgets(
    'PR detail breadcrumb inserts owner/repo that opens the list on that repo',
    (tester) async {
      final router = GoRouter(
        initialLocation: pullRequestDetailRoute('ws1', 'acme/alpha', 7),
        routes: [
          GoRoute(
            path: pullRequestsRoute(workspaceIdParam),
            builder: (_, state) => _Bar(
              child: Text('list:${state.uri.queryParameters['repo'] ?? ''}'),
            ),
            routes: [
              GoRoute(
                path: ':owner/:repo/:prNumber',
                builder: (_, _) => const _Bar(child: Text('detail')),
              ),
            ],
          ),
        ],
      );
      addTearDown(router.dispose);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            routerProvider.overrideWithValue(router),
            prReviewRepositoryProvider.overrideWith(
              (ref) => const EmptyPrReviewRepository(),
            ),
            prDetailProvider.overrideWith((ref, pr) => Stream.value(_pr())),
          ],
          child: MaterialApp.router(
            localizationsDelegates: [
              ...AppLocalizations.localizationsDelegates,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('en'),
            routerConfig: router,
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Pull requests'), findsOneWidget);
      expect(find.text('acme/alpha'), findsOneWidget);
      expect(find.text('Ship the suite'), findsOneWidget);

      await tester.tap(find.text('acme/alpha'));
      await tester.pumpAndSettle();

      expect(find.text('list:acme/alpha'), findsOneWidget);
      expect(
        router.state.uri.toString(),
        pullRequestsRoute('ws1', repo: 'acme/alpha'),
      );
    },
  );
}

class _Bar extends StatelessWidget {
  const _Bar({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return CcTheme(
      data: CcThemeData.light(),
      child: Scaffold(
        body: Column(children: [const TitleBarBreadcrumb(), child]),
      ),
    );
  }
}
