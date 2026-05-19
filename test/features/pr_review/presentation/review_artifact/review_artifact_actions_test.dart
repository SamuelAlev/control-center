import 'package:cc_domain/core/domain/entities/message.dart';
import 'package:cc_domain/core/domain/entities/review_space_association.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pr_user.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pull_request.dart';
import 'package:cc_domain/features/pr_review/domain/value_objects/review_node_payload.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/pr_review/presentation/review_artifact/review_artifact_actions.dart';
import 'package:control_center/features/pr_review/presentation/utils/review_item_palette.dart';
import 'package:control_center/features/pr_review/presentation/widgets/review_accordion_list.dart';
import 'package:control_center/features/pr_review/providers/pr_review_run_providers.dart';
import 'package:control_center/features/pr_review/providers/review_artifact_providers.dart';
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

ReviewFinding _finding(
  String id, {
  ReviewNodePriority priority = ReviewNodePriority.p0,
  ReviewNodeStatus status = ReviewNodeStatus.open,
}) {
  return (
    message: Message(
      id: id,
      spaceId: 'space-1',
      conversationId: 'space-1',
      senderId: 'agent-1',
      senderType: SenderType.agent,
      content: 'finding $id',
      messageType: MessageType.reviewNode,
      metadata: const {},
      createdAt: DateTime(2025, 1, 1),
    ),
    payload: ReviewNodePayload(
      kind: ReviewNodeKind.bug,
      priority: priority,
      confidence: 0.9,
      anchor: const ReviewNodeAnchor(filePath: 'lib/foo.dart', lineNumber: 42),
      status: status,
    ),
  );
}

final _findings = [
  _finding('msg-p0'),
  _finding('msg-p1', priority: ReviewNodePriority.p1),
  _finding('msg-p2', priority: ReviewNodePriority.p2),
  _finding('msg-p3', priority: ReviewNodePriority.p3),
  _finding('msg-resolved', status: ReviewNodeStatus.resolved),
];

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

/// Records the scope each verb was invoked with, so the test can assert the
/// exact finding set without a findings list attached to consume commands.
class _RecordingController extends ReviewAccordionController {
  List<String>? fixedIds;
  List<String>? commentedIds;

  @override
  void fixFindings(List<String> ids) {
    fixedIds = ids;
  }

  @override
  void commentFindings(List<String> ids) {
    commentedIds = ids;
  }
}

void main() {
  Future<void> pump(
    WidgetTester tester,
    _RecordingController controller,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          prReviewAssociationProvider((
            repoFullName: 'test/repo',
            prNumber: 42,
          )).overrideWith((ref) => _association()),
          reviewArtifactFindingsProvider(
            'space-1',
          ).overrideWith((ref) => _findings),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          builder: (context, child) =>
              CcTheme(data: CcThemeData.light(), child: child!),
          home: CcTheme(
            data: CcThemeData.light(),
            child: Scaffold(
              body: ReviewArtifactActions(
                pr: _pr(),
                spaceId: 'space-1',
                accordion: controller,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('default scope is every open P0–P2 finding', (tester) async {
    final controller = _RecordingController();
    addTearDown(controller.dispose);
    await pump(tester, controller);

    // The bar's tally counts every non-dismissed finding; the fix verb is on
    // the open P0–P2 subset, and publish is available.
    expect(find.text('5 open findings'), findsOneWidget);
    expect(find.text('Fix 3 findings'), findsOneWidget);
    expect(find.text('Publish to GitHub'), findsOneWidget);
    expect(find.text('Clear selection'), findsNothing);

    await tester.tap(find.text('Fix 3 findings'));
    await tester.pump();
    expect(controller.fixedIds, ['msg-p0', 'msg-p1', 'msg-p2']);
  });

  testWidgets('ticking a checkbox rescopes the verbs to the selection', (
    tester,
  ) async {
    final controller = _RecordingController();
    addTearDown(controller.dispose);
    await pump(tester, controller);

    controller.toggleSelected('msg-p3', true);
    await tester.pump();

    // Labels and actions now name the selection — and the verdict publish is
    // replaced by plain inline comments, since a subset is not the review's
    // verdict.
    expect(find.text('1 selected'), findsOneWidget);
    expect(find.text('Fix 1 selected'), findsOneWidget);
    expect(find.text('Comment 1 selected'), findsOneWidget);
    expect(find.text('Clear selection'), findsOneWidget);
    expect(find.text('Publish to GitHub'), findsNothing);

    await tester.tap(find.text('Fix 1 selected'));
    await tester.pump();
    expect(controller.fixedIds, ['msg-p3']);

    await tester.tap(find.text('Comment 1 selected'));
    await tester.pump();
    expect(controller.commentedIds, ['msg-p3']);
  });

  testWidgets('clearing the selection restores the default scope', (
    tester,
  ) async {
    final controller = _RecordingController();
    addTearDown(controller.dispose);
    await pump(tester, controller);

    controller.toggleSelected('msg-p3', true);
    await tester.pump();
    expect(find.text('Fix 1 selected'), findsOneWidget);

    await tester.tap(find.text('Clear selection'));
    await tester.pump();
    expect(controller.selectedIds, isEmpty);
    expect(find.text('Fix 3 findings'), findsOneWidget);
    expect(find.text('Publish to GitHub'), findsOneWidget);
  });
}
