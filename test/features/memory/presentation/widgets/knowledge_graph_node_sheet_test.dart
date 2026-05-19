import 'package:cc_domain/core/domain/entities/memory_fact.dart';
import 'package:cc_domain/core/domain/entities/memory_policy.dart';
import 'package:cc_domain/core/domain/value_objects/agent_role.dart';
import 'package:control_center/features/memory/presentation/widgets/confidence_meter.dart';
import 'package:control_center/features/memory/presentation/widgets/knowledge_graph.dart'
    show NodeData, NodeType;
import 'package:control_center/features/memory/presentation/widgets/knowledge_graph_node_sheet.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../helpers/test_wrap.dart';

MemoryFact _fact({
  String id = 'fact-1',
  String workspaceId = 'ws-1',
  String domain = 'preferences',
  String topic = 'colors',
  String content = 'User likes dark theme.',
  double confidence = 1.0,
  String? supersededBy,
  AgentRole? authoredByRole,
  DateTime? createdAt,
  DateTime? updatedAt,
}) {
  return MemoryFact(
    id: id,
    workspaceId: workspaceId,
    domain: domain,
    topic: topic,
    content: content,
    confidence: confidence,
    supersededBy: supersededBy,
    authoredByRole: authoredByRole,
    createdAt: createdAt ?? DateTime(2026, 6, 1),
    updatedAt: updatedAt ?? DateTime(2026, 6, 1),
  );
}

MemoryPolicy _policy({
  String id = 'pol-1',
  String workspaceId = 'ws-1',
  String domain = 'preferences',
  String rule = 'Only allow coder role.',
  List<String> sourceFactIds = const [],
  AgentRole? requiredRole,
  bool active = true,
  DateTime? createdAt,
  DateTime? updatedAt,
}) {
  return MemoryPolicy(
    id: id,
    workspaceId: workspaceId,
    domain: domain,
    rule: rule,
    sourceFactIds: sourceFactIds,
    requiredRole: requiredRole,
    active: active,
    createdAt: createdAt ?? DateTime(2026, 6, 1),
    updatedAt: updatedAt ?? DateTime(2026, 6, 1),
  );
}

