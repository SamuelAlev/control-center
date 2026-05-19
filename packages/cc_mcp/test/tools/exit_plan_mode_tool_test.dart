import 'dart:convert';

import 'package:cc_domain/core/domain/entities/agent_run_log.dart';
import 'package:cc_domain/core/domain/repositories/agent_run_log_repository.dart';
import 'package:cc_domain/core/domain/value_objects/mode.dart';
import 'package:cc_domain/features/governance/domain/entities/approval.dart';
import 'package:cc_domain/features/governance/domain/entities/approval_comment.dart';
import 'package:cc_domain/features/governance/domain/repositories/approval_repository.dart';
import 'package:cc_domain/features/governance/domain/services/approval_workflow_service.dart';
import 'package:cc_domain/features/governance/domain/value_objects/approval_kind.dart';
import 'package:cc_domain/features/governance/domain/value_objects/approval_status.dart';
import 'package:cc_domain/features/messaging/domain/entities/conversation_tree.dart';
import 'package:cc_domain/features/messaging/domain/entities/space.dart';
import 'package:cc_domain/features/messaging/domain/repositories/messaging_repository.dart';
import 'package:cc_mcp/src/tools/exit_plan_mode_tool.dart';
import 'package:test/test.dart';

/// In-memory [ApprovalRepository] — enough for the tool + workflow under test.
class _InMemoryApprovals implements ApprovalRepository {
  final List<Approval> rows = [];

  List<Approval> _ws(String ws) =>
      rows.where((a) => a.workspaceId == ws).toList();

  @override
  Future<void> upsert(Approval approval) async {
    rows.removeWhere((a) => a.id == approval.id);
    rows.add(approval);
  }

  @override
  Stream<List<Approval>> watchByWorkspace(String workspaceId) =>
      Stream.value(_ws(workspaceId));

  @override
  Future<Approval?> getById(String workspaceId, String id) async =>
      _ws(workspaceId).where((a) => a.id == id).firstOrNull;

  @override
  Stream<List<Approval>> watchByStatus(String workspaceId, String status) =>
      Stream.value(
        _ws(workspaceId).where((a) => a.status.storage == status).toList(),
      );

  @override
  Future<void> delete(String workspaceId, String id) async =>
      rows.removeWhere((a) => a.id == id && a.workspaceId == workspaceId);

  @override
  Stream<List<ApprovalComment>> watchComments(String w, String a) =>
      const Stream.empty();

  @override
  Future<List<ApprovalComment>> getComments(String w, String a) async =>
      const [];

  @override
  Future<void> addComment(ApprovalComment comment) async {}
}

/// Returns a fixed active run (or none) for any agent.
class _FakeRunLogs implements AgentRunLogRepository {
  _FakeRunLogs(this._run);
  final AgentRunLog? _run;

  @override
  Future<AgentRunLog?> activeRunForAgent(
    String workspaceId,
    String agentId,
  ) async => _run;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Records every mode flip the tool performs.
class _RecordingMessaging implements MessagingRepository {
  @override
  Future<Space?> getSpaceById(String workspaceId, String spaceId) async => null;

  final List<({String workspaceId, String spaceId, Mode mode})> flips = [];

  @override
  Future<void> setSpaceMode(
    String workspaceId,
    String spaceId,
    Mode mode,
  ) async =>
      flips.add((workspaceId: workspaceId, spaceId: spaceId, mode: mode));

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  /// The tree is not exercised by this fake — a branch it silently accepted
  /// would be a pointer move nothing could observe, so it refuses instead.
  @override
  Future<ConversationTree> conversationTree({
    required String workspaceId,
    required String conversationId,
  }) async => throw UnimplementedError();

  @override
  Future<void> branchConversationAt({
    required String workspaceId,
    required String conversationId,
    required String messageId,
  }) async => throw UnimplementedError();

