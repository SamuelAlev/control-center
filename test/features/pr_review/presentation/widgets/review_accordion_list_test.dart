import 'dart:async';

import 'package:control_center/core/domain/entities/channel_message.dart';
import 'package:control_center/core/domain/entities/workspace.dart';
import 'package:control_center/core/theme/design_system_tokens.dart';
import 'package:control_center/features/agents/providers/agent_providers.dart';
import 'package:control_center/features/auth/providers/auth_providers.dart';
import 'package:control_center/features/messaging/providers/messaging_providers.dart';
import 'package:control_center/features/pr_review/domain/entities/pr_user.dart';
import 'package:control_center/features/pr_review/domain/entities/pull_request.dart';
import 'package:control_center/features/pr_review/presentation/widgets/review_accordion_list.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
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

ChannelMessage _makeMessage({
  String id = 'msg-1',
  String channelId = 'ch-1',
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
  return ChannelMessage(
    id: id,
    channelId: channelId,
    senderId: senderId,
    senderType: ChannelSenderType.agent,
    content: content,
    messageType: ChannelMessageType.reviewNode,
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
/// for errors) to [channelMessagesProvider].
Widget _buildTestApp(
  Widget child, {
  Stream<List<ChannelMessage>>? messages,
  Object? error,
}) {
  final streamOverride = error != null
      ? Stream<List<ChannelMessage>>.error(error)
      : messages ?? const Stream<List<ChannelMessage>>.empty();

  return ProviderScope(
    overrides: [
      githubAuthTokenProvider.overrideWith((ref) => 'test-token'),
      agentDetailProvider.overrideWith((ref, id) async => null),
      workspacesProvider.overrideWith(
        (ref) => const Stream<List<Workspace>>.empty(),
      ),
      channelMessagesProvider.overrideWith(
        (ref, channelId) => streamOverride,
      ),
    ],
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: ThemeData(
        extensions: [DesignSystemTokens.light()],
      ),
      home: FTheme(
        data: FThemes.zinc.light.desktop,
        child: Scaffold(body: child),
      ),
    ),
  );
}

/// Builds a [ReviewAccordionList] with the default PR, given channel and
/// optional stream overrides.
ReviewAccordionList _buildWidget({
  String channelId = 'ch-1',
  PullRequest? pr,
}) {
  return ReviewAccordionList(
    channelId: channelId,
    pr: pr ?? _pr(),
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
        messages: const Stream<List<ChannelMessage>>.empty(),
      ),
    );
    await tester.pump();
    expect(find.byType(FCircularProgress), findsOneWidget);
  });

  // ---------------------------------------------------------------------------
  // 2. Error state
  // ---------------------------------------------------------------------------
  testWidgets('renders error state when stream errors', (tester) async {
    await tester.pumpWidget(
      _buildTestApp(
        _buildWidget(),
        error: Exception('network down'),
      ),
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
      _buildTestApp(
        _buildWidget(),
        messages: Stream.value([]),
      ),
    );
    await tester.pump();
    expect(find.text('No review findings yet'), findsOneWidget);
    expect(
      find.text('Findings will appear as agents post review nodes.'),
      findsOneWidget,
    );
  });

  // ---------------------------------------------------------------------------
  // 4. Filter bar with kind chips
  // ---------------------------------------------------------------------------
  testWidgets('renders filter bar with kind chips', (tester) async {
    await tester.pumpWidget(
      _buildTestApp(
        _buildWidget(),
        messages: Stream.value([
          _makeMessage(),
        ]),
      ),
    );
    await tester.pump();
    // Kind label
    expect(find.text('Kind:'), findsOneWidget);
    // Kind chip labels
    expect(find.text('Bug'), findsWidgets); // one chip + payload in item
    expect(find.text('Suggestion'), findsOneWidget);
    expect(find.text('Recommendation'), findsOneWidget);
    expect(find.text('Question'), findsOneWidget);
    // Status label
    expect(find.text('Status:'), findsOneWidget);
  });

  // ---------------------------------------------------------------------------
  // 5. Status filter chips
  // ---------------------------------------------------------------------------
  testWidgets('renders status filter chips (Open, Consensus, Resolved)', (
    tester,
  ) async {
    await tester.pumpWidget(
      _buildTestApp(
        _buildWidget(),
        messages: Stream.value([
          _makeMessage(),
        ]),
      ),
    );
    await tester.pump();
    expect(find.text('Open'), findsWidgets); // chip + item badge
    expect(find.text('Consensus'), findsOneWidget);
    expect(find.text('Resolved'), findsOneWidget);
  });

  // ---------------------------------------------------------------------------
  // 6. Select button
  // ---------------------------------------------------------------------------
  testWidgets('renders Select button to enter selection mode', (tester) async {
    await tester.pumpWidget(
      _buildTestApp(
        _buildWidget(),
        messages: Stream.value([
          _makeMessage(),
        ]),
      ),
    );
    await tester.pump();
    expect(find.text('Select'), findsOneWidget);
  });

  testWidgets('tapping Select enters selection mode', (tester) async {
    await tester.pumpWidget(
      _buildTestApp(
        _buildWidget(),
        messages: Stream.value([
          _makeMessage(),
        ]),
      ),
    );
    await tester.pump();
    await tester.tap(find.text('Select'));
    await tester.pumpAndSettle();
    // Exit selection button appears, checkboxes appear
    expect(find.text('Exit selection'), findsOneWidget);
    expect(find.byType(FCheckbox), findsOneWidget);
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
        messages: Stream.value([
          _makeMessage(status: 'dismissed'),
        ]),
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
      _buildTestApp(
        _buildWidget(),
        messages: Stream.value([
          _makeMessage(),
        ]),
      ),
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
  testWidgets(
    'disagreements panel appears when disagreements exist',
    (tester) async {
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
        _buildTestApp(
          _buildWidget(),
          messages: Stream.value(messages),
        ),
      );
      await tester.pump();
      expect(
        find.textContaining('reviewer disagreement'),
        findsOneWidget,
      );
      // The description should mention severity
      expect(
        find.textContaining('reviewers disagree on severity'),
        findsOneWidget,
      );
    },
  );

  testWidgets('disagreements panel absent when no conflicts', (tester) async {
    await tester.pumpWidget(
      _buildTestApp(
        _buildWidget(),
        messages: Stream.value([
          _makeMessage(),
        ]),
      ),
    );
    await tester.pump();
    expect(find.textContaining('disagreement'), findsNothing);
  });
}
