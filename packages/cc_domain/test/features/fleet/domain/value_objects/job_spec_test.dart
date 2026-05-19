import 'dart:convert';

import 'package:cc_domain/features/fleet/domain/value_objects/job_spec.dart';
import 'package:cc_domain/features/fleet/domain/value_objects/worker_capabilities.dart';
import 'package:test/test.dart';

/// Covers the [JobSpec] sealed class hierarchy, the [JobKind] wire enum, and
/// every concrete spec subtype: kind wiring, capability seeds
/// (`defaultRequiredCaps`/`defaultPreferredCaps`), JSON round-trips, the
/// `fromJson(kind, json)` and `fromJsonString` factory fallbacks.
void main() {
  group('JobKind wire', () {
    test('exposes a stable wire string per variant', () {
      expect(JobKind.agentRun.wire, 'agentRun');
      expect(JobKind.pipelineStep.wire, 'pipelineStep');
      expect(JobKind.codeIndex.wire, 'codeIndex');
      expect(JobKind.goldenRender.wire, 'goldenRender');
      expect(JobKind.benchmark.wire, 'benchmark');
      expect(JobKind.evalBatch.wire, 'evalBatch');
    });

    test('fromWire parses each known wire value', () {
      expect(JobKind.fromWire('agentRun'), JobKind.agentRun);
      expect(JobKind.fromWire('pipelineStep'), JobKind.pipelineStep);
      expect(JobKind.fromWire('codeIndex'), JobKind.codeIndex);
      expect(JobKind.fromWire('goldenRender'), JobKind.goldenRender);
      expect(JobKind.fromWire('benchmark'), JobKind.benchmark);
      expect(JobKind.fromWire('evalBatch'), JobKind.evalBatch);
    });

    test('fromWire falls back to agentRun for unknown wire', () {
      expect(JobKind.fromWire('nope'), JobKind.agentRun);
    });
  });

  group('JobSpec base', () {
    test('default capability seeds are empty', () {
      // The base spec exposes no required/preferred caps by default.
      const spec = BenchmarkJobSpec(name: 'x');
      expect(spec.defaultRequiredCaps, isEmpty);
      expect(spec.defaultPreferredCaps, isEmpty);
    });

    test('toJsonString round-trips the payload to a JSON string', () {
      const spec = BenchmarkJobSpec(name: 'bench', paramsJson: '{"a":1}');
      expect(jsonDecode(spec.toJsonString()), {
        'name': 'bench',
        'paramsJson': '{"a":1}',
      });
    });
  });

  group('JobSpec.fromJson dispatch', () {
    test('routes each kind to its concrete spec', () {
      expect(
        JobSpec.fromJson(JobKind.agentRun, const {'agentId': 'a1'}),
        isA<AgentRunJobSpec>(),
      );
      expect(
        JobSpec.fromJson(JobKind.pipelineStep, const {
          'pipelineRunId': 'r',
          'stepRunId': 's',
        }),
        isA<PipelineStepJobSpec>(),
      );
      expect(
        JobSpec.fromJson(JobKind.codeIndex, const {'repoId': 'repo'}),
        isA<CodeIndexJobSpec>(),
      );
      expect(
        JobSpec.fromJson(JobKind.goldenRender, const {
          'prNodeId': 'p',
          'repoId': 'r',
        }),
        isA<GoldenRenderJobSpec>(),
      );
      expect(
        JobSpec.fromJson(JobKind.benchmark, const {'name': 'n'}),
        isA<BenchmarkJobSpec>(),
      );
      expect(
        JobSpec.fromJson(JobKind.evalBatch, const {
          'evalRunId': 'e',
          'suiteId': 's',
          'configHash': 'h',
        }),
        isA<EvalBatchJobSpec>(),
      );
    });

    test('fromJsonString parses a populated JSON payload', () {
      final spec = JobSpec.fromJsonString(
        JobKind.pipelineStep,
        jsonEncode(const {'pipelineRunId': 'r1', 'stepRunId': 's1'}),
      );
      expect(spec, isA<PipelineStepJobSpec>());
      expect((spec as PipelineStepJobSpec).pipelineRunId, 'r1');
      expect(spec.stepRunId, 's1');
    });

    test('fromJsonString tolerates a blank payload', () {
      final spec = JobSpec.fromJsonString(JobKind.agentRun, '   ');
      expect(spec, isA<AgentRunJobSpec>());
      expect((spec as AgentRunJobSpec).agentId, '');
    });
  });

  group('AgentRunJobSpec', () {
    test('round-trips a fully populated spec through toJson/fromJson', () {
      const spec = AgentRunJobSpec(
        agentId: 'a1',
        conversationId: 'c1',
        runLogId: 'rl1',
        prompt: 'do thing',
        mode: 'chat',
        repoRemote: 'git@x:y.git',
        headSha: 'deadbeef',
        requestedByUserId: 'u1',
        extraRequiredCaps: {'flutter'},
        extraPreferredCaps: {'ml'},
      );
      final decoded = AgentRunJobSpec.fromJson(
        jsonDecode(jsonEncode(spec)) as Map<String, dynamic>,
      );
      expect(decoded.agentId, 'a1');
      expect(decoded.conversationId, 'c1');
      expect(decoded.runLogId, 'rl1');
      expect(decoded.prompt, 'do thing');
      expect(decoded.mode, 'chat');
      expect(decoded.repoRemote, 'git@x:y.git');
      expect(decoded.headSha, 'deadbeef');
      expect(decoded.requestedByUserId, 'u1');
      expect(decoded.extraRequiredCaps, {'flutter'});
      expect(decoded.extraPreferredCaps, {'ml'});
    });

    test('kind is agentRun and capability seeds mirror extra sets', () {
      const spec = AgentRunJobSpec(
        agentId: 'a',
        extraRequiredCaps: {'a'},
        extraPreferredCaps: {'b'},
      );
      expect(spec.kind, JobKind.agentRun);
      expect(spec.defaultRequiredCaps, {'a'});
      expect(spec.defaultPreferredCaps, {'b'});
    });

    test('toJson omits null fields and sorts cap lists', () {
      final json = const AgentRunJobSpec(
        agentId: 'a',
        extraRequiredCaps: {'b', 'a'},
      ).toJson();
      expect(json['agentId'], 'a');
      expect(json.containsKey('conversationId'), isFalse);
      expect(json.containsKey('prompt'), isFalse);
      expect(json.containsKey('extraPreferredCaps'), isFalse);
      expect(json['extraRequiredCaps'], ['a', 'b']);
    });

    test('fromJson tolerates missing fields and null cap lists', () {
      final decoded = AgentRunJobSpec.fromJson(const {'agentId': 'a'});
      expect(decoded.agentId, 'a');
      expect(decoded.conversationId, isNull);
      expect(decoded.extraRequiredCaps, isEmpty);
      expect(decoded.extraPreferredCaps, isEmpty);
    });

    test('fromJson defaults a missing agentId to empty', () {
      expect(AgentRunJobSpec.fromJson(const {}).agentId, '');
    });
  });

  group('PipelineStepJobSpec', () {
    test('round-trips through toJson/fromJson with sorted caps', () {
      const spec = PipelineStepJobSpec(
        pipelineRunId: 'r1',
        stepRunId: 's1',
        requiredCaps: {'flutter', 'ml'},
      );
      final json = spec.toJson();
      expect(json['pipelineRunId'], 'r1');
      expect(json['stepRunId'], 's1');
      expect(json['requiredCaps'], ['flutter', 'ml']);

      final decoded = PipelineStepJobSpec.fromJson(
        jsonDecode(jsonEncode(spec)) as Map<String, dynamic>,
      );
      expect(decoded.pipelineRunId, 'r1');
      expect(decoded.stepRunId, 's1');
      expect(decoded.requiredCaps, {'flutter', 'ml'});
    });

    test('kind is pipelineStep and required caps seed defaults', () {
      const spec = PipelineStepJobSpec(
        pipelineRunId: 'r',
        stepRunId: 's',
        requiredCaps: {'flutter'},
      );
      expect(spec.kind, JobKind.pipelineStep);
      expect(spec.defaultRequiredCaps, {'flutter'});
      expect(spec.defaultPreferredCaps, isEmpty);
    });

    test('toJson omits empty requiredCaps', () {
      final json = const PipelineStepJobSpec(
        pipelineRunId: 'r',
        stepRunId: 's',
      ).toJson();
      expect(json.containsKey('requiredCaps'), isFalse);
    });

    test('fromJson tolerates missing ids and null caps', () {
      final decoded = PipelineStepJobSpec.fromJson(const {});
      expect(decoded.pipelineRunId, '');
      expect(decoded.stepRunId, '');
      expect(decoded.requiredCaps, isEmpty);
    });
  });

  group('CodeIndexJobSpec', () {
    test('round-trips through toJson/fromJson', () {
      const spec = CodeIndexJobSpec(
        repoId: 'repo',
        repoRemote: 'git@x:y.git',
        headSha: 'abc',
      );
      final decoded = CodeIndexJobSpec.fromJson(
        jsonDecode(jsonEncode(spec)) as Map<String, dynamic>,
      );
      expect(decoded.repoId, 'repo');
      expect(decoded.repoRemote, 'git@x:y.git');
      expect(decoded.headSha, 'abc');
    });

    test('kind is codeIndex with empty default caps', () {
      const spec = CodeIndexJobSpec(repoId: 'repo');
      expect(spec.kind, JobKind.codeIndex);
      expect(spec.defaultRequiredCaps, isEmpty);
      expect(spec.defaultPreferredCaps, isEmpty);
    });

    test('toJson omits null remote/sha', () {
      final json = const CodeIndexJobSpec(repoId: 'repo').toJson();
      expect(json['repoId'], 'repo');
      expect(json.containsKey('repoRemote'), isFalse);
      expect(json.containsKey('headSha'), isFalse);
    });

    test('fromJson defaults a missing repoId to empty', () {
      expect(CodeIndexJobSpec.fromJson(const {}).repoId, '');
    });
  });

  group('GoldenRenderJobSpec', () {
    test('round-trips through toJson/fromJson', () {
      const spec = GoldenRenderJobSpec(
        prNodeId: 'pr1',
        repoId: 'repo',
        repoRemote: 'git@x:y.git',
        headSha: 'abc',
      );
      final decoded = GoldenRenderJobSpec.fromJson(
        jsonDecode(jsonEncode(spec)) as Map<String, dynamic>,
      );
      expect(decoded.prNodeId, 'pr1');
      expect(decoded.repoId, 'repo');
      expect(decoded.repoRemote, 'git@x:y.git');
      expect(decoded.headSha, 'abc');
    });

    test('kind is goldenRender and requires the flutter capability', () {
      const spec = GoldenRenderJobSpec(prNodeId: 'pr', repoId: 'r');
      expect(spec.kind, JobKind.goldenRender);
      expect(spec.defaultRequiredCaps, {FleetCaps.flutter});
      expect(spec.defaultPreferredCaps, isEmpty);
    });

    test('toJson omits null remote/sha', () {
      final json = const GoldenRenderJobSpec(
        prNodeId: 'pr',
        repoId: 'r',
      ).toJson();
      expect(json['prNodeId'], 'pr');
      expect(json['repoId'], 'r');
      expect(json.containsKey('repoRemote'), isFalse);
      expect(json.containsKey('headSha'), isFalse);
    });

    test('fromJson defaults missing ids to empty', () {
      final decoded = GoldenRenderJobSpec.fromJson(const {});
      expect(decoded.prNodeId, '');
      expect(decoded.repoId, '');
    });
  });

  group('BenchmarkJobSpec', () {
    test('round-trips through toJson/fromJson', () {
      const spec = BenchmarkJobSpec(name: 'bench', paramsJson: '{"x":1}');
      final decoded = BenchmarkJobSpec.fromJson(
        jsonDecode(jsonEncode(spec)) as Map<String, dynamic>,
      );
      expect(decoded.name, 'bench');
      expect(decoded.paramsJson, '{"x":1}');
    });

    test('kind is benchmark and always serialises name/paramsJson', () {
      final json = const BenchmarkJobSpec(name: 'n').toJson();
      expect(specKind(const BenchmarkJobSpec(name: 'n')), JobKind.benchmark);
      expect(json['name'], 'n');
      expect(json['paramsJson'], '{}');
    });

    test('fromJson defaults name to empty and paramsJson to {}', () {
      final decoded = BenchmarkJobSpec.fromJson(const {});
      expect(decoded.name, '');
      expect(decoded.paramsJson, '{}');
    });
  });

  group('EvalBatchJobSpec', () {
    test('round-trips through toJson/fromJson', () {
      const spec = EvalBatchJobSpec(
        evalRunId: 'e1',
        suiteId: 's1',
        configHash: 'h1',
        repetitionIndex: 3,
      );
      final decoded = EvalBatchJobSpec.fromJson(
        jsonDecode(jsonEncode(spec)) as Map<String, dynamic>,
      );
      expect(decoded.evalRunId, 'e1');
      expect(decoded.suiteId, 's1');
      expect(decoded.configHash, 'h1');
      expect(decoded.repetitionIndex, 3);
    });

    test('kind is evalBatch and prefers the parallel capability', () {
      const spec = EvalBatchJobSpec(
        evalRunId: 'e',
        suiteId: 's',
        configHash: 'h',
      );
      expect(spec.kind, JobKind.evalBatch);
      expect(spec.defaultRequiredCaps, isEmpty);
      expect(spec.defaultPreferredCaps, {FleetCaps.parallel});
    });

    test('fromJson defaults repetitionIndex to 0 and ids to empty', () {
      final decoded = EvalBatchJobSpec.fromJson(const {});
      expect(decoded.evalRunId, '');
      expect(decoded.suiteId, '');
      expect(decoded.configHash, '');
      expect(decoded.repetitionIndex, 0);
    });

    test('fromJson tolerates a num-typed repetitionIndex', () {
      final decoded = EvalBatchJobSpec.fromJson(const {
        'evalRunId': 'e',
        'suiteId': 's',
        'configHash': 'c',
        'repetitionIndex': 2.0,
      });
      expect(decoded.repetitionIndex, 2);
    });

    test('fromJson tolerates a null repetitionIndex', () {
      final decoded = EvalBatchJobSpec.fromJson(const {
        'evalRunId': 'e',
        'suiteId': 's',
        'configHash': 'c',
        'repetitionIndex': null,
      });
      expect(decoded.repetitionIndex, 0);
    });
  });
}

/// Helper to read a spec's kind without a stray local in the group body.
JobKind specKind(JobSpec spec) => spec.kind;
