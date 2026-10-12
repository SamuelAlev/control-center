import 'dart:async';

import 'package:cc_domain/core/domain/entities/agent.dart';
import 'package:cc_domain/core/domain/events/agent_events.dart';
import 'package:cc_domain/core/domain/events/domain_event_bus.dart';
import 'package:cc_domain/core/domain/repositories/agent_repository.dart';
import 'package:cc_domain/core/domain/value_objects/agent_skills.dart';
import 'package:cc_domain/features/guardrails/domain/services/action_guard_service.dart';
import 'package:cc_domain/features/guardrails/domain/value_objects/action_decision.dart';
import 'package:cc_server_core/src/agent_action_blocked_publisher.dart';
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

/// The verdict the guard emits for every gated action. Only the fields that
/// decide whether a human was told matter here.
GuardAudit _audit({
  required ActionDecision decision,
  bool prompted = false,
  String? spaceId = 'space-1',
  String? agentId = 'agent-1',
  String summary = 'git push origin main',
  String reason = 'Pushing to main is denied by workspace policy',
  String source = 'workspace',
}) => GuardAudit(
  workspaceId: 'ws-1',
  decision: decision,
  reason: reason,
  source: source,
  agentId: agentId,
  spaceId: spaceId,
  actionSummary: summary,
  prompted: prompted,
);

void main() {
  late DomainEventBus bus;
  late List<AgentActionBlocked> published;
  late StreamSubscription<AgentActionBlocked> sub;
  late AgentActionBlockedPublisher publisher;

  setUp(() {
    bus = DomainEventBus();
    published = [];
    sub = bus.on<AgentActionBlocked>().listen(published.add);
    publisher = AgentActionBlockedPublisher(eventBus: bus, agents: _Agents());
  });

  tearDown(() async {
    await sub.cancel();
    bus.dispose();
  });

  test('an answered approval announces nothing', () async {
    // The operator declined the prompt. `AgentAwaitingInput` announced that
    // action when it arrived and `AgentInputResolved` ended it; a second,
    // "blocked" row here would tell them a wait they just answered is pending.
    publisher.report(_audit(decision: ActionDecision.deny, prompted: true));
    await _pump();

    expect(published, isEmpty);
  });

  test('an allow announces nothing', () async {
    publisher.report(_audit(decision: ActionDecision.allow));
    await _pump();

    expect(published, isEmpty);
  });

  test('a refusal with no space or agent still announces', () async {
    publisher.report(
      _audit(decision: ActionDecision.deny, spaceId: null, agentId: null),
    );
    await _pump();

    final event = published.single;
    expect(event.spaceId, isNull);
    expect(event.agentId, isNull);
    expect(event.agentName, isNull);
  });
}
