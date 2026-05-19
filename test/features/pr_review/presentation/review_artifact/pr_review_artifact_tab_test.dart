import 'dart:async';

import 'package:cc_domain/core/domain/entities/message.dart';
import 'package:cc_domain/core/domain/entities/review_space_association.dart';
import 'package:cc_domain/core/domain/entities/workspace.dart';
import 'package:cc_domain/features/governance/domain/entities/work_product.dart';
import 'package:cc_domain/features/governance/domain/services/artifact_document_codec.dart';
import 'package:cc_domain/features/governance/domain/value_objects/artifact_block.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pr_user.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pull_request.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/agents/providers/agent_providers.dart';
import 'package:control_center/features/artifacts/presentation/widgets/artifact_detail_view.dart';
import 'package:control_center/features/artifacts/providers/artifact_providers.dart';
import 'package:control_center/features/messaging/providers/messaging_providers.dart';
import 'package:control_center/features/pr_review/presentation/review_artifact/pr_review_artifact_tab.dart';
import 'package:control_center/features/pr_review/providers/pr_review_run_providers.dart';
import 'package:control_center/features/pr_review/providers/review_artifact_providers.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

PullRequest _pr() => PullRequest(
  id: 1,
  number: 42,
  title: 'Test PR',
  body: '',
  state: PrState.open,
  isDraft: false,
  author: const PrUser(login: 'tester', avatarUrl: ''),
  createdAt: DateTime(2025),
  updatedAt: DateTime(2025),
  repoFullName: 'test/repo',
  htmlUrl: 'https://example.com',
);

ReviewSpaceAssociation _association() => ReviewSpaceAssociation(
  id: 'assoc-1',
  spaceId: 'space-1',
  workspaceId: 'ws-1',
  prExternalId: 'ext-1',
  prNumber: 42,
  repoFullName: 'test/repo',
  status: ReviewSpaceStatus.awaitingApproval,
  createdAt: DateTime(2025),
  updatedAt: DateTime(2025),
);

WorkProduct _artifact() => WorkProduct(
  id: 'wp-1',
  workspaceId: 'ws-1',
  title: 'Review report',
  createdAt: DateTime(2026),
  updatedAt: DateTime(2026),
);

WorkProductRevision _revision(int number, String text) => WorkProductRevision(
  id: 'rev-$number',
  workProductId: 'wp-1',
  workspaceId: 'ws-1',
  revisionNumber: number,
  content: ArtifactDocument(
    blocks: [ArtifactMarkdownBlock(text: text)],
  ).toEnvelopeJsonString(),
  createdAt: DateTime(2026, 1, number),
);

Message _findingMessage(
  String id, {
  String priority = 'p1',
  String content = 'Finding body',
  DateTime? createdAt,
}) {
  return Message(
    id: id,
    spaceId: 'space-1',
    conversationId: 'space-1',
    senderId: 'agent-1',
    senderType: SenderType.agent,
    content: content,
    messageType: MessageType.reviewNode,
    metadata: {
      'nodeType': 'bug',
      'priority': priority,
      'confidence': 0.9,
      'filePath': 'lib/foo.dart',
      'lineNumber': 42,
    },
    createdAt: createdAt ?? DateTime(2025, 1, 1),
  );
}

List<Message> _findings(int count, {String round = ''}) => [
  for (var i = 0; i < count; i++)
    _findingMessage(
      'msg-$i',
      content: 'Finding $i$round\n\n```dart\nvoid f() {}\n```\n',
      createdAt: DateTime(2025, 1, 1).add(Duration(minutes: i)),
    ),
];

/// A starter reporting one review as already in flight.
class _StartingStarter extends PrReviewStarter {
  @override
  Set<PrReviewKey> build() => const {(repoFullName: 'test/repo', prNumber: 42)};
}

Widget _host(Widget child) => MaterialApp(
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  builder: (context, c) => CcTheme(data: CcThemeData.light(), child: c!),
  home: CcTheme(
    data: CcThemeData.light(),
    child: Scaffold(body: child),
  ),
);

