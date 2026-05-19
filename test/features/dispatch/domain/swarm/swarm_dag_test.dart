import 'package:cc_domain/features/dispatch/domain/swarm/swarm_dag.dart';
import 'package:cc_domain/features/dispatch/domain/swarm/swarm_definition.dart';
import 'package:flutter_test/flutter_test.dart';

/// Builds a [SwarmDefinition] from a list of agents, preserving their order as
/// the declaration order ([SwarmDefinition.agentOrder]).
SwarmDefinition _def(
  List<SwarmAgent> agents, {
  SwarmMode mode = SwarmMode.parallel,
  int targetCount = 1,
}) {
  return SwarmDefinition(
    name: 'swarm',
    workspace: 'ws',
    mode: mode,
    targetCount: targetCount,
    agents: {for (final a in agents) a.name: a},
    agentOrder: [for (final a in agents) a.name],
  );
}

SwarmAgent _agent(
  String name, {
  List<String> waitsFor = const <String>[],
  List<String> reportsTo = const <String>[],
}) {
  return SwarmAgent(
    name: name,
    role: 'role-$name',
    task: 'task-$name',
    waitsFor: waitsFor,
    reportsTo: reportsTo,
  );
}

void main() {
  group('buildDependencyGraph', () {
    test('builds dependencies from waitsFor', () {
      final def = _def([
        _agent('a'),
        _agent('b', waitsFor: ['a']),
        _agent('c', waitsFor: ['a', 'b']),
      ]);

      final deps = buildDependencyGraph(def);

      expect(deps['a'], isEmpty);
      expect(deps['b'], {'a'});
      expect(deps['c'], {'a', 'b'});
    });

    test('reportsTo inverts the dependency direction', () {
      // a reports to b => b depends on a.
      final def = _def([
        _agent('a', reportsTo: ['b']),
        _agent('b'),
      ]);

      final deps = buildDependencyGraph(def);

      expect(deps['a'], isEmpty);
      expect(deps['b'], {'a'});
    });

    test('skips waitsFor / reportsTo referencing unknown agents', () {
      final def = _def([
        _agent('a', waitsFor: ['ghost']),
        _agent('b', reportsTo: ['phantom']),
      ]);

      final deps = buildDependencyGraph(def);

      expect(deps['a'], isEmpty);
      expect(deps['b'], isEmpty);
      expect(deps.keys, {'a', 'b'});
    });

    test('chains by declaration order for pipeline with no explicit deps', () {
      final def = _def(
        [_agent('first'), _agent('second'), _agent('third')],
        mode: SwarmMode.pipeline,
      );

      final deps = buildDependencyGraph(def);

      expect(deps['first'], isEmpty);
      expect(deps['second'], {'first'});
      expect(deps['third'], {'second'});
    });

    test('chains by declaration order for sequential with no explicit deps',
        () {
      final def = _def(
        [_agent('one'), _agent('two')],
        mode: SwarmMode.sequential,
      );

      final deps = buildDependencyGraph(def);

      expect(deps['one'], isEmpty);
      expect(deps['two'], {'one'});
    });

    test('does NOT chain when explicit deps already exist', () {
      final def = _def(
        [_agent('one'), _agent('two', waitsFor: ['one']), _agent('three')],
        mode: SwarmMode.pipeline,
      );

      final deps = buildDependencyGraph(def);

      // Only the explicit edge survives; "three" stays unchained.
      expect(deps['one'], isEmpty);
      expect(deps['two'], {'one'});
      expect(deps['three'], isEmpty);
    });

    test('does NOT chain in parallel mode', () {
      final def = _def(
        [_agent('one'), _agent('two')],
        mode: SwarmMode.parallel,
      );

      final deps = buildDependencyGraph(def);

      expect(deps['one'], isEmpty);
      expect(deps['two'], isEmpty);
    });
  });

  group('detectCycles', () {
    test('returns null for an acyclic graph', () {
      final deps = <String, Set<String>>{
        'a': <String>{},
        'b': {'a'},
        'c': {'b'},
      };

      expect(detectCycles(deps), isNull);
    });

    test('returns the nodes involved in a cycle (A -> B -> A)', () {
      final deps = <String, Set<String>>{
        'a': {'b'},
        'b': {'a'},
      };

      final cycle = detectCycles(deps);

      expect(cycle, isNotNull);
      expect(cycle!.toSet(), {'a', 'b'});
    });

    test('isolates the cyclic nodes from acyclic ones', () {
      // root -> (clean) acyclic; x <-> y form a cycle.
      final deps = <String, Set<String>>{
        'root': <String>{},
        'clean': {'root'},
        'x': {'y'},
        'y': {'x'},
      };

      final cycle = detectCycles(deps);

      expect(cycle, isNotNull);
      expect(cycle!.toSet(), {'x', 'y'});
    });

    test('detects a longer cycle (A -> B -> C -> A)', () {
      final deps = <String, Set<String>>{
        'a': {'c'},
        'b': {'a'},
        'c': {'b'},
      };

      final cycle = detectCycles(deps);

      expect(cycle!.toSet(), {'a', 'b', 'c'});
    });
  });

  group('buildExecutionWaves', () {
    test('groups parallelizable agents into a single wave', () {
      final deps = <String, Set<String>>{
        'a': <String>{},
        'b': <String>{},
        'c': {'a', 'b'},
      };

      final waves = buildExecutionWaves(deps);

      expect(waves, [
        ['a', 'b'],
        ['c'],
      ]);
    });

    test('orders each wave deterministically (sorted)', () {
      final deps = <String, Set<String>>{
        'zebra': <String>{},
        'alpha': <String>{},
        'mango': <String>{},
      };

      final waves = buildExecutionWaves(deps);

      expect(waves, [
        ['alpha', 'mango', 'zebra'],
      ]);
    });

    test('produces a chain as one agent per wave', () {
      final deps = <String, Set<String>>{
        'first': <String>{},
        'second': {'first'},
        'third': {'second'},
      };

      final waves = buildExecutionWaves(deps);

      expect(waves, [
        ['first'],
        ['second'],
        ['third'],
      ]);
    });

    test('all dependencies of a wave land in earlier waves', () {
      final def = _def([
        _agent('design'),
        _agent('build', waitsFor: ['design']),
        _agent('test', waitsFor: ['build']),
        _agent('docs', waitsFor: ['design']),
      ]);

      final waves = buildExecutionWaves(buildDependencyGraph(def));

      // design first; build + docs both depend only on design; test last.
      expect(waves, [
        ['design'],
        ['build', 'docs'],
        ['test'],
      ]);
    });

    test('throws StateError on a deadlocked (cyclic) graph', () {
      final deps = <String, Set<String>>{
        'a': {'b'},
        'b': {'a'},
      };

      expect(() => buildExecutionWaves(deps), throwsStateError);
    });
  });
}
