import 'package:cc_domain/core/domain/entities/memory_fact.dart';
import 'package:cc_domain/core/domain/entities/memory_policy.dart';
import 'package:cc_domain/core/domain/value_objects/agent_role.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/memory/presentation/widgets/confidence_meter.dart';
import 'package:control_center/features/memory/presentation/widgets/knowledge_graph_data.dart'
    show NodeData, NodeType;
import 'package:control_center/features/memory/presentation/widgets/knowledge_graph_inspector.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/test_wrap.dart';

MemoryFact _fact({
  String content = 'User likes dark theme.',
  double confidence = 1.0,
  String? supersededBy,
  AgentRole? authoredByRole,
}) {
  return MemoryFact(
    id: 'fact-1',
    workspaceId: 'ws-1',
    domain: 'preferences',
    topic: 'colors',
    content: content,
    confidence: confidence,
    supersededBy: supersededBy,
    authoredByRole: authoredByRole,
    createdAt: DateTime(2026, 6, 1),
    updatedAt: DateTime(2026, 6, 1),
  );
}

MemoryPolicy _policy({
  String domain = 'preferences',
  String rule = 'Only allow coder role.',
  AgentRole? requiredRole,
  bool active = true,
}) {
  return MemoryPolicy(
    id: 'pol-1',
    workspaceId: 'ws-1',
    domain: domain,
    rule: rule,
    requiredRole: requiredRole,
    active: active,
    createdAt: DateTime(2026, 6, 1),
    updatedAt: DateTime(2026, 6, 1),
  );
}

Future<void> _pump(
  WidgetTester tester,
  NodeData data, {
  VoidCallback? onClose,
  VoidCallback? onOpen,
  VoidCallback? onDelete,
  ValueChanged<bool>? onToggleActive,
  VoidCallback? onToggleFacts,
  bool factsShown = false,
}) async {
  await tester.pumpWidget(
    testWrap(
      SizedBox(
        width: kKnowledgeGraphInspectorWidth,
        height: 700,
        child: KnowledgeGraphInspector(
          nodeData: data,
          onClose: onClose ?? () {},
          onOpen: onOpen,
          onDelete: onDelete,
          onToggleActive: onToggleActive,
          onToggleFacts: onToggleFacts,
          factsShown: factsShown,
        ),
      ),
    ),
  );
  await tester.pump();
}

NodeData _factNode(MemoryFact fact) =>
    NodeData(type: NodeType.fact, fact: fact, factCount: 1);

NodeData _policyNode(MemoryPolicy policy) =>
    NodeData(type: NodeType.policy, policy: policy);

/// The rendered text of the markdown body, which is rich text.
Finder _rendered(String text) => find.textContaining(text, findRichText: true);

void main() {
  group('domain', () {
    testWidgets('shows its name and counts', (tester) async {
      await _pump(
        tester,
        const NodeData(
          type: NodeType.domain,
          domainLabel: 'Preferences',
          domainSlug: 'prefs',
          factCount: 5,
          policyCount: 2,
        ),
      );

      expect(find.text('Preferences'), findsOneWidget);
      expect(find.text('5'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
    });

    testWidgets('falls back to the slug without a label', (tester) async {
      await _pump(
        tester,
        const NodeData(type: NodeType.domain, domainSlug: 'test-domain'),
      );

      expect(find.text('test-domain'), findsOneWidget);
    });
  });

  group('topic', () {
    testWidgets('shows its name and fact count', (tester) async {
      await _pump(
        tester,
        const NodeData(type: NodeType.topic, topic: 'Colors', factCount: 42),
      );

      expect(find.text('Colors'), findsOneWidget);
      expect(find.text('42'), findsOneWidget);
    });

    testWidgets('offers to show or hide its facts', (tester) async {
      var toggled = 0;
      await _pump(
        tester,
        const NodeData(type: NodeType.topic, topic: 'Colors', factCount: 3),
        onToggleFacts: () => toggled++,
      );

      await tester.tap(find.text('Show facts'));
      expect(toggled, 1);

      await _pump(
        tester,
        const NodeData(type: NodeType.topic, topic: 'Colors', factCount: 3),
        onToggleFacts: () {},
        factsShown: true,
      );
      expect(find.text('Hide facts'), findsOneWidget);
    });
  });

  group('fact', () {
    testWidgets('renders its markdown instead of printing the source', (
      tester,
    ) async {
      await _pump(
        tester,
        _factNode(_fact(content: '**Prefers** the `dark` theme.')),
      );

      expect(_rendered('Prefers'), findsWidgets);
      expect(_rendered('**'), findsNothing);
      expect(_rendered('`'), findsNothing);
    });

    testWidgets('tags a superseded fact', (tester) async {
      await _pump(tester, _factNode(_fact(supersededBy: 'newer-fact-1')));

      expect(find.text('Superseded'), findsOneWidget);
    });

    testWidgets('shows confidence and the authoring role', (tester) async {
      await _pump(
        tester,
        _factNode(_fact(confidence: 0.75, authoredByRole: AgentRole.coder)),
      );

      expect(find.byType(ConfidenceMeter), findsOneWidget);
      expect(find.text('Coder'), findsOneWidget);
    });

    testWidgets('leaves out the role when nobody is known', (tester) async {
      await _pump(tester, _factNode(_fact()));

      expect(find.text('Role'), findsNothing);
    });

    testWidgets('offers open and delete when given them', (tester) async {
      var opened = 0;
      var deleted = 0;
      await _pump(
        tester,
        _factNode(_fact()),
        onOpen: () => opened++,
        onDelete: () => deleted++,
      );

      await tester.tap(find.text('Open'));
      await tester.tap(find.byIcon(AppIcons.trash2));
      expect((opened, deleted), (1, 1));
    });

    testWidgets('has no footer without actions', (tester) async {
      await _pump(tester, _factNode(_fact()));

      expect(find.text('Open'), findsNothing);
      expect(find.byIcon(AppIcons.trash2), findsNothing);
    });
  });

  group('policy', () {
    testWidgets('renders its rule, role and bare domain', (tester) async {
      await _pump(
        tester,
        _policyNode(
          _policy(
            rule: 'Deny access for QA role.',
            requiredRole: AgentRole.qa,
            domain: 'security',
          ),
        ),
      );

      expect(_rendered('Deny access for QA role.'), findsWidgets);
      expect(find.text('QA'), findsOneWidget);
      expect(find.text('security'), findsOneWidget);
    });

    testWidgets('its switch reports the new state', (tester) async {
      bool? active;
      await _pump(
        tester,
        _policyNode(_policy()),
        onToggleActive: (value) => active = value,
      );

      await tester.tap(find.byType(CcSwitch));
      expect(active, isFalse);
    });

    testWidgets('says so when inactive and it cannot be switched', (
      tester,
    ) async {
      await _pump(tester, _policyNode(_policy(active: false)));

      expect(find.text('Inactive'), findsOneWidget);
    });
  });

  group('closing', () {
    testWidgets('the close button dismisses it', (tester) async {
      var closed = 0;
      await _pump(tester, _factNode(_fact()), onClose: () => closed++);

      await tester.tap(find.byIcon(AppIcons.x));
      expect(closed, 1);
    });

    testWidgets('Escape dismisses it', (tester) async {
      var closed = 0;
      await _pump(tester, _factNode(_fact()), onClose: () => closed++);

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      expect(closed, 1);
    });
  });
}
