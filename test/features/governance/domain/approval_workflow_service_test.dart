import 'package:cc_domain/features/governance/domain/entities/approval.dart';
import 'package:cc_domain/features/governance/domain/entities/approval_comment.dart';
import 'package:cc_domain/features/governance/domain/repositories/approval_repository.dart';
import 'package:cc_domain/features/governance/domain/services/approval_workflow_service.dart';
import 'package:cc_domain/features/governance/domain/value_objects/approval_status.dart';
import 'package:cc_domain/src/errors/app_exceptions.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeApprovalRepo implements ApprovalRepository {
  final Map<String, Approval> approvals = {};
  final List<ApprovalComment> comments = [];

  @override
  Future<Approval?> getById(String workspaceId, String id) async {
    final a = approvals[id];
    if (a == null || a.workspaceId != workspaceId) {
      return null;
    }
    return a;
  }

  @override
  Future<void> upsert(Approval approval) async {
    approvals[approval.id] = approval;
  }

  @override
  Future<void> addComment(ApprovalComment comment) async {
    comments.add(comment);
  }

  @override
  Stream<List<Approval>> watchByWorkspace(String workspaceId) => Stream.value(
    approvals.values.where((a) => a.workspaceId == workspaceId).toList(),
  );

  @override
  Stream<List<Approval>> watchByStatus(String workspaceId, String status) =>
      Stream.value(
        approvals.values
            .where(
              (a) => a.workspaceId == workspaceId && a.status.storage == status,
            )
            .toList(),
      );

  @override
  Future<List<ApprovalComment>> getComments(
    String workspaceId,
    String approvalId,
  ) async => comments.where((c) => c.approvalId == approvalId).toList();

  @override
  Stream<List<ApprovalComment>> watchComments(
    String workspaceId,
    String approvalId,
  ) => Stream.value(comments.where((c) => c.approvalId == approvalId).toList());

  @override
  Future<void> delete(String workspaceId, String id) async {
    approvals.remove(id);
  }
}

void main() {
  late _FakeApprovalRepo repo;
  late ApprovalWorkflowService svc;

  setUp(() {
    repo = _FakeApprovalRepo();
    svc = ApprovalWorkflowService(repository: repo);
  });

  test('a new approval starts pending', () async {
    final a = await svc.createApproval(workspaceId: 'ws1', title: 'Ship 1.0');
    expect(a.status, ApprovalStatus.pending);
    expect(a.isDecided, isFalse);
  });

  test(
    'approve transitions pending → approved and stamps the decision',
    () async {
      final a = await svc.createApproval(workspaceId: 'ws1', title: 'Merge');
      final decided = await svc.decide(
        a.id,
        workspaceId: 'ws1',
        decision: ApprovalDecision.approve,
        decidedById: 'user1',
        reason: 'LGTM',
      );
      expect(decided.status, ApprovalStatus.approved);
      expect(decided.isApproved, isTrue);
      expect(decided.decidedById, 'user1');
      expect(decided.decidedAt, isNotNull);
    },
  );

  test('approving an already-approved approval is rejected', () async {
    final a = await svc.createApproval(workspaceId: 'ws1', title: 'Merge');
    await svc.decide(
      a.id,
      workspaceId: 'ws1',
      decision: ApprovalDecision.approve,
    );
    expect(
      () => svc.decide(
        a.id,
        workspaceId: 'ws1',
        decision: ApprovalDecision.reject,
      ),
      throwsA(isA<InvalidApprovalTransitionException>()),
    );
  });

  test('request_revision then resubmit returns to pending', () async {
    final a = await svc.createApproval(workspaceId: 'ws1', title: 'Plan');
    final revised = await svc.decide(
      a.id,
      workspaceId: 'ws1',
      decision: ApprovalDecision.requestRevision,
    );
    expect(revised.status, ApprovalStatus.revisionRequested);
    final resubmitted = await svc.decide(
      a.id,
      workspaceId: 'ws1',
      decision: ApprovalDecision.resubmit,
    );
    expect(resubmitted.status, ApprovalStatus.pending);
    expect(resubmitted.decidedAt, isNull);
  });

  test('resubmit is only valid from revision_requested', () async {
    final a = await svc.createApproval(workspaceId: 'ws1', title: 'Plan');
    expect(
      () => svc.decide(
        a.id,
        workspaceId: 'ws1',
        decision: ApprovalDecision.resubmit,
      ),
      throwsA(isA<InvalidApprovalTransitionException>()),
    );
  });

  test('deciding a missing approval throws not found', () async {
    expect(
      () => svc.decide(
        'ghost',
        workspaceId: 'ws1',
        decision: ApprovalDecision.approve,
      ),
      throwsA(isA<NotFoundException>()),
    );
  });

  test('comments attach to the approval and build a history', () async {
    final a = await svc.createApproval(workspaceId: 'ws1', title: 'Plan');
    await svc.comment(
      a.id,
      workspaceId: 'ws1',
      body: 'Needs more detail',
      authorId: 'user1',
    );
    final history = await repo.getComments('ws1', a.id);
    expect(history.length, 1);
    expect(history.single.body, 'Needs more detail');
  });
}
