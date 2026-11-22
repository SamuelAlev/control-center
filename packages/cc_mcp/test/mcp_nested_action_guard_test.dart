// ignore_for_file: avoid_dynamic_calls

import 'package:cc_domain/cc_domain.dart';
import 'package:cc_domain/core/domain/value_objects/script_call_origin.dart';
import 'package:cc_domain/features/code_mode/domain/ports/code_execution_port.dart'
    show NestedCallOutcome;
import 'package:cc_domain/features/code_mode/domain/value_objects/code_execution_status.dart';
import 'package:cc_domain/features/code_mode/domain/value_objects/code_mode_limits.dart';
import 'package:cc_domain/features/code_mode/domain/value_objects/script_approval_budget.dart';
import 'package:cc_domain/features/guardrails/domain/entities/action_policy_rule.dart';
import 'package:cc_domain/features/guardrails/domain/repositories/action_policy_repository.dart';
import 'package:cc_domain/features/guardrails/domain/services/action_guard_service.dart';
import 'package:cc_domain/features/guardrails/domain/value_objects/action_decision.dart';
import 'package:cc_domain/features/mcp/domain/services/mcp_tool_registry.dart';
import 'package:cc_domain/features/ticketing/domain/entities/ticket_provider.dart';
import 'package:cc_domain/features/ticketing/domain/services/ticket_workflow_service.dart';
import 'package:cc_harness/tools.dart' show ActionClass;
import 'package:cc_mcp/src/mcp_tool_dispatcher.dart';
import 'package:cc_mcp/src/tools/ticket_crud_tools.dart';
import 'package:test/test.dart';

import 'code_mode_fakes.dart';