  @override
  Future<String> forkConversation({
    required String workspaceId,
    required String spaceId,
    required String conversationId,
    String? messageId,
    String? title,
  }) async => throw UnimplementedError();
}

AgentRunLog _run({
  String workspaceId = 'ws1',
  String? conversationId = 'chan-1',
}) => AgentRunLog(
  id: 'run-1',
  agentId: 'a1',
  workspaceId: workspaceId,
  spaceId: conversationId,
  conversationId: conversationId,
  startedAt: DateTime.utc(2026, 6, 30),
  status: RunStatus.running,
);

void main() {
  late _InMemoryApprovals approvals;
  late ApprovalWorkflowService workflow;
  late _RecordingMessaging messaging;

  ExitPlanModeTool build(AgentRunLog? run) => ExitPlanModeTool(
    runLogRepository: _FakeRunLogs(run),
    approvalWorkflow: workflow,
    approvalRepository: approvals,
    messagingRepository: messaging,
  );

  setUp(() {
    approvals = _InMemoryApprovals();
    workflow = ApprovalWorkflowService(repository: approvals);
    messaging = _RecordingMessaging();
  });

  test(
    'first call opens a pending plan_exit approval; no mode flip yet',
    () async {
      final tool = build(_run());
      final result = await tool.run({'workspace_id': 'ws1', 'agent_id': 'a1'});

      expect(result.isError, isFalse);
      final json =
          jsonDecode(result.content.first.text) as Map<String, dynamic>;
      expect(json['status'], 'pending');

      // A plan_exit approval was opened, linked to the conversation.
      expect(approvals.rows, hasLength(1));
      final approval = approvals.rows.single;
      expect(approval.kind, ApprovalKind.planExit);
      expect(approval.status, ApprovalStatus.pending);
      expect(approval.linkedEntityType, 'conversation');
      expect(approval.linkedEntityId, 'chan-1');
      expect(approval.requestedById, 'a1');

      // The conversation has NOT left plan mode.
      expect(messaging.flips, isEmpty);
    },
  );

  test(
    'a second call while pending stays pending and opens no duplicate',
    () async {
      final tool = build(_run());
      await tool.run({'workspace_id': 'ws1', 'agent_id': 'a1'});
      final again = await tool.run({'workspace_id': 'ws1', 'agent_id': 'a1'});

      final json = jsonDecode(again.content.first.text) as Map<String, dynamic>;
      expect(json['status'], 'pending');
      expect(approvals.rows, hasLength(1), reason: 'no duplicate approval');
      expect(messaging.flips, isEmpty);
    },
  );

  test(
    'once approved, the next call flips the conversation out of plan mode',
    () async {
      final tool = build(_run());
      await tool.run({'workspace_id': 'ws1', 'agent_id': 'a1'});
      // Human approves.
      await workflow.decide(
        approvals.rows.single.id,
        workspaceId: 'ws1',
        decision: ApprovalDecision.approve,
      );

      final result = await tool.run({'workspace_id': 'ws1', 'agent_id': 'a1'});
      final json =
          jsonDecode(result.content.first.text) as Map<String, dynamic>;
      expect(json['status'], 'approved');
      expect(messaging.flips, hasLength(1));
      // The flip is applied in the run's own workspace database.
      expect(messaging.flips.single.workspaceId, 'ws1');
      expect(messaging.flips.single.spaceId, 'chan-1');
      expect(messaging.flips.single.mode, Mode.chat);
    },
  );

  test('errors when the agent has no active run', () async {
    final tool = build(null);
    final result = await tool.run({'workspace_id': 'ws1', 'agent_id': 'a1'});
    expect(result.isError, isTrue);
    expect(approvals.rows, isEmpty);
  });

  test('rejects a run that belongs to a different workspace', () async {
    final tool = build(_run(workspaceId: 'other-ws'));
    final result = await tool.run({'workspace_id': 'ws1', 'agent_id': 'a1'});
    expect(result.isError, isTrue);
    expect(approvals.rows, isEmpty);
  });
}
