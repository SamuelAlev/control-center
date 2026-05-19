import 'package:cc_domain/cc_domain.dart';
import 'package:cc_domain/features/guardrails/domain/entities/action_policy_rule.dart';
import 'package:cc_domain/features/guardrails/domain/repositories/action_policy_repository.dart';
import 'package:cc_domain/features/guardrails/domain/services/action_guard_service.dart';
import 'package:cc_domain/features/guardrails/domain/value_objects/action_decision.dart';
import 'package:cc_harness/tools.dart';
import 'package:cc_host/cc_host.dart';
import 'package:test/test.dart';

/// In-memory [ActionPolicyRepository] returning a fixed rule list.
class _FakePolicyRepo implements ActionPolicyRepository {
  _FakePolicyRepo(this._rules);
  final List<ActionPolicyRule> _rules;

  @override
  Future<List<ActionPolicyRule>> rules(String workspaceId) async =>
      _rules.where((r) => r.workspaceId == workspaceId).toList();

  @override
  Stream<List<ActionPolicyRule>> watchRules(String workspaceId) =>
      Stream.value(_rules);

  @override
  Future<List<ActionPolicyRule>> rulesForScope(
    String workspaceId,
    ActionScopeType scopeType,
    String scopeId,
  ) async => _rules
      .where((r) => r.scopeType == scopeType && r.scopeId == scopeId)
      .toList();

  @override
  Future<ActionPolicyRule?> ruleById(String workspaceId, String id) async =>
      _rules
          .where((r) => r.id == id)
          .cast<ActionPolicyRule?>()
          .firstWhere((r) => r != null, orElse: () => null);

  @override
  Future<void> upsertRule(ActionPolicyRule rule) async {}

  @override
  Future<void> deleteRule(String workspaceId, String id) async {}
}

/// A [ConfirmationPort] that answers every request with [answer] and records
/// how many prompts it surfaced.
class _RecordingPort implements ConfirmationPort {
  _RecordingPort({required this.answer});
  final bool answer;
  int prompts = 0;

  @override
  Future<bool> requestApproval(ConfirmationRequest request) async {
    prompts++;
    return answer;
  }
}

ActionPolicyRule _wsRule(ActionClass cls, ActionDecision decision) =>
    ActionPolicyRule(
      id: 'ws::${cls.wire}',
      workspaceId: 'ws-1',
      scopeType: ActionScopeType.workspace,
      scopeId: '',
      actionClass: cls,
      decision: decision,
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
    );

void main() {
  const wsArgs = {'workspace_id': 'ws-1'};

  RepoOpDispatcher dispatcher({
    required List<ActionPolicyRule> rules,
    ConfirmationPort? port,
    Set<ActionClass> deleteClasses = const {ActionClass.fileDelete},
  }) => RepoOpDispatcher(
    registry: RepoOpRegistry([
      RepoOp(
        name: 'thing.read',
        kind: RepoOpKind.read,
        handler: (ctx) async => {'ok': true},
      ),
      RepoOp(
        name: 'thing.plainMutate',
        kind: RepoOpKind.mutate,
        handler: (ctx) async => {'ok': true},
      ),
      RepoOp(
        name: 'thing.deleteFile',
        kind: RepoOpKind.mutate,
        actionClasses: deleteClasses,
        handler: (ctx) async => {'ok': true},
      ),
    ]),
    actionGuard: ActionGuardService(
      repository: _FakePolicyRepo(rules),
      confirmationPort: port,
    ),
  );

  Future<Map<String, dynamic>> call(RepoOpDispatcher d, String op) => d.call(
    id: 1,
    params: {'op': op, 'args': wsArgs},
    deviceId: 'dev',
    userId: 'user',
    sessionCapability: SessionCapability.fullClient,
  );

  bool isError(Map<String, dynamic> r) => r.containsKey('error');

  group('repo-op ActionGuard effect net (PRD 24)', () {
    test(
      'a workspace deny rule blocks an op that declares that class',
      () async {
        final d = dispatcher(
          rules: [_wsRule(ActionClass.fileDelete, ActionDecision.deny)],
        );
        final r = await call(d, 'thing.deleteFile');
        expect(isError(r), isTrue, reason: 'deny policy must refuse the op');
        expect((r['error'] as Map)['message'], contains('action policy'));
      },
    );

    test('an effect-free op (empty actionClasses) skips the gate', () async {
      final d = dispatcher(
        rules: [_wsRule(ActionClass.fileDelete, ActionDecision.deny)],
      );
      // Even with a deny rule present, an op that declares no classes runs.
      expect(isError(await call(d, 'thing.plainMutate')), isFalse);
      expect(isError(await call(d, 'thing.read')), isFalse);
    });

    test('an allow rule lets the declared-class op through', () async {
      final d = dispatcher(
        rules: [_wsRule(ActionClass.fileDelete, ActionDecision.allow)],
      );
      expect(isError(await call(d, 'thing.deleteFile')), isFalse);
    });

    test(
      'a prompt decision surfaces one confirmation; approve → runs',
      () async {
        final port = _RecordingPort(answer: true);
        final d = dispatcher(
          rules: [_wsRule(ActionClass.fileDelete, ActionDecision.prompt)],
          port: port,
        );
        expect(isError(await call(d, 'thing.deleteFile')), isFalse);
        expect(port.prompts, 1);
      },
    );

    test('a prompt decision with no approver fails closed (deny)', () async {
      final d = dispatcher(
        rules: [_wsRule(ActionClass.fileDelete, ActionDecision.prompt)],
      );
      final r = await call(d, 'thing.deleteFile');
      expect(isError(r), isTrue, reason: 'prompt + no approver = fail-closed');
    });

    test(
      'fileDelete defaults to prompt even with no rule → fail-closed w/o port',
      () async {
        final d = dispatcher(rules: const []);
        final r = await call(d, 'thing.deleteFile');
        expect(
          isError(r),
          isTrue,
          reason: 'fileDelete default is prompt; no approver denies',
        );
      },
    );
  });
}