/// A script's call that a stored rule asks a person about: the card names
/// the script, and the script's clock stops only while the person is asked.
void main() {
  late ProbeTool writer;
  late _Rules rules;
  late List<GuardAudit> audits;
  late Approver approver;
  late McpToolDispatcher dispatcher;

  McpToolDispatcher build(Approver port) => McpToolDispatcher(
    registry: McpToolRegistry([writer]),
    confirmationPort: port,
    actionGuard: ActionGuardService(
      repository: rules,
      confirmationPort: port,
      onAudit: audits.add,
    ),
  );

  final origin = ScriptCallOrigin(
    parentToolCallId: 'toolu_repl',
    executionId: 'log-1/toolu_repl#2',
  );

  setUp(() {
    writer = ProbeTool(
      'write_thing',
      actionClasses: {ActionClass.workspaceMutation},
    );
    rules = _Rules();
    audits = [];
    approver = Approver(delay: const Duration(milliseconds: 80));
    dispatcher = build(approver);
  });

  test('a prompted call carries the script on its card, reports the '
      'measured wait, and runs once approved', () async {
    rules.list.add(_rule(ActionDecision.prompt));
    final waits = <bool>[];

    final outcome = await dispatcher.callNested(
      runScope(),
      nestedRequest('write_thing', onPersonWait: waits.add, origin: origin),
      approvals: ScriptApprovalBudget(),
    );

    expect(outcome.status, NestedCallStatus.completed);
    expect(outcome.gateDecision, NestedCallGateDecision.approved);
    expect(waits, [true, false]);
    expect(outcome.approvalWaitMs, greaterThanOrEqualTo(70));
    final card = approver.requests.single;
    expect(card.origin, origin);
    expect(card.actionClasses, [ActionClass.workspaceMutation.wire]);
    expect(writer.runs, 1);
    expect(audits.single.prompted, isTrue);
  });

  test('the clock stops while the person is asked: an ask longer than the '
      'call\'s deadline still completes', () async {
    rules.list.add(_rule(ActionDecision.prompt));
    dispatcher = build(Approver(delay: const Duration(milliseconds: 300)));

    final outcome = await dispatcher.callNested(
      runScope(),
      nestedRequest(
        'write_thing',
        deadline: const Duration(milliseconds: 150),
        origin: origin,
      ),
      approvals: ScriptApprovalBudget(),
    );

    expect(outcome.status, NestedCallStatus.completed);
    expect(writer.runs, 1);
  });

  test('reading policy is not a wait: a slow read with no ask runs the '
      'clock and signals nothing', () async {
    rules
      ..list.add(_rule(ActionDecision.allow))
      ..delay = const Duration(milliseconds: 200);
    final waits = <bool>[];

    final outcome = await dispatcher.callNested(
      runScope(),
      nestedRequest(
        'write_thing',
        deadline: const Duration(milliseconds: 80),
        onPersonWait: waits.add,
        origin: origin,
      ),
      approvals: ScriptApprovalBudget(),
    );

    expect(outcome.status, NestedCallStatus.timedOut);
    expect(waits, isEmpty);
    expect(approver.requests, isEmpty);
    // The deadline passed while the gate read policy: the tool never runs.
    await Future<void>.delayed(const Duration(milliseconds: 250));
    expect(writer.runs, 0);
  });

  for (final decision in [ActionDecision.allow, ActionDecision.deny]) {
    test(
      '${decision.wire}: nobody is asked and no wait is signalled',
      () async {
        rules.list.add(_rule(decision));
        final waits = <bool>[];

        final outcome = await dispatcher.callNested(
          runScope(),
          nestedRequest('write_thing', onPersonWait: waits.add, origin: origin),
          approvals: ScriptApprovalBudget(),
        );

        expect(
          outcome.status,
          decision == ActionDecision.allow
              ? NestedCallStatus.completed
              : NestedCallStatus.denied,
        );
        expect(waits, isEmpty);
        expect(outcome.approvalWaitMs, 0);
        expect(approver.requests, isEmpty);
        expect(audits.single.decision, decision);
      },
    );
  }

  test('a declined ask is denied, and its wait still ends', () async {
    rules.list.add(_rule(ActionDecision.prompt));
    approver.answer = false;
    final waits = <bool>[];

    final outcome = await dispatcher.callNested(
      runScope(),
      nestedRequest('write_thing', onPersonWait: waits.add, origin: origin),
      approvals: ScriptApprovalBudget(),
    );

    expect(outcome.status, NestedCallStatus.denied);
    expect(outcome.errorMessage, startsWith('Denied by action policy'));
    expect(waits, [true, false]);
    expect(approver.requests.single.origin, origin);
    expect(writer.runs, 0);
  });

  test('after a declined ask, a call the rules would ask about is refused '
      'without a card, audited as a denial nobody was asked about', () async {
    rules.list.add(_rule(ActionDecision.prompt));
    approver.answer = false;
    final approvals = ScriptApprovalBudget();
    final waits = <bool>[];

    await dispatcher.callNested(
      runScope(),
      nestedRequest('write_thing', origin: origin),
      approvals: approvals,
    );
    approver.answer = true;
    final second = await dispatcher.callNested(
      runScope(),
      nestedRequest(
        'write_thing',
        sequence: 2,
        origin: origin,
        onPersonWait: waits.add,
      ),
      approvals: approvals,
    );

    expect(second.status, NestedCallStatus.denied);
    expect(second.errorMessage, contains('already declined'));
    expect(approver.requests, hasLength(1));
    expect(waits, isEmpty);
    expect(writer.runs, 0);
    expect(audits.last.decision, ActionDecision.deny);
    expect(audits.last.prompted, isFalse);
    // The trail says why nobody was asked, not that the rule asked.
    expect(audits.last.reason, contains('already declined'));
  });

  test('a card nobody answered refuses only its call: the script\'s next '
      'call asks again, and a person\'s decline still refuses the rest '
      'without a card', () async {
    rules.list.add(_rule(ActionDecision.prompt));
    final port = Approver()..queued.addAll([null, false]);
    dispatcher = build(port);
    final approvals = ScriptApprovalBudget();
    Future<NestedCallOutcome> write(int n) => dispatcher.callNested(
      runScope(),
      nestedRequest('write_thing', sequence: n, origin: origin),
      approvals: approvals,
    );

    final expired = await write(1);
    expect(expired.status, NestedCallStatus.denied);
    expect(expired.errorMessage, contains('Nobody answered'));
    expect(approvals.declined, isFalse);
    // The audit row tells it apart from a decline.
    expect(audits.last.prompted, isTrue);
    expect(audits.last.unanswered, isTrue);

    final declined = await write(2);
    expect(declined.status, NestedCallStatus.denied);
    expect(declined.errorMessage, contains('Denied at confirmation'));
    expect(audits.last.prompted, isTrue);
    expect(audits.last.unanswered, isFalse);
    expect(port.requests, hasLength(2));

    final refused = await write(3);
    expect(refused.errorMessage, contains('already declined'));
    expect(port.requests, hasLength(2));
    expect(writer.runs, 0);
  });

  test('a script\'s asks stop at ${CodeModeLimits.maxApprovalAsks}', () async {
    rules.list.add(_rule(ActionDecision.prompt));
    dispatcher = build(Approver());
    final approvals = ScriptApprovalBudget();

    final outcomes = [
      for (var i = 1; i <= CodeModeLimits.maxApprovalAsks + 1; i++)
        await dispatcher.callNested(
          runScope(),
          nestedRequest('write_thing', sequence: i, origin: origin),
          approvals: approvals,
        ),
    ];

    expect(writer.runs, CodeModeLimits.maxApprovalAsks);
    expect(outcomes.last.status, NestedCallStatus.denied);
    expect(outcomes.last.errorMessage, contains('maxApprovalAsks'));
    expect(audits.last.prompted, isFalse);
    expect(audits.last.decision, ActionDecision.deny);
    expect(audits.last.reason, contains('maxApprovalAsks'));
  });

  test('asks of one script that arrive together put up at most '
      '${CodeModeLimits.maxApprovalAsks} cards', () async {
    rules.list.add(_rule(ActionDecision.prompt));
    final slow = Approver(delay: const Duration(milliseconds: 100));
    dispatcher = build(slow);
    final approvals = ScriptApprovalBudget();

    final outcomes = await Future.wait([
      for (var i = 1; i <= 30; i++)
        dispatcher.callNested(
          runScope(),
          nestedRequest('write_thing', sequence: i, origin: origin),
          approvals: approvals,
        ),
    ]);

    expect(slow.requests, hasLength(CodeModeLimits.maxApprovalAsks));
    expect(approvals.asked, CodeModeLimits.maxApprovalAsks);
    final refused = [
      for (final o in outcomes)
        if (o.status == NestedCallStatus.denied) o,
    ];
    expect(refused, hasLength(30 - CodeModeLimits.maxApprovalAsks));
    expect(
      refused.map((o) => o.errorMessage),
      everyElement(contains('maxApprovalAsks')),
    );
    expect(
      audits.where((a) => a.reason.contains('maxApprovalAsks')),
      hasLength(30 - CodeModeLimits.maxApprovalAsks),
    );
  });

  test('a card the resolution did not foresee is refused once the script '
      'may not ask any more, without a card', () async {
    final approver = Approver();
    dispatcher = build(approver);
    final approvals = ScriptApprovalBudget();
    for (var i = 0; i < CodeModeLimits.maxApprovalAsks; i++) {
      approvals.asking();
    }
    // Nothing asks when the call is resolved; a prompt rule is there when it
    // is checked, as when a rule is added in between.
    rules.queued.addAll([
      const [],
      [_rule(ActionDecision.prompt)],
    ]);

    final outcome = await dispatcher.callNested(
      runScope(),
      nestedRequest('write_thing', sequence: 1, origin: origin),
      approvals: approvals,
    );

    expect(outcome.status, NestedCallStatus.denied);
    expect(outcome.errorMessage, contains('maxApprovalAsks'));
    expect(approver.requests, isEmpty);
    expect(approvals.asked, CodeModeLimits.maxApprovalAsks);
  });

  group('an argument a script may not use', () {
    const refusal = 'assign with a direct call';

    setUp(() {
      writer = ProbeTool(
        'write_thing',
        actionClasses: {ActionClass.workspaceMutation},
        argumentRefusal: (arguments) =>
            arguments.containsKey('assignee') ? refusal : null,
      );
      dispatcher = build(approver);
      rules.list.add(_rule(ActionDecision.prompt));
    });

    test('refuses the script\'s call before any card', () async {
      final approvals = ScriptApprovalBudget();
      final refused = await dispatcher.callNested(
        runScope(),
        nestedRequest(
          'write_thing',
          arguments: const {'assignee': 'agent-2'},
          origin: origin,
        ),
        approvals: approvals,
      );

      expect(refused.status, NestedCallStatus.denied);
      expect(refused.gateDecision, NestedCallGateDecision.denied);
      expect(refused.errorMessage, refusal);
      expect(approver.requests, isEmpty);
      expect(writer.runs, 0);
      // No card, so nothing counted: the budget is whole.
      expect(approvals.refusal, isNull);

      // The same tool without the argument is asked about and runs.
      final plain = await dispatcher.callNested(
        runScope(),
        nestedRequest('write_thing', sequence: 2, origin: origin),
        approvals: approvals,
      );
      expect(plain.status, NestedCallStatus.completed);
      expect(approver.requests, hasLength(1));
      expect(writer.runs, 1);
    });

    test('a direct call with it is asked about and runs', () async {
      final response = await dispatcher.handleScopedRequest(
        JsonRpcRequest(
          method: 'tools/call',
          params: {
            'name': 'write_thing',
            'arguments': {'workspace_id': 'ws-own', 'assignee': 'agent-2'},
          },
          id: 1,
        ),
        scope: runScope(),
      );

      expect(response['result']['isError'], isNot(true));
      expect(approver.requests, hasLength(1));
      expect(writer.runs, 1);
    });

    test('create_ticket refuses a script its assignee, and nothing else', () {
      final tool = CreateTicketTool(
        service: _NoTickets(),
        provider: TicketProvider.linear,
      );
      expect(tool.scriptCallable, isTrue);
      expect(
        tool.scriptArgumentRefusal(const {'title': 't', 'assignee': 'a'}),
        allOf(contains('refuses assignee'), contains('directly')),
      );
      expect(tool.scriptArgumentRefusal(const {'title': 't'}), isNull);
      expect(
        tool.scriptArgumentRefusal(const {'title': 't', 'team_id': 'eng'}),
        isNull,
      );
    });
  });

  test('a call the rules allow is not bounded by the budget', () async {
    rules.list.add(_rule(ActionDecision.allow));
    final approvals = ScriptApprovalBudget()
      ..answered(approved: false, unanswered: false);

    final outcome = await dispatcher.callNested(
      runScope(),
      nestedRequest('write_thing', origin: origin),
      approvals: approvals,
    );

    expect(outcome.status, NestedCallStatus.completed);
  });

  test('the model\'s own call asks the same way, with no origin', () async {
    rules.list.add(_rule(ActionDecision.prompt));

    final response = await dispatcher.handleScopedRequest(
      JsonRpcRequest(
        method: 'tools/call',
        params: {
          'name': 'write_thing',
          'arguments': {'workspace_id': 'ws-own'},
        },
        id: 1,
      ),
      scope: runScope(),
    );

    expect(response['result']['isError'], isNot(true));
    expect(approver.requests.single.origin, isNull);
    expect(writer.runs, 1);
  });
}

ActionPolicyRule _rule(ActionDecision decision) => ActionPolicyRule(
  id: 'r-${decision.wire}',
  workspaceId: 'ws-own',
  scopeType: ActionScopeType.workspace,
  scopeId: '',
  actionClass: ActionClass.workspaceMutation,
  decision: decision,
  createdAt: DateTime.now(),
  updatedAt: DateTime.now(),
);

class _NoTickets implements TicketWorkflowService {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw StateError('no tickets in this test');
}

/// The workspace's rules, read after [delay].
class _Rules implements ActionPolicyRepository {
  final list = <ActionPolicyRule>[];
  Duration? delay;

  /// Read once each before [list]: a policy that changes between reads.
  final queued = <List<ActionPolicyRule>>[];

  @override
  Future<List<ActionPolicyRule>> rules(String workspaceId) async {
    final d = delay;
    if (d != null) {
      await Future<void>.delayed(d);
    }
    return queued.isEmpty ? list : queued.removeAt(0);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
