import 'dart:async';

import 'package:control_center/features/pr_review/domain/entities/pr_user.dart';
import 'package:control_center/features/pr_review/domain/entities/pull_request.dart';
import 'package:control_center/features/pr_review/presentation/widgets/pull_request_list/pr_peek_panel.dart';
import 'package:control_center/features/pr_review/providers/pr_review_providers.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../../helpers/test_wrap.dart';

/// Null workspace id notifier — avoids drift chain in tests.
class _NullWorkspaceIdNotifier extends ActiveWorkspaceIdNotifier {
  @override
  String? build() => null;
}

/// Creates a [PullRequest] with sensible defaults for peek panel testing.
PullRequest _pr({
  int number = 1,
  String repoFullName = 'owner/repo',
  String body = '',
  PrChecksStatus checksStatus = PrChecksStatus.none,
  int changedFiles = 0,
  int commitsCount = 0,
  int commentsCount = 0,
  DateTime? updatedAt,
}) {
  return PullRequest(
    id: number,
    number: number,
    title: 'Test PR #$number',
    body: body,
    state: PrState.open,
    isDraft: false,
    author: const PrUser(login: 'test-user', avatarUrl: ''),
    createdAt: DateTime(2024, 1, 1),
    updatedAt: updatedAt ?? DateTime(2024, 6, 10),
    repoFullName: repoFullName,
    htmlUrl: 'https://github.com/$repoFullName/pull/$number',
    changedFiles: changedFiles,
    commitsCount: commitsCount,
    commentsCount: commentsCount,
    checksStatus: checksStatus,
  );
}

/// Content key derived from [pr]'s repoFullName.
PeekContentKey _keyFor(PullRequest pr) {
  final parts = pr.repoFullName.split('/');
  return (
    owner: parts[0],
    repo: parts.length > 1 ? parts[1] : '',
    number: pr.number,
  );
}

/// Wraps [child] with [ProviderScope] overrides for [peekPrContentProvider]
/// plus [testWrap]. Uses [pr] to derive the peek content key.
Widget _wrap({
  required PullRequest pr,
  required Widget child,
  PeekContent? content,
  Completer<PeekContent>? completer,
}) {
  return ProviderScope(
    overrides: [
      activeWorkspaceIdProvider.overrideWith(_NullWorkspaceIdNotifier.new),
      if (completer != null)
        peekPrContentProvider(_keyFor(pr))
            .overrideWith((ref) => completer.future)
      else
        peekPrContentProvider(_keyFor(pr)).overrideWith(
          (ref) async => content ??
              (body: '', bodyHtml: null, changedFiles: 0, commitsCount: 0),
        ),
    ],
    child: testWrap(child),
  );
}