void main() {
  testWidgets('a review whose start is in flight shows the starting state, not '
      'the never-reviewed CTA', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          prReviewStarterProvider.overrideWith(_StartingStarter.new),
          prReviewAssociationProvider((
            repoFullName: 'test/repo',
            prNumber: 42,
          )).overrideWith((ref) => null),
          // The run does not exist yet — that is the whole window this state
          // covers: `startPrReview` waits for the PR worktree before it
          // answers, so the press and the run row are seconds to minutes apart.
          prReviewRunProvider((
            repoFullName: 'test/repo',
            prNumber: 42,
          )).overrideWith((ref) => null),
          workspacesProvider.overrideWith(
            (ref) => const Stream<List<Workspace>>.empty(),
          ),
        ],
        child: _host(PrReviewArtifactTab(pr: _pr())),
      ),
    );
    await tester.pump();

    final l10n = await AppLocalizations.delegate.load(const Locale('en'));
    expect(find.text(l10n.prReviewStarting), findsOneWidget);
    expect(find.text(l10n.askAi), findsNothing);
  });

  testWidgets('with no review and no start in flight the tab keeps its CTA', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          prReviewAssociationProvider((
            repoFullName: 'test/repo',
            prNumber: 42,
          )).overrideWith((ref) => null),
          prReviewRunProvider((
            repoFullName: 'test/repo',
            prNumber: 42,
          )).overrideWith((ref) => null),
          workspacesProvider.overrideWith(
            (ref) => const Stream<List<Workspace>>.empty(),
          ),
        ],
        child: _host(PrReviewArtifactTab(pr: _pr())),
      ),
    );
    await tester.pump();

    final l10n = await AppLocalizations.delegate.load(const Locale('en'));
    expect(find.text(l10n.askAi), findsOneWidget);
    expect(find.text(l10n.prReviewStarting), findsNothing);
  });

  testWidgets('the published review renders report and findings in one scroll, '
      'clean through streaming churn', (tester) async {
    // Wide enough that the rail engages the resizable split (breakpoint 900).
    tester.view.physicalSize = const Size(2800, 1800);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);

    final messages = StreamController<List<Message>>();
    addTearDown(messages.close);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          prReviewAssociationProvider((
            repoFullName: 'test/repo',
            prNumber: 42,
          )).overrideWith((ref) => _association()),
          prReviewRunProvider((
            repoFullName: 'test/repo',
            prNumber: 42,
          )).overrideWith((ref) => null),
          spaceArtifactsProvider(
            'space-1',
          ).overrideWith((ref) => Stream.value([_artifact()])),
          artifactProvider(
            'wp-1',
          ).overrideWith((ref) => Stream.value(_artifact())),
          artifactRevisionsProvider(
            'wp-1',
          ).overrideWith((ref) async => [_revision(1, '# Report\n\nBody.')]),
          reviewArtifactFindingsProvider(
            'space-1',
          ).overrideWith((ref) => const []),
          spaceWideMessagesProvider.overrideWith(
            (ref, spaceId) => messages.stream,
          ),
          agentDetailProvider.overrideWith((ref, id) async => null),
          workspacesProvider.overrideWith(
            (ref) => const Stream<List<Workspace>>.empty(),
          ),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          builder: (context, child) =>
              CcTheme(data: CcThemeData.light(), child: child!),
          home: CcTheme(
            data: CcThemeData.light(),
            child: Scaffold(body: PrReviewArtifactTab(pr: _pr())),
          ),
        ),
      ),
    );
    await tester.pump();
    expect(tester.takeException(), isNull);

    // The accordion gates the whole scroll (report sliver included) on the
    // messages stream's first emission — deliver the findings first.
    messages.add(_findings(20));
    await tester.pump();
    await tester.pump();
    await tester.pump();
    expect(tester.takeException(), isNull);

    // The report renders in the shared scroll (no viewport of its own —
    // regression: an Expanded body inside the sliver crashed the frame).
    expect(find.text('Review report'), findsOneWidget);
    // Twice: once as the pinned row's headline, once as the finding's body.
    expect(find.textContaining('Finding 0'), findsNWidgets(2));

    // Scroll the one shared scroll: pinned finding headers and their
    // selectable bodies build mid-layout.
    final scroll = find.byType(CustomScrollView);
    await tester.drag(scroll, const Offset(0, -1500));
    await tester.pump();
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(
      tester.widget<CustomScrollView>(scroll).controller!.offset,
      greaterThan(0),
      reason: 'the drag must move the shared scroll to exercise lazy builds',
    );

    // Churn while scrolled — the room re-emits on every write, and the
    // accordion rebuilds without remounting the pinned rows (stable anchor
    // keys) or crashing the selection flush.
    for (var round = 0; round < 4; round++) {
      messages.add(_findings(20 + round, round: ' r$round'));
      await tester.pump();
      await tester.pump();
      expect(tester.takeException(), isNull, reason: 'churn round $round');
    }

    tester.widget<CustomScrollView>(scroll).controller!.jumpTo(0);
    // The report sliver rebuilds on return; its auto-disposed providers
    // re-emit through one loading frame first.
    await tester.pump();
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    final detailViews = find.byType(ArtifactDetailView);
    expect(
      detailViews,
      findsOneWidget,
      reason:
          'spinners: ${find.byType(CcSpinner).evaluate().length}, '
          'scroll offset: ${tester.widget<CustomScrollView>(scroll).controller!.offset}',
    );
    expect(find.text('Review report'), findsOneWidget);
  });
}
