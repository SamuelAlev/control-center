import 'package:control_center/features/pr_review/domain/entities/pull_request.dart';
import 'package:control_center/features/pr_review/presentation/widgets/pr_status_badge.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

PullRequest _pr({
  bool isDraft = false,
  String state = 'open',
  DateTime? mergedAt,
}) {
  return PullRequest(
    id: 1,
    number: 1,
    title: 'Test PR',
    body: '',
    state: PrStateExtension.fromString(state),
    isDraft: isDraft,
    author: null,
    createdAt: DateTime(2024, 1, 1),
    updatedAt: DateTime(2024, 1, 1),
    repoFullName: 'owner/repo',
    htmlUrl: '',
    mergedAt: mergedAt,
  );
}

void main() {
  testWidgets('displays OPEN status', (tester) async {
    final pr = _pr();
    await tester.pumpWidget(
      MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: PrStatusBadge(pr: pr)),
      ),
    );
    expect(find.text('OPEN'), findsOneWidget);
  });

  testWidgets('displays DRAFT status', (tester) async {
    final pr = _pr(isDraft: true);
    await tester.pumpWidget(
      MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: PrStatusBadge(pr: pr)),
      ),
    );
    expect(find.text('DRAFT'), findsOneWidget);
  });

  testWidgets('displays MERGED status', (tester) async {
    final pr = _pr(mergedAt: DateTime(2024, 1, 1));
    await tester.pumpWidget(
      MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: PrStatusBadge(pr: pr)),
      ),
    );
    expect(find.text('MERGED'), findsOneWidget);
  });

  testWidgets('displays CLOSED status', (tester) async {
    final pr = _pr(state: 'closed');
    await tester.pumpWidget(
      MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: PrStatusBadge(pr: pr)),
      ),
    );
    expect(find.text('CLOSED'), findsOneWidget);
  });

  testWidgets('DRAFT takes priority over merged state', (tester) async {
    final pr = _pr(isDraft: true, mergedAt: DateTime(2024, 1, 1));
    await tester.pumpWidget(
      MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: PrStatusBadge(pr: pr)),
      ),
    );
    expect(find.text('DRAFT'), findsOneWidget);
    expect(find.text('MERGED'), findsNothing);
  });

  testWidgets('MERGED takes priority over OPEN state', (tester) async {
    final pr = _pr(mergedAt: DateTime(2024, 1, 1));
    await tester.pumpWidget(
      MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: PrStatusBadge(pr: pr)),
      ),
    );
    expect(find.text('MERGED'), findsOneWidget);
  });

  testWidgets('renders icon alongside status text', (tester) async {
    final pr = _pr();
    await tester.pumpWidget(
      MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: PrStatusBadge(pr: pr)),
      ),
    );
    expect(find.byIcon(LucideIcons.gitPullRequest), findsOneWidget);
  });

  testWidgets('DRAFT shows file-edit icon', (tester) async {
    final pr = _pr(isDraft: true);
    await tester.pumpWidget(
      MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: PrStatusBadge(pr: pr)),
      ),
    );
    expect(find.byIcon(LucideIcons.gitPullRequestDraft), findsOneWidget);
  });

  testWidgets('CLOSED shows x-circle icon', (tester) async {
    final pr = _pr(state: 'closed');
    await tester.pumpWidget(
      MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: PrStatusBadge(pr: pr)),
      ),
    );
    expect(find.byIcon(LucideIcons.gitPullRequestClosed), findsOneWidget);
  });

  testWidgets('MERGED shows git-merge icon', (tester) async {
    final pr = _pr(mergedAt: DateTime(2024, 1, 1));
    await tester.pumpWidget(
      MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: PrStatusBadge(pr: pr)),
      ),
    );
    expect(find.byIcon(LucideIcons.gitMerge), findsOneWidget);
  });

  testWidgets('renders with FTheme wrapping for color propagation', (
    tester,
  ) async {
    final pr = _pr();
    await tester.pumpWidget(
      MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: PrStatusBadge(pr: pr)),
      ),
    );
    expect(find.text('OPEN'), findsOneWidget);
  });

  testWidgets('CLOSED state uses gitPullRequestClosed icon', (tester) async {
    final pr = _pr(state: 'closed');
    await tester.pumpWidget(
      MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: PrStatusBadge(pr: pr)),
      ),
    );
    expect(find.byIcon(LucideIcons.gitPullRequestClosed), findsOneWidget);
  });

  testWidgets('DRAFT status uses fileEdit icon', (tester) async {
    final pr = _pr(isDraft: true);
    await tester.pumpWidget(
      MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: PrStatusBadge(pr: pr)),
      ),
    );
    expect(find.byIcon(LucideIcons.gitPullRequestDraft), findsOneWidget);
  });

  testWidgets('OPEN status uses gitPullRequest icon', (tester) async {
    final pr = _pr();
    await tester.pumpWidget(
      MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: PrStatusBadge(pr: pr)),
      ),
    );
    expect(find.byIcon(LucideIcons.gitPullRequest), findsOneWidget);
  });

  testWidgets('renders both icon and text label', (tester) async {
    final pr = _pr();
    await tester.pumpWidget(
      MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: PrStatusBadge(pr: pr)),
      ),
    );
    expect(find.byIcon(LucideIcons.gitPullRequest), findsOneWidget);
    expect(find.text('OPEN'), findsOneWidget);
  });

  testWidgets('CLOSED status does not show merge icon', (tester) async {
    final pr = _pr(state: 'closed');
    await tester.pumpWidget(
      MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: PrStatusBadge(pr: pr)),
      ),
    );
    expect(find.byIcon(LucideIcons.gitMerge), findsNothing);
  });

  testWidgets('renders without crash for minimal PR', (tester) async {
    final pr = PullRequest(
      id: 1,
      number: 1,
      title: 'Minimal',
      body: '',
      state: PrState.open,
      isDraft: false,
      author: null,
      createdAt: null,
      updatedAt: null,
      repoFullName: 'o/r',
      htmlUrl: '',
    );
    await tester.pumpWidget(
      MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: PrStatusBadge(pr: pr)),
      ),
    );
    expect(find.text('OPEN'), findsOneWidget);
  });
}
