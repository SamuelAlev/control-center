import 'dart:async';

import 'package:cc_domain/core/domain/entities/agent.dart';
import 'package:cc_domain/core/domain/events/agent_events.dart';
import 'package:cc_domain/core/domain/events/domain_event_bus.dart';
import 'package:cc_domain/core/domain/ports/agent_question_port.dart';
import 'package:cc_domain/core/domain/ports/confirmation_port.dart';
import 'package:cc_domain/core/domain/ports/run_credential_gate_port.dart';
import 'package:cc_domain/core/domain/repositories/agent_repository.dart';
import 'package:cc_domain/core/domain/value_objects/agent_skills.dart';
import 'package:cc_host/cc_host.dart';
import 'package:cc_server_core/src/agent_awaiting_input_publisher.dart';
import 'package:test/test.dart';

/// Names `agent-1` "Ada"; every other id is unknown.
class _Agents implements AgentRepository {
  @override
  Future<Agent?> getById(String workspaceId, String id) async => id == 'agent-1'
      ? Agent(
          id: 'agent-1',
          name: 'Ada',
          title: 'Engineer',
          agentMdPath: '/tmp/ada.md',
          workspaceId: workspaceId,
          skills: AgentSkills(const []),
          createdAt: DateTime(2026),
        )
      : null;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Future<void> _pump() => Future<void>.delayed(const Duration(milliseconds: 20));

void main() {
  late DomainEventBus bus;
  late List<AgentAwaitingInput> published;
  late StreamSubscription<AgentAwaitingInput> sub;
  late AgentAwaitingInputPublisher publisher;
  late PendingConfirmationRegistry approvals;
  late PendingCredentialBlockRegistry credentials;

  setUp(() {
    bus = DomainEventBus();
    published = [];
    sub = bus.on<AgentAwaitingInput>().listen(published.add);
    publisher = AgentAwaitingInputPublisher(eventBus: bus, agents: _Agents());
    approvals = PendingConfirmationRegistry();
    credentials = PendingCredentialBlockRegistry(deadline: null);
    publisher.watch(confirmations: approvals, credentialBlocks: credentials);
  });

  tearDown(() async {
    await publisher.dispose();
    await sub.cancel();
    approvals.dispose();
    credentials.dispose();
    bus.dispose();
  });

  test('a pending approval notifies once, naming the agent', () async {
    final first = approvals.register(
      const ConfirmationRequest(
        spaceId: 'space-1',
        workspaceId: 'ws-1',
        title: 'Push to main',
        detail: 'git push origin main',
        agentId: 'agent-1',
      ),
    );
    await _pump();
    // A second request changes the snapshot; the first must not re-notify.
    approvals.register(
      const ConfirmationRequest(
        spaceId: '',
        workspaceId: 'ws-1',
        title: 'Install package',
        detail: 'npm install',
      ),
    );
    await _pump();

    expect(published, hasLength(2));
    final event = published.first;
    expect(event.kind, AgentInputKind.approval);
    expect(event.summary, 'Push to main');
    expect(event.workspaceId, 'ws-1');
    expect(event.spaceId, 'space-1');
    expect(event.agentName, 'Ada');
    // No space id is no space, not an empty one to deep-link into.
    expect(published.last.spaceId, isNull);
    expect(published.last.agentName, isNull);

    approvals.respond(first.id, approved: true);
    await _pump();
    expect(published, hasLength(2));
  });

  test('an approval with no workspace is left to the approval card', () async {
    approvals.register(
      const ConfirmationRequest(spaceId: 's', title: 't', detail: 'd'),
    );
    await _pump();
    expect(published, isEmpty);
  });

  test('a run parked on a credential notifies with why', () async {
    credentials.register(
      const RunCredentialBlockRequest(
        lane: RunCredentialLane.claudeCode,
        reason: RunCredentialReason.signedOut,
        detail: 'Claude Code is signed out.',
        workspaceId: 'ws-1',
        spaceId: 'space-1',
        conversationId: 'conv-1',
        agentId: 'agent-2',
        agentName: 'Grace',
      ),
      recheck: () async => false,
    );
    await _pump();

    final event = published.single;
    expect(event.kind, AgentInputKind.credential);
    expect(event.summary, 'Claude Code is signed out.');
    expect(event.conversationId, 'conv-1');
    expect(event.agentName, 'Grace');
  });

  test('a question notifies with the question', () async {
    publisher.questionAsked(
      const AgentQuestionRequest(
        workspaceId: 'ws-1',
        spaceId: 'space-1',
        question: 'Which database?',
        askedByAgentId: 'agent-1',
      ),
    );
    await _pump();

    final event = published.single;
    expect(event.kind, AgentInputKind.question);
    expect(event.summary, 'Which database?');
    expect(event.agentName, 'Ada');
  });
}
