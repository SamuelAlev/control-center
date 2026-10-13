import 'dart:convert';
import 'dart:io';

import 'package:cc_domain/features/evals/domain/evaluation/evaluation_backend_port.dart';
import 'package:cc_domain/features/evals/domain/evaluation/evaluation_manifest.dart';
import 'package:cc_domain/features/evals/domain/evaluation/evaluation_plan.dart';
import 'package:cc_domain/features/evals/domain/evaluation/evaluation_task.dart';
import 'package:cc_harness/context.dart';
import 'package:cc_harness/messages.dart';
import 'package:cc_harness/provider.dart';
import 'package:cc_harness_runtime/cc_harness_runtime.dart';
import 'package:cc_infra/src/evaluation/backends/builtin_evaluation_backend.dart';
import 'package:cc_infra/src/evaluation/backends/claude_cli_evaluation_backend.dart';
import 'package:test/test.dart';

class _Factory extends HarnessProviderFactory {
  _Factory(this.provider);

  final LlmProviderPort provider;

  @override
  LlmProviderPort create({
    required String providerId,
    String? model,
    ProviderCredential? credential,
    ProviderTokenResolver? tokenResolver,
  }) => provider;
}

class _StreamedProvider implements LlmProviderPort {
  _StreamedProvider(
    this.turns, {
    this.unobservedFirst = false,
    this.secondDelayMs = 1,
    this.firstDispatchDelayMs = 0,
    this.firstResponseDelayMs = 55,
  }) : observeTransport = true;

  final List<List<LlmEvent>> turns;
  final bool observeTransport;
  final bool unobservedFirst;
  final int secondDelayMs;
  final int firstDispatchDelayMs;
  final int firstResponseDelayMs;
  var calls = 0;

  @override
  String get displayName => 'scripted';

  @override
  String get defaultModel => 'scripted';

  @override
  Future<List<ProviderModel>> listModels() async => const [];

