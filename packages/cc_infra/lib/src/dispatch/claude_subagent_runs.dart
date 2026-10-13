import 'dart:async';

import 'package:cc_domain/core/domain/entities/agent_run_log.dart';
import 'package:cc_domain/core/domain/ports/media_render_port.dart';
import 'package:cc_domain/core/domain/repositories/agent_run_log_repository.dart';
import 'package:cc_domain/core/domain/value_objects/agent_run_role.dart';
import 'package:cc_domain/core/domain/value_objects/transcript_segment.dart';
import 'package:cc_domain/features/dispatch/domain/entities/agent_process_event.dart';
import 'package:cc_infra/src/blobs/blob_store.dart';
import 'package:cc_infra/src/dispatch/read_media_capture.dart';
import 'package:cc_infra/src/log/cc_infra_log.dart';
import 'package:cc_infra/src/messaging/run_transcript_recorder.dart';
import 'package:cc_infra/src/sandboxing/claude_stream_json.dart';

/// Records the subagents a `claude -p` run spawns as child runs.
///
/// The same shape the harness `task` tool writes: an [AgentRunLog] with
/// [AgentRunRole.sub], [AgentRunLog.parentRunId] and
/// [AgentRunLog.spawnToolCallId], plus a [RunTranscriptRecording] under the
/// child's id. That is all the space's AGENTS tree and the agent-activity tab
/// read, so a Claude subagent nests under its parent and opens like a harness
/// one. Nested spawns (a subagent's own `Agent` call) nest under that
/// subagent's row.
class ClaudeSubagentRuns {
  /// Creates a [ClaudeSubagentRuns] for the run [parentRunId].
  ClaudeSubagentRuns({
    required this.parentRunId,
    required this.workspaceId,
    required this.agentId,
    this.spaceId,
    this.conversationId,
    this.modelId,
    this.repo,
    this.recorder,
    this.workingDirectory,
    this.blobStore,
    this.mediaRenderer,
  });

  /// The `claude -p` run the subagents belong to.
  final String parentRunId;

  /// Owning workspace; scopes every row and recording.
  final String workspaceId;

  /// The agent running the parent; its subagents run as it.
  final String agentId;

  /// The space the parent runs in, so the rows reach its AGENTS tree.
  final String? spaceId;

  /// The parent's conversation.
  final String? conversationId;

  /// The parent's model; `claude` names a subagent's own only at the end.
  final String? modelId;

  /// Where child rows are written. Null records nothing.
  final AgentRunLogRepository? repo;

  /// Where child transcripts are recorded. Null records rows only.
  final RunTranscriptRecorder? recorder;

  /// Parent cwd for relative Read paths; absent when no file capture is wired.
  final String? workingDirectory;

  /// Workspace blob storage for successfully read media.
  final BlobStore? blobStore;

  /// Shared renderer for successfully read, unsupported image formats.
  final MediaRenderPort? mediaRenderer;

  final Map<String, _ChildRun> _children = {};
  final Set<String> _closedSpawns = {};
  final Set<Future<void>> _closing = {};

  /// Spawn call id → its description, from the call's input.
  final Map<String, String> _labels = {};

  /// Spawn call id → the child run that made it, for nested spawns.
  final Map<String, String> _spawnedBy = {};

  /// Whether [toolName] is Claude Code's subagent tool.
  static bool isSpawnTool(String toolName) =>
      toolName == 'Agent' || toolName == 'Task';

  /// Notes a spawn call so the child it starts gets its description as a
  /// label. [byRunId] is the child that made the call, when one did.
  void noteSpawnCall(ClaudeToolUse call, {String? byRunId}) {
    if (call.id.isEmpty || !isSpawnTool(call.name)) {
      return;
    }
    final input = call.input;
    final description = input is Map ? input['description'] : null;
    if (description is String && description.trim().isNotEmpty) {
      _labels[call.id] = description.trim();
    }
    if (byRunId != null) {
      _spawnedBy[call.id] = byRunId;
    }
  }

  /// Folds one subagent event into its child run, opening the run on first
  /// sight.
  void onEvent(ClaudeSubagentEvent event) {
    if (_closedSpawns.contains(event.spawnToolUseId)) {
      return;
    }
    if (event is ClaudeSubagentFinished) {
      unawaited(
        _finish(
          event.spawnToolUseId,
          status: event.status == ClaudeSubagentStatus.completed
              ? RunStatus.completed
              : RunStatus.error,
          outcome: switch (event.status) {
            ClaudeSubagentStatus.completed => TurnOutcome.completed,
            ClaudeSubagentStatus.failed => TurnOutcome.failed,
            ClaudeSubagentStatus.stopped => TurnOutcome.interrupted,
          },
          summary: event.summary,
        ),
      );
      return;
    }
    final child = _open(
      event.spawnToolUseId,
      label: event is ClaudeSubagentStarted ? event.description : null,
    );
    switch (event) {
      case ClaudeSubagentStarted() || ClaudeSubagentFinished():
        break;
      case ClaudeSubagentText(:final text):
        child.textSinceTool = true;
        child.record(TextEvent(content: text));
      case ClaudeSubagentThinking(:final text):
        child.record(ThinkingEvent(content: text));
      case ClaudeSubagentToolCall(:final call):
        noteSpawnCall(call, byRunId: child.runId);
        child.toolNames[call.id] = call.name;
        child.textSinceTool = false;
        final input = call.input;
        child.record(
          ToolCallEvent(
            toolName: call.name,
            toolCallId: call.id,
            inputs: input is Map ? input.cast<String, dynamic>() : null,
          ),
        );
      case ClaudeSubagentToolResult(:final result):
        child.record(
          ToolResultEvent(
            toolCallId: result.id,
            outputs: result.outputs,
            toolName: child.toolNames.remove(result.id),
            isError: result.isError,
            images: result.images,
          ),
        );
        // A nested subagent ends on its parent subagent's lane.
        unawaited(complete(result));
    }
  }

