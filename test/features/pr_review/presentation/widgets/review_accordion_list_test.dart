import 'dart:async';

import 'package:cc_domain/core/domain/entities/message.dart';
import 'package:cc_domain/core/domain/entities/workspace.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pr_user.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pull_request.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/agents/providers/agent_providers.dart';
import 'package:control_center/features/messaging/providers/messaging_providers.dart';
import 'package:control_center/features/pr_review/presentation/widgets/review_accordion_list.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

// Helpers
// -----------------------------------------------------------------------------

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

Message _makeMessage({
  String id = 'msg-1',
  String spaceId = 'ch-1',
  String senderId = 'agent-1',
  String nodeType = 'bug',
  String priority = 'p0',
  double confidence = 0.9,
  String? filePath = 'lib/foo.dart',
  int? lineNumber = 42,
  int? lineEnd,
  String status = 'open',
  String content = 'This is a bug',
  DateTime? createdAt,
}) {
  return Message(
    id: id,
    spaceId: spaceId,
    conversationId: spaceId,
    senderId: senderId,
    senderType: SenderType.agent,
    content: content,
    messageType: MessageType.reviewNode,
    metadata: {
      'nodeType': nodeType,
      'priority': priority,
      'confidence': confidence,
      if (status != 'open') 'status': status,
      'filePath': ?filePath,
      'lineNumber': ?lineNumber,
      'lineEnd': ?lineEnd,
    },
    createdAt: createdAt ?? _defaultCreatedAt,
  );
}

final _defaultCreatedAt = DateTime(2025, 1, 1);

/// Builds a test app wrapping [child] in ProviderScope with overrides that
/// supply [messages] (or a never-emitting stream for loading / an error stream
/// for errors) to [spaceWideMessagesProvider].
Widget _buildTestApp(
  Widget child, {
  Stream<List<Message>>? messages,
  Object? error,
}) {
  final streamOverride = error != null
      ? Stream<List<Message>>.error(error)
      : messages ?? const Stream<List<Message>>.empty();

  return ProviderScope(
    overrides: [
      agentDetailProvider.overrideWith((ref, id) async => null),
      workspacesProvider.overrideWith(
        (ref) => const Stream<List<Workspace>>.empty(),
      ),
      spaceWideMessagesProvider.overrideWith((ref, spaceId) => streamOverride),
    ],
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      builder: (context, child) =>
          CcTheme(data: CcThemeData.light(), child: child!),
      home: CcTheme(
        data: CcThemeData.light(),
        child: Scaffold(body: child),
      ),
    ),
  );
}

/// Builds a [ReviewAccordionList] with the default PR, given space and
/// optional stream overrides.
ReviewAccordionList _buildWidget({
  String spaceId = 'ch-1',
  PullRequest? pr,
  ReviewAccordionController? controller,
}) {
  return ReviewAccordionList(
    spaceId: spaceId,
    pr: pr ?? _pr(),
    controller: controller,
  );
}

