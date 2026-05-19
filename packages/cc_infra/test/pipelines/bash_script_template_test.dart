import 'dart:convert';
import 'dart:io';

import 'package:cc_domain/features/auth/domain/entities/api_credentials.dart';
import 'package:cc_domain/features/auth/domain/repositories/credentials_repository.dart';
import 'package:cc_domain/features/pipelines/domain/entities/pipeline_definition.dart';
import 'package:cc_domain/features/pipelines/domain/entities/pipeline_node_config.dart';
import 'package:cc_domain/features/pipelines/domain/entities/pipeline_step_definition.dart';
import 'package:cc_domain/features/pipelines/domain/entities/step_kind.dart';
import 'package:cc_domain/features/pipelines/domain/entities/step_result.dart';
import 'package:cc_domain/features/pipelines/domain/repositories/pipeline_run_repository.dart';
import 'package:cc_domain/features/pipelines/domain/repositories/pipeline_template_repository.dart';
import 'package:cc_domain/features/pipelines/domain/services/pipeline_body_registry.dart';
import 'package:cc_domain/features/pipelines/domain/services/pipeline_context.dart';
import 'package:cc_domain/features/pipelines/domain/services/step_process_registry.dart';
import 'package:cc_domain/features/pipelines/domain/templates/builtin_template_seeds.dart';
import 'package:cc_infra/src/pipelines/bash_script_template.dart';
import 'package:test/test.dart';

/// Exercises [registerBashScriptBody] — the agentless `pipeline.bashScript`
/// body. Covers: missing config/script validation, the dry-run echo path,
/// successful execution (exit 0 → outputKey populated), template `{{key}}`
/// substitution, shell-escaping of untrusted values, and the non-zero exit
/// failure path. The run repository records snapshots so the streaming side
/// is also exercised.
void main() {
  late Directory runDir;
  late _FakeCredentials creds;
  late _FakeRunRepo runRepo;
  late StepProcessRegistry stepRegistry;

  setUp(() {
    runDir = Directory.systemTemp.createTempSync('bash_template_');
    creds = _FakeCredentials();
    runRepo = _FakeRunRepo();
    stepRegistry = StepProcessRegistry();
  });
  tearDown(() => runDir.deleteSync(recursive: true));

  /// Builds a registry whose bash body resolves the given step config.
  PipelineBodyRegistry build({
    String? script,
    String? outputKey,
    required String stepId,
  }) {
    final tpl = _FakeTemplateRepo(
      _PipelineConfig(stepId: stepId, script: script, outputKey: outputKey),
    );
    final registry = PipelineBodyRegistry();
    registerBashScriptBody(
      registry,
      templateRepository: tpl,
      runRepository: runRepo,
      credentialsRepository: creds,
      stepProcessRegistry: stepRegistry,
      runDirPath: (_) async => runDir.path,
    );
    return registry;
  }

  PipelineContext ctx({
    String stepId = 'bash',
    Map<String, dynamic> state = const {},
    Map<String, dynamic>? trigger,
    bool dryRun = false,
  }) => PipelineContext(
    pipelineRunId: 'run-1',
    templateId: 'tpl-1',
    stepId: stepId,
    stepRunId: 'sr-1',
    workspaceId: 'ws-1',
    state: state,
    triggerPayload: trigger,
    dryRun: dryRun,
  );

  Future<StepResult> run({
    String? script,
    String? outputKey,
    String stepId = 'bash',
    Map<String, dynamic> state = const {},
    Map<String, dynamic>? trigger,
    bool dryRun = false,
  }) => build(script: script, outputKey: outputKey, stepId: stepId).body(
    BuiltInBodyKeys.bashScript,
  )(ctx(stepId: stepId, state: state, trigger: trigger, dryRun: dryRun));

  group('registerBashScriptBody — validation', () {
    test(
      'fails when the step has no config (template missing the step)',
      () async {
        final registry = PipelineBodyRegistry();
        registerBashScriptBody(
          registry,
          templateRepository: _NullTemplateRepo(),
          runRepository: runRepo,
          credentialsRepository: creds,
          stepProcessRegistry: stepRegistry,
          runDirPath: (_) async => runDir.path,
        );
        final res = await registry.body(BuiltInBodyKeys.bashScript)(
          ctx(stepId: 'nope'),
        );
        expect(res.errorMessage, contains('missing config'));
      },
    );

    test('fails when the script is missing', () async {
      final res = await run(stepId: 'bash'); // no script
      expect(res.errorMessage, contains('missing script'));
    });

    test('fails when the script is whitespace-only', () async {
      final res = await run(script: '   \n  ', stepId: 'bash');
      expect(res.errorMessage, contains('missing script'));
    });
  });

  group('registerBashScriptBody — dry run', () {
    test(
      'skips execution and echoes the dry-run marker under outputKey',
      () async {
        final res = await run(
          script: 'echo hi',
          outputKey: 'greeting',
          dryRun: true,
        );
        expect(res.isFailed, isFalse);
        expect(res.mutatedState!['greeting'], contains('[dry-run]'));
      },
    );

    test('omits the output key when outputKey is unset', () async {
      final res = await run(script: 'echo hi', dryRun: true);
      expect(res.isFailed, isFalse);
      expect(res.mutatedState, isNot(contains('[dry-run]')));
    });
  });

  group('registerBashScriptBody — execution', () {
    test('exit 0 writes stdout to outputKey + exposes the runDir', () async {
      final res = await run(
        script: 'echo hello-world\nsleep 0.1',
        outputKey: 'msg',
      );
      expect(res.isFailed, isFalse);
      expect(res.mutatedState!['msg'], 'hello-world');
      expect(res.mutatedState!['bash_runDir'], contains(runDir.path));
    });

    test('non-zero exit fails with the stderr tail', () async {
      final res = await run(
        script: 'echo oops 1>&2\nsleep 0.1\nexit 7',
        outputKey: 'msg',
      );
      expect(res.isFailed, isTrue);
      expect(res.errorMessage, contains('bash exited 7'));
      expect(res.errorMessage, contains('oops'));
    });

    test('non-zero exit with empty stderr falls back to stdout tail', () async {
      final res = await run(script: 'echo only-stdout\nsleep 0.1\nexit 3');
      expect(res.isFailed, isTrue);
      expect(res.errorMessage, contains('only-stdout'));
    });

    test('substitutes {{key}} placeholders from state and trigger', () async {
      final res = await run(
        script: "echo '{{who}} from {{place}}'\nsleep 0.1",
        outputKey: 'greeting',
        state: {'who': 'sam'},
        trigger: {'place': 'work'},
      );
      expect(res.isFailed, isFalse);
      expect(res.mutatedState!['greeting'], 'sam from work');
    });

    test(
      'shell-escapes an untrusted value spliced into double quotes',
      () async {
        // An injection attempt in the title must NOT run the injected command.
        final res = await run(
          script:
              r'echo "title={{title}}"'
              '\nsleep 0.1',
          outputKey: 'out',
          state: {'title': 'safe"; echo PWNED; echo "'},
        );
        expect(res.isFailed, isFalse);
        // The whole malicious string is rendered as data — no PWNED line.
        expect(res.mutatedState!['out'], contains('PWNED'));
        // But it's inside the echo (escaped), not a separate command — so only
        // ONE line of output is produced.
        expect((res.mutatedState!['out'] as String).split('\n'), hasLength(1));
      },
    );

    test('state takes precedence over the trigger payload', () async {
      final res = await run(
        script: 'echo {{k}}\nsleep 0.1',
        outputKey: 'out',
        state: {'k': 'state-val'},
        trigger: {'k': 'trigger-val'},
      );
      expect(res.mutatedState!['out'], 'state-val');
    });

    test('a missing key renders as empty', () async {
      final res = await run(
        script: 'echo "[{{nope}}]"\nsleep 0.1',
        outputKey: 'out',
      );
      expect(res.mutatedState!['out'], '[]');
    });

    test('exposes GITHUB_TOKEN env when credentials hold one', () async {
      creds.creds = const ApiCredentials(githubToken: 'tok-123');
      final res = await run(
        script: 'echo "\$GITHUB_TOKEN"\nsleep 0.1',
        outputKey: 'out',
      );
      expect(res.isFailed, isFalse);
      expect(res.mutatedState!['out'], 'tok-123');
    });

    test(
      'streams at least one output snapshot to the run repository',
      () async {
        await run(script: 'echo streamed\nsleep 0.1', outputKey: 'out');
        expect(runRepo.updates, isNotEmpty);
        // The final snapshot carries an exitCode + the streamed output.
        final last = jsonDecode(runRepo.updates.last) as Map<String, dynamic>;
        expect(last['exitCode'], 0);
        expect(last['output'], contains('streamed'));
      },
    );
  });
}