  /// Closes the child that the spawn call [result] answers, if one ran.
  ///
  /// A background-launch acknowledgement leaves the child open for its task
  /// lifecycle event. Foreground results append the final answer unless the
  /// child already ended on its own text.
  Future<void> complete(ClaudeToolResult result) async {
    if (result.isAsync && !result.isError) {
      return;
    }
    await _finish(
      result.id,
      status: result.isError ? RunStatus.error : RunStatus.completed,
      outcome: result.isError ? TurnOutcome.failed : TurnOutcome.completed,
      summary: result.outputs,
    );
  }

  Future<void> _finish(
    String spawnId, {
    required RunStatus status,
    required TurnOutcome outcome,
    String? summary,
  }) async {
    final child = _children.remove(spawnId);
    if (child == null) {
      return;
    }
    _closedSpawns.add(spawnId);
    final answer = summary?.trim();
    if (!child.textSinceTool && answer != null && answer.isNotEmpty) {
      child.record(TextEvent(content: answer));
    }
    final closing = child.close(
      status: status,
      outcome: outcome,
      summary: answer == null || answer.isEmpty ? null : answer,
    );
    _closing.add(closing);
    try {
      await closing;
    } finally {
      _closing.remove(closing);
    }
  }

  /// Closes every child still open — the parent process ended, or was
  /// stopped, before their spawn calls returned.
  Future<void> closeAll() async {
    final open = [..._children.values];
    _closedSpawns.addAll(_children.keys);
    _children.clear();
    await Future.wait([
      ..._closing,
      for (final child in open)
        child.close(status: RunStatus.error, outcome: TurnOutcome.interrupted),
    ]);
  }

  _ChildRun _open(String spawnId, {String? label}) {
    final existing = _children[spawnId];
    if (existing != null) {
      return existing;
    }
    final runId = '$parentRunId-sub-$spawnId';
    final startedAt = DateTime.now();
    final child = _ChildRun(
      runId: runId,
      recording: recorder?.begin(
        runId: runId,
        workspaceId: workspaceId,
        startedAt: startedAt,
      ),
      repo: repo,
      workingDirectory: workingDirectory,
      workspaceId: workspaceId,
      mediaRenderer: mediaRenderer,
      agentId: agentId,
      spaceId: spaceId,
      conversationId: conversationId,
      blobStore: blobStore,
      row: AgentRunLog(
        id: runId,
        agentId: agentId,
        workspaceId: workspaceId,
        spaceId: spaceId,
        conversationId: conversationId,
        startedAt: startedAt,
        status: RunStatus.running,
        summary: _labels[spawnId] ?? label,
        adapter: 'claude',
        modelId: modelId,
        role: AgentRunRole.sub,
        parentRunId: _spawnedBy[spawnId] ?? parentRunId,
        spawnToolCallId: spawnId,
      ),
    );
    _children[spawnId] = child;
    child.write(child.row);
    return child;
  }
}

class _ChildRun {
  _ChildRun({
    required this.runId,
    required this.recording,
    required this.repo,
    required this.row,
    required String? workingDirectory,
    required String workspaceId,
    required BlobStore? blobStore,
    required MediaRenderPort? mediaRenderer,
    required String agentId,
    required String? spaceId,
    required String? conversationId,
  }) : media = ReadMediaCapture(
         emit: (event) => recording?.add(event),
         workingDirectory: workingDirectory ?? '',
         workspaceId: workspaceId,
         store: workingDirectory == null ? null : blobStore,
         renderer: mediaRenderer,
         agentId: agentId,
         spaceId: spaceId,
         conversationId: conversationId,
       );

  final String runId;
  final RunTranscriptRecording? recording;
  final AgentRunLogRepository? repo;
  AgentRunLog row;
  final ReadMediaCapture media;

  /// Tool name per open call: a result names only the id it answers.
  final Map<String, String> toolNames = {};

  /// Whether the transcript currently ends on the child's own text.
  bool textSinceTool = false;

  /// Row writes, chained so the completion can never land before the start.
  Future<void> _writes = Future.value();

  void record(AgentProcessEvent event) => media.add(event);

  void write(AgentRunLog next) {
    row = next;
    final repo = this.repo;
    if (repo == null) {
      return;
    }
    _writes = _writes.then((_) async {
      try {
        await repo.upsert(next);
      } catch (e) {
        CcInfraLog.warning('Failed to write Claude subagent run "$runId": $e');
      }
    });
  }

  Future<void> close({
    required RunStatus status,
    required TurnOutcome outcome,
    String? summary,
  }) async {
    await media.drained;
    await recording?.finish(outcome);
    write(
      row.copyWith(
        status: status,
        completedAt: DateTime.now(),
        summary: summary == null ? null : _clip(summary, 2000),
      ),
    );
    await _writes;
  }

  static String _clip(String text, int max) =>
      text.length <= max ? text : '${text.substring(0, max - 1)}…';
}
