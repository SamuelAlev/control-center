import 'package:cc_domain/features/pr_review/domain/entities/pull_request.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/messaging/presentation/widgets/space_row_adornments.dart';
import 'package:control_center/features/pr_review/providers/pr_review_providers.dart';
import 'package:control_center/features/pr_review/providers/pr_space_provider.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod/src/framework.dart' show Override;

PullRequest _openPr() {
  return PullRequest(
    id: 33982,
    number: 33982,
    title: 'feat: add saml logout links endpoint',
    body: '',
    state: PrState.open,
    isDraft: false,
    author: null,
    createdAt: DateTime.utc(2026),
    updatedAt: DateTime.utc(2026),
    repoFullName: 'control-center/control-center',
    htmlUrl: 'https://example.invalid/control-center/control-center/pull/33982',
    headRef: 'space/6b2256bb',
    baseRef: 'main',
  );
}

Future<void> _pump(WidgetTester tester, {required List<Override> overrides}) {
  return tester.pumpWidget(
    ProviderScope(
      overrides: overrides,
      child: CcTheme(
        data: CcThemeData.light(),
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: SpaceLeadingIcon(
              spaceId: 'space-1',
              running: false,
              selected: false,
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
          (ref) async => [
            (
              repoId: 'repo-1',
              repoFullName: 'control-center/control-center',
              branch: 'space/6b2256bb',
              pr: _openPr(),
            ),
          ],
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
        spaceBranchPullRequestsProvider(
          'space-1',
        ).overrideWith((ref) async => const []),
      ],
    );
    await tester.pump();

    expect(find.byIcon(AppIcons.pencil), findsOneWidget);
    expect(find.byIcon(AppIcons.gitPullRequest), findsNothing);
    expect(find.text('1'), findsNothing);
  });
}
