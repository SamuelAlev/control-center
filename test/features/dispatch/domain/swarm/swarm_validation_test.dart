import 'package:cc_domain/features/dispatch/domain/swarm/swarm_definition.dart';
import 'package:cc_domain/features/dispatch/domain/swarm/swarm_validation.dart';
import 'package:flutter_test/flutter_test.dart';

SwarmDefinition _def(
  List<SwarmAgent> agents, {
  SwarmMode mode = SwarmMode.parallel,
  int targetCount = 1,
  String? model,
}) {
  return SwarmDefinition(
    name: 'swarm',
    workspace: 'ws',
    mode: mode,
    targetCount: targetCount,
    model: model,
    agents: {for (final a in agents) a.name: a},
    agentOrder: [for (final a in agents) a.name],
  );
}

SwarmAgent _agent(
  String name, {
  List<String> waitsFor = const <String>[],
  List<String> reportsTo = const <String>[],
  String? model,
}) {
  return SwarmAgent(
    name: name,
    role: 'role-$name',
    task: 'task-$name',
    waitsFor: waitsFor,
    reportsTo: reportsTo,
    model: model,
  );
}

void main() {
  group('validateSwarmDefinition', () {
    test('returns no errors for a valid definition', () {
      final def = _def([
        _agent('a'),
        _agent('b', waitsFor: ['a']),
      ]);

      expect(validateSwarmDefinition(def), isEmpty);
    });

    test('flags waitsFor referencing an unknown agent', () {
      final def = _def([
        _agent('a', waitsFor: ['ghost']),
      ]);

      expect(
        validateSwarmDefinition(def),
        contains("Agent 'a' waits_for unknown agent 'ghost'"),
      );
    });

    test('flags reportsTo referencing an unknown agent', () {
      final def = _def([
        _agent('a', reportsTo: ['phantom']),
      ]);

      expect(
        validateSwarmDefinition(def),
        contains("Agent 'a' reports_to unknown agent 'phantom'"),
      );
    });

    test('flags an agent waiting for itself', () {
      final def = _def([
        _agent('a', waitsFor: ['a']),
      ]);

      expect(
        validateSwarmDefinition(def),
        contains("Agent 'a' cannot wait for itself"),
      );
    });

    test('flags an agent reporting to itself', () {
      final def = _def([
        _agent('a', reportsTo: ['a']),
      ]);

      expect(
        validateSwarmDefinition(def),
        contains("Agent 'a' cannot report to itself"),
      );
    });

    test('flags an empty swarm-level model', () {
      final def = _def([_agent('a')], model: '');

      expect(
        validateSwarmDefinition(def),
        contains('swarm.model must not be empty when provided'),
      );
    });

    test('accepts a non-empty swarm-level model', () {
      final def = _def([_agent('a')], model: 'opus');

      expect(validateSwarmDefinition(def), isEmpty);
    });

    test('flags an empty per-agent model', () {
      final def = _def([
        _agent('a', model: ''),
      ]);

      expect(
        validateSwarmDefinition(def),
        contains("Agent 'a' model must not be empty when provided"),
      );
    });

    test('flags targetCount below 1', () {
      final def = _def(
        [_agent('a')],
        mode: SwarmMode.pipeline,
        targetCount: 0,
      );

      expect(
        validateSwarmDefinition(def),
        contains('target_count must be at least 1'),
      );
    });

    test('flags targetCount != 1 outside pipeline mode', () {
      final def = _def(
        [_agent('a')],
        mode: SwarmMode.parallel,
        targetCount: 3,
      );

      expect(
        validateSwarmDefinition(def),
        contains('target_count is only supported in pipeline mode'),
      );
    });

    test('allows targetCount != 1 in pipeline mode', () {
      final def = _def(
        [_agent('a')],
        mode: SwarmMode.pipeline,
        targetCount: 4,
      );

      expect(validateSwarmDefinition(def), isEmpty);
    });

    test('accumulates multiple errors', () {
      final def = _def(
        [
          _agent('a', waitsFor: ['a', 'ghost'], model: ''),
        ],
        mode: SwarmMode.sequential,
        targetCount: 2,
      );

      final errors = validateSwarmDefinition(def);

      expect(
        errors,
        containsAll(<String>[
          "Agent 'a' waits_for unknown agent 'ghost'",
          "Agent 'a' cannot wait for itself",
          "Agent 'a' model must not be empty when provided",
          'target_count is only supported in pipeline mode',
        ]),
      );
    });
  });
}
