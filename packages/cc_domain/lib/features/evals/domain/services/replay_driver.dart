import 'dart:convert';

import 'package:cc_domain/features/evals/domain/value_objects/session_recording_data.dart';
import 'package:cc_harness/loop.dart';
import 'package:cc_harness/messages.dart';
import 'package:cc_harness/provider.dart';
import 'package:cc_harness/tools.dart';

/// An [LlmProviderPort] that replays a recorded session's turns instead of
/// calling a real model.
///
/// Each `complete()` call returns the next [RecordedLlmTurn]'s events as a
/// stream, in order. There is no network and no token cost: it is driven
/// entirely by the recording. Calling `complete()` more times than were
/// recorded throws — an over-call is itself a harness regression (the loop ran
/// a turn the recording never saw).
class ReplayLlmProvider implements LlmProviderPort {
  /// Creates a provider that replays [_turns] in order.
  ReplayLlmProvider(this._turns);

  final List<RecordedLlmTurn> _turns;
  int _calls = 0;

  /// How many times `complete()` has been called so far. A faithful replay ends
  /// with this equal to the recorded turn count.
  int get callCount => _calls;

  @override
  String get displayName => 'Replay';

  @override
  String get defaultModel => 'replay';

  @override
  Future<List<ProviderModel>> listModels() async => const [];

  @override
  Stream<LlmEvent> complete({
    required List<HarnessMessage> messages,
    List<LlmToolSchema> tools = const [],
    LlmCompleteConfig config = const LlmCompleteConfig(),
  }) {
    if (_calls >= _turns.length) {
      throw StateError(
        'Replay regression: the loop called complete() ${_calls + 1} time(s) '
        'but only ${_turns.length} turn(s) were recorded.',
      );
    }
    final turn = _turns[_calls];
    _calls++;
    return Stream<LlmEvent>.fromIterable(turn.events);
  }
}

/// A tool that replays recorded results for one tool name WITHOUT running
/// anything. Deterministic replay executes nothing (PRD 21 Clarifications), so
/// each call pops the next recorded result for this tool in call order.
///
/// It is read-tier so it never trips the loop's approval gate — the recorded
/// result stands in for whatever the real (possibly write/exec) tool returned,
/// and no side effect is reproduced.
class ReplayTool extends HarnessTool {
  /// Creates a replay tool for [name] that returns [_results] in order.
  ReplayTool({required this.name, required List<HarnessToolResult> results})
    : _results = results;

  @override
  final String name;

  final List<HarnessToolResult> _results;
  int _index = 0;

  @override
  String get description => 'Replays recorded results for "$name".';

  @override
  Map<String, dynamic> get inputSchema => const {'type': 'object'};

  @override
  ToolApprovalTier get approvalTier => ToolApprovalTier.read;

  @override
  Future<HarnessToolResult> execute(
    Map<String, dynamic> args,
    HarnessToolContext context,
  ) async {
    if (_index >= _results.length) {
      return HarnessToolResult.error(
        'Replay regression: tool "$name" was called more times than recorded.',
      );
    }
    return _results[_index++];
  }
}

/// The outcome of replaying a recording against the live harness.
class ReplayResult {
  /// Creates a replay result.
  const ReplayResult({
    required this.byteIdentical,
    required this.expected,
    required this.actual,
    required this.diff,
    this.firstMismatchIndex,
  });

  /// True when the harness emitted exactly the recorded signature stream.
  final bool byteIdentical;

  /// Index of the first diverging signature, or null when identical.
  final int? firstMismatchIndex;

  /// The recorded (golden) signatures.
  final List<String> expected;

  /// The signatures the harness emitted this run.
  final List<String> actual;

  /// A human-readable diff, empty when [byteIdentical].
  final String diff;
}

/// Re-runs a recorded harness session with ALL externals stubbed from the
/// cassette and asserts the harness produces a byte-identical event stream.
///
/// This tests THE HARNESS, not the agent: the model is a [ReplayLlmProvider]
/// and every tool is a [ReplayTool], so the run is deterministic and free. Any
/// harness change that alters the emitted event stream — reordering, dropping,
/// or reshaping events — makes [replay] report `byteIdentical == false`.
class ReplayDriver {
  /// Creates a replay driver.
  const ReplayDriver();

  /// Replays [recording] against [loop] and compares the emitted event
  /// signatures to the recorded golden.
  ///
  /// [provider] lets a caller inject (and afterwards inspect) the replay
  /// provider; when null one is built from the recording. [config] is the loop
  /// config to run under — it must match the one the session was recorded with
  /// for the streams to line up (default config for a default recording).
  Future<ReplayResult> replay(
    SessionRecordingData recording, {
    required AgentLoop loop,
    HarnessToolContext? context,
    AgentLoopConfig config = const AgentLoopConfig(),
    ReplayLlmProvider? provider,
  }) async {
    final replayProvider = provider ?? ReplayLlmProvider(recording.llmTurns);
    final tools = buildReplayTools(recording);
    final history = recording.toHistoryMessages();

    final actual = <String>[];
    await for (final event in loop.run(
      history: history,
      userMessage: recording.userMessage,
      tools: tools,
      provider: replayProvider,
      context: context,
      config: config,
    )) {
      actual.add(loopEventSignature(event));
    }

    return _compare(recording.expectedEventSignatures, actual);
  }

