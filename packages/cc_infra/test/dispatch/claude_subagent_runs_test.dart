import 'package:cc_domain/core/domain/entities/agent_run_log.dart';
import 'package:cc_domain/core/domain/repositories/agent_run_log_repository.dart';
import 'package:cc_domain/core/domain/repositories/run_transcript_repository.dart';
import 'package:cc_domain/core/domain/value_objects/agent_run_role.dart';
import 'package:cc_domain/core/domain/value_objects/transcript_segment.dart';
import 'package:cc_infra/src/dispatch/claude_subagent_runs.dart';
import 'package:cc_infra/src/messaging/active_stream_registry.dart';
import 'package:cc_infra/src/messaging/run_transcript_recorder.dart';
import 'package:cc_infra/src/sandboxing/claude_stream_json.dart';
import 'package:test/test.dart';

/// Keeps the latest row per id, in write order.
class _RunLogs implements AgentRunLogRepository {
  final rows = <String, AgentRunLog>{};

  @override
  Future<void> upsert(AgentRunLog log) async => rows[log.id] = log;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Keeps each run's final transcript write.
class _Transcripts implements RunTranscriptRepository {
  final finalSegments = <String, List<Map<String, dynamic>>>{};
  final outcomes = <String, TurnOutcome?>{};

  @override
  Future<void> upsert({
    required String runId,
    required String workspaceId,
    required List<Map<String, dynamic>> segmentsJson,
    required int transcriptChars,
    required DateTime startedAt,
    required DateTime updatedAt,
    TurnOutcome? outcome,
    bool complete = false,
  }) async {
    if (complete) {
      finalSegments[runId] = segmentsJson;
      outcomes[runId] = outcome;
    }
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late _RunLogs logs;
  late ActiveStreamRegistry registry;
  late ClaudeSubagentRuns runs;

  setUp(() {
    logs = _RunLogs();
    registry = ActiveStreamRegistry();
    runs = ClaudeSubagentRuns(
      parentRunId: 'run-1',
      workspaceId: 'ws-1',
      agentId: 'engineer',
      spaceId: 'space-1',
      conversationId: 'conv-1',
      modelId: 'sonnet',
      repo: logs,
      recorder: RunTranscriptRecorder(registry: registry),
    );
  });

  Future<void> settle() => Future<void>.delayed(Duration.zero);

  test('a spawned subagent becomes a child run in the parent space', () async {
    runs
      ..noteSpawnCall(
        const ClaudeToolUse(
          id: 'tu_a',
          name: 'Agent',
          input: {'description': 'Survey the API', 'prompt': '…'},
        ),
      )
      ..onEvent(const ClaudeSubagentStarted('tu_a'));
    await settle();

    final row = logs.rows['run-1-sub-tu_a']!;
    expect(row.role, AgentRunRole.sub);
    expect(row.parentRunId, 'run-1');
    expect(row.spawnToolCallId, 'tu_a');
    expect(row.spaceId, 'space-1');
    expect(row.conversationId, 'conv-1');
    expect(row.agentId, 'engineer');
    expect(row.status, RunStatus.running);
    expect(row.summary, 'Survey the API');
    expect(registry.isActive(row.id), isTrue);
  });

  test('its result closes it and ends the transcript on the answer', () async {
    runs
      ..onEvent(const ClaudeSubagentStarted('tu_a', description: 'Look'))
      ..onEvent(
        const ClaudeSubagentToolCall(
          'tu_a',
          ClaudeToolUse(id: 'tu_ls', name: 'Bash', input: {'command': 'ls'}),
        ),
      )
      ..onEvent(
        const ClaudeSubagentToolResult(
          'tu_a',
          ClaudeToolResult(id: 'tu_ls', outputs: 'a.txt'),
        ),
      );
    await runs.complete(
      const ClaudeToolResult(id: 'tu_a', outputs: 'One file: a.txt'),
    );

    final row = logs.rows['run-1-sub-tu_a']!;
    expect(row.status, RunStatus.completed);
    expect(row.completedAt, isNotNull);
    expect(row.summary, 'One file: a.txt');
    expect(registry.isActive(row.id), isFalse);
  });

  test('a failed spawn call marks the child failed', () async {
    runs.onEvent(const ClaudeSubagentStarted('tu_a'));
    await runs.complete(
      const ClaudeToolResult(id: 'tu_a', outputs: 'boom', isError: true),
    );
    expect(logs.rows['run-1-sub-tu_a']!.status, RunStatus.error);
  });

  test('a result for some other tool is ignored', () async {
    await runs.complete(const ClaudeToolResult(id: 'tu_bash', outputs: 'ok'));
    expect(logs.rows, isEmpty);
  });

  test('a subagent spawned by a subagent nests under it', () async {
    runs
      ..onEvent(const ClaudeSubagentStarted('tu_outer'))
      ..onEvent(
        const ClaudeSubagentToolCall(
          'tu_outer',
          ClaudeToolUse(
            id: 'tu_inner',
            name: 'Agent',
            input: {'description': 'Dig deeper'},
          ),
        ),
      )
      ..onEvent(const ClaudeSubagentStarted('tu_inner'))
      // The inner one ends on the outer one's lane.
      ..onEvent(
        const ClaudeSubagentToolResult(
          'tu_outer',
          ClaudeToolResult(id: 'tu_inner', outputs: 'found it'),
        ),
      );
    await settle();
    await settle();

    final inner = logs.rows['run-1-sub-tu_inner']!;
    expect(inner.parentRunId, 'run-1-sub-tu_outer');
    expect(inner.summary, 'found it');
    expect(inner.status, RunStatus.completed);
    expect(logs.rows['run-1-sub-tu_outer']!.status, RunStatus.running);
  });

  test('closeAll interrupts what never returned', () async {
    runs.onEvent(const ClaudeSubagentStarted('tu_a'));
    await runs.closeAll();
    final row = logs.rows['run-1-sub-tu_a']!;
    expect(row.status, RunStatus.error);
    expect(registry.isActive(row.id), isFalse);
  });

  group('transcript', () {
    late _Transcripts transcripts;
    late ClaudeSubagentRuns recorded;

    setUp(() {
      transcripts = _Transcripts();
      recorded = ClaudeSubagentRuns(
        parentRunId: 'run-2',
        workspaceId: 'ws-1',
        agentId: 'engineer',
        recorder: RunTranscriptRecorder(registry: registry, repo: transcripts),
      );
    });

    List<String?> kinds() => [
      for (final seg in transcripts.finalSegments['run-2-sub-tu_a']!)
        seg['type'] as String?,
    ];

    test('keeps its own last words instead of repeating the result', () async {
      recorded
        ..onEvent(const ClaudeSubagentThinking('tu_a', 'plan'))
        ..onEvent(const ClaudeSubagentText('tu_a', 'done'));
      await recorded.complete(
        const ClaudeToolResult(id: 'tu_a', outputs: 'done'),
      );
      final texts = [
        for (final seg in transcripts.finalSegments['run-2-sub-tu_a']!)
          if (seg['type'] == 'text') seg['text'],
      ];
      expect(texts, ['done']);
    });

    test('ends on the spawn result when it stopped on a tool', () async {
      recorded
        ..onEvent(
          const ClaudeSubagentToolCall(
            'tu_a',
            ClaudeToolUse(id: 'tu_ls', name: 'Bash', input: {'command': 'ls'}),
          ),
        )
        ..onEvent(
          const ClaudeSubagentToolResult(
            'tu_a',
            ClaudeToolResult(id: 'tu_ls', outputs: 'a.txt'),
          ),
        );
      await recorded.complete(
        const ClaudeToolResult(id: 'tu_a', outputs: 'One file'),
      );
      expect(kinds().last, 'text');
      expect(transcripts.outcomes['run-2-sub-tu_a'], TurnOutcome.completed);
    });
  });
}
