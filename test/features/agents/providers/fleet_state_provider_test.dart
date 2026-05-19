import 'dart:async';

import 'package:cc_domain/core/domain/entities/agent.dart';
import 'package:cc_domain/core/domain/entities/agent_run_log.dart';
import 'package:cc_domain/core/domain/value_objects/agent_skills.dart';
import 'package:cc_domain/features/agents/domain/value_objects/agent_live_state.dart';
import 'package:control_center/features/agents/providers/agent_providers.dart';
import 'package:control_center/features/agents/providers/fleet_state_provider.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _TestActiveWorkspaceNotifier extends ActiveWorkspaceIdNotifier {
  _TestActiveWorkspaceNotifier(this._id);

  final String? _id;

  @override
  String? build() => _id;
}

Agent _agent({String id = 'agent-1', String name = 'Alice'}) {
  return Agent(
    id: id,
    name: name,
    title: 'Senior Engineer',
    agentMdPath: '/agents/$id.md',
    workspaceId: 'ws-1',
    skills: AgentSkills(<String>[]),
    createdAt: DateTime(2024, 1, 1),
  );
}

AgentRunLog _log({
  String id = 'run-1',
  RunStatus status = RunStatus.completed,
  String summary = 'shipped the thing',
}) {
  return AgentRunLog(
    id: id,
    agentId: 'agent-1',
    workspaceId: 'ws-1',
    startedAt: DateTime(2024, 1, 1, 9),
    completedAt: status == RunStatus.running
        ? null
        : DateTime(2024, 1, 1, 9, 30),
    status: status,
    summary: summary,
  );
}

const _key = (workspaceId: 'ws-1', agentId: 'agent-1');

void main() {
  group('FleetAgent', () {
    test('two fleet agents built from equal parts are equal', () {
      final a = FleetAgent(
        agent: _agent(),
        state: AgentLiveState.idle,
        latestRun: _log(),
        lastActive: DateTime(2024, 1, 1, 9, 30),
      );
      final b = FleetAgent(
        agent: _agent(),
        state: AgentLiveState.idle,
        latestRun: _log(),
        lastActive: DateTime(2024, 1, 1, 9, 30),
      );

      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('a different live state breaks equality', () {
      final a = FleetAgent(agent: _agent(), state: AgentLiveState.idle);
      final b = FleetAgent(agent: _agent(), state: AgentLiveState.running);

      expect(a, isNot(equals(b)));
    });
  });

  group('FleetList', () {
    FleetAgent one(AgentLiveState state) =>
        FleetAgent(agent: _agent(), state: state);

    // Compared with `==` rather than `equals(...)`: the matcher deep-compares
    // iterables, which would pass whatever the operator does. Riverpod's
    // notification check is `previous != next`, so the operator is the contract.
    test('compares by value, not identity', () {
      expect(
        FleetList([one(AgentLiveState.idle)]) ==
            FleetList([one(AgentLiveState.idle)]),
        isTrue,
      );
      expect(
        FleetList([one(AgentLiveState.idle)]) ==
            FleetList([one(AgentLiveState.running)]),
        isFalse,
      );
      expect(FleetList(const []) == FleetList(const []), isTrue);
      expect(
        FleetList([one(AgentLiveState.idle)]).hashCode,
        FleetList([one(AgentLiveState.idle)]).hashCode,
      );
    });

    test('is not equal to a plain list, keeping equality symmetric', () {
      final agents = [one(AgentLiveState.idle)];

      // ignore: unrelated_type_equality_checks
      expect(FleetList(agents) == agents, isFalse);
      // ignore: unrelated_type_equality_checks
      expect(agents == FleetList(agents), isFalse);
    });

    test('rejects modification', () {
      final list = FleetList([one(AgentLiveState.idle)]);

      expect(
        () => list.add(one(AgentLiveState.running)),
        throwsUnsupportedError,
      );
    });
  });

  group('agentFleetProvider', () {
    // A single-subscription controller so an emission is buffered rather than
    // dropped if the fleet has not subscribed yet — the provider is lazy.
    late StreamController<List<AgentRunLog>> logs;

    ProviderContainer makeContainer() {
      final container = ProviderContainer(
        overrides: [
          activeWorkspaceIdProvider.overrideWith(
            () => _TestActiveWorkspaceNotifier('ws-1'),
          ),
          workspaceAgentsProvider.overrideWith(
            (ref, workspaceId) => Stream.value(<Agent>[_agent()]),
          ),
          agentRunLogsProvider.overrideWith((ref, key) => logs.stream),
        ],
      );
      addTearDown(container.dispose);
      return container;
    }

    setUp(() {
      logs = StreamController<List<AgentRunLog>>();
      addTearDown(logs.close);
    });

    // The fleet is lazy: it only subscribes to a run-log stream once a read has
    // flushed it with a non-empty agent list. Settle that before emitting, so
    // emissions are never waiting on a subscription that does not exist yet.
    Future<void> settle(ProviderContainer container) async {
      await container.pump();
      container.read(agentFleetProvider);
      await container.pump();
      container.read(agentFleetProvider);
    }

    test('derives live state from the run logs', () async {
      final container = makeContainer();
      container.listen(agentFleetProvider, (_, _) {});
      await settle(container);

      logs.add(<AgentRunLog>[_log(status: RunStatus.running)]);
      await settle(container);

      expect(
        container.read(agentFleetProvider).single.state,
        AgentLiveState.running,
      );
    });

    test('an unchanged recompute does not notify dependents', () async {
      final container = makeContainer();
      var fleetNotifications = 0;
      var sourceNotifications = 0;
      container.listen(agentFleetProvider, (_, _) => fleetNotifications++);
      container.listen(
        agentRunLogsProvider(_key),
        (_, _) => sourceNotifications++,
      );
      await settle(container);

      logs.add(<AgentRunLog>[_log()]);
      await settle(container);
      final fleetBefore = fleetNotifications;
      final sourceBefore = sourceNotifications;
      expect(fleetBefore, greaterThan(0), reason: 'sanity: changes do notify');

      // Re-emit equal content in a fresh list — what a run-log stream tick
      // does when nothing about the run actually changed.
      logs.add(<AgentRunLog>[_log()]);
      await container.pump();
      expect(
        sourceNotifications,
        greaterThan(sourceBefore),
        reason: 'sanity: the run-log stream did emit',
      );

      // The fleet recomputes lazily, so this read is what flushes it — the
      // same thing a watching widget does when it mounts mid-frame.
      container.read(agentFleetProvider);

      expect(
        fleetNotifications,
        fleetBefore,
        reason: 'an unchanged fleet must not invalidate its dependents',
      );
    });

    test('a real change still notifies when flushed by a read', () async {
      final container = makeContainer();
      var fleetNotifications = 0;
      container.listen(agentFleetProvider, (_, _) => fleetNotifications++);
      await settle(container);

      logs.add(<AgentRunLog>[_log()]);
      await settle(container);
      final fleetBefore = fleetNotifications;

      logs.add(<AgentRunLog>[_log(id: 'run-2', status: RunStatus.running)]);
      await settle(container);

      expect(fleetNotifications, greaterThan(fleetBefore));
      expect(
        container.read(agentFleetProvider).single.state,
        AgentLiveState.running,
      );
    });
  });
}
