import 'package:cc_domain/core/domain/entities/agent_run_log.dart';
import 'package:cc_domain/features/agents/domain/value_objects/agent_live_state.dart';
import 'package:flutter_test/flutter_test.dart';

AgentRunLog _makeLog({
  String id = 'log-1',
  RunStatus status = RunStatus.completed,
  RunLiveness? liveness,
  DateTime? startedAt,
  DateTime? completedAt,
  DateTime? lastOutputAt,
}) =>
    AgentRunLog(
      id: id,
      agentId: 'agent-1',
      startedAt: startedAt ?? DateTime(2025, 6, 1),
      completedAt: completedAt,
      status: status,
      liveness: liveness,
      lastOutputAt: lastOutputAt,
    );

void main() {
  group('deriveAgentLiveState', () {
    test('returns neverRun for empty logs', timeout: const Timeout.factor(2), () {
      expect(deriveAgentLiveState([]), AgentLiveState.neverRun);
    });

    test('returns running when any log is running', timeout: const Timeout.factor(2), () {
      final logs = [
        _makeLog(status: RunStatus.completed),
        _makeLog(id: 'log-2', status: RunStatus.running),
      ];
      expect(deriveAgentLiveState(logs), AgentLiveState.running);
    });

    test('running takes priority over other states', timeout: const Timeout.factor(2), () {
      final logs = [
        _makeLog(status: RunStatus.error, liveness: RunLiveness.dead),
        _makeLog(id: 'log-2', status: RunStatus.running),
      ];
      expect(deriveAgentLiveState(logs), AgentLiveState.running);
    });

    test('returns failed when latest log has error status', timeout: const Timeout.factor(2), () {
      final logs = [
        _makeLog(status: RunStatus.error),
      ];
      expect(deriveAgentLiveState(logs), AgentLiveState.failed);
    });

    test('returns failed when latest log has failed liveness',
        timeout: const Timeout.factor(2), () {
      final logs = [
        _makeLog(status: RunStatus.completed, liveness: RunLiveness.failed),
      ];
      expect(deriveAgentLiveState(logs), AgentLiveState.failed);
    });

    test('returns failed when latest log has dead liveness', timeout: const Timeout.factor(2), () {
      final logs = [
        _makeLog(status: RunStatus.completed, liveness: RunLiveness.dead),
      ];
      expect(deriveAgentLiveState(logs), AgentLiveState.failed);
    });

    test('returns blocked when latest log has blocked liveness',
        timeout: const Timeout.factor(2), () {
      final logs = [
        _makeLog(status: RunStatus.completed, liveness: RunLiveness.blocked),
      ];
      expect(deriveAgentLiveState(logs), AgentLiveState.blocked);
    });

    test('returns blocked when latest log has stalled liveness',
        timeout: const Timeout.factor(2), () {
      final logs = [
        _makeLog(status: RunStatus.completed, liveness: RunLiveness.stalled),
      ];
      expect(deriveAgentLiveState(logs), AgentLiveState.blocked);
    });

    test('returns blocked when latest log has looping liveness',
        timeout: const Timeout.factor(2), () {
      final logs = [
        _makeLog(status: RunStatus.completed, liveness: RunLiveness.looping),
      ];
      expect(deriveAgentLiveState(logs), AgentLiveState.blocked);
    });

    test('returns idle for completed run with no issues', timeout: const Timeout.factor(2), () {
      final logs = [
        _makeLog(
          status: RunStatus.completed,
          liveness: RunLiveness.completed,
        ),
      ];
      expect(deriveAgentLiveState(logs), AgentLiveState.idle);
    });

    test('returns idle for completed run with alive liveness', timeout: const Timeout.factor(2), () {
      final logs = [
        _makeLog(
          status: RunStatus.completed,
          liveness: RunLiveness.alive,
        ),
      ];
      expect(deriveAgentLiveState(logs), AgentLiveState.idle);
    });

    test('returns idle for completed run with productive liveness',
        timeout: const Timeout.factor(2), () {
      final logs = [
        _makeLog(
          status: RunStatus.completed,
          liveness: RunLiveness.productive,
        ),
      ];
      expect(deriveAgentLiveState(logs), AgentLiveState.idle);
    });

    test('returns idle for completed run with empty liveness', timeout: const Timeout.factor(2), () {
      final logs = [
        _makeLog(
          status: RunStatus.completed,
          liveness: RunLiveness.empty,
        ),
      ];
      expect(deriveAgentLiveState(logs), AgentLiveState.idle);
    });

    test('classifies based on latest (first) log', timeout: const Timeout.factor(2), () {
      final logs = [
        _makeLog(id: 'newer', status: RunStatus.completed),
        _makeLog(id: 'older', status: RunStatus.error),
      ];
      expect(deriveAgentLiveState(logs), AgentLiveState.idle);
    });
  });

  group('agentLastActive', () {
    test('returns null for empty logs', timeout: const Timeout.factor(2), () {
      expect(agentLastActive([]), isNull);
    });

    test('returns lastOutputAt when present', timeout: const Timeout.factor(2), () {
      final lastOutput = DateTime(2025, 6, 5, 10, 30);
      final logs = [
        _makeLog(
          lastOutputAt: lastOutput,
          completedAt: DateTime(2025, 6, 5, 11),
          startedAt: DateTime(2025, 6, 5, 9),
        ),
      ];
      expect(agentLastActive(logs), lastOutput);
    });

    test('falls back to completedAt when lastOutputAt is null',
        timeout: const Timeout.factor(2), () {
      final completedAt = DateTime(2025, 6, 5, 11);
      final logs = [
        _makeLog(
          completedAt: completedAt,
          startedAt: DateTime(2025, 6, 5, 9),
        ),
      ];
      expect(agentLastActive(logs), completedAt);
    });

    test('falls back to startedAt when both are null', timeout: const Timeout.factor(2), () {
      final startedAt = DateTime(2025, 6, 5, 9);
      final logs = [_makeLog(startedAt: startedAt)];
      expect(agentLastActive(logs), startedAt);
    });
  });

  group('AgentLiveState', () {
    test('sortPriority ordering', timeout: const Timeout.factor(2), () {
      expect(AgentLiveState.running.sortPriority, 0);
      expect(AgentLiveState.blocked.sortPriority, 1);
      expect(AgentLiveState.failed.sortPriority, 2);
      expect(AgentLiveState.idle.sortPriority, 3);
      expect(AgentLiveState.neverRun.sortPriority, 4);
    });

    test('sort priority is monotonically increasing', timeout: const Timeout.factor(2), () {
      const values = AgentLiveState.values;
      for (var i = 1; i < values.length; i++) {
        expect(
          values[i].sortPriority > values[i - 1].sortPriority,
          isTrue,
          reason: '${values[i]}.sortPriority should be > ${values[i - 1]}.sortPriority',
        );
      }
    });
  });
}
