import 'dart:convert';

import 'package:cc_domain/features/evals/domain/services/replay_driver.dart';
import 'package:cc_domain/features/evals/domain/value_objects/session_recording_data.dart';
import 'package:cc_harness/loop.dart';
import 'package:cc_harness/messages.dart';
import 'package:cc_harness/provider.dart';
import 'package:cc_harness/tools.dart';
import 'package:test/test.dart';

/// Runs the REAL [AgentLoopRunner] once over a scripted provider + scripted
/// tools and captures the emitted event signatures into a [SessionRecordingData].
///
/// Three turns: a turn that reads a file, a turn that searches, then a final
/// text turn — exercising thinking, text, tool calls, usage, tool results and
/// the terminal done event.
Future<SessionRecordingData> _record() async {
  const runner = AgentLoopRunner();
  const userMessage = 'Check the config and search the code.';

  final turns = <RecordedLlmTurn>[
    const RecordedLlmTurn([
      LlmThinkingDelta('Reading the config first.'),
      LlmTextDelta('Let me read the config file.'),
      LlmToolUseDelta(
        id: 'call_read',
        name: 'read_file',
        argumentsJson: '{"path":"config.yaml"}',
      ),
      LlmUsage(inputTokens: 12, outputTokens: 8),
      LlmDone(stopReason: LlmStopReason.toolUse),
    ]),
    const RecordedLlmTurn([
      LlmTextDelta('Now searching the code.'),
      LlmToolUseDelta(
        id: 'call_search',
        name: 'search_code',
        argumentsJson: '{"query":"main"}',
      ),
      LlmDone(stopReason: LlmStopReason.toolUse),
    ]),
    const RecordedLlmTurn([
      LlmTextDelta('All checks passed.'),
      LlmDone(stopReason: LlmStopReason.endTurn),
    ]),
  ];

  final toolResults = <String, HarnessToolResult>{
    'call_read': HarnessToolResult.success('name: control-center'),
    'call_search': HarnessToolResult.success('3 matches in main.dart'),
  };

  // Scripted stub tools that return the recorded results — they run nothing.
  final tools = <HarnessTool>[
    ReplayTool(name: 'read_file', results: [toolResults['call_read']!]),
    ReplayTool(name: 'search_code', results: [toolResults['call_search']!]),
  ];

  final provider = ReplayLlmProvider(turns);
  final signatures = <String>[];
  await for (final event in runner.run(
    history: <HarnessMessage>[],
    userMessage: userMessage,
    tools: tools,
    provider: provider,
  )) {
    signatures.add(loopEventSignature(event));
  }

  // The scripted script must have driven exactly one provider call per turn.
  expect(provider.callCount, turns.length);

  return SessionRecordingData(
    configHash: 'sha256:test-config',
    history: const [],
    userMessage: userMessage,
    llmTurns: turns,
    toolResults: toolResults,
    expectedEventSignatures: signatures,
  );
}

void main() {
  group('ReplayDriver', () {
    test(
      'records a session then replays it byte-identically at zero cost',
      () async {
        final recording = await _record();

        // Sanity: the recording captured a real, multi-turn event stream.
        expect(recording.llmTurns, hasLength(3));
        expect(recording.expectedEventSignatures, isNotEmpty);
        expect(recording.expectedEventSignatures, contains('done:completed'));
        expect(
          recording.expectedEventSignatures.any(
            (s) => s.startsWith('tool_result:read_file:call_read:'),
          ),
          isTrue,
        );

        // Round-trip through JSON to prove the golden is a self-contained file
        // runnable under plain `dart test`.
        final restored = SessionRecordingData.fromJson(
          jsonDecode(jsonEncode(recording.toJson())) as Map<String, dynamic>,
        );
        expect(
          restored.expectedEventSignatures,
          recording.expectedEventSignatures,
        );

        final provider = ReplayLlmProvider(restored.llmTurns);
        final result = await const ReplayDriver().replay(
          restored,
          loop: const AgentLoopRunner(),
          provider: provider,
        );

        expect(result.byteIdentical, isTrue, reason: result.diff);
        expect(result.firstMismatchIndex, isNull);
        expect(result.actual, restored.expectedEventSignatures);
        // Driven only from the recording: exactly one provider call per recorded
        // turn — no network, no extra tokens.
        expect(provider.callCount, restored.llmTurns.length);
      },
    );

    test(
      'replay fails when a recorded tool result is mutated (seeded bug)',
      () async {
        final recording = await _record();

        final mutated = SessionRecordingData(
          configHash: recording.configHash,
          history: recording.history,
          userMessage: recording.userMessage,
          llmTurns: recording.llmTurns,
          toolResults: {
            ...recording.toolResults,
            'call_read': HarnessToolResult.success('name: WRONG-VALUE'),
          },
          expectedEventSignatures: recording.expectedEventSignatures,
        );

        final result = await const ReplayDriver().replay(
          mutated,
          loop: const AgentLoopRunner(),
        );

        expect(result.byteIdentical, isFalse);
        expect(result.firstMismatchIndex, isNotNull);
        final index = result.firstMismatchIndex!;
        expect(result.actual[index], contains('WRONG-VALUE'));
        expect(result.expected[index], contains('control-center'));
        expect(result.diff, contains('diverged at index'));
      },
    );

    test(
      'replay fails when an expected signature is altered (seeded bug)',
      () async {
        final recording = await _record();

        final tampered = [...recording.expectedEventSignatures];
        tampered[0] = 'text:TAMPERED';
        final mutated = SessionRecordingData(
          configHash: recording.configHash,
          history: recording.history,
          userMessage: recording.userMessage,
          llmTurns: recording.llmTurns,
          toolResults: recording.toolResults,
          expectedEventSignatures: tampered,
        );

        final result = await const ReplayDriver().replay(
          mutated,
          loop: const AgentLoopRunner(),
        );

        expect(result.byteIdentical, isFalse);
        expect(result.firstMismatchIndex, 0);
        expect(result.diff, isNotEmpty);
      },
    );

    test('the replay provider throws when driven past the recorded turns', () {
      final provider = ReplayLlmProvider(const [
        RecordedLlmTurn([
          LlmTextDelta('hi'),
          LlmDone(stopReason: LlmStopReason.endTurn),
        ]),
      ]);

      // The single recorded turn is served fine.
      expect(provider.complete(messages: const []), isA<Stream<LlmEvent>>());
      expect(provider.callCount, 1);
      // A second call is a harness regression — the loop ran an unrecorded turn.
      expect(() => provider.complete(messages: const []), throwsStateError);
    });
  });
}