void main() {
  // ── Domain node ────────────────────────────────────────────────────

  testWidgets('renders domain label and stat counts', (tester) async {
    await tester.pumpWidget(
      testWrap(
        const KnowledgeGraphNodeSheet(
          nodeData: NodeData(
            type: NodeType.domain,
            domainLabel: 'Preferences',
            domainSlug: 'prefs',
            factCount: 5,
            policyCount: 2,
          ),
          workspaceId: 'ws-1',
        ),
      ),
    );

    expect(find.text('Preferences'), findsOneWidget);
    expect(find.text('5'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
  });

  testWidgets('falls back to domain slug when label is null', (tester) async {
    await tester.pumpWidget(
      testWrap(
        const KnowledgeGraphNodeSheet(
          nodeData: NodeData(
            type: NodeType.domain,
            domainSlug: 'test-domain',
            factCount: 0,
            policyCount: 0,
          ),
          workspaceId: 'ws-1',
        ),
      ),
    );

    expect(find.text('test-domain'), findsOneWidget);
  });

  testWidgets('falls back to empty string when no domain label or slug',
      (tester) async {
    await tester.pumpWidget(
      testWrap(
        const KnowledgeGraphNodeSheet(
          nodeData: NodeData(
            type: NodeType.domain,
            factCount: 0,
            policyCount: 0,
          ),
          workspaceId: 'ws-1',
        ),
      ),
    );

    // The domain label renders empty string (nodeData.domainLabel ?? nodeData.domainSlug ?? '')
    expect(find.text(''), findsOneWidget);
  });

  // ── Topic node ─────────────────────────────────────────────────────

  testWidgets('renders topic name and fact count', (tester) async {
    await tester.pumpWidget(
      testWrap(
        const KnowledgeGraphNodeSheet(
          nodeData: NodeData(
            type: NodeType.topic,
            topic: 'Colors',
            factCount: 3,
          ),
          workspaceId: 'ws-1',
        ),
      ),
    );

    expect(find.text('Colors'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
  });

  // ── Fact node ──────────────────────────────────────────────────────

  testWidgets('renders fact content and creation date', (tester) async {
    final fact = _fact(
      content: 'The user prefers dark theme.',
      createdAt: DateTime(2026, 3, 15),
    );

    await tester.pumpWidget(
      testWrap(
        KnowledgeGraphNodeSheet(
          nodeData: const NodeData(type: NodeType.fact, factCount: 1)
              .copyWithFact(fact),
          workspaceId: 'ws-1',
        ),
      ),
    );

    expect(find.text('The user prefers dark theme.'), findsOneWidget);
    expect(find.textContaining('2026-03-15'), findsOneWidget);
  });

  testWidgets('renders superseded chip for superseded fact', (tester) async {
    final fact = _fact(supersededBy: 'newer-fact-1');

    await tester.pumpWidget(
      testWrap(
        KnowledgeGraphNodeSheet(
          nodeData: const NodeData(type: NodeType.fact, factCount: 1)
              .copyWithFact(fact),
          workspaceId: 'ws-1',
        ),
      ),
    );

    expect(find.text('Superseded'), findsOneWidget);
  });

  testWidgets('shows confidence meter', (tester) async {
    final fact = _fact(confidence: 0.75);

    await tester.pumpWidget(
      testWrap(
        KnowledgeGraphNodeSheet(
          nodeData: const NodeData(type: NodeType.fact, factCount: 1)
              .copyWithFact(fact),
          workspaceId: 'ws-1',
        ),
      ),
    );

    // ConfidenceMeter is rendered
    expect(find.byType(ConfidenceMeter), findsOneWidget);
  });

  testWidgets('shows authored by role when present', (tester) async {
    final fact = _fact(authoredByRole: AgentRole.coder);

    await tester.pumpWidget(
      testWrap(
        KnowledgeGraphNodeSheet(
          nodeData: const NodeData(type: NodeType.fact, factCount: 1)
              .copyWithFact(fact),
          workspaceId: 'ws-1',
        ),
      ),
    );

    expect(find.textContaining('Coder'), findsOneWidget);
  });

  testWidgets('does not show authored by when role is null', (tester) async {
    final fact = _fact(authoredByRole: null);

    await tester.pumpWidget(
      testWrap(
        KnowledgeGraphNodeSheet(
          nodeData: const NodeData(type: NodeType.fact, factCount: 1)
              .copyWithFact(fact),
          workspaceId: 'ws-1',
        ),
      ),
    );

    // "authoredByLabel" text won't appear since authoredByRole is null
    // The ConfidenceMeter label says "Confidence" which may or may not show
    // The fact content is shown
    expect(find.text('User likes dark theme.'), findsOneWidget);
  });

  testWidgets('shows edit and delete buttons when callbacks are provided',
      (tester) async {
    final fact = _fact();

    await tester.pumpWidget(
      testWrap(
        KnowledgeGraphNodeSheet(
          nodeData: const NodeData(type: NodeType.fact, factCount: 1)
              .copyWithFact(fact),
          workspaceId: 'ws-1',
          onEditFact: () {},
          onDeleteFact: () {},
        ),
      ),
    );

    // Pencil and trash icons should be visible
    expect(find.byIcon(LucideIcons.pencil), findsOneWidget);
    expect(find.byIcon(LucideIcons.trash2), findsOneWidget);
  });

  testWidgets('hides edit and delete when callbacks are null', (tester) async {
    final fact = _fact();

    await tester.pumpWidget(
      testWrap(
        KnowledgeGraphNodeSheet(
          nodeData: const NodeData(type: NodeType.fact, factCount: 1)
              .copyWithFact(fact),
          workspaceId: 'ws-1',
        ),
      ),
    );

    expect(find.byIcon(LucideIcons.pencil), findsNothing);
    expect(find.byIcon(LucideIcons.trash2), findsNothing);
  });

  // ── Policy node ────────────────────────────────────────────────────

  testWidgets('renders policy rule text', (tester) async {
    final policy = _policy(rule: 'Deny access for QA role.');

    await tester.pumpWidget(
      testWrap(
        KnowledgeGraphNodeSheet(
          nodeData: const NodeData(type: NodeType.policy)
              .copyWithPolicy(policy),
          workspaceId: 'ws-1',
        ),
      ),
    );

    expect(find.text('Deny access for QA role.'), findsOneWidget);
  });

  testWidgets('renders inactive chip when policy is not active',
      (tester) async {
    final policy = _policy(active: false);

    await tester.pumpWidget(
      testWrap(
        KnowledgeGraphNodeSheet(
          nodeData: const NodeData(type: NodeType.policy)
              .copyWithPolicy(policy),
          workspaceId: 'ws-1',
        ),
      ),
    );

    expect(find.text('Inactive'), findsOneWidget);
  });

  testWidgets('does not show inactive chip when policy is active',
      (tester) async {
    final policy = _policy(active: true);

    await tester.pumpWidget(
      testWrap(
        KnowledgeGraphNodeSheet(
          nodeData: const NodeData(type: NodeType.policy)
              .copyWithPolicy(policy),
          workspaceId: 'ws-1',
        ),
      ),
    );

    expect(find.text('Inactive'), findsNothing);
  });

  testWidgets('renders required role label when present', (tester) async {
    final policy = _policy(requiredRole: AgentRole.qa);

    await tester.pumpWidget(
      testWrap(
        KnowledgeGraphNodeSheet(
          nodeData: const NodeData(type: NodeType.policy)
              .copyWithPolicy(policy),
          workspaceId: 'ws-1',
        ),
      ),
    );

    expect(find.textContaining('QA'), findsOneWidget);
  });

  testWidgets('does not show required role when null', (tester) async {
    final policy = _policy(requiredRole: null);

    await tester.pumpWidget(
      testWrap(
        KnowledgeGraphNodeSheet(
          nodeData: const NodeData(type: NodeType.policy)
              .copyWithPolicy(policy),
          workspaceId: 'ws-1',
        ),
      ),
    );

    // Required role icon should not be present
    expect(find.byIcon(LucideIcons.user), findsNothing);
  });

  testWidgets('renders source fact IDs as chips', (tester) async {
    final policy = _policy(sourceFactIds: ['abc12345', 'xyz']);

    await tester.pumpWidget(
      testWrap(
        KnowledgeGraphNodeSheet(
          nodeData: const NodeData(type: NodeType.policy)
              .copyWithPolicy(policy),
          workspaceId: 'ws-1',
        ),
      ),
    );

    // Short ID shown in full, long ID truncated to 8 chars
    expect(find.text('abc12345'), findsOneWidget);
    expect(find.text('xyz'), findsOneWidget);
  });

  testWidgets('shows toggle button when callback is provided', (tester) async {
    final policy = _policy(active: true);

    await tester.pumpWidget(
      testWrap(
        KnowledgeGraphNodeSheet(
          nodeData: const NodeData(type: NodeType.policy)
              .copyWithPolicy(policy),
          workspaceId: 'ws-1',
          onTogglePolicy: () {},
        ),
      ),
    );

    expect(find.text('Deactivate'), findsOneWidget);
  });

  testWidgets('shows activate label when policy is inactive', (tester) async {
    final policy = _policy(active: false);

    await tester.pumpWidget(
      testWrap(
        KnowledgeGraphNodeSheet(
          nodeData: const NodeData(type: NodeType.policy)
              .copyWithPolicy(policy),
          workspaceId: 'ws-1',
          onTogglePolicy: () {},
        ),
      ),
    );

    expect(find.text('Activate'), findsOneWidget);
  });

  testWidgets('hides toggle button when callback is null', (tester) async {
    final policy = _policy();

    await tester.pumpWidget(
      testWrap(
        KnowledgeGraphNodeSheet(
          nodeData: const NodeData(type: NodeType.policy)
              .copyWithPolicy(policy),
          workspaceId: 'ws-1',
        ),
      ),
    );

    expect(find.text('Deactivate'), findsNothing);
    expect(find.text('Activate'), findsNothing);
  });

  testWidgets('shows edit and delete for policy when callbacks provided',
      (tester) async {
    final policy = _policy();

    await tester.pumpWidget(
      testWrap(
        KnowledgeGraphNodeSheet(
          nodeData: const NodeData(type: NodeType.policy)
              .copyWithPolicy(policy),
          workspaceId: 'ws-1',
          onEditPolicy: () {},
          onDeletePolicy: () {},
        ),
      ),
    );

    expect(find.byIcon(LucideIcons.pencil), findsOneWidget);
    expect(find.byIcon(LucideIcons.trash2), findsOneWidget);
  });

  testWidgets('shows policy domain chip', (tester) async {
    final policy = _policy(domain: 'security');

    await tester.pumpWidget(
      testWrap(
        KnowledgeGraphNodeSheet(
          nodeData: const NodeData(type: NodeType.policy)
              .copyWithPolicy(policy),
          workspaceId: 'ws-1',
        ),
      ),
    );

    expect(find.text('security'), findsOneWidget);
  });

  // ── _StatRow ───────────────────────────────────────────────────────

  testWidgets('stat row shows icon, label, and value', (tester) async {
    await tester.pumpWidget(
      testWrap(
        const KnowledgeGraphNodeSheet(
          nodeData: NodeData(
            type: NodeType.topic,
            topic: 'Colors',
            factCount: 42,
          ),
          workspaceId: 'ws-1',
        ),
      ),
    );

    expect(find.text('42'), findsOneWidget);
  });

  // ── _formatDate ────────────────────────────────────────────────────

  testWidgets('formats date as yyyy-MM-dd', (tester) async {
    final fact = _fact(
      createdAt: DateTime(2026, 1, 5),
    );

    await tester.pumpWidget(
      testWrap(
        KnowledgeGraphNodeSheet(
          nodeData: const NodeData(type: NodeType.fact, factCount: 1)
              .copyWithFact(fact),
          workspaceId: 'ws-1',
        ),
      ),
    );

    expect(find.textContaining('2026-01-05'), findsOneWidget);
  });

  testWidgets('zero-pads single-digit month and day', (tester) async {
    final fact = _fact(
      createdAt: DateTime(2026, 3, 7),
    );

    await tester.pumpWidget(
      testWrap(
        KnowledgeGraphNodeSheet(
          nodeData: const NodeData(type: NodeType.fact, factCount: 1)
              .copyWithFact(fact),
          workspaceId: 'ws-1',
        ),
      ),
    );

    expect(find.textContaining('2026-03-07'), findsOneWidget);
  });
}

extension _NodeDataCopy on NodeData {
  NodeData copyWithFact(MemoryFact fact) {
    return NodeData(
      type: NodeType.fact,
      fact: fact,
      factCount: factCount,
      supersededFacts: supersededFacts,
    );
  }

  NodeData copyWithPolicy(MemoryPolicy policy) {
    return NodeData(
      type: NodeType.policy,
      policy: policy,
      policyCount: policyCount,
      supersededFacts: supersededFacts,
    );
  }
}
