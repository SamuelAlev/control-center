import 'package:cc_domain/core/domain/events/domain_event_bus.dart';
import 'package:cc_domain/features/messaging/domain/repositories/messaging_repository.dart';
import 'package:cc_domain/features/orchestration/domain/entities/orchestration.dart';
import 'package:cc_domain/features/orchestration/domain/entities/orchestration_proposal.dart';
import 'package:cc_domain/features/orchestration/domain/entities/orchestration_status.dart';
import 'package:cc_domain/features/orchestration/domain/repositories/orchestration_repository.dart';
import 'package:cc_domain/features/orchestration/domain/services/register_orchestration_bodies.dart';
import 'package:cc_domain/features/pipelines/domain/services/pipeline_body_registry.dart';
import 'package:cc_domain/features/pipelines/domain/services/pipeline_context.dart';
import 'package:cc_domain/features/pipelines/domain/templates/builtin_template_seeds.dart';
import 'package:cc_domain/features/ticketing/domain/services/ticket_workflow_service.dart';
import 'package:test/test.dart';

const _ws = 'ws-1';
final _t0 = DateTime.utc(2026, 11, 20, 9);

/// The orchestrations, in memory, with the conditional write of the store.
class _Orchestrations implements OrchestrationRepository {
  final Map<String, Orchestration> rows = {};
  int writes = 0;

  @override
  Future<Orchestration?> getById(String workspaceId, String id) async {
    final o = rows[id];
    return o != null && o.workspaceId == workspaceId ? o : null;
  }

  @override
  Future<bool> update(Orchestration next, {required Orchestration read}) async {
    final stored = rows[next.id];
    if (stored == null ||
        stored.revision != read.revision ||
        stored.status != read.status) {
      return false;
    }
    rows[next.id] = next;
    writes++;
    return true;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnsupportedError('${invocation.memberName}');
}

/// Records every ticket move and message instead of making it.
class _Recorder implements TicketWorkflowService, MessagingRepository {
  final List<Symbol> calls = [];

  @override
  dynamic noSuchMethod(Invocation invocation) {
    calls.add(invocation.memberName);
    return invocation.memberName == #sendMessage
        ? Future<String>.value('message-id')
        : Future<void>.value();
  }
}

const _proposal = OrchestrationProposal(
  goal: 'ship it',
  roles: [ProposedRole(roleKey: 'lead', title: 'Lead', existingAgentId: 'a1')],
  subTickets: [
    ProposedSubTicket(key: 's1', title: 'Do', roleKey: 'lead', dependsOn: []),
  ],
  synthesis: SynthesisSpec(
    roleKey: 'lead',
    prompt: 'combine',
    outputSchema: {'type': 'object'},
  ),
);

void main() {
  late _Orchestrations orchestrations;
  late _Recorder recorder;
  late PipelineBodyRegistry registry;

  setUp(() {
    orchestrations = _Orchestrations();
    recorder = _Recorder();
    registry = PipelineBodyRegistry();
    registerOrchestrationBodies(
      registry,
      orchestrations: orchestrations,
      ticketWorkflow: recorder,
      messaging: recorder,
      eventBus: DomainEventBus(),
    );
    // Ada's orchestration, executing as run `run-ada` in space S.
    orchestrations.rows['o-ada'] = Orchestration(
      id: 'o-ada',
      workspaceId: _ws,
      proposal: _proposal,
      status: OrchestrationStatus.executing,
      parentTicketId: 'ticket-ada',
      spaceId: 'space-s',
      orchestratorAgentId: 'agent-orch',
      pipelineRunId: 'run-ada',
      createdAt: _t0,
      updatedAt: _t0,
    );
  });

  PipelineContext ctx(String runId, {Map<String, dynamic>? payload}) =>
      PipelineContext(
        pipelineRunId: runId,
        templateId: 'carol-template',
        stepId: 'step',
        stepRunId: 'step-run',
        workspaceId: _ws,
        state: const {'deliverable': 'not from the orchestration'},
        triggerPayload: payload ?? const {'orchestration_id': 'o-ada'},
      );

  group("a run that names another run's orchestration", () {
    for (final body in [
      BuiltInBodyKeys.orchestrationPersistDeliverable,
      BuiltInBodyKeys.orchestrationMarkPhase,
      BuiltInBodyKeys.orchestrationAwaitApproval,
    ]) {
      test('$body fails its step and changes nothing', () async {
        final before = orchestrations.rows['o-ada'];
        final result = await registry.body(body)(
          ctx(
            'run-carol',
            payload: {'orchestration_id': 'o-ada', 'node_key': 's1'},
          ),
        );
        expect(result.isFailed, isTrue);
        expect(orchestrations.rows['o-ada'], same(before));
        expect(orchestrations.writes, 0);
        expect(recorder.calls, isEmpty, reason: 'no ticket move, no message');
      });
    }
  });

  test("the orchestration's own run completes it", () async {
    final result = await registry.body(
      BuiltInBodyKeys.orchestrationPersistDeliverable,
    )(ctx('run-ada'));
    expect(result.isFailed, isFalse);
    expect(orchestrations.rows['o-ada']!.status, OrchestrationStatus.completed);
    expect(recorder.calls, [#completeTicket, #sendMessage, #sendMessage]);
  });
}