void main() {
  // ---------------------------------------------------------------------------
  // 1. Loading state
  // ---------------------------------------------------------------------------
  testWidgets('renders loading state when stream has not emitted', (
    tester,
  ) async {
    // Use a StreamController that never emits → `when(loading: …)`.
    await tester.pumpWidget(
      _buildTestApp(
        _buildWidget(),
        messages: const Stream<List<Message>>.empty(),
      ),
    );
    await tester.pump();
    expect(find.byType(CcSpinner), findsOneWidget);
  });

  // ---------------------------------------------------------------------------
  // 2. Error state
  // ---------------------------------------------------------------------------
  testWidgets('renders error state when stream errors', (tester) async {
    await tester.pumpWidget(
      _buildTestApp(_buildWidget(), error: Exception('network down')),
    );
    await tester.pumpAndSettle();
    // Error state renders a description that includes the error text.
    expect(find.textContaining('Failed'), findsOneWidget);
  });

  // ---------------------------------------------------------------------------
  // 3. Empty state
  // ---------------------------------------------------------------------------
  testWidgets('renders empty state when no review findings', (tester) async {
    await tester.pumpWidget(
      _buildTestApp(_buildWidget(), messages: Stream.value([])),
    );
    await tester.pump();
    expect(find.byType(CcEmptyState), findsOneWidget);
    expect(find.text('No review findings yet'), findsOneWidget);
    expect(
      find.text('Findings appear here as agents post them.'),
      findsOneWidget,
    );
  });

  // ---------------------------------------------------------------------------
  // 4. Selection: always-on checkboxes feeding the shared controller
  // ---------------------------------------------------------------------------
  // There is no selection mode any more: the checkboxes are on every row by
  // default, an empty selection means the bulk verbs act on every open P0–P2
  // finding, and ticking one narrows them to exactly that subset. The
  // controller holds the set so the artifact's action bar and the rows can
  // never disagree about the scope.
  testWidgets('checkboxes are on every row by default', (tester) async {
    await tester.pumpWidget(
      _buildTestApp(
        _buildWidget(),
        messages: Stream.value([
          _makeMessage(id: 'msg-1'),
          _makeMessage(id: 'msg-2', lineNumber: 43),
        ]),
      ),
    );
    await tester.pump();
    expect(find.byType(CcCheckbox), findsNWidgets(2));
  });

  testWidgets('tapping a checkbox ticks the finding in the controller', (
    tester,
  ) async {
    final controller = ReviewAccordionController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      _buildTestApp(
        _buildWidget(controller: controller),
        messages: Stream.value([_makeMessage()]),
      ),
    );
    await tester.pump();
    expect(controller.selectedIds, isEmpty);

    await tester.tap(find.byType(CcCheckbox));
    await tester.pump();
    expect(controller.selectedIds, {'msg-1'});

    await tester.tap(find.byType(CcCheckbox));
    await tester.pump();
    expect(controller.selectedIds, isEmpty);
  });

  testWidgets('clearSelection returns the verbs to their default scope', (
    tester,
  ) async {
    final controller = ReviewAccordionController()
      ..toggleSelected('msg-1', true);
    addTearDown(controller.dispose);
    expect(controller.selectedIds, {'msg-1'});
    controller.clearSelection();
    expect(controller.selectedIds, isEmpty);
  });

  // ---------------------------------------------------------------------------
  // 7. Dismissed toggle
  // ---------------------------------------------------------------------------
  testWidgets('dismissed toggle appears when dismissed findings exist', (
    tester,
  ) async {
    await tester.pumpWidget(
      _buildTestApp(
        _buildWidget(),
        messages: Stream.value([_makeMessage(status: 'dismissed')]),
      ),
    );
    await tester.pump();
    // Dismissed items are hidden by default, but the toggle shows.
    expect(find.text('Show 1 dismissed'), findsOneWidget);
  });

  testWidgets('dismissed toggle absent when no dismissed findings', (
    tester,
  ) async {
    await tester.pumpWidget(
      _buildTestApp(_buildWidget(), messages: Stream.value([_makeMessage()])),
    );
    await tester.pump();
    expect(find.textContaining('dismissed'), findsNothing);
  });

  testWidgets('tapping dismissed toggle shows dismissed items', (tester) async {
    await tester.pumpWidget(
      _buildTestApp(
        _buildWidget(),
        messages: Stream.value([
          _makeMessage(id: 'msg-open', status: 'open'),
          _makeMessage(
            id: 'msg-dismissed',
            status: 'dismissed',
            nodeType: 'suggestion',
            content: 'Dismissed finding',
          ),
        ]),
      ),
    );
    await tester.pump();
    // Only the open item is visible initially — one BUG badge.
    expect(find.text('BUG'), findsOneWidget);
    expect(find.text('SUGGEST'), findsNothing);

    // Tap toggle
    await tester.tap(find.textContaining('Show'));
    await tester.pumpAndSettle();
    // Now the dismissed suggestion item is visible.
    expect(find.text('SUGGEST'), findsOneWidget);
    expect(find.textContaining('Hide'), findsOneWidget);
  });

  // ---------------------------------------------------------------------------
  // 8. Disagreements panel
  // ---------------------------------------------------------------------------
  testWidgets('disagreements panel appears when disagreements exist', (
    tester,
  ) async {
    // Two messages from different agents, same file+line, priority gap ≥2.
    final messages = [
      _makeMessage(
        id: 'msg-a',
        senderId: 'agent-alpha',
        priority: 'p0',
        lineNumber: 42,
      ),
      _makeMessage(
        id: 'msg-b',
        senderId: 'agent-beta',
        priority: 'p2',
        lineNumber: 42,
      ),
    ];
    await tester.pumpWidget(
      _buildTestApp(_buildWidget(), messages: Stream.value(messages)),
    );
    await tester.pump();
    expect(find.textContaining('reviewer disagreement'), findsOneWidget);
    // The description should mention severity
    expect(
      find.textContaining('reviewers disagree on severity'),
      findsOneWidget,
    );
  });

  testWidgets('disagreements panel absent when no conflicts', (tester) async {
    await tester.pumpWidget(
      _buildTestApp(_buildWidget(), messages: Stream.value([_makeMessage()])),
    );
    await tester.pump();
    expect(find.textContaining('disagreement'), findsNothing);
  });
}
