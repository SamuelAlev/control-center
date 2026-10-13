import 'dart:async';

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

  test('a background task notification completes its recorded run', () async {
    final parser = ClaudeStreamJsonParser(
      ClaudeStreamJsonCallbacks(onSubagent: runs.onEvent),
    );
    parser
      ..process({
        'type': 'system',
        'subtype': 'task_started',
        'task_id': 'task-a',
        'tool_use_id': 'tu_a',
        'subagent_type': 'general-purpose',
      })
      ..process({
        'type': 'assistant',
        'parent_tool_use_id': 'tu_a',
        'message': {
          'content': [
            {'type': 'text', 'text': 'The change is implemented.'},
          ],
        },
      })
      ..process({
        'type': 'system',
        'subtype': 'task_notification',
        'task_id': 'task-a',
        'tool_use_id': 'tu_a',
        'status': 'completed',
        'summary': 'Implemented the change',
      });
    await settle();

    final row = logs.rows['run-1-sub-tu_a']!;
    expect(row.status, RunStatus.completed);
    expect(row.completedAt, isNotNull);
    expect(registry.isActive(row.id), isFalse);

    parser.process({
      'type': 'assistant',
      'parent_tool_use_id': 'tu_a',
      'message': {
        'content': [
          {'type': 'text', 'text': 'The change is implemented.'},
        ],
      },
    });
    await runs.closeAll();
    expect(logs.rows[row.id]!.status, RunStatus.completed);
    expect(registry.isActive(row.id), isFalse);
  });

  test('an async launch stays active until its task update ends it', () async {
    final parser = ClaudeStreamJsonParser(
      ClaudeStreamJsonCallbacks(
        onToolCall: runs.noteSpawnCall,
        onToolResult: (result) => unawaited(runs.complete(result)),
        onSubagent: runs.onEvent,
      ),
    );
    parser
      ..process({
        'type': 'stream_event',
        'event': {
          'type': 'content_block_start',
          'index': 0,
          'content_block': {'type': 'tool_use', 'id': 'tu_a', 'name': 'Agent'},
        },
      })
      ..process({
        'type': 'stream_event',
        'event': {'type': 'content_block_stop', 'index': 0},
      })
      ..process({
        'type': 'system',
        'subtype': 'task_started',
        'task_id': 'task-a',
        'tool_use_id': 'tu_a',
        'task_type': 'local_agent',
        'description': 'Background work',
      })
      ..process({
        'type': 'user',
        'tool_use_result': {'status': 'async_launched', 'agentId': 'task-a'},
        'message': {
          'content': [
            {
              'type': 'tool_result',
              'tool_use_id': 'tu_a',
              'content': 'Background agent launched.',
            },
          ],
        },
      });
    await settle();
    expect(logs.rows['run-1-sub-tu_a']!.status, RunStatus.running);
    expect(registry.isActive('run-1-sub-tu_a'), isTrue);

    parser.process({
      'type': 'system',
      'subtype': 'task_updated',
      'task_id': 'task-a',
      'patch': {'status': 'completed'},
    });
    // Parent shutdown must wait for an already-closing child's final writes.
    await runs.closeAll();
    expect(logs.rows['run-1-sub-tu_a']!.status, RunStatus.completed);
    expect(registry.isActive('run-1-sub-tu_a'), isFalse);
  });

  test('nested background results do not finish their child early', () async {
    final parser = ClaudeStreamJsonParser(
      ClaudeStreamJsonCallbacks(onSubagent: runs.onEvent),
    );
    parser
      ..process({
        'type': 'assistant',
        'parent_tool_use_id': 'tu_outer',
        'message': {
          'content': [
            {
              'type': 'tool_use',
              'id': 'tu_inner',
              'name': 'Agent',
              'input': {'description': 'Nested background work'},
            },
          ],
        },
      })
      ..process({
        'type': 'system',
        'subtype': 'task_started',
        'parent_tool_use_id': 'tu_outer',
        'task_id': 'inner',
        'tool_use_id': 'tu_inner',
        'task_type': 'local_agent',
      })
      ..process({
        'type': 'user',
        'parent_tool_use_id': 'tu_outer',
        'tool_use_result': {'status': 'async_launched', 'isAsync': true},
        'message': {
          'content': [
            {
              'type': 'tool_result',
              'tool_use_id': 'tu_inner',
              'content': 'Background agent launched.',
            },
          ],
        },
      });
    await settle();
    const innerId = 'run-1-sub-tu_inner';
    expect(logs.rows[innerId]!.status, RunStatus.running);
    expect(logs.rows[innerId]!.parentRunId, 'run-1-sub-tu_outer');
    parser.process({
      'type': 'system',
      'subtype': 'task_notification',
      'parent_tool_use_id': 'tu_outer',
      'task_id': 'inner',
      'status': 'completed',
    });
    await settle();
    expect(logs.rows[innerId]!.status, RunStatus.completed);
    expect(logs.rows['run-1-sub-tu_outer']!.status, RunStatus.running);
    await runs.closeAll();
  });

  test('a late notification cannot finish a resumed task run', () async {
    final parser = ClaudeStreamJsonParser(
      ClaudeStreamJsonCallbacks(onSubagent: runs.onEvent),
    );
    for (final (spawnId, runId) in [('tu_old', 'r1'), ('tu_new', 'r2')]) {
      parser.process({
        'type': 'system',
        'subtype': 'task_started',
        'task_id': 'reused-task',
        'tool_use_id': spawnId,
        'run_id': runId,
        'task_type': 'local_agent',
      });
      if (runId == 'r1') {
        await runs.complete(
          const ClaudeToolResult(id: 'tu_old', outputs: 'First run done.'),
        );
      }
    }
    parser.process({
      'type': 'system',
      'subtype': 'task_notification',
      'task_id': 'reused-task',
      'run_id': 'r1',
      'status': 'completed',
    });
    await settle();
    expect(logs.rows['run-1-sub-tu_new']!.status, RunStatus.running);

    parser.process({
      'type': 'system',
      'subtype': 'task_notification',
      'task_id': 'reused-task',
      'run_id': 'r2',
      'status': 'completed',
    });
    await runs.closeAll();
    expect(logs.rows['run-1-sub-tu_new']!.status, RunStatus.completed);
  });

  test('background shell lifecycle messages never create agent rows', () async {
    final parser = ClaudeStreamJsonParser(
      ClaudeStreamJsonCallbacks(onSubagent: runs.onEvent),
    );
    parser
      ..process({
        'type': 'system',
        'subtype': 'task_started',
        'task_id': 'shell',
        'tool_use_id': 'tu_bash',
        'task_type': 'local_bash',
      })
      ..process({
        'type': 'system',
        'subtype': 'task_notification',
        'task_id': 'shell',
        'tool_use_id': 'tu_bash',
        'status': 'completed',
      });
    await runs.closeAll();
    expect(logs.rows, isEmpty);
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

    for (final (status, outcome) in [
      ('failed', TurnOutcome.failed),
      ('stopped', TurnOutcome.interrupted),
    ]) {
      test('a $status background task records its terminal outcome', () async {
        final parser = ClaudeStreamJsonParser(
          ClaudeStreamJsonCallbacks(onSubagent: recorded.onEvent),
        );
        parser
          ..process({
            'type': 'system',
            'subtype': 'task_started',
            'task_id': 'task-a',
            'tool_use_id': 'tu_a',
            'task_type': 'local_agent',
          })
          ..process({
            'type': 'system',
            'subtype': 'task_notification',
            'task_id': 'task-a',
            'status': status,
          });
        await recorded.closeAll();
        expect(transcripts.outcomes['run-2-sub-tu_a'], outcome);
        expect(registry.isActive('run-2-sub-tu_a'), isFalse);
      });
    }

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
