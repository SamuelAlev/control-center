import 'dart:convert';
import 'dart:io';

import 'package:cc_domain/features/evals/domain/evaluation/evaluation_task.dart';
import 'package:cc_harness/cancellation.dart';
import 'package:cc_harness/messages.dart';
import 'package:cc_harness/provider.dart';
import 'package:cc_harness_runtime/cc_harness_runtime.dart';
import 'package:cc_infra/src/evaluation/controlled_evaluation_process.dart';
import 'package:cc_infra/src/evaluation/controlled_skill_evaluation.dart';
import 'package:cc_infra/src/evaluation/evaluation_artifacts.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  tearDownAll(ControlledEvaluationProcess.disposeRuntime);
  test('package identity includes all resource bytes and rejects escapes', () {
    final files = <String, List<int>>{
      'SKILL.md': utf8.encode('---\nname: serialize\n---\n'),
      'scripts/check.py': utf8.encode('print(1)'),
    };
    final hash = SkillPackageSnapshot.computeHash(files);
    final snapshot = SkillPackageSnapshot(
      slug: 'serialize',
      packageHash: hash,
      files: files,
      origin: 'workspace',
    );
    files['scripts/check.py']![0] = 0;
    expect(snapshot.files['scripts/check.py']![0], 'p'.codeUnitAt(0));
    expect(SkillPackageSnapshot.computeHash(files), isNot(hash));
    expect(
      () => SkillPackageSnapshot(
        slug: 'serialize',
        packageHash: hash,
        files: files,
        origin: 'workspace',
      ),
      throwsArgumentError,
    );
    expect(SkillPackageSnapshot.safeRelativePath('../canary'), isFalse);
    expect(
      SkillPackageSnapshot.safeRelativePath('scripts/../../canary'),
      isFalse,
    );
  });

  test(
    'strict guest cannot read host canary or write immutable assets',
    () async {
      if (ControlledEvaluationProcess.capabilityReason() != null) {
        return;
      }
      final parent = await Directory.systemTemp.createTemp('cc-eval-policy-');
      try {
        final root = await Directory(p.join(parent.path, 'workspace')).create();
        final home = await Directory(p.join(parent.path, 'home')).create();
        final assets = await Directory(
          p.join(root.path, '.agents', 'skills', 'x'),
        ).create(recursive: true);
        final skillFile = File(p.join(assets.path, 'SKILL.md'));
        await skillFile.writeAsString('unchanged');
        final canary = File(p.join(parent.path, 'host-canary'));
        await canary.writeAsString('HOST-CANARY');
        final runner = ControlledEvaluationProcess(
          root: root.path,
          home: home.path,
          readOnlyRoots: [assets.path],
        );
        final outcome = await runner.execute('/usr/bin/python3', [
          '-c',
          '''import pathlib,sys
try:
 leaked=pathlib.Path(sys.argv[1]).read_text()=='HOST-CANARY'
except OSError:
 leaked=False
try:
 pathlib.Path(sys.argv[2]).write_text('changed')
 changed=True
except OSError:
 changed=False
sys.exit(1 if leaked or changed else 0)
''',
          canary.path,
          skillFile.path,
        ]);
        expect(outcome.exitCode, 0, reason: outcome.stderr);
        expect(await skillFile.readAsString(), 'unchanged');
      } finally {
        await parent.delete(recursive: true);
      }
    },
  );
  test('cancellation stops an active confined subprocess', () async {
    if (ControlledEvaluationProcess.capabilityReason() != null) {
      return;
    }
    final parent = await Directory.systemTemp.createTemp('cc-eval-stop-');
    final source = CancellationTokenSource();
    try {
      final root = await Directory(p.join(parent.path, 'work')).create();
      final home = await Directory(p.join(parent.path, 'home')).create();
      final runner = ControlledEvaluationProcess(
        root: root.path,
        home: home.path,
        cancellation: source.token,
      );
      final ready = root
          .watch(events: FileSystemEvent.create)
          .firstWhere((event) => event.path.endsWith('ready'));
      final pending = runner.execute(
        '/usr/bin/python3',
        [
          '-c',
          "import pathlib,time; pathlib.Path('ready').write_text('ready'); time.sleep(30)",
        ],
        cancel: source.token,
        timeout: const Duration(seconds: 10),
      );
      await ready.timeout(const Duration(seconds: 5));
      source.cancel();
      final outcome = await pending;
      expect(outcome.exitCode, isNot(0));
      expect(outcome.timedOut, isFalse);
    } finally {
      await parent.delete(recursive: true);
    }
  });

  for (final unsupportedVerifier in [false, true]) {
    test(
      unsupportedVerifier
          ? 'unsupported verifier rejects admission'
          : 'insufficient call reservation rejects admission',
      () async {
        final parent = await Directory.systemTemp.createTemp(
          'cc-eval-admission-',
        );
        try {
          final files = {
            'SKILL.md': utf8.encode('---\ndescription: demo\n---\n'),
          };
          final skill = SkillPackageSnapshot(
            slug: 'demo',
            packageHash: SkillPackageSnapshot.computeHash(files),
            files: files,
            origin: 'workspace',
          );
          final service = ControlledSkillEvaluation(
            workspaceId: 'w',
            campaignId: 'c',
            candidate: skill,
            corpus: EvaluationCorpus(
              id: 'x',
              tasks: [
                EvaluationTask(
                  id: 't',
                  kind: EvaluationTaskKind.bugfix,
                  prompt: 'repair',
                  verifiers: [
                    unsupportedVerifier
                        ? const EvaluationVerifier(
                            id: 'git',
                            kind: EvaluationVerifierKind.noWrites,
                          )
                        : const EvaluationVerifier(
                            id: 'result',
                            kind: EvaluationVerifierKind.tests,
                            params: {
                              'oracle': {
                                'kind': 'json-artifact',
                                'path': 'answer.json',
                                'expected': {'ok': true},
                              },
                            },
                          ),
                  ],
                ),
              ],
            ),
            comparison: SkillComparison.absent,
            providerId: 'openai',
            modelId: 'm',
            credential: const ProviderCredential(
              providerId: 'openai',
              method: HarnessAuthMethod.apiKey,
              apiKey: 'test',
            ),
            priceLookup: (_) => const ProviderCallCost(10),
            maxCallMicros: 100,
            budgetMicros: unsupportedVerifier ? 100 : 50,
            repetitions: 1,
            factory: const _NoModelCallsFactory(),
            outDir: p.join(parent.path, 'not-created'),
            cancellation: CancellationToken.none,
            onAttempt: (_) async {},
          );
          await expectLater(service.run(), throwsUnsupportedError);
          expect(
            Directory(p.join(parent.path, 'not-created')).existsSync(),
            isFalse,
          );
        } finally {
          await parent.delete(recursive: true);
        }
      },
      skip: ControlledEvaluationProcess.capabilityReason(),
    );
  }
  test(
    'Codex OAuth accepts a post-call threshold but API-key mode requires a reservation',
    () async {
      final files = {'SKILL.md': utf8.encode('---\ndescription: demo\n---\n')};
      final skill = SkillPackageSnapshot(
        slug: 'demo',
        packageHash: SkillPackageSnapshot.computeHash(files),
        files: files,
        origin: 'workspace',
      );
      ControlledSkillEvaluation campaign(HarnessAuthMethod method) =>
          ControlledSkillEvaluation(
            workspaceId: 'w',
            campaignId: 'threshold',
            candidate: skill,
            corpus: const EvaluationCorpus(
              id: 'x',
              tasks: [
                EvaluationTask(
                  id: 't',
                  kind: EvaluationTaskKind.bugfix,
                  prompt: 'repair',
                  verifiers: [
                    EvaluationVerifier(
                      id: 'result',
                      kind: EvaluationVerifierKind.tests,
                      params: {
                        'oracle': {
                          'kind': 'json-artifact',
                          'path': 'answer.json',
                          'expected': {'ok': true},
                        },
                      },
                    ),
                  ],
                ),
              ],
            ),
            comparison: SkillComparison.absent,
            providerId: 'codex',
            modelId: 'gpt-5.6-terra',
            credential: ProviderCredential(
              providerId: 'codex',
              method: method,
              accessToken: method == HarnessAuthMethod.oauth ? 'local' : null,
              apiKey: method == HarnessAuthMethod.apiKey ? 'local' : null,
            ),
            priceLookup: (_) => const ProviderCallCost(10),
            budgetEnforcement: 'stop_after_call',
            budgetMicros: 1000000,
            repetitions: 1,
            factory: const _NoModelCallsFactory(),
            outDir: 'not-created',
            cancellation: CancellationToken.none,
            onAttempt: (_) async {},
          );
      expect(
        await campaign(HarnessAuthMethod.oauth).capabilityReason(),
        isNull,
      );
      expect(
        await campaign(HarnessAuthMethod.apiKey).capabilityReason(),
        contains('budget enforcement'),
      );
    },
    skip: ControlledEvaluationProcess.capabilityReason(),
  );
}

class _NoModelCallsFactory extends HarnessProviderFactory {
  const _NoModelCallsFactory();
  @override
  LlmProviderPort create({
    required String providerId,
    String? model,
    ProviderCredential? credential,
    ProviderTokenResolver? tokenResolver,
  }) => _NoModelCallsProvider();
}

class _NoModelCallsProvider implements LlmProviderPort {
  @override
  String get displayName => 'never called';

  @override
  String get defaultModel => 'm';

  @override
  Future<List<ProviderModel>> listModels() async => const [];

  @override
  Stream<LlmEvent> complete({
    required List<HarnessMessage> messages,
    List<LlmToolSchema> tools = const [],
    LlmCompleteConfig config = const LlmCompleteConfig(),
  }) => throw StateError('Rejected admission must not request a completion');
}