  @override
  Stream<LlmEvent> complete({
    required List<HarnessMessage> messages,
    List<LlmToolSchema> tools = const [],
    LlmCompleteConfig config = const LlmCompleteConfig(),
  }) async* {
    final index = calls++;
    if (observeTransport && !(unobservedFirst && index == 0)) {
      if (index == 0 && firstDispatchDelayMs > 0) {
        await Future<void>.delayed(
          Duration(milliseconds: firstDispatchDelayMs),
        );
      }
      config.trace?.requestSent();
      await Future<void>.delayed(
        Duration(
          milliseconds: index == 0 ? firstResponseDelayMs : secondDelayMs,
        ),
      );
      config.trace?.transportFirstByte();
    }
    for (final event in turns[index]) {
      yield event;
      // Make the first character measurably separate from the later characters.
      if (index == 0 && event is LlmTextDelta && event.text == 'a') {
        await Future<void>.delayed(const Duration(milliseconds: 45));
      }
    }
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _AuxCompactor implements HarnessCompactor {
  _AuxCompactor(this.provider);

  final LlmProviderPort provider;
  var requested = false;

  @override
  Future<HarnessCompactionResult> maybeCompact(
    List<HarnessMessage> history, {
    required int? contextWindow,
    int overheadTokens = 0,
    int reservedOutputTokens = 0,
    String selfAgentName = 'assistant',
    bool force = false,
  }) async {
    if (!requested) {
      requested = true;
      await provider
          .complete(
            messages: history,
            config: const LlmCompleteConfig(purpose: LlmCallPurpose.compaction),
          )
          .drain<void>();
    }
    return const HarnessCompactionResult.unchanged(0);
  }

  @override
  int pruneToolResults(List<HarnessMessage> history, {bool force = false}) => 0;
}

void main() {
  late Directory workspace;
  setUp(() => workspace = Directory.systemTemp.createTempSync('eval_latency_'));
  tearDown(() => workspace.deleteSync(recursive: true));

  EvaluationAttemptRequest request({List<String> followUps = const []}) =>
      EvaluationAttemptRequest(
        task: EvaluationTask(
          id: 'latency',
          kind: EvaluationTaskKind.exploration,
          prompt: 'answer the question',
          followUps: followUps,
          verifiers: const [],
        ),
        arm: const EvaluationArm(id: 'baseline', axis: EvaluationAxis.baseline),
        effective: const EvaluationEffectiveConfig(
          adapter: 'builtin',
          providerId: 'anthropic',
          modelId: 'scripted',
        ),
        manifest: const EvaluationManifest(
          corpusId: 'latency',
          corpusHash: 'scripted',
          adapter: 'builtin',
          providerId: 'anthropic',
          modelId: 'scripted',
        ),
        workspaceRoot: workspace.path,
        stratum: CacheStratum.cold,
        repetition: 0,
        seed: 7,
        ordinal: 0,
        attemptId: 'latency-0',
      );

  test(
    'character-streamed answer is useful at its first nonblank character',
    () async {
      final provider = _StreamedProvider([
        const [
          LlmThinkingDelta('planning'),
          LlmTextDelta('  '),
          LlmTextDelta('a'),
          LlmTextDelta('b'),
          LlmTextDelta('c'),
          LlmDone(stopReason: LlmStopReason.endTurn),
        ],
      ]);
      final attempt = await BuiltinEvaluationBackend(
        factory: _Factory(provider),
      ).execute(request());
      expect(attempt.completed, isTrue);
      expect(attempt.latency.firstModelEventMs, isNotNull);
      expect(attempt.latency.firstUsefulTextMs, isNotNull);
      expect(
        attempt.latency.firstUsefulTextMs!,
        greaterThanOrEqualTo(attempt.latency.firstModelEventMs!),
      );
      expect(
        attempt.latency.totalMs - attempt.latency.firstUsefulTextMs!,
        greaterThanOrEqualTo(40),
      );
    },
  );

  test('tool-first run reports work before the final answer', () async {
    final provider = _StreamedProvider([
      const [
        LlmThinkingDelta('looking up evidence'),
        LlmToolUseDelta(
          id: 'read-1',
          name: 'read',
          argumentsJson: '{"path":"missing.txt"}',
        ),
        LlmDone(stopReason: LlmStopReason.toolUse),
      ],
      const [LlmTextDelta('ok'), LlmDone(stopReason: LlmStopReason.endTurn)],
    ], secondDelayMs: 150);
    final attempt = await BuiltinEvaluationBackend(
      factory: _Factory(provider),
    ).execute(request());
    expect(attempt.completed, isTrue);
    expect(attempt.toolEvents, isNotEmpty);
    expect(attempt.latency.firstUsefulTextMs, isNotNull);
    expect(
      attempt.latency.totalMs - attempt.latency.firstUsefulTextMs!,
      greaterThanOrEqualTo(140),
    );
  });

  test(
    'first main request owns transport TTFB, not a faster later turn',
    () async {
      final provider = _StreamedProvider([
        const [
          LlmTextDelta('first'),
          LlmDone(stopReason: LlmStopReason.endTurn),
        ],
        const [
          LlmTextDelta('next'),
          LlmDone(stopReason: LlmStopReason.endTurn),
        ],
      ], firstDispatchDelayMs: 40);
      final attempt = await BuiltinEvaluationBackend(
        factory: _Factory(provider),
      ).execute(request(followUps: ['continue']));
      expect(provider.calls, 2);
      expect(attempt.latency.transportTtfbMs, greaterThanOrEqualTo(45));
      expect(attempt.latency.firstModelEventMs, isNotNull);
      expect(
        attempt.latency.firstModelEventMs! - attempt.latency.transportTtfbMs!,
        greaterThanOrEqualTo(30),
      );
      expect(
        attempt.latency.providerTotalMs,
        greaterThanOrEqualTo(attempt.latency.transportTtfbMs!),
      );
    },
  );

  test(
    'fast auxiliary call cannot replace the main transport boundary',
    () async {
      final provider = _StreamedProvider(
        [
          const [
            LlmDone(
              stopReason: LlmStopReason.endTurn,
              usage: LlmUsage(inputTokens: 1),
            ),
          ],
          const [
            LlmTextDelta('answer'),
            LlmDone(
              stopReason: LlmStopReason.endTurn,
              usage: LlmUsage(inputTokens: 1),
            ),
          ],
        ],
        firstResponseDelayMs: 1,
        secondDelayMs: 80,
      );
      final calls = <ProviderCallRecord>[];
      final attempt = await BuiltinEvaluationBackend(
        factory: _Factory(provider),
        contextWindowTokens: 10000,
        compactorFactory:
            ({
              required policy,
              required provider,
              required providerId,
              required modelId,
              required readerHasVision,
              required calibration,
              required onResult,
            }) => _AuxCompactor(provider),
        priceLookup: (record) {
          calls.add(record);
          return null;
        },
      ).execute(request());
      expect(provider.calls, 2);
      expect(calls.map((call) => call.purpose), [
        LlmCallPurpose.compaction,
        LlmCallPurpose.main,
      ]);
      final main = calls.last;
      expect(
        attempt.latency.transportTtfbMs,
        main.transportFirstByteMs! - main.requestSentMs!,
      );
      expect(attempt.latency.transportTtfbMs, greaterThanOrEqualTo(70));
      expect(attempt.latency.providerTotalMs, main.durationMs);
      expect(attempt.latency.firstModelEventMs, isNotNull);
    },
  );

  test(
    'unobserved first request stays null even when later turn observes bytes',
    () async {
      final provider = _StreamedProvider([
        const [
          LlmTextDelta('first'),
          LlmDone(stopReason: LlmStopReason.endTurn),
        ],
        const [
          LlmTextDelta('next'),
          LlmDone(stopReason: LlmStopReason.endTurn),
        ],
      ], unobservedFirst: true);
      final attempt = await BuiltinEvaluationBackend(
        factory: _Factory(provider),
      ).execute(request(followUps: ['continue']));
      expect(provider.calls, 2);
      expect(attempt.latency.transportTtfbMs, isNull);
      expect(attempt.latency.firstModelEventMs, isNotNull);
    },
  );

  // The CLI fixture is a `#!/bin/sh` script, which Windows cannot execute.
  group('Claude CLI backend', () {
    void cliScript(List<Map<String, dynamic>> lines) {
      final executable = File('${workspace.path}/claude-fixture');
      executable.writeAsStringSync(
        '#!/bin/sh\nread prompt\n${lines.map((line) => "printf '%s\\n' '${jsonEncode(line)}'\n").join()}',
      );
      expect(Process.runSync('chmod', ['+x', executable.path]).exitCode, 0);
    }

    Map<String, dynamic> stream(Map<String, dynamic> event) => {
      'type': 'stream_event',
      'event': event,
    };

    test(
      'CLI init is not provider TTFB and streamed characters report work',
      () async {
        cliScript([
          {'type': 'system', 'subtype': 'init', 'session_id': 'session-1'},
          stream({
            'type': 'content_block_start',
            'index': 0,
            'content_block': {'type': 'thinking'},
          }),
          stream({
            'type': 'content_block_delta',
            'index': 0,
            'delta': {'type': 'thinking_delta', 'thinking': 'thinking'},
          }),
          stream({
            'type': 'content_block_start',
            'index': 1,
            'content_block': {'type': 'text'},
          }),
          for (final text in [' ', 'o', 'k'])
            stream({
              'type': 'content_block_delta',
              'index': 1,
              'delta': {'type': 'text_delta', 'text': text},
            }),
          {
            'type': 'result',
            'subtype': 'success',
            'total_cost_usd': 0,
            'usage': {'input_tokens': 1, 'output_tokens': 2},
          },
        ]);
        final attempt = await ClaudeCliEvaluationBackend(
          claudePath: '${workspace.path}/claude-fixture',
        ).execute(request());
        expect(attempt.completed, isTrue);
        expect(attempt.latency.transportTtfbMs, isNull);
        expect(attempt.latency.firstModelEventMs, isNotNull);
        expect(attempt.latency.firstUsefulTextMs, isNotNull);
        expect(
          attempt.latency.firstUsefulTextMs!,
          greaterThanOrEqualTo(attempt.latency.firstModelEventMs!),
        );
      },
    );

    test('CLI tool call is useful even before any text arrives', () async {
      cliScript([
        {'type': 'system', 'subtype': 'init', 'session_id': 'session-1'},
        stream({
          'type': 'content_block_start',
          'index': 0,
          'content_block': {'type': 'tool_use', 'id': 'tool-1', 'name': 'Bash'},
        }),
        stream({'type': 'content_block_stop', 'index': 0}),
        {
          'type': 'user',
          'message': {
            'role': 'user',
            'content': [
              {
                'type': 'tool_result',
                'tool_use_id': 'tool-1',
                'content': 'ok',
                'is_error': false,
              },
            ],
          },
        },
        {
          'type': 'result',
          'subtype': 'success',
          'total_cost_usd': 0,
          'usage': {'input_tokens': 1, 'output_tokens': 2},
        },
      ]);
      final attempt = await ClaudeCliEvaluationBackend(
        claudePath: '${workspace.path}/claude-fixture',
      ).execute(request());
      expect(attempt.completed, isTrue);
      expect(attempt.toolEvents, hasLength(1));
      expect(attempt.latency.firstUsefulTextMs, isNotNull);
      expect(attempt.latency.transportTtfbMs, isNull);
    });

    test(
      'CLI init alone does not claim a model event or useful work',
      () async {
        cliScript([
          {'type': 'system', 'subtype': 'init', 'session_id': 'session-1'},
        ]);
        final attempt = await ClaudeCliEvaluationBackend(
          claudePath: '${workspace.path}/claude-fixture',
        ).execute(request());
        expect(attempt.completed, isFalse);
        expect(attempt.error, isNotNull);
        expect(attempt.latency.transportTtfbMs, isNull);
        expect(attempt.latency.firstModelEventMs, isNull);
        expect(attempt.latency.firstUsefulTextMs, isNull);
        expect(attempt.cost.budgetMicros, isNull);
      },
    );
  }, skip: Platform.isWindows ? 'the shebang CLI fixture is POSIX-only' : false);
}
