import 'dart:async';
import 'dart:math';

import 'package:cc_harness/cancellation.dart';
import 'package:cc_harness/loop.dart';
import 'package:cc_harness/messages.dart';
import 'package:cc_harness/provider.dart';
import 'package:cc_harness/tools.dart';
import 'package:cc_server_core/src/demo/demo_script.dart';

/// How fast a scripted run streams.
///
/// Tuned to read like a real model rather than a progress bar: prose arrives in
/// small chunks, thinking is slower than speech, and a tool call has a beat of
/// latency before it starts and a variable one before it answers.
class DemoPacing {
  /// Creates a pacing profile.
  const DemoPacing({
    this.textChunk = 12,
    this.textDelay = const Duration(milliseconds: 18),
    this.thinkingChunk = 18,
    this.thinkingDelay = const Duration(milliseconds: 28),
    this.beforeToolMin = const Duration(milliseconds: 400),
    this.beforeToolMax = const Duration(milliseconds: 900),
    this.toolMin = const Duration(milliseconds: 300),
    this.toolMax = const Duration(milliseconds: 1500),
  });

  /// Zero-delay pacing, so tests do not pay a scripted run's wall clock.
  static const DemoPacing instant = DemoPacing(
    textDelay: Duration.zero,
    thinkingDelay: Duration.zero,
    beforeToolMin: Duration.zero,
    beforeToolMax: Duration.zero,
    toolMin: Duration.zero,
    toolMax: Duration.zero,
  );

  /// Characters per prose delta.
  final int textChunk;

  /// Delay between prose deltas.
  final Duration textDelay;

  /// Characters per thinking delta.
  final int thinkingChunk;

  /// Delay between thinking deltas.
  final Duration thinkingDelay;

  /// Lower bound of the pause before a tool call starts.
  final Duration beforeToolMin;

  /// Upper bound of the pause before a tool call starts.
  final Duration beforeToolMax;

  /// Lower bound of a tool call's apparent duration.
  final Duration toolMin;

  /// Upper bound of a tool call's apparent duration.
  final Duration toolMax;
}

/// An [AgentLoop] that replays a hand-authored [DemoRunScript] instead of
/// calling a model.
///
/// This is the demo's execution boundary, and it is the reason a public demo
/// can be safe. Replacing only the LLM *provider* would not be enough: a
/// dispatched run builds its REAL tool surface (`materializeHarnessToolSurface`
/// in `dispatch_session.dart`) and the stock [AgentLoopRunner] executes
/// whatever the model asks for — a scripted model emitting a `bash` call would
/// really run bash. Injecting the loop one level up means the `tools`,
/// `deferredTools` and `provider` arguments are simply ignored: **zero** tools
/// execute, while every persistence path around the loop (run logs, transcript
/// segments, the live stream registry, cost accounting, `AgentRunCompleted`)
/// stays exactly as it is on a real run.
///
/// Contract obligations this honours, per [AgentLoop]:
///  * exactly one `LoopDone` terminates the stream, on every path including
///    cancellation and an empty script;
///  * `cancel` is observed between beats, so `dispatch.stopRun` works;
///  * `history` is caller-owned and appended in place, so a follow-up turn in
///    the same conversation carries the run that preceded it.
class ScriptedAgentLoop implements AgentLoop {
  /// Creates a scripted loop over [scripts].
  ///
  /// [random] seeds the jitter on tool latency; pass a seeded [Random] for a
  /// deterministic test.
  ScriptedAgentLoop({
    required this.scripts,
    this.pacing = const DemoPacing(),
    Random? random,
  }) : _random = random ?? Random();

  /// Every script this demo can play.
  final List<DemoRunScript> scripts;

  /// Stream pacing.
  final DemoPacing pacing;

  final Random _random;

  /// Marker a seeded message can carry to demand a specific script, bypassing
  /// keyword matching: `[[demo:script=review-auth-pr]]`.
  static final RegExp scriptMarker = RegExp(r'\[\[demo:script=([a-z0-9._-]+)\]\]');

  /// The script [message] selects: an explicit marker wins, then the best
  /// keyword match, then the first script as a generic fallback.
  ///
  /// Returns null only when there are no scripts at all.
  DemoRunScript? selectScript(String message) {
    if (scripts.isEmpty) {
      return null;
    }
    final marked = scriptMarker.firstMatch(message)?.group(1);
    if (marked != null) {
      for (final script in scripts) {
        if (script.id == marked) {
          return script;
        }
      }
    }
    DemoRunScript? best;
    var bestScore = 0;
    for (final script in scripts) {
      final score = script.scoreFor(message);
      if (score > bestScore) {
        best = script;
        bestScore = score;
      }
    }
    return best ?? scripts.first;
  }