  /// Builds one [ReplayTool] per tool name that appears in the recording's
  /// turns, seeded with that tool's recorded results in call order.
  ///
  /// The loop looks a tool up by name and calls `execute` without a call id, so
  /// results are matched by (toolName, nth-call): walking the turns in order
  /// resolves each call to its tool-call id, then to the recorded result.
  /// Loop-handled control tools (`checkpoint` / `rewind`) are skipped — the
  /// loop services them itself and never dispatches to a tool.
  List<HarnessTool> buildReplayTools(SessionRecordingData recording) {
    final resultsByName = <String, List<HarnessToolResult>>{};
    for (final turn in recording.llmTurns) {
      for (final event in turn.events) {
        if (event is! LlmToolUseDelta) {
          continue;
        }
        if (harnessControlToolNames.contains(event.name)) {
          continue;
        }
        (resultsByName[event.name] ??= <HarnessToolResult>[]).add(
          recording.toolResults[event.id] ??
              HarnessToolResult.error(
                'Replay regression: no recorded result for tool-call '
                '"${event.id}".',
              ),
        );
      }
    }
    return [
      for (final entry in resultsByName.entries)
        ReplayTool(name: entry.key, results: entry.value),
    ];
  }

  ReplayResult _compare(List<String> expected, List<String> actual) {
    final count = expected.length > actual.length
        ? expected.length
        : actual.length;
    int? mismatch;
    for (var i = 0; i < count; i++) {
      final e = i < expected.length ? expected[i] : null;
      final a = i < actual.length ? actual[i] : null;
      if (e != a) {
        mismatch = i;
        break;
      }
    }
    if (mismatch == null) {
      return ReplayResult(
        byteIdentical: true,
        expected: expected,
        actual: actual,
        diff: '',
      );
    }
    final e = mismatch < expected.length ? expected[mismatch] : '<missing>';
    final a = mismatch < actual.length ? actual[mismatch] : '<missing>';
    final diff = StringBuffer()
      ..writeln('Event stream diverged at index $mismatch:')
      ..writeln('  expected: $e')
      ..writeln('  actual:   $a')
      ..writeln(
        '(recorded ${expected.length} event(s), harness emitted '
        '${actual.length})',
      );
    return ReplayResult(
      byteIdentical: false,
      firstMismatchIndex: mismatch,
      expected: expected,
      actual: actual,
      diff: diff.toString(),
    );
  }
}

/// A canonical, timestamp-free signature for one agent-loop event — the unit of
/// the byte-identical replay comparison.
///
/// It captures each event's kind plus its salient fields (text/thinking by
/// content, tool calls by name + id + args, results by id + isError + output,
/// done by reason, usage by token counts) and nothing volatile, so two runs of
/// the same harness over the same recording produce identical signature lists.
String loopEventSignature(AgentLoopEvent event) {
  switch (event) {
    case LoopTextDelta(:final text):
      return 'text:$text';
    case LoopThinkingDelta(:final thinking):
      return 'thinking:$thinking';
    case LoopToolCallStart(:final toolName, :final toolUseId, :final args):
      return 'tool_start:$toolName:$toolUseId:${jsonEncode(args)}';
    case LoopToolCallResult(:final toolName, :final toolUseId, :final result):
      return 'tool_result:$toolName:$toolUseId:${result.isError}:'
          '${result.content}';
    case LoopTurnComplete(:final message):
      return 'turn_complete:${jsonEncode(message.toJson())}';
    case LoopUsage(:final usage):
      return 'usage:in=${usage.inputTokens}:out=${usage.outputTokens}:'
          'cr=${usage.cacheReadTokens}:cw=${usage.cacheWriteTokens}:'
          'th=${usage.thoughtTokens}';
    case LoopAdvisorNote(:final note, :final severity):
      return 'advisor:${severity.name}:$note';
    case LoopNotice(:final message):
      return 'notice:$message';
    case LoopCompaction(
      :final summarized,
      :final messagesFolded,
      :final tokensBefore,
      :final tokensAfter,
    ):
      return 'compaction:summarized=$summarized:folded=$messagesFolded:'
          'before=$tokensBefore:after=$tokensAfter';
    case LoopDone(:final reason):
      return 'done:${reason.name}';
    case LoopError(:final message, :final code):
      return 'error:${code ?? ''}:$message';
  }
}
