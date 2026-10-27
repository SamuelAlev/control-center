import 'package:cc_domain/core/domain/ports/confirmation_port.dart';
import 'package:cc_domain/features/guardrails/domain/entities/action_policy_rule.dart';
import 'package:cc_domain/features/guardrails/domain/repositories/action_policy_repository.dart';
import 'package:cc_domain/features/guardrails/domain/services/action_guard_service.dart';
import 'package:cc_domain/features/guardrails/domain/value_objects/action_decision.dart';
import 'package:cc_domain/features/guardrails/domain/value_objects/action_request.dart';
import 'package:cc_harness/tools.dart';
import 'package:test/test.dart';

class _Rules implements ActionPolicyRepository {
  @override
  Future<List<ActionPolicyRule>> rules(String workspaceId) async => [];

  @override
  Stream<List<ActionPolicyRule>> watchRules(String workspaceId) =>
      Stream.value([]);

  @override
  Future<List<ActionPolicyRule>> rulesForScope(
    String workspaceId,
    ActionScopeType scopeType,
    String scopeId,
  ) async => [];

  @override
  Future<ActionPolicyRule?> ruleById(String workspaceId, String id) async =>
      null;

  @override
  Future<void> upsertRule(ActionPolicyRule rule) async {}

  @override
  Future<void> deleteRule(String workspaceId, String id) async {}
}

class _Approver implements ConfirmationPort {
  final requests = <ConfirmationRequest>[];

  @override
  Future<bool> requestApproval(ConfirmationRequest request) async {
    requests.add(request);
    return true;
  }
}

void main() {
  test(
    'an explicit shell push names the actual branch, not the tool or script',
    () async {
      final approver = _Approver();
      final guard = ActionGuardService(
        repository: _Rules(),
        confirmationPort: approver,
      );
      const script = 'git push origin feature/review\necho done';
      final verdict = await guard.check(
        workspaceId: 'ws',
        classes: {ActionClass.gitPush, ActionClass.processSpawn},
        command: script,
        actionSummary: 'bash: $script',
        approvalRationale: 'Update the release notes in this branch',
      );
      expect(verdict.allowed, isTrue);
      final prompt = approver.requests.single;
      expect(prompt.title, contains('feature/review'));
      expect(prompt.title, isNot(contains('bash:')));
      expect(prompt.title, isNot(contains('gitPush')));
      expect(prompt.detail, contains('run a process'));
      expect(prompt.detail, isNot(contains('Policy:')));
      expect(
        prompt.detail,
        contains('Update the release notes in this branch'),
      );
      expect(prompt.command, script);
      expect(prompt.actionClasses, contains('gitPush'));
      // The request named no refs, so there is no branch to remember, and a
      // standing approval of this exact script would never match again.
      expect(prompt.rememberChoice, isNull);
      expect(prompt.constraintJson, isNull);
    },
  );

  test(
    'compound deletion and push disclose both effects and literal targets',
    () async {
      final approver = _Approver();
      final guard = ActionGuardService(
        repository: _Rules(),
        confirmationPort: approver,
      );
      const script = 'rm -rf docs/archive && git push origin release/1';
      await guard.check(
        workspaceId: 'ws',
        classes: {
          ActionClass.fileDelete,
          ActionClass.gitPush,
          ActionClass.processSpawn,
        },
        request: const ActionRequest(command: script),
      );
      final prompt = approver.requests.single;
      expect(prompt.detail, contains('delete docs/archive'));
      expect(prompt.detail, contains('push to release/1'));
      expect(prompt.command, script);
      expect(prompt.severity, ConfirmationSeverity.destructive);
    },
  );

  test(
    'unknown branch remains unknown and different commands retain identity',
    () async {
      final approver = _Approver();
      final guard = ActionGuardService(
        repository: _Rules(),
        confirmationPort: approver,
      );
      for (final command in ['git push', 'git push origin HEAD']) {
        await guard.check(
          workspaceId: 'ws',
          classes: {ActionClass.gitPush},
          command: command,
        );
      }
      expect(approver.requests, hasLength(2));
      expect(approver.requests.first.title, contains('branch not specified'));
      expect(approver.requests.last.title, contains('branch not specified'));
      expect(
        approver.requests.first.fingerprint,
        isNot(approver.requests.last.fingerprint),
      );
    },
  );

  test(
    'structured push refs appear without inventing a shell command',
    () async {
      final approver = _Approver();
      final guard = ActionGuardService(
        repository: _Rules(),
        confirmationPort: approver,
      );
      await guard.check(
        workspaceId: 'ws',
        classes: {ActionClass.gitPush},
        request: const ActionRequest(refs: ['refs/heads/feature/review']),
      );
      final prompt = approver.requests.single;
      expect(prompt.title, contains('feature/review'));
      expect(prompt.command, isNull);
      expect(prompt.constraintJson, isNotNull);
    },
  );

  test('structured and shell targets name the same branch only once', () async {
    final approver = _Approver();
    final guard = ActionGuardService(
      repository: _Rules(),
      confirmationPort: approver,
    );
    await guard.check(
      workspaceId: 'ws',
      classes: {ActionClass.gitPush},
      request: const ActionRequest(refs: ['refs/heads/feature/review']),
      command: 'git push origin feature/review',
    );
    final prompt = approver.requests.single;
    final target = RegExp(RegExp.escape('feature/review'));
    expect(target.allMatches(prompt.title), hasLength(1));
    expect(target.allMatches(prompt.detail), hasLength(1));
  });

  test(
    'several branches are counted in the title and named in the detail',
    () async {
      final approver = _Approver();
      final guard = ActionGuardService(
        repository: _Rules(),
        confirmationPort: approver,
      );
      await guard.check(
        workspaceId: 'ws',
        classes: {ActionClass.gitPush},
        request: const ActionRequest(
          refs: ['space/a--data', 'space/a--ui', 'space/a--page'],
        ),
      );
      final prompt = approver.requests.single;
      expect(
        prompt.title,
        'Agent would like to push to 3 branches. Do you accept?',
      );
      for (final branch in ['space/a--data', 'space/a--ui', 'space/a--page']) {
        expect(prompt.detail, contains(branch));
      }
    },
  );

  test('force push and remote branch deletion are both disclosed', () async {
    final approver = _Approver();
    final guard = ActionGuardService(
      repository: _Rules(),
      confirmationPort: approver,
    );
    const script =
        'git push --force origin feature/review && git push origin :legacy';
    await guard.check(
      workspaceId: 'ws',
      classes: {ActionClass.gitPush},
      command: script,
    );
    final prompt = approver.requests.single;
    expect(prompt.detail, contains('force-push to feature/review'));
    expect(prompt.detail, contains('delete remote branch legacy'));
    expect(prompt.command, script);
  });
}
