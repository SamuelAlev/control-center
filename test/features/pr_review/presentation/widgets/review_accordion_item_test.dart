import 'package:cc_domain/core/domain/entities/channel_message.dart';
import 'package:cc_domain/core/domain/entities/workspace.dart';
import 'package:cc_domain/features/pr_review/domain/value_objects/review_node_payload.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/agents/providers/agent_providers.dart';
import 'package:control_center/features/auth/providers/auth_providers.dart';
import 'package:control_center/features/messaging/providers/messaging_providers.dart';
import 'package:control_center/features/pr_review/presentation/widgets/review_accordion_item.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const testPayload = ReviewNodePayload(
  kind: ReviewNodeKind.bug,
  priority: ReviewNodePriority.p0,
  confidence: 0.9,
  anchor: ReviewNodeAnchor(filePath: 'lib/foo.dart', lineNumber: 42),
  status: ReviewNodeStatus.open,
);

final testMessage = ChannelMessage(
  id: 'msg-1',
  channelId: 'ch-1',
  senderId: 'agent-1',
  senderType: ChannelSenderType.agent,
  content: 'This is a bug finding',
  messageType: ChannelMessageType.reviewNode,
  metadata: {
    'nodeType': 'bug',
    'priority': 'p0',
    'confidence': 0.9,
    'status': 'open',
    'filePath': 'lib/foo.dart',
    'lineNumber': 42,
  },
  createdAt: DateTime(2024, 1, 1),
);

Widget _buildTestApp(Widget child) {
  return ProviderScope(
    overrides: [
      githubAuthTokenProvider.overrideWith((ref) => 'test-token'),
      agentDetailProvider.overrideWith((ref, id) async => null),
      workspacesProvider.overrideWith(
        (ref) => const Stream<List<Workspace>>.empty(),
      ),
      channelMessagesProvider.overrideWith(
        (ref, channelId) => Stream.value([]),
      ),
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

ReviewAccordionItem _buildWidget({
  ReviewNodePayload? payload,
  ChannelMessage? message,
  bool selectionMode = false,
  bool isSelected = false,
  ValueChanged<bool>? onToggleSelect,
  VoidCallback? onFix,
  VoidCallback? onComment,
}) {
  return ReviewAccordionItem(
    message: message ?? testMessage,
    payload: payload ?? testPayload,
    channelId: 'ch-1',
    isSelected: isSelected,
    selectionMode: selectionMode,
    onToggleSelect: onToggleSelect ?? ((_) {}),
    fetchFileContent: (_) async => '',
    onFix: onFix ?? (() {}),
    onComment: onComment ?? (() {}),
  );
}

void main() {
  testWidgets('collapsed row renders kind label', (tester) async {
    await tester.pumpWidget(_buildTestApp(_buildWidget()));
    await tester.pump();
    expect(find.text('BUG'), findsOneWidget);
  });

  testWidgets('collapsed row renders priority', (tester) async {
    await tester.pumpWidget(_buildTestApp(_buildWidget()));
    await tester.pump();
    expect(
      find.byWidgetPredicate(
        (w) => w is Text && (w.data?.contains('P0') ?? false),
      ),
      findsWidgets,
    );
  });

  testWidgets('collapsed row renders file path', (tester) async {
    await tester.pumpWidget(_buildTestApp(_buildWidget()));
    await tester.pump();
    expect(
      find.byWidgetPredicate(
        (w) => w is Text && (w.data?.contains('lib/foo.dart') ?? false),
      ),
      findsOneWidget,
    );
  });

  testWidgets('collapsed row renders status pill', (tester) async {
    await tester.pumpWidget(_buildTestApp(_buildWidget()));
    await tester.pump();
    expect(find.text('Open'), findsOneWidget);
  });

  testWidgets('expanding on tap', (tester) async {
    await tester.pumpWidget(_buildTestApp(_buildWidget()));
    await tester.pump();
    await tester.tap(find.text('BUG'));
    await tester.pump();
    expect(
      find.byWidgetPredicate(
        (w) => w is Text && (w.data?.contains('priority:') ?? false),
      ),
      findsOneWidget,
    );
  });

  testWidgets('markdown body rendered', (tester) async {
    await tester.pumpWidget(_buildTestApp(_buildWidget()));
    await tester.pump();
    await tester.tap(find.text('BUG'));
    await tester.pump();
    expect(find.text('This is a bug finding'), findsOneWidget);
  });

  testWidgets('action bar rendered', (tester) async {
    await tester.pumpWidget(_buildTestApp(_buildWidget()));
    await tester.pump();
    await tester.tap(find.text('BUG'));
    await tester.pump();
    expect(find.widgetWithText(CcButton, 'Fix'), findsOneWidget);
    expect(find.widgetWithText(CcButton, 'Comment'), findsOneWidget);
  });

  testWidgets('comment disabled without anchor', (tester) async {
    const noAnchorPayload = ReviewNodePayload(
      kind: ReviewNodeKind.suggestion,
      priority: ReviewNodePriority.p2,
      confidence: 0.8,
      anchor: ReviewNodeAnchor(),
      status: ReviewNodeStatus.open,
    );
    await tester.pumpWidget(
      _buildTestApp(_buildWidget(payload: noAnchorPayload)),
    );
    await tester.pump();
    await tester.tap(find.text('SUGGEST'));
    await tester.pump();
    final commentButton = tester.widget<CcButton>(
      find.widgetWithText(CcButton, 'Comment'),
    );
    expect(commentButton.onPressed, isNull);
  });

  testWidgets('selection checkbox visible in selection mode', (tester) async {
    await tester.pumpWidget(
      _buildTestApp(_buildWidget(selectionMode: true)),
    );
    await tester.pump();
    expect(find.byType(CcCheckbox), findsOneWidget);
  });

  testWidgets('selection checkbox not visible outside selection mode',
      (tester) async {
    await tester.pumpWidget(_buildTestApp(_buildWidget()));
    await tester.pump();
    expect(find.byType(CcCheckbox), findsNothing);
  });
}