// --- Fakes -----------------------------------------------------------------

class _PipelineConfig {
  const _PipelineConfig({this.stepId, this.script, this.outputKey});
  final String? stepId;
  final String? script;
  final String? outputKey;
}

class _FakeTemplateRepo implements PipelineTemplateRepository {
  _FakeTemplateRepo(this._cfg);
  final _PipelineConfig _cfg;

  @override
  Future<PipelineDefinition?> getById(String workspaceId, String templateId) {
    return Future.value(
      PipelineDefinition(
        templateId: templateId,
        workspaceId: workspaceId,
        name: 'test',
        steps: [
          PipelineStepDefinition(
            id: _cfg.stepId ?? 'bash',
            kind: StepKind.terminal,
            bodyKey: BuiltInBodyKeys.bashScript,
            config: PipelineNodeConfig(
              script: _cfg.script,
              outputKey: _cfg.outputKey,
            ),
          ),
        ],
      ),
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _NullTemplateRepo extends _FakeTemplateRepo {
  _NullTemplateRepo() : super(const _PipelineConfig());
  @override
  Future<PipelineDefinition?> getById(String workspaceId, String templateId) =>
      Future.value(null);
}

class _FakeCredentials implements CredentialsRepository {
  ApiCredentials creds = const ApiCredentials();
  @override
  Future<ApiCredentials> loadCredentials() async => creds;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeRunRepo implements PipelineRunRepository {
  final List<String> updates = [];
  @override
  dynamic noSuchMethod(Invocation invocation) {
    // Capture updateStepRun(...outputJson: x) calls.
    if (invocation.memberName == #updateStepRun) {
      for (final arg in invocation.namedArguments.values) {
        if (arg is String && arg.contains('"stepId"')) {
          updates.add(arg);
        }
      }
    }
    return super.noSuchMethod(invocation);
  }
}
