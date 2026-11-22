import 'package:cc_domain/core/domain/value_objects/transcript_segment.dart';
import 'package:cc_domain/features/code_mode/domain/value_objects/script_call_site.dart';
import 'package:cc_domain/features/dispatch/domain/entities/agent_process_event.dart';
import 'package:cc_harness/context.dart';
import 'package:cc_harness/loop.dart';
import 'package:cc_harness/provider.dart';
import 'package:cc_harness/tools.dart';
import 'package:cc_harness_runtime/cc_harness_runtime.dart';
import 'package:cc_infra/src/context/snapcompact_compactor.dart';

/// Resolves the image references a tool result carries.
typedef HarnessToolImageRefs =
    Future<List<ToolImageRef>> Function(
      String toolName,
      HarnessToolResult result,
    );

// The pieces every host of an `AgentLoopRunner` assembles the same way.
//
// The session host, the subagent host and the evaluation backend each used to
// build their own compactor stack and their own `AgentLoopEvent` →
// `AgentProcessEvent` translation. The copies drifted (the subagent dropped
// the turn-discard event and loop error codes), so the shape is declared once
// here.

/// The shipped compactor stack: a model-written summary
/// ([LlmHarnessSummarizer] on [summaryProvider]) under the snapshot
/// compactor, priced with [providerId]'s cache economics.
///
/// [modelId] is the bare model id; the snapshot layer is handed the
/// provider-qualified form it sizes pages for. [readerHasVision] false makes
/// the snapshot layer a pass-through.
HarnessCompactor buildHarnessCompactor({
  required LlmProviderPort summaryProvider,
  required String providerId,
  required String modelId,
  required CompactionConfig config,
  required bool readerHasVision,
  required bool preferSnapshots,
  TokenCalibration? calibration,
  LlmCallPurpose purpose = LlmCallPurpose.main,
  String? retainedSnapshotSource,
  void Function(HarnessRewriteDecision decision)? onRewriteDecision,
}) => SnapcompactCompactor(
  fallback: buildHarnessTextCompactor(
    summaryProvider: summaryProvider,
    providerId: providerId,
    modelId: modelId,
    config: config,
    calibration: calibration,
    purpose: purpose,
    onRewriteDecision: onRewriteDecision,
  ),
  modelId: '$providerId/$modelId',
  readerHasVision: readerHasVision,
  providerId: providerId,
  retainedSource: retainedSnapshotSource,
  preferSnapshots: preferSnapshots,
  config: config,
);

/// The text-only layer of [buildHarnessCompactor], for a caller that measures it alone.
DefaultHarnessCompactor buildHarnessTextCompactor({
  required LlmProviderPort summaryProvider,
  required String providerId,
  required String modelId,
  required CompactionConfig config,
  TokenCalibration? calibration,
  LlmCallPurpose purpose = LlmCallPurpose.main,
  void Function(HarnessRewriteDecision decision)? onRewriteDecision,
}) => DefaultHarnessCompactor(
  summarizer: LlmHarnessSummarizer(summaryProvider),
  config: config,
  calibration: calibration,
  providerId: providerId,
  modelId: modelId,
  purpose: purpose,
  economics: CompactionEconomics(
    cache: ProviderCacheEconomics.forProvider(providerId),
  ),
  onRewriteDecision: onRewriteDecision,
);

/// The transcript event [event] contributes, or null when it contributes
/// none (usage, notices, compaction, the terminal events — each host
/// handles those itself).
///
/// Covers what every host records identically: streamed text and thinking,
/// the withdrawal of an abandoned attempt's deltas, tool calls, tool results
/// (with their images resolved through [imageRefs]) and loop errors.
///
/// A call a script made (through a tool's reentry) carries the id of the call
/// that ran the script as `parentToolCallId`, so every host's transcript can
/// fold it under that call instead of showing it as a call the model made.
Future<AgentProcessEvent?> harnessTranscriptEvent(
  AgentLoopEvent event, {
  required HarnessToolImageRefs imageRefs,
}) async => switch (event) {
  LoopTextDelta(:final text) => TextEvent(content: text),
  LoopThinkingDelta(:final thinking) => ThinkingEvent(content: thinking),
  LoopTurnDiscarded(:final text, :final thinking) => TextRetractedEvent(
    text: text,
    thinking: thinking,
  ),
  LoopToolCallStart(
    :final toolName,
    :final toolUseId,
    :final args,
    :final parentToolUseId,
    :final callSite,
  ) =>
    ToolCallEvent(
      toolName: toolName,
      toolCallId: toolUseId,
      inputs: args,
      parentToolCallId: parentToolUseId,
      // Out of range is dropped, never thrown: a site is only a hint.
      callSite: callSite == null
          ? null
          : ScriptCallSite.tryParse([callSite.line, callSite.column]),
    ),
  LoopToolCallResult(
    :final toolName,
    :final toolUseId,
    :final result,
    :final parentToolUseId,
  ) =>
    ToolResultEvent(
      toolCallId: toolUseId,
      outputs: result.content,
      toolName: toolName,
      isError: result.isError,
      // A script's call keeps no images: its row is a bounded preview
      // (NestedCallRows), and storing them would let a script write one
      // blob per call.
      images: parentToolUseId == null
          ? await imageRefs(toolName, result)
          : const [],
      parentToolCallId: parentToolUseId,
      outcome: result.outcome,
    ),
  LoopError(:final message, :final code) => ErrorEvent(
    content: message,
    code: code,
    source: 'harness',
  ),
  _ => null,
};
