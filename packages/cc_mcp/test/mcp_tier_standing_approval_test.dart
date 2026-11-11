// ignore_for_file: avoid_dynamic_calls

import 'package:cc_domain/cc_domain.dart';
import 'package:cc_domain/features/guardrails/domain/entities/action_policy_rule.dart';
import 'package:cc_domain/features/guardrails/domain/repositories/action_policy_repository.dart';
import 'package:cc_domain/features/guardrails/domain/services/action_guard_service.dart';
import 'package:cc_domain/features/guardrails/domain/value_objects/action_constraint.dart';
import 'package:cc_domain/features/guardrails/domain/value_objects/action_decision.dart';
import 'package:cc_domain/features/mcp/domain/ports/mcp_tool_port.dart';
import 'package:cc_domain/features/mcp/domain/services/mcp_tool_registry.dart';
import 'package:cc_domain/features/mcp/domain/value_objects/mcp_call_scope.dart';
import 'package:cc_harness/tools.dart' show ActionClass;
import 'package:cc_mcp/src/mcp_tool_dispatcher.dart';
import 'package:test/test.dart';

/// An MCP tool's own declared approval offers "Approve for 8 hours", and only
/// a live standing approval of that tool spares it: a plain allow rule keeps
/// it asking, a deny keeps denying.
void main() {
  late _Rules rules;
  late _Approver approver;
  late McpToolDispatcher dispatcher;
  late _GatedTool rename;
  late _GatedTool archive;
  late _GatedTool plain;

  setUp(() {
    rules = _Rules();
    approver = _Approver();
    rename = _GatedTool('rename_space', {ActionClass.workspaceMutation});
    archive = _GatedTool('archive_space', {ActionClass.workspaceMutation});
    plain = _GatedTool('classless_tool', const {});
    dispatcher = McpToolDispatcher(
      registry: McpToolRegistry([rename, archive, plain]),
      confirmationPort: approver,
      actionGuard: ActionGuardService(
        repository: rules,
        confirmationPort: approver,
      ),
    );
  });

  Future<bool> call(String tool) async {
    final result = await dispatcher.handleScopedRequest(
      JsonRpcRequest(
        method: 'tools/call',
        params: {'name': tool, 'arguments': <String, dynamic>{}},
        id: 1,
      ),
      scope: const McpCallScope(
        workspaceId: 'ws-own',
        agentId: 'agent-1',
        conversationId: 'conv-1',
        spaceId: 'sp-1',
      ),
    );
    return result['result']['isError'] == false;
  }

  ActionPolicyRule userRule(ActionDecision decision) => ActionPolicyRule(
    id: 'user-${decision.wire}',
    workspaceId: 'ws-own',
    scopeType: ActionScopeType.workspace,
    scopeId: '',
    actionClass: ActionClass.workspaceMutation,
    decision: decision,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );

  test('the card names the tool, in the space the guard resolved', () async {
    expect(await call('rename_space'), isTrue);
    final card = approver.requests.single;
    expect(card.title, 'Rename it?');
    expect(card.rememberChoice, isNotNull);
    expect(card.spaceId, 'sp-1');
    expect(card.workspaceId, 'ws-own');
    expect(card.agentId, 'agent-1');
    expect(card.actionClasses, ['workspaceMutation']);
    expect(
      ActionConstraint.decode(card.constraintJson),
      const ActionConstraint(tools: ['rename_space']),
    );
  });

  test('approving for 8 hours spares that tool, not another with the same '
      'effects', () async {
    await call('rename_space');
    rules.remember(approver.requests.single);

    expect(await call('rename_space'), isTrue);
    expect(rename.runs, 2);
    expect(approver.requests, hasLength(1));

    expect(await call('archive_space'), isTrue);
    expect(approver.requests, hasLength(2));
  });

  test('a plain allow rule keeps the tool asking', () async {
    rules.list.add(userRule(ActionDecision.allow));
    await call('rename_space');
    await call('rename_space');
    expect(approver.requests, hasLength(2));
  });

  test('a deny still denies', () async {
    await call('rename_space');
    rules.remember(approver.requests.single);
    rules.list.add(userRule(ActionDecision.deny));
    expect(await call('rename_space'), isFalse);
    expect(approver.requests, hasLength(1));
  });

  test('an expired approval asks again', () async {
    await call('rename_space');
    rules.remember(
      approver.requests.single,
      expiresAt: DateTime.now().subtract(const Duration(seconds: 1)),
    );
    await call('rename_space');
    expect(approver.requests, hasLength(2));
  });

  group('a tool that declares no effect class', () {
    ActionPolicyRule spawnRule(ActionDecision decision) => ActionPolicyRule(
      id: 'spawn-${decision.wire}',
      workspaceId: 'ws-own',
      scopeType: ActionScopeType.workspace,
      scopeId: '',
      actionClass: ActionClass.processSpawn,
      decision: decision,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    test('files its approval under the undeclared-effect class, by name', () {
      expect(ActionGuardService.undeclaredEffect, {ActionClass.processSpawn});
    });

    test('approving for 8 hours spares that tool only', () async {
      expect(await call('classless_tool'), isTrue);
      final card = approver.requests.single;
      expect(card.actionClasses, ['processSpawn']);
      expect(
        ActionConstraint.decode(card.constraintJson),
        const ActionConstraint(tools: ['classless_tool']),
      );
      rules.remember(card);

      expect(await call('classless_tool'), isTrue);
      expect(plain.runs, 2);
      expect(approver.requests, hasLength(1));
    });

    test('a plain allow of that class keeps it asking', () async {
      rules.list.add(spawnRule(ActionDecision.allow));
      await call('classless_tool');
      await call('classless_tool');
      expect(approver.requests, hasLength(2));
    });

    test('a deny of that class neither refuses the call nor lets an approval '
        'stand', () async {
      await call('classless_tool');
      rules.remember(approver.requests.single);
      rules.list.add(spawnRule(ActionDecision.deny));

      // The tool never declared the class, so the deny is not about it; the
      // approval filed there stops standing and the tool asks again, with
      // nothing to remember.
      expect(await call('classless_tool'), isTrue);
      expect(approver.requests, hasLength(2));
      expect(approver.requests.last.rememberChoice, isNull);
    });
  });
}

class _GatedTool extends McpTool {
  _GatedTool(this.name, this.actionClasses);

  @override
  final String name;

  @override
  final Set<ActionClass> actionClasses;

  int runs = 0;

  @override
  String get description => 'A tool that asks first';

  @override
  Map<String, dynamic> get inputSchema => {'type': 'object', 'properties': {}};

  @override
  bool get requiresApproval => true;

  @override
  ApprovalPayload? buildConfirmationRequest(Map<String, dynamic> arguments) =>
      const ApprovalPayload(title: 'Rename it?', detail: 'It gets a new name.');

  @override
  Future<CallResult> run(Map<String, dynamic> arguments) async {
    runs++;
    return CallResult.success('ok');
  }
}

/// Writes what `confirmation.respond` writes for a space-scoped remember.
class _Rules implements ActionPolicyRepository {
  final list = <ActionPolicyRule>[];

  void remember(ConfirmationRequest request, {DateTime? expiresAt}) {
    final now = DateTime.now();
    for (final wire in request.actionClasses) {
      list.add(
        ActionPolicyRule(
          id: 'remembered-$wire-${list.length}',
          workspaceId: request.workspaceId!,
          scopeType: ActionScopeType.space,
          scopeId: request.spaceId,
          actionClass: ActionClass.fromWire(wire),
          decision: ActionDecision.allow,
          provenance: 'remembered',
          constraint: ActionConstraint.decode(request.constraintJson),
          expiresAt: expiresAt ?? now.add(const Duration(hours: 8)),
          createdAt: now,
          updatedAt: now,
        ),
      );
    }
  }

  @override
  Future<List<ActionPolicyRule>> rules(String workspaceId) async => list;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Approver implements ConfirmationPort {
  final requests = <ConfirmationRequest>[];

  @override
  Future<bool> requestApproval(ConfirmationRequest request) async {
    requests.add(request);
    return true;
  }
}
