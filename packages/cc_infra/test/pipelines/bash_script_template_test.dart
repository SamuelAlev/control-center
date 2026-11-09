import 'dart:convert';
import 'dart:io';

import 'package:cc_domain/core/domain/ports/credential_broker_port.dart';
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
import 'package:cc_domain/features/sandboxing/domain/sandbox_config.dart';
import 'package:cc_infra/src/pipelines/bash_script_template.dart';
import 'package:cc_infra/src/sandboxing/sandbox_manager.dart';
import 'package:test/test.dart';

/// Exercises [registerBashScriptBody] — the agentless `pipeline.bashScript`
/// body. Covers: missing config/script validation, the dry-run echo path,
/// successful execution (exit 0 → outputKey populated), template `{{key}}`
/// substitution, shell-escaping of untrusted values and the non-zero exit
/// failure path. The run repository records snapshots so the streaming side
/// is also exercised.
void main() {
  late Directory runDir;
  late _FakeRunRepo runRepo;
  late StepProcessRegistry stepRegistry;
  late _FakeBroker broker;
  late List<SandboxConfig> wrapped;

  setUp(() {
    runDir = Directory.systemTemp.createTempSync('bash_template_');
    runRepo = _FakeRunRepo();
    stepRegistry = StepProcessRegistry();
    broker = _FakeBroker();
    wrapped = [];
  });
  tearDown(() => runDir.deleteSync(recursive: true));

  /// A pass-through "sandbox" that records the config it was asked for and
  /// runs the argv as is: the real OS sandbox is proven separately below.
  Future<SandboxWrapResult> passThrough({
    required SandboxConfig config,
    required List<String> argv,
    String? workingDirectory,
  }) async {
    wrapped.add(config);
    return SandboxWrapResult(
      executable: argv.first,
      argv: argv.sublist(1),
      environment: const {},
    );
  }

  BashScriptSandbox sandbox({
    BashScriptSandboxWrap? wrap,
    bool noSandbox = false,
    List<String> deniedPaths = const ['/srv/cc/data', '/srv/cc/.env'],
  }) => BashScriptSandbox(
    wrap: noSandbox ? null : wrap ?? passThrough,
    deniedPaths: deniedPaths,
    broker: broker,
    linkedRepo: (workspaceId, repoFullName) async =>
        workspaceId == 'ws-1' && repoFullName == 'acme/linked'
        ? (owner: 'acme', name: 'linked')
        : null,
  );

  /// Builds a registry whose bash body resolves the given step config.
  PipelineBodyRegistry build({
    String? script,
    String? outputKey,
    required String stepId,
    BashScriptSandbox? withSandbox,
  }) {
    final tpl = _FakeTemplateRepo(
      _PipelineConfig(stepId: stepId, script: script, outputKey: outputKey),
    );
    final registry = PipelineBodyRegistry();
    registerBashScriptBody(
      registry,
      templateRepository: tpl,
      runRepository: runRepo,
      stepProcessRegistry: stepRegistry,
      runDirPath: (_) async => runDir.path,
      sandbox: withSandbox ?? sandbox(),
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
    BashScriptSandbox? withSandbox,
  }) =>
      build(
        script: script,
        outputKey: outputKey,
        stepId: stepId,
        withSandbox: withSandbox,
      ).body(BuiltInBodyKeys.bashScript)(
        ctx(stepId: stepId, state: state, trigger: trigger, dryRun: dryRun),
      );

  group('registerBashScriptBody — validation', () {
    test(
      'fails when the step has no config (template missing the step)',
      () async {
        final registry = PipelineBodyRegistry();
        registerBashScriptBody(
          registry,
          templateRepository: _NullTemplateRepo(),
          runRepository: runRepo,
          stepProcessRegistry: stepRegistry,
          runDirPath: (_) async => runDir.path,
          sandbox: sandbox(),
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

  group('registerBashScriptBody — refuse', () {
    test('execute: false never spawns bash', () async {
      final marker = File('${runDir.path}/pwned');
      expect(marker.existsSync(), isFalse);
      final tpl = _FakeTemplateRepo(
        const _PipelineConfig(stepId: 'bash', script: 'echo pwned > pwned'),
      );
      final registry = PipelineBodyRegistry();
      registerBashScriptBody(
        registry,
        templateRepository: tpl,
        runRepository: runRepo,
        stepProcessRegistry: stepRegistry,
        runDirPath: (_) async => runDir.path,
        sandbox: sandbox(),
        execute: false,
      );
      final res = await registry.body(BuiltInBodyKeys.bashScript)(
        ctx(stepId: 'bash'),
      );
      expect(res.isFailed, isTrue);
      expect(res.errorMessage, contains('disabled on this host'));
      expect(marker.existsSync(), isFalse);
    });

    test('no OS sandbox fails the step closed and never spawns', () async {
      final marker = File('${runDir.path}/pwned');
      final res = await run(
        script: 'echo pwned > pwned',
        withSandbox: sandbox(noSandbox: true),
      );
      expect(res.isFailed, isTrue);
      expect(res.errorMessage, contains('no OS sandbox'));
      expect(res.errorMessage, contains('never run unsandboxed'));
      expect(marker.existsSync(), isFalse);
      expect(broker.minted, isEmpty);
    });
  });

  group('registerBashScriptBody — confinement', () {
    test('runs inside the sandbox with the data dir and .env denied', () async {
      final res = await run(script: 'true');
      expect(res.isFailed, isFalse);
      final config = wrapped.single;
      expect(config.filesystem.denyRead, contains('/srv/cc/data'));
      expect(config.filesystem.denyRead, contains('/srv/cc/.env'));
      // The step's own run dir (inside the data dir) stays usable.
      expect(config.filesystem.allowRead, contains(runDir.path));
      // Named by its resolved path, which is what Seatbelt matches.
      expect(config.policy!.runDir, runDir.resolveSymbolicLinksSync());
      if (Platform.isMacOS) {
        expect(config.filesystem.denyWrite, contains('/srv/cc/data'));
      }
    });

    test('git and gh see no host configuration or token', () async {
      final res = await run(
        script:
            r'echo "$GIT_CONFIG_GLOBAL|$GIT_CONFIG_NOSYSTEM|${GH_TOKEN:-none}"'
            '\n'
            r'ls -A "$GH_CONFIG_DIR" | wc -l | tr -d " "',
        outputKey: 'out',
      );
      expect(res.isFailed, isFalse, reason: res.errorMessage);
      final lines = (res.mutatedState!['out'] as String).split('\n');
      expect(lines.first, '${Platform.isWindows ? 'NUL' : '/dev/null'}|1|none');
      expect(lines.last, '0');
      expect(broker.minted, isEmpty);
    });

    test('a linked target repo gets a minted one-repo read token', () async {
      final res = await run(
        script: r'echo "$GH_TOKEN"',
        outputKey: 'out',
        state: {'repo_full_name': 'acme/linked'},
      );
      expect(res.isFailed, isFalse, reason: res.errorMessage);
      expect(res.mutatedState!['out'], 'ghs_minted_acme_linked');
      final mint = broker.minted.single;
      expect(mint.scope, ForgeTokenScope.read);
      expect(mint.repo, 'acme/linked');
      expect(mint.workspaceId, 'ws-1');
      await pumpEventQueue();
      expect(broker.revoked, ['h-acme/linked']);
    });

    test('an unlinked target repo gets no token', () async {
      final res = await run(
        script: r'echo "${GH_TOKEN:-none}"',
        outputKey: 'out',
        state: {'repo_full_name': 'someone/else'},
      );
      expect(res.mutatedState!['out'], 'none');
      expect(broker.minted, isEmpty);
    });
  }, skip: Platform.isWindows ? 'bash exec contract is POSIX-only' : false);

  group('registerBashScriptBody — real OS sandbox', () {
    late Directory root;
    late Directory data;
    late Directory stepDir;
    late SandboxManager manager;

    setUp(() {
      root = Directory.systemTemp.createTempSync('cc-bash-sandbox-');
      data = Directory('${root.path}/data')..createSync();
      File('${data.path}/global.db').writeAsStringSync('server secrets');
      stepDir = Directory('${data.path}/pipelines/run-1')
        ..createSync(recursive: true);
      File('${root.path}/.env').writeAsStringSync('GITHUB_CLIENT_SECRET=x');
      manager = SandboxManager();
    });

    tearDown(() async {
      await manager.disposeSession('pipeline-run-1::bash');
      root.deleteSync(recursive: true);
    });

    test(
      'the script cannot read the data dir or .env, only its run dir',
      () async {
        final tpl = _FakeTemplateRepo(
          _PipelineConfig(
            stepId: 'bash',
            outputKey: 'out',
            script:
                'echo ok > mine.txt && cat mine.txt\n'
                // Renames and deletes in the run dir work (git needs both).
                'mkdir sub && echo x > sub/a && mv sub/a sub/b && rm -r sub '
                '&& echo moved\n'
                'cat ${data.path}/global.db 2>/dev/null || echo db-denied\n'
                'cat ${root.path}/.env 2>/dev/null || echo env-denied\n'
                'echo pwned > ${data.path}/planted 2>/dev/null || echo write-denied',
          ),
        );
        final registry = PipelineBodyRegistry();
        registerBashScriptBody(
          registry,
          templateRepository: tpl,
          runRepository: runRepo,
          stepProcessRegistry: stepRegistry,
          runDirPath: (_) async => stepDir.path,
          sandbox: sandbox(
            wrap: manager.wrap,
            deniedPaths: [data.path, '${root.path}/.env'],
          ),
        );
        final res = await registry.body(BuiltInBodyKeys.bashScript)(
          ctx(stepId: 'bash'),
        );
        expect(res.isFailed, isFalse, reason: res.errorMessage);
        expect((res.mutatedState!['out'] as String).split('\n'), [
          'ok',
          'moved',
          'db-denied',
          'env-denied',
          'write-denied',
        ]);
        expect(File('${data.path}/planted').existsSync(), isFalse);
      },
    );
  }, skip: Platform.isMacOS ? false : 'real Seatbelt proof runs on macOS');

  group(
    'registerBashScriptBody — execution',
    () {
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

      test(
        'non-zero exit with empty stderr falls back to stdout tail',
        () async {
          final res = await run(script: 'echo only-stdout\nsleep 0.1\nexit 3');
          expect(res.isFailed, isTrue);
          expect(res.errorMessage, contains('only-stdout'));
        },
      );

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
          expect(
            (res.mutatedState!['out'] as String).split('\n'),
            hasLength(1),
          );
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

      test(
        'an untrusted value is one literal word wherever the placeholder '
        'sits',
        () async {
          const attack =
              r"a'; echo PWNED; echo 'b $(echo SUB) `echo TICK`"
              '\necho NEWLINE';
          for (final script in [
            'echo {{title}}',
            "echo '{{title}}'",
            'echo "{{title}}"',
            r'echo "$(printf %s {{title}})"',
            "echo pre-{{title}}-post # a comment's apostrophe",
          ]) {
            final res = await run(
              script: '$script\nsleep 0.1',
              outputKey: 'out',
              trigger: {'title': attack},
            );
            expect(res.isFailed, isFalse, reason: script);
            final out = res.mutatedState!['out'] as String;
            expect(out, contains(r"a'; echo PWNED"), reason: script);
            expect(out, contains(r'$(echo SUB) `echo TICK`'), reason: script);
            expect(out.split('\n'), hasLength(2), reason: script);
            expect(out, isNot(contains('\nPWNED')), reason: script);
          }
        },
      );

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
    },
    // The execution body runs `bash` — a POSIX contract. On the GitHub
    // Windows runner the PATH `bash` is the WSL stub with no distro
    // installed (it exits 1 printing "Windows Subsystem for Linux has no
    // installed distributions"), so the real-exec assertions can only run
    // on POSIX hosts. Validation and dry-run stay covered on Windows.
    skip: Platform.isWindows ? 'bash exec contract is POSIX-only' : false,
  );
}

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

class _FakeBroker implements CredentialBrokerPort {
  final List<({ForgeTokenScope scope, String repo, String? workspaceId})>
  minted = [];
  final List<String> revoked = [];

  @override
  Future<ScopedCredentials> mint({
    required String conversationId,
    required ForgeTokenScope scope,
    String? repoOwner,
    String? repoName,
    String? actingUserId,
    String? workspaceId,
    bool personal = false,
  }) async {
    minted.add((
      scope: scope,
      repo: '$repoOwner/$repoName',
      workspaceId: workspaceId,
    ));
    return ScopedCredentials(
      handle: 'h-$repoOwner/$repoName',
      environment: {'GH_TOKEN': 'ghs_minted_${repoOwner}_$repoName'},
    );
  }

  @override
  Future<void> revoke(String handle) async => revoked.add(handle);
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
