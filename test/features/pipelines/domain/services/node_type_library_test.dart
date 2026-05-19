import 'package:cc_domain/features/pipelines/domain/entities/pipeline_node_config.dart';
import 'package:cc_domain/features/pipelines/domain/entities/step_kind.dart';
import 'package:cc_domain/features/pipelines/domain/services/node_type_library.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('NodeType', () {
    test('stores all fields', timeout: const Timeout.factor(2), () {
      const type = NodeType(
        id: 'test.node',
        displayName: 'Test Node',
        description: 'A test node',
        defaultKind: StepKind.listen,
        defaultBodyKey: 'test.body',
      );
      expect(type.id, 'test.node');
      expect(type.displayName, 'Test Node');
      expect(type.description, 'A test node');
      expect(type.defaultKind, StepKind.listen);
      expect(type.defaultBodyKey, 'test.body');
      expect(type.iconCodePoint, isNull);
    });

    test('stores optional iconCodePoint', () {
      const type = NodeType(
        id: 't',
        displayName: 'T',
        description: '',
        defaultKind: StepKind.listen,
        defaultBodyKey: 'b',
        iconCodePoint: 0xe000,
      );
      expect(type.iconCodePoint, 0xe000);
    });

    test('stores optional defaultConfig', () {
      const type = NodeType(
        id: 't',
        displayName: 'T',
        description: '',
        defaultKind: StepKind.listen,
        defaultBodyKey: 'b',
        defaultConfig: PipelineNodeConfig.empty,
      );
      expect(type.defaultConfig, isNotNull);
    });
  });

  group('NodeTypeLibrary', () {
    test('byId returns matching entry', timeout: const Timeout.factor(2), () {
      const lib = NodeTypeLibrary([
        NodeType(
          id: 'a',
          displayName: 'A',
          description: '',
          defaultKind: StepKind.listen,
          defaultBodyKey: 'b',
        ),
        NodeType(
          id: 'b',
          displayName: 'B',
          description: '',
          defaultKind: StepKind.router,
          defaultBodyKey: 'c',
        ),
      ]);
      expect(lib.byId('a')!.displayName, 'A');
      expect(lib.byId('b')!.displayName, 'B');
    });

    test('byId returns null for missing id', timeout: const Timeout.factor(2), () {
      const lib = NodeTypeLibrary([]);
      expect(lib.byId('missing'), isNull);
    });

    test('byId returns null when library is non-empty but id missing', () {
      const lib = NodeTypeLibrary([
        NodeType(
          id: 'x',
          displayName: 'X',
          description: '',
          defaultKind: StepKind.listen,
          defaultBodyKey: 'y',
        ),
      ]);
      expect(lib.byId('y'), isNull);
    });

    test('types are accessible', timeout: const Timeout.factor(2), () {
      const lib = NodeTypeLibrary([
        NodeType(
          id: 'x',
          displayName: 'X',
          description: '',
          defaultKind: StepKind.terminal,
          defaultBodyKey: 'y',
        ),
      ]);
      expect(lib.types.length, 1);
      expect(lib.types.first.id, 'x');
    });
  });

  group('defaultNodeTypeLibrary', () {
    test('returns a library with entries', timeout: const Timeout.factor(2), () {
      final lib = defaultNodeTypeLibrary();
      expect(lib.types, isNotEmpty);
    });

    test('contains expected built-in node types',
        timeout: const Timeout.factor(2), () {
      final lib = defaultNodeTypeLibrary();
      expect(lib.byId('bash.script'), isNotNull);
      expect(lib.byId('bash.clonePr'), isNotNull);
      expect(lib.byId('prReview.comment'), isNotNull);
      expect(lib.byId('prompt.reviewer'), isNotNull);
      expect(lib.byId('prompt.join'), isNotNull);
      expect(lib.byId('prompt.custom'), isNotNull);
      expect(lib.byId('hello.greet'), isNotNull);
      expect(lib.byId('hello.world'), isNotNull);
      expect(lib.byId('messaging.postChannel'), isNotNull);
      expect(lib.byId('pipeline.condition'), isNotNull);
      expect(lib.byId('condition.fileExists'), isNotNull);
      expect(lib.byId('condition.anyOf'), isNotNull);
      expect(lib.byId('condition.allOf'), isNotNull);
      expect(lib.byId('team.dispatch'), isNotNull);
      expect(lib.byId('human.gate'), isNotNull);
      expect(lib.byId('flow.forEach'), isNotNull);
      expect(lib.byId('flow.callPipeline'), isNotNull);
    });

    test('all entries have non-empty id, displayName, description, bodyKey',
        timeout: const Timeout.factor(2), () {
      final lib = defaultNodeTypeLibrary();
      for (final type in lib.types) {
        expect(type.id.isNotEmpty, isTrue,
            reason: 'Empty id');
        expect(type.displayName.isNotEmpty, isTrue,
            reason: 'Empty displayName for ${type.id}');
        expect(type.description.isNotEmpty, isTrue,
            reason: 'Empty description for ${type.id}');
        expect(type.defaultBodyKey.isNotEmpty, isTrue,
            reason: 'Empty bodyKey for ${type.id}');
      }
    });

    test('all entries have unique ids', timeout: const Timeout.factor(2), () {
      final lib = defaultNodeTypeLibrary();
      final ids = lib.types.map((t) => t.id).toSet();
      expect(ids.length, lib.types.length, reason: 'Duplicate ids found');
    });

    test('bash.script has correct defaults',
        timeout: const Timeout.factor(2), () {
      final lib = defaultNodeTypeLibrary();
      final bash = lib.byId('bash.script')!;
      expect(bash.defaultKind, StepKind.listen);
      expect(bash.defaultConfig.outputKey, 'script_output');
      expect(bash.defaultConfig.script, isNotNull);
    });

    test('bash.clonePr has correct defaults', () {
      final lib = defaultNodeTypeLibrary();
      final clone = lib.byId('bash.clonePr')!;
      expect(clone.defaultKind, StepKind.listen);
      expect(clone.defaultConfig.inputKeys, containsAll(['repoFullName', 'prNumber']));
      expect(clone.defaultConfig.outputKey, 'repoLocalPath');
    });

    test('prompt.reviewer has correct defaults', () {
      final lib = defaultNodeTypeLibrary();
      final reviewer = lib.byId('prompt.reviewer')!;
      expect(reviewer.defaultKind, StepKind.listen);
      expect(reviewer.defaultConfig.inputKeys,
          containsAll(['repoLocalPath', 'prTitle', 'prNumber']));
      expect(reviewer.defaultConfig.outputKey, 'reviewer_findings');
      expect(reviewer.defaultConfig.prompt, isNotNull);
    });

    test('prompt.join has join kind', timeout: const Timeout.factor(2), () {
      final lib = defaultNodeTypeLibrary();
      final join = lib.byId('prompt.join')!;
      expect(join.defaultKind, StepKind.join);
      expect(join.defaultConfig.outputKey, 'consolidatedFindings');
    });

    test('prompt.custom has listen kind and prompt with instructions', () {
      final lib = defaultNodeTypeLibrary();
      final custom = lib.byId('prompt.custom')!;
      expect(custom.defaultKind, StepKind.listen);
      expect(custom.defaultConfig.outputKey, 'custom_output');
      expect(custom.defaultConfig.prompt, isNotNull);
    });

    test('hello.greet has listen kind', () {
      final lib = defaultNodeTypeLibrary();
      final greet = lib.byId('hello.greet')!;
      expect(greet.defaultKind, StepKind.listen);
    });

    test('hello.world has listen kind', () {
      final lib = defaultNodeTypeLibrary();
      final world = lib.byId('hello.world')!;
      expect(world.defaultKind, StepKind.listen);
    });

    test('messaging.postChannel has correct defaults', () {
      final lib = defaultNodeTypeLibrary();
      final channel = lib.byId('messaging.postChannel')!;
      expect(channel.defaultKind, StepKind.listen);
      expect(channel.defaultConfig.inputKeys, containsAll(['channelId', 'content']));
      expect(channel.defaultConfig.outputKey, 'postedChannelId');
    });

    test('pipeline.condition has router kind',
        timeout: const Timeout.factor(2), () {
      final lib = defaultNodeTypeLibrary();
      final cond = lib.byId('pipeline.condition')!;
      expect(cond.defaultKind, StepKind.router);
    });

    test('condition.fileExists has router kind and predicate extras', () {
      final lib = defaultNodeTypeLibrary();
      final fe = lib.byId('condition.fileExists')!;
      expect(fe.defaultKind, StepKind.router);
      expect(fe.defaultConfig.extras['predicate'], isNotNull);
      final predicate = fe.defaultConfig.extras['predicate'] as Map;
      expect(predicate['type'], 'fileExists');
    });

    test('condition.anyOf has router kind and predicate extras', () {
      final lib = defaultNodeTypeLibrary();
      final anyOf = lib.byId('condition.anyOf')!;
      expect(anyOf.defaultKind, StepKind.router);
      expect(anyOf.defaultConfig.extras['predicate'], isNotNull);
      final predicate = anyOf.defaultConfig.extras['predicate'] as Map;
      expect(predicate['type'], 'fileExists');
    });

    test('condition.allOf has router kind and and-type predicate', () {
      final lib = defaultNodeTypeLibrary();
      final allOf = lib.byId('condition.allOf')!;
      expect(allOf.defaultKind, StepKind.router);
      expect(allOf.defaultConfig.extras['predicate'], isNotNull);
      final predicate = allOf.defaultConfig.extras['predicate'] as Map;
      expect(predicate['type'], 'and');
    });

    test('team.dispatch has dispatchMode and reducer', () {
      final lib = defaultNodeTypeLibrary();
      final team = lib.byId('team.dispatch')!;
      expect(team.defaultKind, StepKind.listen);
      expect(team.defaultConfig.dispatchMode, 'allParallel');
      expect(team.defaultConfig.reducer, 'append');
      expect(team.defaultConfig.outputKey, 'team_findings');
    });

    test('human.gate has listen kind', () {
      final lib = defaultNodeTypeLibrary();
      final gate = lib.byId('human.gate')!;
      expect(gate.defaultKind, StepKind.listen);
      expect(gate.defaultConfig.outputKey, 'approvalDecision');
    });

    test('flow.forEach has forEach kind', timeout: const Timeout.factor(2), () {
      final lib = defaultNodeTypeLibrary();
      final fe = lib.byId('flow.forEach')!;
      expect(fe.defaultKind, StepKind.forEach);
      expect(fe.defaultConfig.extras['iterableKey'], isNotNull);
      expect(fe.defaultConfig.reducer, 'append');
    });

    test('flow.callPipeline has listen kind and templateId extras', () {
      final lib = defaultNodeTypeLibrary();
      final call = lib.byId('flow.callPipeline')!;
      expect(call.defaultKind, StepKind.listen);
      expect(call.defaultConfig.outputKey, 'subflow_result');
      expect(
          call.defaultConfig.extras.containsKey('templateId'), isTrue);
    });
  });
}
