import 'package:cc_domain/core/domain/entities/message.dart';
import 'package:cc_domain/core/domain/entities/workspace.dart';
import 'package:cc_domain/features/pr_review/domain/value_objects/review_node_payload.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/agents/providers/agent_providers.dart';
import 'package:control_center/features/messaging/providers/messaging_providers.dart';
import 'package:control_center/features/pr_review/presentation/widgets/review_accordion_item.dart';
import 'package:control_center/features/pr_review/presentation/widgets/review_finding_header.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
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

final testMessage = Message(
  id: 'msg-1',
  spaceId: 'ch-1',
  conversationId: 'ch-1',
  senderId: 'agent-1',
  senderType: SenderType.agent,
  content: 'This is a bug finding',
  messageType: MessageType.reviewNode,
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
      agentDetailProvider.overrideWith((ref, id) async => null),
      workspacesProvider.overrideWith(
        (ref) => const Stream<List<Workspace>>.empty(),
      ),
      spaceWideMessagesProvider.overrideWith(
        (ref, spaceId) => Stream.value([]),
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
  Message? message,
  bool isSelected = false,
  ValueChanged<bool>? onToggleSelect,
  VoidCallback? onFix,
  VoidCallback? onComment,
  bool alwaysExpanded = false,
}) {
  return ReviewAccordionItem(
    alwaysExpanded: alwaysExpanded,
    message: message ?? testMessage,
    payload: payload ?? testPayload,
    spaceId: 'ch-1',
    isSelected: isSelected,
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

  testWidgets('row renders file path', (tester) async {
    await tester.pumpWidget(_buildTestApp(_buildWidget()));
    await tester.pump();
    // Findings open by default now, so the path is on the row AND on the
    // expanded body's anchor.
    expect(
      find.byWidgetPredicate(
        (w) => w is Text && (w.data?.contains('lib/foo.dart') ?? false),
      ),
      findsWidgets,
    );
  });

  testWidgets('collapsed row renders status pill', (tester) async {
    await tester.pumpWidget(_buildTestApp(_buildWidget()));
    await tester.pump();
    expect(find.text('Open'), findsOneWidget);
  });

  testWidgets('a finding opens by default and folds on tap', (tester) async {
    // A review is read by working down its findings, so the body is there to
    // begin with; the chevron is for folding away what you have dealt with.
    await tester.pumpWidget(_buildTestApp(_buildWidget()));
    await tester.pump();
    Finder body() => find.widgetWithText(CcButton, 'Fix');
    expect(body(), findsOneWidget);

    await tester.tap(find.text('BUG'));
    await tester.pump();
    expect(body(), findsNothing);

    await tester.tap(find.text('BUG'));
    await tester.pump();
    expect(body(), findsOneWidget);
  });

  testWidgets('the row carries the finding’s own headline', (tester) async {
    // A column of rows reading `BUG · P1 · 85% · path` is a column of identical
    // rows; the summary is the only thing that tells two findings apart. It
    // stays on the row while the finding is open too — the row is a PINNED
    // sliver header, so it is what names the body scrolling under it.
    await tester.pumpWidget(_buildTestApp(_buildWidget()));
    await tester.pump();
    final header = tester.widget<ReviewFindingHeader>(
      find.byType(ReviewFindingHeader),
    );
    expect(header.summary, 'This is a bug finding');
  });

  testWidgets('the body does not restate what the row already says', (
    tester,
  ) async {
    await tester.pumpWidget(_buildTestApp(_buildWidget()));
    await tester.pump();
    // Priority, confidence and status live on the row exactly once.
    expect(find.text('P0'), findsOneWidget);
    expect(find.text('90%'), findsOneWidget);
    expect(find.text('Open'), findsOneWidget);
  });

  testWidgets('alwaysExpanded drops the collapse affordance', (tester) async {
    await tester.pumpWidget(_buildTestApp(_buildWidget(alwaysExpanded: true)));
    await tester.pump();
    expect(find.text('BUG'), findsNothing, reason: 'no collapsed row');
    expect(find.text('This is a bug finding'), findsOneWidget);
  });

  testWidgets('markdown body rendered', (tester) async {
    await tester.pumpWidget(_buildTestApp(_buildWidget()));
    await tester.pump();
    // Twice, by design: once as the pinned row's headline and once as the body
    // itself. This one-line finding is the case where they coincide.
    expect(find.text('This is a bug finding'), findsNWidgets(2));
  });

  testWidgets('action bar rendered', (tester) async {
    await tester.pumpWidget(_buildTestApp(_buildWidget()));
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
    final commentButton = tester.widget<CcButton>(
      find.widgetWithText(CcButton, 'Comment'),
    );
    expect(commentButton.onPressed, isNull);
  });

  testWidgets('selection checkbox is always visible', (tester) async {
    // There is no selection mode to enter: ticking a checkbox is what scopes
    // the bulk verbs to a subset, so the affordance is on every row by
    // default.
    await tester.pumpWidget(_buildTestApp(_buildWidget()));
    await tester.pump();
    expect(find.byType(CcCheckbox), findsOneWidget);
  });

  testWidgets('chevron sits flush against the row’s trailing edge', (
    tester,
  ) async {
    // Regression: a loose Flexible next to a Spacer split the slack 1:1 and
    // dropped the text's unused half, parking the chevron in the middle of
    // the leftover space on wide windows.
    tester.view.physicalSize = const Size(2200, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    const wideAnchorPayload = ReviewNodePayload(
      kind: ReviewNodeKind.bug,
      priority: ReviewNodePriority.p2,
      confidence: 0.7,
      anchor: ReviewNodeAnchor(
        filePath: 'application/client/Utility/l18n/l18n.ts',
        lineNumber: 71,
      ),
      status: ReviewNodeStatus.open,
    );
    await tester.pumpWidget(
      _buildTestApp(_buildWidget(payload: wideAnchorPayload)),
    );
    await tester.pump();

    final trailing = tester.getTopRight(find.byIcon(AppIcons.chevronUp));
    expect(trailing.dx, greaterThan(2200 - 32));
  });

  testWidgets('expanded header paints an opaque background', (tester) async {
    // The row pins over its own scrolling body as a sliver header; a
    // translucent fill lets that body bleed through as ghost text.
    await tester.pumpWidget(_buildTestApp(_buildWidget()));
    await tester.pump();

    final row = find.byWidgetPredicate(
      (w) =>
          w is Container &&
          w.constraints?.maxHeight == 44 &&
          w.decoration is BoxDecoration,
    );
    expect(row, findsOneWidget);
    final decoration =
        tester.widget<Container>(row).decoration! as BoxDecoration;
    expect(decoration.color!.a, 1.0);
  });
}
