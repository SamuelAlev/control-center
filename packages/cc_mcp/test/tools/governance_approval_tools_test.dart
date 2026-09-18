import 'dart:convert';

import 'package:cc_domain/features/governance/domain/entities/approval.dart';
import 'package:cc_domain/features/governance/domain/repositories/approval_repository.dart';
import 'package:cc_domain/features/governance/domain/services/approval_workflow_service.dart';
import 'package:cc_mcp/src/tools/governance_approval_tools.dart';
import 'package:test/test.dart';

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
    });
    expect(result.isError, isFalse);
    expect(approvals.store, hasLength(1));
    expect(approvals.store.values.single.title, 'Ship the release');
    final body = jsonDecode(result.content.first.text) as Map<String, dynamic>;
    expect(body['title'], 'Ship the release');
    expect(body['status'], 'pending');
  });
}

class _FakeApprovals implements ApprovalRepository {
  final Map<String, Approval> store = {};

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