  @override
  Stream<AgentLoopEvent> run({
    required List<HarnessMessage> history,
    required String userMessage,
    required List<HarnessTool> tools,
    List<HarnessTool> deferredTools = const [],
    required LlmProviderPort provider,
    HarnessToolContext? context,
    AgentLoopConfig config = const AgentLoopConfig(),
    CancellationToken? cancel,
    List<HarnessImageBlock> userImages = const [],
  }) async* {
    // `tools`, `deferredTools` and `provider` are deliberately unused: the
    // whole point of this loop is that nothing is callable and nothing is
    // dialled. See the class doc.
    history.add(HarnessMessage.user(userMessage));

    final script = selectScript(userMessage);
    if (script == null) {
      yield const LoopError('The demo has no scripts installed.');
      yield const LoopDone(LoopDoneReason.completed);
      return;
    }

    final spoken = StringBuffer();
    var toolCall = 0;
    var sawUsage = false;

    for (final step in script.steps) {
      if (cancel?.isCancelled ?? false) {
        break;
      }
      switch (step) {
        case DemoThinkingStep(:final text):
          yield* _stream(
            text,
            pacing.thinkingChunk,
            pacing.thinkingDelay,
            cancel,
            LoopThinkingDelta.new,
          );
        case DemoSayStep(:final text):
          spoken.write(text);
          yield* _stream(
            text,
            pacing.textChunk,
            pacing.textDelay,
            cancel,
            LoopTextDelta.new,
          );
        case DemoToolStep(:final tool, :final args, :final result, :final isError):
          await _pause(pacing.beforeToolMin, pacing.beforeToolMax, cancel);
          if (cancel?.isCancelled ?? false) {
            break;
          }
          final id = '${script.id}-${toolCall++}';
          yield LoopToolCallStart(toolName: tool, toolUseId: id, args: args);
          await _pause(pacing.toolMin, pacing.toolMax, cancel);
          yield LoopToolCallResult(
            toolName: tool,
            toolUseId: id,
            result: isError
                ? HarnessToolResult.error(result)
                : HarnessToolResult.success(result),
          );
        case DemoUsageStep(
          :final inputTokens,
          :final outputTokens,
          :final cacheReadTokens,
          :final cacheWriteTokens,
          :final thoughtTokens,
        ):
          sawUsage = true;
          yield LoopUsage(
            LlmUsage(
              inputTokens: inputTokens,
              outputTokens: outputTokens,
              cacheReadTokens: cacheReadTokens,
              cacheWriteTokens: cacheWriteTokens,
              thoughtTokens: thoughtTokens,
            ),
          );
      }
    }

    // A script with no explicit usage still has to price: the run log's token
    // columns, the cost calculator and the cache-rate metric are all real code
    // paths, and a run that reports zero tokens reads as broken rather than
    // cheap. Synthesize something proportionate to what was actually streamed.
    if (!sawUsage) {
      final out = (spoken.length / 4).ceil().clamp(1, 1 << 20);
      yield LoopUsage(
        LlmUsage(
          inputTokens: 900 + out * 3,
          outputTokens: out,
          cacheReadTokens: 6400,
          cacheWriteTokens: 320,
        ),
      );
    }

    if (spoken.isNotEmpty) {
      history.add(HarnessMessage.assistant(spoken.toString()));
    }

    final cancelled = cancel?.isCancelled ?? false;
    yield LoopDone(
      cancelled ? LoopDoneReason.cancelled : LoopDoneReason.completed,
    );
  }

  /// Emits [text] in [chunk]-sized deltas built by [wrap], pausing [delay]
  /// between them and stopping early when [cancel] fires.
  Stream<AgentLoopEvent> _stream(
    String text,
    int chunk,
    Duration delay,
    CancellationToken? cancel,
    AgentLoopEvent Function(String) wrap,
  ) async* {
    for (var i = 0; i < text.length; i += chunk) {
      if (cancel?.isCancelled ?? false) {
        return;
      }
      yield wrap(text.substring(i, min(i + chunk, text.length)));
      if (delay > Duration.zero) {
        await Future<void>.delayed(delay);
      }
    }
  }

  /// Waits a jittered duration between [lo] and [hi], returning early on cancel.
  Future<void> _pause(Duration lo, Duration hi, CancellationToken? cancel) async {
    final span = hi.inMilliseconds - lo.inMilliseconds;
    final ms = lo.inMilliseconds + (span <= 0 ? 0 : _random.nextInt(span + 1));
    if (ms <= 0) {
      return;
    }
    final token = cancel;
    if (token == null) {
      await Future<void>.delayed(Duration(milliseconds: ms));
      return;
    }
    await Future.any([
      Future<void>.delayed(Duration(milliseconds: ms)),
      token.whenCancelled,
    ]);
  }
}
