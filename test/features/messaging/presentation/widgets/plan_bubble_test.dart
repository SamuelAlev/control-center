import 'package:cc_domain/core/domain/entities/channel_message.dart';
import 'package:cc_domain/features/plan_studio/domain/entities/plan_document.dart';
import 'package:cc_domain/features/plan_studio/domain/value_objects/plan_graph.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/messaging/presentation/ide/editor/messaging_tab_kinds.dart';
import 'package:control_center/features/messaging/presentation/widgets/channel_bubble/plan_bubble.dart';
import 'package:control_center/features/plan_studio/providers/plan_studio_providers.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/editor/editor_tab.dart';
import 'package:control_center/shared/editor/editor_tab_opener.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _TestActiveWorkspaceNotifier extends ActiveWorkspaceIdNotifier {
  _TestActiveWorkspaceNotifier(this._id);
  final String? _id;
  @override
  String? build() => _id;
}

ChannelMessage _planMessage(DateTime createdAt) => ChannelMessage(
  id: 'msg-1',
  channelId: 'ch',
  conversationId: 'ch',
  senderId: 'agent',
  senderType: ChannelSenderType.agent,
  content: 'plan submitted',
  messageType: ChannelMessageType.plan,
  metadata: const {'planId': 'plan-1'},
  createdAt: createdAt,
);

PlanDocument _plan({PlanDocumentStatus status = PlanDocumentStatus.proposed}) =>
    PlanDocument(
      id: 'plan-1',
      workspaceId: 'ws-1',
      conversationId: 'ch',
      agentId: 'agent-1',
      goal: 'Ship the invoice importer',
      graph: const PlanGraph(
        nodes: [
          PlanNode(key: 'a', title: 'Parse', type: PlanNodeType.work),
          PlanNode(
            key: 'b',
            title: 'Import',
            type: PlanNodeType.work,
            dependsOn: ['a'],
          ),
        ],
      ),
      status: status,
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
    );

/// Pumps the bubble with a collecting [EditorTabOpenerScope] in place of the
/// messaging IDE layout, so "opens a tab" is observable. [hosted] false drops
/// the scope, standing in for a surface with no editor layout.
Future<List<EditorTab>> _pump(
  WidgetTester tester, {
  required DateTime submittedAt,
  PlanDocumentStatus status = PlanDocumentStatus.proposed,
  bool hosted = true,
}) async {
  final opened = <EditorTab>[];
  final bubble = PlanBubble(message: _planMessage(submittedAt));
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        activeWorkspaceIdProvider.overrideWith(
          () => _TestActiveWorkspaceNotifier('ws-1'),
        ),
        planDocumentProvider('plan-1').overrideWith(
          (ref) => Stream<PlanDocument?>.value(_plan(status: status)),
        ),
      ],
      child: CcTheme(
        data: CcThemeData.light(),
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: hosted
                ? EditorTabOpenerScope(
                    opener: EditorTabOpener(opened.add),
                    child: bubble,
                  )
                : bubble,
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return opened;
}

void main() {
  setUp(resetAutoOpenedPlanTabs);

  testWidgets('renders the plan as one compact row', (tester) async {
    await _pump(tester, submittedAt: DateTime(2026));

    expect(find.text('Ship the invoice importer'), findsOneWidget);
    // Status label and step count share one metadata line.
    expect(find.textContaining('2 steps'), findsOneWidget);
    expect(find.text('Open'), findsOneWidget);
    expect(find.text('Approve and run'), findsOneWidget);
  });

  testWidgets('a non-proposed plan drops the approve action', (tester) async {
    await _pump(
      tester,
      submittedAt: DateTime(2026),
      status: PlanDocumentStatus.approved,
    );

    expect(find.text('Open'), findsOneWidget);
    expect(find.text('Approve and run'), findsNothing);
  });

  testWidgets('"open in studio" opens a plan tab in the host layout', (
    tester,
  ) async {
    final opened = await _pump(tester, submittedAt: DateTime(2026));
    expect(opened, isEmpty, reason: 'an old plan must not auto-open');

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    expect(opened, hasLength(1));
    expect(opened.single.kind, MessagingTabKinds.plan);
    expect(opened.single.dedupKey, 'plan:document:plan-1');
    expect(opened.single.args['planKind'], 'document');
    expect(opened.single.args['planId'], 'plan-1');
    expect(opened.single.label, 'Ship the invoice importer');
  });

  testWidgets('a plan that just landed opens its tab on arrival', (
    tester,
  ) async {
    final opened = await _pump(tester, submittedAt: DateTime.now());

    expect(opened, hasLength(1));
    expect(opened.single.dedupKey, 'plan:document:plan-1');
  });

  testWidgets('an already-approved plan never auto-opens', (tester) async {
    final opened = await _pump(
      tester,
      submittedAt: DateTime.now(),
      status: PlanDocumentStatus.approved,
    );

    expect(opened, isEmpty);
  });

  testWidgets('with no host layout the row still renders (route fallback)', (
    tester,
  ) async {
    final opened = await _pump(
      tester,
      submittedAt: DateTime(2026),
      hosted: false,
    );

    expect(opened, isEmpty);
    expect(find.text('Open'), findsOneWidget);
  });
}
