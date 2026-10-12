import 'dart:convert';
import 'dart:io';

import 'package:cc_domain/features/evals/domain/evaluation/evaluation_task.dart';
import 'package:cc_harness/cancellation.dart';
import 'package:cc_harness/provider.dart';
import 'package:cc_infra/src/evaluation/controlled_evaluation_process.dart';
import 'package:cc_infra/src/evaluation/controlled_skill_evaluation.dart';
import 'package:cc_infra/src/evaluation/evaluation_artifacts.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  for (final nativeModel in ['vendor/model', 'openrouter/auto']) {
    test(
      'paired exposure verifies exact bytes with native model $nativeModel',
      () => _run(nativeModel),
      skip: ControlledEvaluationProcess.capabilityReason(),
    );
  }
}

// Local scripted HTTP endpoint: exercises the real provider, loop, guest tools,
// verifier and artifacts. It is not a live-model benchmark or quality evidence.
Future<void> _run(String nativeModel) async {
  final temporary = Directory.systemTemp.createTempSync('cc-skill-pair-smoke-');
  final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
  final models = <String>[];
  const marker = 'CC_SKILL_BODY_CANARY';
  server.listen((request) async {
    try {
      final body =
          jsonDecode(await utf8.decoder.bind(request).join())
              as Map<String, dynamic>;
      models.add(body['model'] as String);
      if (body['model'] != nativeModel) {
        request.response.statusCode = 400;
        request.response.write(
          'The pinned native model identifier was changed',
        );
        await request.response.close();
        return;
      }
      final messages = body['messages'] as List;
      final results = messages
          .where((message) => message['role'] == 'tool')
          .toList();
      final loaded = jsonEncode(results).contains(marker);
      final Map<String, dynamic> delta;
      final String finish;
      if (results.length < 2) {
        final reading = results.isEmpty;
        delta = {
          'tool_calls': [
            {
              'index': 0,
              'id': 'call-${models.length}',
              'type': 'function',
              'function': {
                'name': reading ? 'read' : 'write',
                'arguments': jsonEncode(
                  reading
                      ? {'path': '.agents/skills/demo/SKILL.md'}
                      : {
                          'path': 'answer.json',
                          'content': jsonEncode({'ok': loaded}),
                        },
                ),
              },
            },
          ],
        };
        finish = 'tool_calls';
      } else {
        delta = {'content': 'Artifact written.'};
        finish = 'stop';
      }
      request.response.headers.contentType = ContentType(
        'text',
        'event-stream',
      );
      request.response.write(
        'data: ${jsonEncode({
          'model': nativeModel,
          'choices': [
            {'index': 0, 'delta': delta, 'finish_reason': finish},
          ],
          'usage': {'prompt_tokens': 10, 'completion_tokens': 5, 'total_tokens': 15},
        })}\n\ndata: [DONE]\n\n',
      );
      await request.response.close();
    } on Object catch (error) {
      request.response.statusCode = 500;
      request.response.write(error.toString());
      await request.response.close();
    }
  });
  try {
    final files = {
      'SKILL.md': utf8.encode(
        '---\nname: demo\ndescription: Fixture guidance\n---\n$marker\n',
      ),
    };
    final snapshot = SkillPackageSnapshot(
      slug: 'demo',
      packageHash: SkillPackageSnapshot.computeHash(files),
      files: files,
      origin: 'workspace',
    );
    final result = await ControlledSkillEvaluation(
      workspaceId: 'smoke',
      campaignId: 'local-transport-smoke',
      candidate: snapshot,
      comparison: SkillComparison.absent,
      corpus: const EvaluationCorpus(
        id: 'scripted-integration-only',
        tasks: [
          EvaluationTask(
            id: 'artifact',
            kind: EvaluationTaskKind.bugfix,
            prompt: 'Write answer.json using available guidance.',
            tags: ['skill_family:serialization', 'should_trigger:true'],
            inlineFiles: {'answer.json': '{"ok":false}'},
            verifiers: [
              EvaluationVerifier(
                id: 'artifact',
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
      providerId: 'openrouter',
      modelId: nativeModel,
      credential: ProviderCredential(
        providerId: 'openrouter',
        method: HarnessAuthMethod.apiKey,
        apiKey: 'synthetic-local-only',
        baseUrl: 'http://127.0.0.1:${server.port}/v1',
      ),
      priceLookup: (_) => const ProviderCallCost(10),
      maxCallMicros: 100,
      budgetMicros: 10000,
      repetitions: 2,
      outDir: p.join(temporary.path, 'artifacts'),
      cancellation: CancellationToken.none,
      onAttempt: (_) async {},
    ).run();
    final rows = result.report.attempts;
    final baseline = rows.where((row) => row.armId == 'baseline').toList();
    final candidate = rows.where((row) => row.armId == 'candidate').toList();
    expect(result.report.coverageComplete, isTrue);
    expect(baseline, hasLength(2));
    expect(candidate, hasLength(2));
    for (final row in baseline) {
      expect(row.verifiedSuccess, isFalse);
      expect(
        row.skillEvents.where((event) => event.kind == 'body_load'),
        isEmpty,
      );
    }
    for (final row in candidate) {
      expect(row.verifiedSuccess, isTrue, reason: jsonEncode(row.toJson()));
      expect(
        row.skillEvents
            .where((event) => event.kind == 'body_load')
            .map((event) => event.skillHash),
        [snapshot.packageHash],
      );
    }
  } finally {
    await server.close(force: true);
    await ControlledEvaluationProcess.disposeRuntime();
    temporary.deleteSync(recursive: true);
  }
}
