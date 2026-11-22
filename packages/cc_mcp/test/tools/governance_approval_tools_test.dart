import 'dart:convert';

import 'package:cc_domain/cc_domain.dart' show JsonRpcRequest;
import 'package:cc_domain/core/domain/services/activity_logger.dart';
import 'package:cc_domain/features/governance/domain/entities/approval.dart';
import 'package:cc_domain/features/governance/domain/entities/approval_comment.dart';
import 'package:cc_domain/features/governance/domain/repositories/approval_repository.dart';
import 'package:cc_domain/features/governance/domain/services/approval_workflow_service.dart';
import 'package:cc_domain/features/governance/domain/value_objects/approval_status.dart';
import 'package:cc_domain/features/mcp/domain/services/mcp_tool_registry.dart';
import 'package:cc_domain/features/mcp/domain/value_objects/mcp_call_scope.dart';
import 'package:cc_mcp/src/mcp_tool_dispatcher.dart';
import 'package:cc_mcp/src/tools/governance_approval_tools.dart';
import 'package:test/test.dart';

import '../code_mode_fakes.dart' show Approver;

void main() {
  late _FakeApprovals approvals;
  late CreateApprovalTool tool;

  setUp(() {
    approvals = _FakeApprovals();
    tool = CreateApprovalTool(
      service: ApprovalWorkflowService(repository: approvals),
    );
  });

  test('missing workspace_id is refused', () async {
    final result = await tool.run({'title': 'Ship the release'});
    expect(result.isError, isTrue);
    expect(result.content.first.text, contains('workspace_id'));
  });

  test('creates a pending approval', () async {
    final result = await tool.run({
      'workspace_id': 'ws-1',
      'title': 'Ship the release',
      'agent_id': 'agent-1',
    });
    expect(result.isError, isFalse);
    expect(approvals.store, hasLength(1));
    expect(approvals.store.values.single.title, 'Ship the release');
    final body = jsonDecode(result.content.first.text) as Map<String, dynamic>;
    expect(body['title'], 'Ship the release');
    expect(body['status'], 'pending');
  });

  // Who acted on an approval is whoever the call is attested as, never an
  // argument: a run's agent, recorded as an agent, in the record and in the
  // audit entry alike.
  group('the actor is the attested caller', () {
    late _Audit audit;
    late McpToolDispatcher dispatcher;
    const run = McpCallScope(
      workspaceId: 'ws-1',
      agentId: 'agent-1',
      attested: true,
      runId: 'dispatch-1',
    );

    setUp(() {
      audit = _Audit();
      final service = ApprovalWorkflowService(
        repository: approvals,
        activityLogger: audit,
      );
      dispatcher = McpToolDispatcher(
        confirmationPort: Approver(),
        registry: McpToolRegistry([
          CreateApprovalTool(service: service),
          DecideApprovalTool(service: service),
          CommentApprovalTool(service: service),
        ]),
      );
      approvals.store['ap-1'] = Approval(
        id: 'ap-1',
        workspaceId: 'ws-1',
        title: 'Ship the release',
        createdAt: DateTime.utc(2026),
        updatedAt: DateTime.utc(2026),
      );
    });

    Future<Map<String, dynamic>> call(
      String name,
      Map<String, dynamic> arguments, {
      McpCallScope? scope = run,
    }) async {
      final response = await dispatcher.handleScopedRequest(
        JsonRpcRequest(
          method: 'tools/call',
          params: {'name': name, 'arguments': arguments},
          id: 1,
        ),
        scope: scope,
      );
      return response['result'] as Map<String, dynamic>;
    }

    test(
      'a comment is the run\'s agent\'s, whatever author it names',
      () async {
        final result = await call('comment_approval', {
          'workspace_id': 'ws-1',
          'approval_id': 'ap-1',
          'body': 'Looks fine to me.',
          // Neither names the author: one is no argument of the tool and is
          // ignored like any unknown argument, the other is the run's own.
          'author_id': 'user-alice',
          'agent_id': 'user-alice',
        });
        expect(result['isError'], isNot(isTrue));
        final comment = approvals.comments.single;
        expect(comment.authorType, 'agent');
        expect(comment.authorId, 'agent-1');
        expect(audit.entries.single, (
          'agent',
          'agent-1',
          'approval_commented',
        ));
      },
    );

    test('a decision and a request are the run\'s agent\'s too', () async {
      await call('create_approval', {
        'workspace_id': 'ws-1',
        'title': 'Merge it',
        'requested_by': 'agent-2',
      });
      await call('decide_approval', {
        'workspace_id': 'ws-1',
        'approval_id': 'ap-1',
        'decision': 'approve',
        'decided_by': 'user-alice',
      });
      final created = approvals.store.values.firstWhere(
        (a) => a.title == 'Merge it',
      );
      expect(created.requestedById, 'agent-1');
      final decided = approvals.store['ap-1']!;
      expect(decided.decidedByActorType, 'agent');
      expect(decided.decidedById, 'agent-1');
      expect(audit.entries, [
        ('agent', 'agent-1', 'approval_requested'),
        ('agent', 'agent-1', 'approval_approve'),
      ]);
    });

    test(
      'a call no run is attested for is refused and records nothing',
      () async {
        for (final scope in [
          null,
          const McpCallScope(workspaceId: 'ws-1', agentId: 'agent-1'),
          const McpCallScope(workspaceId: 'ws-1', attested: true),
        ]) {
          final result = await call('comment_approval', {
            'workspace_id': 'ws-1',
            'approval_id': 'ap-1',
            'body': 'Approved by me.',
            'agent_id': 'agent-1',
          }, scope: scope);
          expect(result['isError'], isTrue, reason: '$scope');
        }
        expect(approvals.comments, isEmpty);
        expect(audit.entries, isEmpty);
      },
    );

    test('a script may not call them', () {
      final service = ApprovalWorkflowService(repository: approvals);
      for (final tool in [
        CreateApprovalTool(service: service),
        DecideApprovalTool(service: service),
        CommentApprovalTool(service: service),
      ]) {
        expect(tool.scriptCallable, isFalse, reason: tool.name);
      }
    });
  });
}

class _Audit extends ActivityLogger {
  final List<(String, String?, String)> entries = [];

  @override
  void log({
    required String actorType,
    String? actorId,
    required String action,
    required String entityType,
    String? entityId,
    String? details,
    String? workspaceId,
    String? runId,
  }) => entries.add((actorType, actorId, action));
}

class _FakeApprovals implements ApprovalRepository {
  final Map<String, Approval> store = {};
  final List<ApprovalComment> comments = [];

  @override
  Future<void> addComment(ApprovalComment comment) async =>
      comments.add(comment);

  @override
  Future<bool> recordDecision(
    Approval approval, {
    required ApprovalStatus expected,
  }) async {
    store[approval.id] = approval;
    return true;
  }

  @override
  Future<void> upsert(Approval approval) async => store[approval.id] = approval;

  @override
  Future<Approval?> getById(String workspaceId, String id) async {
    final approval = store[id];
    return approval?.workspaceId == workspaceId ? approval : null;
  }

  @override
  Stream<List<Approval>> watchByWorkspace(String workspaceId) => Stream.value(
    store.values.where((a) => a.workspaceId == workspaceId).toList(),
  );

  @override
  dynamic noSuchMethod(Invocation invocation) {}
}