void main() {
  testWidgets('renders with data — summary, checks, and stats', (
    tester,
  ) async {
    final pr = _pr(
      body: '## Description\n\nSome markdown body.',
      checksStatus: PrChecksStatus.passing,
      changedFiles: 5,
      commitsCount: 3,
      commentsCount: 7,
    );

    await tester.pumpWidget(
      _wrap(
        pr: pr,
        content: (
          body: pr.body,
          bodyHtml: null,
          changedFiles: pr.changedFiles,
          commitsCount: pr.commitsCount,
        ),
        child: PrPeekPanel(pr: pr, onOpen: () {}),
      ),
    );
    await tester.pumpAndSettle();

    // Summary heading (uppercased label)
    expect(find.text('SUMMARY'), findsOneWidget);

    // The markdown body text
    expect(find.textContaining('Some markdown body'), findsOneWidget);

    // Checks heading (uppercased label)
    expect(find.text('CHECKS'), findsOneWidget);

    // Passing status
    expect(find.textContaining('Checks passing'), findsOneWidget);

    // Stat value texts
    expect(find.text('5'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
    expect(find.text('7'), findsOneWidget);

    // Action buttons
    expect(find.text('Open full diff'), findsOneWidget);
    expect(find.text('View files'), findsOneWidget);
  });

  testWidgets('renders without data — empty body, no checks, no stats', (
    tester,
  ) async {
    final pr = _pr(
      body: '',
      checksStatus: PrChecksStatus.none,
      changedFiles: 0,
      commitsCount: 0,
      commentsCount: 0,
    );

    await tester.pumpWidget(
      _wrap(
        pr: pr,
        child: PrPeekPanel(pr: pr, onOpen: () {}),
      ),
    );
    await tester.pumpAndSettle();

    // Summary heading still shown
    expect(find.text('SUMMARY'), findsOneWidget);

    // No description placeholder
    expect(find.text('No description provided.'), findsOneWidget);

    // Checks heading still shown
    expect(find.text('CHECKS'), findsOneWidget);

    // No checks status labels for PrChecksStatus.none
    expect(find.textContaining('Checks passing'), findsNothing);
    expect(find.textContaining('Checks failing'), findsNothing);
    expect(find.textContaining('Checks running'), findsNothing);

    // Action buttons still shown
    expect(find.text('Open full diff'), findsOneWidget);
    expect(find.text('View files'), findsOneWidget);
  });

  testWidgets('renders checks status — failing', (tester) async {
    final pr = _pr(checksStatus: PrChecksStatus.failing);

    await tester.pumpWidget(
      _wrap(
        pr: pr,
        child: PrPeekPanel(pr: pr, onOpen: () {}),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('Checks failing'), findsOneWidget);
  });

  testWidgets('renders checks status — pending', (tester) async {
    final pr = _pr(checksStatus: PrChecksStatus.pending);

    await tester.pumpWidget(
      _wrap(
        pr: pr,
        child: PrPeekPanel(pr: pr, onOpen: () {}),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('Checks running'), findsOneWidget);
  });

  testWidgets('renders loading placeholder while description is fetching', (
    tester,
  ) async {
    final pr = _pr(body: '');

    final completer = Completer<PeekContent>();

    await tester.pumpWidget(
      _wrap(
        pr: pr,
        completer: completer,
        child: PrPeekPanel(pr: pr, onOpen: () {}),
      ),
    );
    // One frame to build, still loading
    await tester.pump();

    // The loading placeholder has three FractionallySizedBox bars
    expect(find.byType(FractionallySizedBox), findsExactly(3));

    // No description text yet
    expect(find.text('No description provided.'), findsNothing);

    // Resolve to clean up
    completer.complete((
      body: '',
      bodyHtml: null,
      changedFiles: 0,
      commitsCount: 0,
    ));
  });

  testWidgets('triggers onOpen callback when buttons are tapped', (
    tester,
  ) async {
    int openCalls = 0;
    final pr = _pr(body: 'Some body');

    await tester.pumpWidget(
      _wrap(
        pr: pr,
        content: (
          body: pr.body,
          bodyHtml: null,
          changedFiles: 0,
          commitsCount: 0,
        ),
        child: PrPeekPanel(pr: pr, onOpen: () => openCalls++),
      ),
    );
    await tester.pumpAndSettle();

    // Both buttons trigger onOpen
    await tester.tap(find.text('Open full diff'));
    // Pump past the FButton tappable timers (100ms)
    await tester.pump(const Duration(milliseconds: 200));
    expect(openCalls, 1);

    await tester.tap(find.text('View files'));
    await tester.pump(const Duration(milliseconds: 200));
    expect(openCalls, 2);
  });

  testWidgets('renders without crash for minimal null-heavy PR', (
    tester,
  ) async {
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
      repoFullName: 'owner/repo',
      htmlUrl: '',
    );

    await tester.pumpWidget(
      _wrap(
        pr: pr,
        child: PrPeekPanel(pr: pr, onOpen: () {}),
      ),
    );
    await tester.pumpAndSettle();

    // Should render without error
    expect(find.text('SUMMARY'), findsOneWidget);
    expect(find.text('No description provided.'), findsOneWidget);
  });
}
