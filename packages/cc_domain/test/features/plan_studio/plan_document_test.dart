import 'package:cc_domain/features/plan_studio/domain/entities/plan_document.dart';
import 'package:cc_domain/features/plan_studio/domain/value_objects/plan_graph.dart';
import 'package:test/test.dart';

final _createdAt = DateTime.utc(2026, 1, 1);
final _updatedAt = DateTime.utc(2026, 1, 2);

PlanDocument _doc({
  String id = 'doc-1',
  String workspaceId = 'ws-1',
  String conversationId = 'conv-1',
  String agentId = 'agent-1',
  String goal = 'The goal',
  PlanGraph graph = const PlanGraph(nodes: []),
  List<PlanClarification> clarifications = const [],
  PlanDocumentStatus status = PlanDocumentStatus.proposed,
  int revision = 1,
}) => PlanDocument(
  id: id,
  workspaceId: workspaceId,
  conversationId: conversationId,
  agentId: agentId,
  goal: goal,
  graph: graph,
  clarifications: clarifications,
  status: status,
  revision: revision,
  createdAt: _createdAt,
  updatedAt: _updatedAt,
);

void main() {
  group('PlanClarification', () {
    test('JSON round-trip', () {
      const c = PlanClarification(question: 'Which repo?', answer: 'cc');
      final restored = PlanClarification.fromJson(c.toJson());
      expect(restored.question, c.question);
      expect(restored.answer, c.answer);
    });

    test('fromJson defaults missing fields to empty strings', () {
      final restored = PlanClarification.fromJson(const {});
      expect(restored.question, '');
      expect(restored.answer, '');
    });
  });

  group('PlanDocumentStatus.fromName', () {
    test('parses known names', () {
      expect(PlanDocumentStatus.fromName('draft'), PlanDocumentStatus.draft);
      expect(
        PlanDocumentStatus.fromName('proposed'),
        PlanDocumentStatus.proposed,
      );
      expect(
        PlanDocumentStatus.fromName('approved'),
        PlanDocumentStatus.approved,
      );
      expect(
        PlanDocumentStatus.fromName('rejected'),
        PlanDocumentStatus.rejected,
      );
      expect(
        PlanDocumentStatus.fromName('superseded'),
        PlanDocumentStatus.superseded,
      );
    });

    test('defaults to proposed for unknown/null names', () {
      expect(PlanDocumentStatus.fromName('bogus'), PlanDocumentStatus.proposed);
      expect(PlanDocumentStatus.fromName(null), PlanDocumentStatus.proposed);
    });
  });

  group('PlanDocument — constructor validation', () {
    test('throws on empty id', () {
      expect(() => _doc(id: ''), throwsArgumentError);
    });

    test('throws on empty workspaceId', () {
      expect(() => _doc(workspaceId: ''), throwsArgumentError);
    });

    test('throws on empty conversationId', () {
      expect(() => _doc(conversationId: ''), throwsArgumentError);
    });

    test('throws on empty agentId', () {
      expect(() => _doc(agentId: ''), throwsArgumentError);
    });

    test('throws when revision < 1', () {
      expect(() => _doc(revision: 0), throwsArgumentError);
      expect(() => _doc(revision: -1), throwsArgumentError);
    });

    test('accepts a well-formed document', () {
      expect(_doc, returnsNormally);
    });
  });

  group('PlanDocument.bodyToJson / fromBody', () {
    test('round-trips goal, graph, and clarifications', () {
      final doc = _doc(
        goal: 'Ship the report',
        graph: const PlanGraph(
          nodes: [
            PlanNode(key: 'w1', title: 'Step 1', type: PlanNodeType.work),
          ],
        ),
        clarifications: const [
          PlanClarification(question: 'Which repo?', answer: 'cc'),
        ],
      );
      final body = doc.bodyToJson();
      final restored = PlanDocument.fromBody(
        id: doc.id,
        workspaceId: doc.workspaceId,
        conversationId: doc.conversationId,
        agentId: doc.agentId,
        body: body,
        status: doc.status,
        revision: doc.revision,
        createdAt: doc.createdAt,
        updatedAt: doc.updatedAt,
      );
      expect(restored.goal, 'Ship the report');
      expect(restored.graph.nodes, hasLength(1));
      expect(restored.graph.nodes.single.key, 'w1');
      expect(restored.clarifications, hasLength(1));
      expect(restored.clarifications.single.question, 'Which repo?');
      expect(restored.clarifications.single.answer, 'cc');
    });

    test('bodyToJson omits clarifications when empty', () {
      final doc = _doc();
      expect(doc.bodyToJson().containsKey('clarifications'), isFalse);
    });

    test('bodyToJsonString parses back through bodyToJson equivalently', () {
      final doc = _doc(goal: 'A goal');
      final restored = PlanDocument.fromBody(
        id: doc.id,
        workspaceId: doc.workspaceId,
        conversationId: doc.conversationId,
        agentId: doc.agentId,
        body: doc.bodyToJson(),
        status: doc.status,
        revision: doc.revision,
        createdAt: doc.createdAt,
        updatedAt: doc.updatedAt,
      );
      expect(restored.goal, doc.goal);
    });

    test('fromBody defaults a missing graph to an empty PlanGraph', () {
      final restored = PlanDocument.fromBody(
        id: 'doc-1',
        workspaceId: 'ws-1',
        conversationId: 'conv-1',
        agentId: 'agent-1',
        body: const {'goal': 'g'},
        status: PlanDocumentStatus.proposed,
        revision: 1,
        createdAt: _createdAt,
        updatedAt: _updatedAt,
      );
      expect(restored.graph.nodes, isEmpty);
    });
  });

  group('PlanDocument.copyWith', () {
    test('replaces only the given fields, keeping identity fields', () {
      final doc = _doc();
      final edited = doc.copyWith(
        goal: 'New goal',
        status: PlanDocumentStatus.approved,
        revision: 2,
      );
      expect(edited.id, doc.id);
      expect(edited.workspaceId, doc.workspaceId);
      expect(edited.conversationId, doc.conversationId);
      expect(edited.agentId, doc.agentId);
      expect(edited.goal, 'New goal');
      expect(edited.status, PlanDocumentStatus.approved);
      expect(edited.revision, 2);
      expect(edited.createdAt, doc.createdAt);
    });

    test('with no arguments, returns an equivalent document', () {
      final doc = _doc();
      final copy = doc.copyWith();
      expect(copy.goal, doc.goal);
      expect(copy.status, doc.status);
      expect(copy.revision, doc.revision);
    });
  });

  group('PlanDocument equality', () {
    test('equal when id/status/revision/updatedAt match', () {
      final a = _doc();
      final b = _doc(goal: 'A totally different goal text');
      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });

    test('not equal when revision differs', () {
      final a = _doc(revision: 1);
      final b = _doc(revision: 2);
      expect(a, isNot(b));
    });

    test('not equal when status differs', () {
      final a = _doc(status: PlanDocumentStatus.proposed);
      final b = _doc(status: PlanDocumentStatus.approved);
      expect(a, isNot(b));
    });
  });
}
