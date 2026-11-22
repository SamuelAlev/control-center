import 'dart:convert';

import 'package:cc_domain/cc_domain.dart' show ValidationException;
import 'package:cc_domain/core/domain/repositories/workspace_repository.dart'
    show DeletedWorkspaceException;
import 'package:cc_domain/features/code_mode/domain/entities/code_execution.dart';
import 'package:cc_domain/features/code_mode/domain/entities/code_execution_call.dart';
import 'package:cc_domain/features/code_mode/domain/ports/code_execution_repository.dart';
import 'package:cc_domain/features/code_mode/domain/value_objects/code_execution_status.dart';
import 'package:cc_domain/features/code_mode/domain/value_objects/code_mode_limits.dart';
import 'package:cc_domain/features/code_mode/domain/value_objects/code_mode_store_write.dart';
import 'package:cc_domain/features/code_mode/domain/value_objects/script_call_site.dart';
import 'package:cc_persistence/cc_persistence.dart';
import 'package:cc_persistence/mappers/code_execution_mapper.dart';
import 'package:test/test.dart';

import 'helpers/seed_agents.dart' as seed;
import 'helpers/seed_platform.dart';
import 'helpers/test_database.dart';

/// The code-mode audit record and stored values against real per-workspace
/// databases: round trips, paging, cascades, the stored-value caps and
/// workspace isolation.
void main() {
  late GlobalDatabase global;
  late WorkspaceDatabaseManager dbs;
  late DaoCodeExecutionRepository executions;
  late DaoCodeModeStoreRepository store;

  final t0 = DateTime.utc(2026, 11, 17, 9, 30, 15, 250);

  setUp(() async {
    global = createTestGlobalDatabase();
    dbs = createTestWorkspaceDatabases(global: global);
    for (final workspaceId in ['ws-a', 'ws-b']) {
      await seedWorkspaceRow(global, workspaceId);
      final db = dbs.of(workspaceId);
      await seed.seedRunLog(db, 'run-1', agentId: 'agent-1');
      await seed.seedRunLog(db, 'run-2', agentId: 'agent-2');
      await seed.seedConversation(db, 'conv-1', spaceId: 'space-1');
      await seed.seedConversation(db, 'conv-2', spaceId: 'space-2');
    }
    executions = DaoCodeExecutionRepository(dbs);
    store = DaoCodeModeStoreRepository(dbs);
  });

  tearDown(() async {
    await dbs.closeAll();
    await global.close();
  });

  /// The record id of the execution a test calls [name]: the `repl` call
  /// `call-<name>` of [runId].
  String idOf(String name, {String runId = 'run-1'}) =>
      CodeExecution.idFor(runId: runId, toolCallId: 'call-$name');

  /// Execution [name] as it is admitted: running, with nothing measured.
  CodeExecution admitted(
    String name, {
    String runId = 'run-1',
    String? id,
    DateTime? startedAt,
    CodeExecutionSurface surface = CodeExecutionSurface.harness,
    String? conversationId = 'conv-1',
    String? agentId = 'agent-1',
    String? spaceId = 'space-1',
    String description = 'Count the failing tests',
    CodeModeLimits? limits,
  }) => CodeExecution(
    id: id ?? idOf(name, runId: runId),
    runId: runId,
    toolCallId: 'call-$name',
    surface: surface,
    startedAt: startedAt ?? t0,
    durationMs: 0,
    status: CodeExecutionStatus.running,
    sourceHash: 'ab' * 32,
    sourceBytes: 42,
    limits: limits ?? CodeModeLimits(),
    conversationId: conversationId,
    agentId: agentId,
    spaceId: spaceId,
    description: description,
  );

  /// [running] as it ended with [status].
  CodeExecution ended(
    CodeExecution running, {
    CodeExecutionStatus status = CodeExecutionStatus.completed,
    NestedCallCounts? callCounts,
    Map<String, dynamic>? lockdown,
  }) => running.ended(
    status: status,
    durationMs: 1200,
    errorKind: status == CodeExecutionStatus.completed
        ? null
        : CodeExecutionErrorKind.scriptError,
    cpuMs: 30,
    peakHeapBytes: 4096,
    callCounts: callCounts,
    questionCount: 1,
    outputBytes: 77,
    outputTruncated: true,
    engineVersion: 'quickjs-ng 0.10.1',
    lockdown: lockdown,
  );

  const source =
      'const r = await tools.search({query: "x"});\nreturn r.length;';

  CodeExecutionPayload payload(String id, {String? errorName}) =>
      CodeExecutionPayload(
        executionId: id,
        source: source,
        output: '3',
        console: 'info: started',
        errorName: errorName,
      );

  CodeExecutionCall call(
    String executionId,
    int sequence, {
    NestedCallStatus status = NestedCallStatus.completed,
    NestedCallGateDecision? gateDecision = NestedCallGateDecision.allowed,
    String? error,
    ScriptCallSite? site,
  }) => CodeExecutionCall(
    executionId: executionId,
    sequence: sequence,
    toolCallId: CodeExecutionCall.nestedToolCallId(
      'call-$executionId',
      sequence,
    ),
    toolName: 'search',
    startOffsetMs: 10 * sequence,
    durationMs: 5,
    status: status,
    gateDecision: gateDecision,
    approvalWaitMs: sequence == 2 ? 400 : 0,
    argumentBytes: 20,
    resultBytes: 300,
    argumentsJson: '{"query":"x","token":"[redacted]"}',
    error: error,
    site: site,
  );

  Future<void> begin(CodeExecution running, {String workspaceId = 'ws-a'}) =>
      executions.begin(workspaceId, running, source: source);

  Future<CodeExecutionFinishResult> finish(
    CodeExecution done, {
    String workspaceId = 'ws-a',
    List<CodeExecutionCall> calls = const [],
    String? errorName,
  }) => executions.finish(
    workspaceId,
    done,
    payload: payload(done.id, errorName: errorName),
    calls: calls,
  );

  /// Records execution [name] from admission to its end in one go.
  Future<CodeExecution> record(
    String name, {
    String workspaceId = 'ws-a',
    String runId = 'run-1',
    DateTime? startedAt,
    CodeExecutionStatus status = CodeExecutionStatus.completed,
    CodeExecutionSurface surface = CodeExecutionSurface.harness,
    String? conversationId = 'conv-1',
    String? agentId = 'agent-1',
    String? spaceId = 'space-1',
    List<CodeExecutionCall> calls = const [],
  }) async {
    final running = admitted(
      name,
      runId: runId,
      startedAt: startedAt,
      surface: surface,
      conversationId: conversationId,
      agentId: agentId,
      spaceId: spaceId,
    );
    await begin(running, workspaceId: workspaceId);
    final done = ended(running, status: status);
    await finish(done, workspaceId: workspaceId, calls: calls);
    return done;
  }

  Future<int> count(String workspaceId, String table) async {
    final row = await dbs
        .of(workspaceId)
        .customSelect('SELECT COUNT(*) AS n FROM $table')
        .getSingle();
    return row.read<int>('n');
  }

  Future<Map<String, String>> read({
    String workspaceId = 'ws-a',
    String conversationId = 'conv-1',
    String agentId = 'agent-1',
  }) => store.readAll(
    workspaceId,
    conversationId: conversationId,
    agentId: agentId,
  );

  Future<void> commit(
    List<CodeModeStoreWrite> writes, {
    String workspaceId = 'ws-a',
    String conversationId = 'conv-1',
    String agentId = 'agent-1',
  }) => store.commit(
    workspaceId,
    conversationId: conversationId,
    agentId: agentId,
    writes: writes,
  );

  CodeModeStoreWrite put(String key, Object? value) =>
      CodeModeStoreWrite(key: key, valueJson: jsonEncode(value));

  CodeModeStoreWrite drop(String key) => CodeModeStoreWrite(key: key);

  String sized(int bytes) => 'x' * bytes;

  group('begin, append and finish', () {
    test('round trips the execution, its payload and its calls', () async {
      final id = idOf('a');
      final running = admitted(
        'a',
        limits: CodeModeLimits(wallClockMs: 60000, maxOutputTokens: 2000),
      );
      await begin(running);

      final begun = await executions.get('ws-a', id);
      expect(begun!.execution, running);
      expect(begun.execution.startedAt, t0, reason: 'millisecond resolution');
      expect(
        begun.payload,
        CodeExecutionPayload(executionId: id, source: source),
      );
      expect(begun.calls, isEmpty);

      final calls = [
        call(
          id,
          1,
          status: NestedCallStatus.denied,
          gateDecision: NestedCallGateDecision.denied,
          error: 'Refused by policy',
        ),
        call(
          id,
          2,
          gateDecision: NestedCallGateDecision.approved,
          site: ScriptCallSite(4, 17),
        ),
        call(
          id,
          3,
          status: NestedCallStatus.unknownTool,
          gateDecision: null,
          site: ScriptCallSite(9, 3),
        ),
      ];
      expect(
        await executions.appendCall('ws-a', calls[1]),
        CodeExecutionAppendOutcome.appended,
      );
      expect(
        await executions.appendCall('ws-a', calls[0]),
        CodeExecutionAppendOutcome.appended,
      );
      expect((await executions.get('ws-a', id))!.calls, [calls[0], calls[1]]);

      final done = ended(
        running,
        status: CodeExecutionStatus.failed,
        callCounts: NestedCallCounts.of(calls),
        lockdown: const {
          'level': 'full',
          'details': ['seccomp', 'no_new_privs'],
        },
      );
      expect(
        await finish(done, calls: [calls[2]], errorName: 'TypeError'),
        CodeExecutionFinishResult.finished,
      );

      final detail = await executions.get('ws-a', id);
      expect(detail!.execution, done);
      expect(detail.payload, payload(id, errorName: 'TypeError'));
      expect(detail.calls, calls);
    });

    test(
      'an execution without a lockdown or optional ids round trips',
      () async {
        final done = await record(
          'bare',
          conversationId: null,
          agentId: null,
          spaceId: null,
          status: CodeExecutionStatus.sandboxError,
        );

        expect((await executions.get('ws-a', done.id))!.execution, done);
      },
    );

    test('only a running execution begins', () async {
      final running = admitted('a');
      await expectLater(
        executions.begin('ws-a', ended(running), source: source),
        throwsArgumentError,
      );
      expect(await count('ws-a', 'code_executions'), 0);
    });

    test('an execution whose run has no run log is refused whole', () async {
      await expectLater(
        begin(admitted('a', runId: 'dispatch-only')),
        throwsA(
          isA<CodeExecutionBeginRefused>().having(
            (e) => e.reason,
            'reason',
            CodeExecutionBeginRefusal.noRun,
          ),
        ),
      );
      expect(await count('ws-a', 'code_executions'), 0);
      expect(await count('ws-a', 'code_execution_payloads'), 0);
    });

    test('a recorded id is never begun again', () async {
      // A tool call id can repeat in a run, and an MCP caller chooses its
      // own: a second begin under the same id must not touch the first.
      final first = await record('a', calls: [call(idOf('a'), 1)]);
      final before = await executions.get('ws-a', first.id);

      await expectLater(
        begin(admitted('a', description: 'Something else')),
        throwsA(
          isA<CodeExecutionBeginRefused>().having(
            (e) => e.reason,
            'reason',
            CodeExecutionBeginRefusal.idTaken,
          ),
        ),
      );

      final after = await executions.get('ws-a', first.id);
      expect(after!.execution, before!.execution);
      expect(after.payload, before.payload);
      expect(after.calls, before.calls);
      expect(await count('ws-a', 'code_executions'), 1);
    });

    test('a conversation or agent already gone is recorded as none', () async {
      final running = admitted(
        'a',
        conversationId: 'conv-gone',
        agentId: 'agent-gone',
      );
      await begin(running);

      final kept = (await executions.get('ws-a', running.id))!.execution;
      expect(kept.conversationId, isNull);
      expect(kept.agentId, isNull);
      expect(kept.spaceId, 'space-1');
      expect(kept.status, CodeExecutionStatus.running);
    });

    test('a space deleted before the script was admitted refuses the record: '
        'nothing is written that every member could read', () async {
      // The run's space is deleted while the run goes on, then its model
      // calls repl.
      await dbs
          .of('ws-a')
          .customStatement("DELETE FROM spaces WHERE id = 'space-1'");
      final running = admitted('a', conversationId: null);

      await expectLater(
        begin(running),
        throwsA(
          isA<CodeExecutionBeginRefused>().having(
            (e) => e.reason,
            'reason',
            CodeExecutionBeginRefusal.spaceGone,
          ),
        ),
      );
      expect(await executions.get('ws-a', running.id), isNull);
      expect(await count('ws-a', 'code_executions'), 0);
      expect(await count('ws-a', 'code_execution_payloads'), 0);
      final page = await executions.list(
        'ws-a',
        CodeExecutionQuery(hiddenSpaceIds: const {'space-1'}),
      );
      expect(page.items, isEmpty);
      // A run that truly has no space still records with none.
      final spaceless = admitted('b', conversationId: null, spaceId: null);
      await begin(spaceless);
      expect(
        (await executions.get('ws-a', spaceless.id))!.execution.spaceId,
        isNull,
      );
    });

    test('a call appended while the finish was on its way is kept, and the '
        'finish still ends the record', () async {
      final running = admitted('a');
      await begin(running);
      // The finish was built with call 1 unsettled; the call's own append
      // landed first with how it really ended.
      expect(
        await executions.appendCall('ws-a', call(running.id, 1)),
        CodeExecutionAppendOutcome.appended,
      );
      expect(
        await finish(
          ended(running),
          calls: [
            call(
              running.id,
              1,
              status: NestedCallStatus.cancelled,
              error: 'did not settle',
            ),
            call(running.id, 2),
          ],
        ),
        CodeExecutionFinishResult.finished,
      );
      final kept = (await executions.get('ws-a', running.id))!;
      expect(kept.execution.status, CodeExecutionStatus.completed);
      expect(kept.calls.map((c) => (c.sequence, c.status)), [
        (1, NestedCallStatus.completed),
        (2, NestedCallStatus.completed),
      ]);
    });

    test(
      'close ends a running record with the least it can write, once',
      () async {
        final running = admitted('a');
        await begin(running);
        await executions.appendCall('ws-a', call(running.id, 1));
        Future<bool> close() => executions.close(
          'ws-a',
          running.id,
          status: CodeExecutionStatus.sandboxError,
          errorKind: CodeExecutionErrorKind.hostError,
          durationMs: 900,
        );

        expect(await close(), isTrue);
        final kept = (await executions.get('ws-a', running.id))!;
        expect(kept.execution.status, CodeExecutionStatus.sandboxError);
        expect(kept.execution.errorKind, CodeExecutionErrorKind.hostError);
        expect(kept.execution.durationMs, 900);
        expect(kept.calls, hasLength(1));
        expect(kept.payload!.source, source);
        expect(
          await close(),
          isFalse,
          reason: 'a finished record never changes',
        );
        expect(
          () => executions.close(
            'ws-a',
            running.id,
            status: CodeExecutionStatus.running,
            errorKind: CodeExecutionErrorKind.hostError,
            durationMs: 1,
          ),
          throwsArgumentError,
        );
      },
    );

    test('a finished record never changes', () async {
      final running = admitted('a');
      await begin(running);
      final done = ended(running);
      await finish(done, calls: [call(running.id, 1)]);
      final before = await executions.get('ws-a', running.id);

      await expectLater(
        finish(
          ended(running, status: CodeExecutionStatus.failed),
          calls: [call(running.id, 2)],
        ),
        throwsStateError,
      );
      expect(
        await executions.appendCall('ws-a', call(running.id, 3)),
        CodeExecutionAppendOutcome.notRunning,
      );

      final after = await executions.get('ws-a', running.id);
      expect(after!.execution, before!.execution);
      expect(after.payload, before.payload);
      expect(after.calls, before.calls);
    });

    test('a call row is written once', () async {
      final running = admitted('a');
      await begin(running);
      await executions.appendCall('ws-a', call(running.id, 1));

      expect(
        await executions.appendCall(
          'ws-a',
          call(running.id, 1, status: NestedCallStatus.failed),
        ),
        CodeExecutionAppendOutcome.sequenceTaken,
      );
      expect(
        (await executions.get('ws-a', running.id))!.calls.single.status,
        NestedCallStatus.completed,
      );
      expect(
        await executions.appendCall('ws-a', call(idOf('unknown'), 1)),
        CodeExecutionAppendOutcome.notRunning,
      );
    });

    test('a finish that names another execution changes nothing', () async {
      final running = admitted('a');
      await begin(running);
      final done = ended(running);
      final other = idOf('b');

      await expectLater(
        executions.finish(
          'ws-a',
          done,
          payload: payload(other),
          calls: const [],
        ),
        throwsArgumentError,
      );
      await expectLater(
        finish(done, calls: [call(other, 1)]),
        throwsArgumentError,
      );
      await expectLater(
        finish(done, calls: [call(running.id, 1), call(running.id, 1)]),
        throwsArgumentError,
      );
      await expectLater(
        executions.finish(
          'ws-a',
          running,
          payload: payload(running.id),
          calls: const [],
        ),
        throwsArgumentError,
      );
      final kept = await executions.get('ws-a', running.id);
      expect(kept!.execution, running);
      expect(kept.calls, isEmpty);
    });

    test('a call that breaks a check rolls back the whole finish', () async {
      final running = admitted('a');
      await begin(running);
      const mapper = CodeExecutionMapper();
      final bad = mapper
          .callToCompanion(call(running.id, 1))
          .copyWith(status: const Value('bogus'));

      await expectLater(
        dbs
            .of('ws-a')
            .codeModeDao
            .finishExecution(
              id: running.id,
              terminal: mapper.terminalCompanion(ended(running)),
              output: 'out',
              console: '',
              errorName: null,
              calls: [bad],
            ),
        throwsA(anything),
      );
      final kept = await executions.get('ws-a', running.id);
      expect(kept!.execution.status, CodeExecutionStatus.running);
      expect(kept.payload!.output, isEmpty);
    });

    test(
      'a conversation and agent deleted mid-run do not fail the finish',
      () async {
        // The agent is not the run's: deleting the run's agent deletes the
        // run, and the record with it.
        final db = dbs.of('ws-a');
        await seed.seedAgent(db, 'agent-x');
        final running = admitted('a', agentId: 'agent-x');
        await begin(running);
        await db.customStatement(
          "DELETE FROM conversations WHERE id = 'conv-1'",
        );
        await db.customStatement("DELETE FROM agents WHERE id = 'agent-x'");

        expect(
          await finish(ended(running)),
          CodeExecutionFinishResult.finished,
        );
        final kept = (await executions.get('ws-a', running.id))!.execution;
        expect(kept.status, CodeExecutionStatus.completed);
        expect(kept.conversationId, isNull);
        expect(kept.agentId, isNull);
        expect(kept.spaceId, 'space-1');
      },
    );

    test('a record deleted with its run mid-script finishes as gone', () async {
      final running = admitted('a');
      await begin(running);
      await dbs
          .of('ws-a')
          .customStatement("DELETE FROM agent_run_logs WHERE id = 'run-1'");

      expect(
        await executions.appendCall('ws-a', call(running.id, 1)),
        CodeExecutionAppendOutcome.notRunning,
      );
      expect(await finish(ended(running)), CodeExecutionFinishResult.gone);
      expect(await count('ws-a', 'code_executions'), 0);
      expect(await count('ws-a', 'code_execution_calls'), 0);
    });

    test('a finish keeps what begin recorded', () async {
      final running = admitted('a');
      await begin(running);
      final relabelled = ended(
        admitted(
          'a',
          description: 'Something else',
          conversationId: 'conv-2',
          spaceId: 'space-2',
          startedAt: t0.add(const Duration(hours: 1)),
        ),
      );

      await finish(relabelled);
      final kept = (await executions.get('ws-a', running.id))!.execution;
      expect(kept.description, running.description);
      expect(kept.conversationId, 'conv-1');
      expect(kept.spaceId, 'space-1');
      expect(kept.startedAt, t0);
      expect(kept.status, CodeExecutionStatus.completed);
    });

    test('get answers null for an unknown id', () async {
      expect(await executions.get('ws-a', 'nope'), isNull);
    });
  });

  group('id suffixes', () {
    test('the highest suffix of a repl call is one read', () async {
      Future<int> highest(String name) => executions.highestIdSuffix(
        'ws-a',
        runId: 'run-1',
        toolCallId: 'call-$name',
      );

      expect(await highest('a'), 0);
      await begin(admitted('a'));
      expect(await highest('a'), 1);
      await begin(admitted('a', id: '${idOf('a')}#3'));
      await begin(admitted('a', id: '${idOf('a')}#2'));
      expect(await highest('a'), 3);
      expect(await highest('b'), 0);
      expect(
        await executions.highestIdSuffix(
          'ws-a',
          runId: 'run-2',
          toolCallId: 'call-a',
        ),
        0,
      );
    });

    test('an id that is not its run and call is refused', () async {
      expect(
        () => begin(admitted('a', id: 'run-1/call-b')),
        throwsArgumentError,
      );
      expect(
        () => begin(admitted('a', id: '${idOf('a')}#1')),
        throwsArgumentError,
      );
      expect(await count('ws-a', 'code_executions'), 0);
    });
  });

  group('boot sweep', () {
    test('finishes every record left running, whatever its start time, and '
        'nothing finished', () async {
      final old = admitted('old');
      await begin(old);
      final done = await record('done', startedAt: t0);
      final fresh = admitted(
        'fresh',
        startedAt: t0.add(const Duration(minutes: 10)),
      );
      await begin(fresh);

      // Started "after" the boot by a clock that stepped back: still a row
      // no live script owns, since the sweep runs before any is admitted.
      final swept = await dbs
          .of('ws-a')
          .codeModeDao
          .finishAllRunning(
            nowMs: t0.add(const Duration(seconds: 90)).millisecondsSinceEpoch,
            status: CodeExecutionStatus.sandboxError.wire,
            errorKind: CodeExecutionErrorKind.serverStopped,
          );

      expect(swept, 2);
      final ended = (await executions.get('ws-a', old.id))!.execution;
      expect(ended.status, CodeExecutionStatus.sandboxError);
      expect(ended.errorKind, CodeExecutionErrorKind.serverStopped);
      expect(ended.durationMs, 90000);
      expect((await executions.get('ws-a', done.id))!.execution, done);
      final stepped = (await executions.get('ws-a', fresh.id))!.execution;
      expect(stepped.status, CodeExecutionStatus.sandboxError);
      expect(stepped.durationMs, 0);
      expect(
        await executions.appendCall('ws-a', call(old.id, 1)),
        CodeExecutionAppendOutcome.notRunning,
        reason: 'a swept record is finished',
      );
    });
  });

  group('list', () {
    Future<void> seedTen() async {
      for (var i = 0; i < 10; i++) {
        await record(
          'ex-$i',
          // Three executions share a millisecond: the id breaks the tie.
          startedAt: t0.add(Duration(milliseconds: i < 3 ? 0 : i)),
          runId: i.isEven ? 'run-1' : 'run-2',
          agentId: i.isEven ? 'agent-1' : 'agent-2',
          conversationId: i < 5 ? 'conv-1' : 'conv-2',
          spaceId: i < 5 ? 'space-1' : 'space-2',
          status: i % 3 == 0
              ? CodeExecutionStatus.failed
              : CodeExecutionStatus.completed,
          surface: i < 7
              ? CodeExecutionSurface.harness
              : CodeExecutionSurface.mcp,
        );
      }
    }

    String nameOf(CodeExecution e) => e.toolCallId.substring('call-'.length);

    Future<List<String>> ids(CodeExecutionQuery query) async => [
      for (final e in (await executions.list('ws-a', query)).items) nameOf(e),
    ];

    const newestFirst = [
      'ex-9', 'ex-8', 'ex-7', 'ex-6', 'ex-5', 'ex-4', 'ex-3', //
      // A tie on the millisecond is broken by the record id, which starts
      // with the run: run-2/call-ex-1 sorts after run-1/call-ex-2.
      'ex-1', 'ex-2', 'ex-0',
    ];

    test('pages newest first with a stable cursor', () async {
      await seedTen();

      final seen = <String>[];
      String? cursor;
      var pages = 0;
      do {
        final page = await executions.list(
          'ws-a',
          CodeExecutionQuery(limit: 3, cursor: cursor),
        );
        seen.addAll(page.items.map(nameOf));
        cursor = page.nextCursor;
        pages++;
      } while (cursor != null);

      expect(seen, newestFirst);
      expect(pages, 4);
    });

    test('a write between pages does not shift the next page', () async {
      await seedTen();
      final first = await executions.list('ws-a', CodeExecutionQuery(limit: 4));
      await record('ex-new', startedAt: t0.add(const Duration(hours: 1)));

      final second = await executions.list(
        'ws-a',
        CodeExecutionQuery(limit: 4, cursor: first.nextCursor),
      );
      expect(second.items.map(nameOf), newestFirst.sublist(4, 8));
    });

    test('a page that reaches the end has no cursor', () async {
      await seedTen();
      final page = await executions.list('ws-a', CodeExecutionQuery(limit: 10));
      expect(page.items, hasLength(10));
      expect(page.nextCursor, isNull);
    });

    test('each filter narrows the list', () async {
      await seedTen();

      expect(await ids(CodeExecutionQuery(runId: 'run-2')), [
        'ex-9', 'ex-7', 'ex-5', 'ex-3', 'ex-1', //
      ]);
      expect(await ids(CodeExecutionQuery(agentId: 'agent-1')), [
        'ex-8', 'ex-6', 'ex-4', 'ex-2', 'ex-0', //
      ]);
      expect(await ids(CodeExecutionQuery(conversationId: 'conv-2')), [
        'ex-9', 'ex-8', 'ex-7', 'ex-6', 'ex-5', //
      ]);
      expect(await ids(CodeExecutionQuery(spaceId: 'space-1')), [
        'ex-4', 'ex-3', 'ex-1', 'ex-2', 'ex-0', //
      ]);
      expect(await ids(CodeExecutionQuery(toolCallId: 'call-ex-4')), ['ex-4']);
      expect(
        await ids(CodeExecutionQuery(statuses: {CodeExecutionStatus.failed})),
        ['ex-9', 'ex-6', 'ex-3', 'ex-0'],
      );
      expect(
        await ids(
          CodeExecutionQuery(
            statuses: {
              CodeExecutionStatus.failed,
              CodeExecutionStatus.completed,
            },
          ),
        ),
        newestFirst,
      );
      expect(await ids(CodeExecutionQuery(surface: CodeExecutionSurface.mcp)), [
        'ex-9',
        'ex-8',
        'ex-7',
      ]);
      // since is inclusive, until exclusive.
      expect(
        await ids(
          CodeExecutionQuery(
            since: t0.add(const Duration(milliseconds: 4)),
            until: t0.add(const Duration(milliseconds: 7)),
          ),
        ),
        ['ex-6', 'ex-5', 'ex-4'],
      );
      expect(
        await ids(
          CodeExecutionQuery(runId: 'run-1', surface: CodeExecutionSurface.mcp),
        ),
        ['ex-8'],
      );
    });

    test(
      'a tool call id that repeats lists every execution, newest first',
      () async {
        // Run 1 and run 2 each have a call `call-same`, and run 1 repeats it.
        await begin(admitted('same'));
        await begin(
          admitted(
            'same',
            id: '${idOf('same')}#2',
            startedAt: t0.add(const Duration(seconds: 2)),
          ),
        );
        await begin(
          admitted(
            'same',
            runId: 'run-2',
            startedAt: t0.add(const Duration(seconds: 1)),
          ),
        );
        await record('other');

        final page = await executions.list(
          'ws-a',
          CodeExecutionQuery(toolCallId: 'call-same'),
        );
        expect(page.items.map((e) => e.id), [
          '${idOf('same')}#2',
          idOf('same', runId: 'run-2'),
          idOf('same'),
        ]);
      },
    );

    test(
      'hidden spaces are left out by the query, so pages stay full',
      () async {
        await seedTen();
        await record(
          'no-space',
          conversationId: null,
          spaceId: null,
          startedAt: t0.add(const Duration(milliseconds: 2)),
        );
        CodeExecutionQuery hidden({String? cursor}) => CodeExecutionQuery(
          limit: 2,
          cursor: cursor,
          hiddenSpaceIds: {'space-2'},
        );
        // ex-5..ex-9 are in the hidden space; the other six, and the one with
        // no space, are visible.
        final seen = <String>[];
        String? cursor;
        do {
          final page = await executions.list('ws-a', hidden(cursor: cursor));
          if (page.nextCursor != null) {
            expect(page.items, hasLength(2), reason: 'a full page');
          }
          seen.addAll(page.items.map(nameOf));
          cursor = page.nextCursor;
        } while (cursor != null);

        expect(seen, ['ex-4', 'ex-3', 'no-space', 'ex-1', 'ex-2', 'ex-0']);
        expect(
          await ids(
            CodeExecutionQuery(spaceId: 'space-2', hiddenSpaceIds: {'space-2'}),
          ),
          isEmpty,
        );
      },
    );

    test('a cursor this list did not return is refused', () async {
      await seedTen();
      for (final cursor in [
        'not base64!',
        base64Url.encode(utf8.encode('[1]')),
      ]) {
        await expectLater(
          executions.list('ws-a', CodeExecutionQuery(cursor: cursor)),
          throwsA(isA<ValidationException>()),
        );
      }
    });
  });

  group('retention', () {
    test('executions, payloads and calls go with their run log', () async {
      await record(
        'ex-1',
        calls: [call(idOf('ex-1'), 1), call(idOf('ex-1'), 2)],
      );
      await record(
        'ex-2',
        runId: 'run-2',
        calls: [call(idOf('ex-2', runId: 'run-2'), 1)],
      );

      await dbs
          .of('ws-a')
          .customStatement("DELETE FROM agent_run_logs WHERE id = 'run-1'");

      expect(await executions.get('ws-a', idOf('ex-1')), isNull);
      expect(await count('ws-a', 'code_executions'), 1);
      expect(await count('ws-a', 'code_execution_payloads'), 1);
      expect(await count('ws-a', 'code_execution_calls'), 1);
    });

    test('the retention sweep removes them with a pruned run', () async {
      final db = dbs.of('ws-a');
      await seed.seedFinishedRunLog(db, 'run-old', completedAt: DateTime(2025));
      final old = await record(
        'ex-old',
        runId: 'run-old',
        calls: [call(idOf('ex-old', runId: 'run-old'), 1)],
      );

      await DatabaseRetentionService(
        workspaces: dbs,
        global: global,
        now: () => DateTime(2026, 11, 17),
      ).runOnce();

      expect(await executions.get('ws-a', old.id), isNull);
      expect(await count('ws-a', 'code_execution_calls'), 0);
      expect(await count('ws-a', 'code_execution_payloads'), 0);
    });

    test(
      'deleting a conversation keeps the execution and clears the key',
      () async {
        final kept = await record('ex-1', spaceId: null);
        await dbs
            .of('ws-a')
            .customStatement("DELETE FROM conversations WHERE id = 'conv-1'");

        expect(
          (await executions.get('ws-a', kept.id))!.execution.conversationId,
          isNull,
        );
      },
    );

    test('deleting a space deletes the executions recorded in it', () async {
      // The source, output and arguments are the space's content: they must
      // not outlive it as a record with no space that any member could read.
      final inSpace = await record('ex-1', calls: [call(idOf('ex-1'), 1)]);
      final elsewhere = await record(
        'ex-2',
        conversationId: 'conv-2',
        spaceId: 'space-2',
      );
      await dbs
          .of('ws-a')
          .customStatement("DELETE FROM spaces WHERE id = 'space-1'");

      expect(await executions.get('ws-a', inSpace.id), isNull);
      expect(await executions.get('ws-a', elsewhere.id), isNotNull);
      expect(await count('ws-a', 'code_execution_payloads'), 1);
      expect(await count('ws-a', 'code_execution_calls'), 0);
    });
  });

  group('stored values check what they store', () {
    test('an unknown execution status or error kind is refused', () async {
      final done = await record('ex-1', status: CodeExecutionStatus.failed);
      for (final statement in [
        "UPDATE code_executions SET status = 'exploded'",
        "UPDATE code_executions SET surface = 'cli'",
        // A script's own error name is display text in the payload; the
        // column holds only the host's vocabulary.
        "UPDATE code_executions SET error_kind = 'TypeError'",
      ]) {
        await expectLater(
          dbs.of('ws-a').customStatement(statement),
          throwsA(anything),
          reason: statement,
        );
      }
      expect((await executions.get('ws-a', done.id))!.execution, done);
    });

    test('an unknown call status or gate decision is refused', () async {
      await record('ex-1', calls: [call(idOf('ex-1'), 1)]);
      for (final statement in [
        "UPDATE code_execution_calls SET status = 'maybe'",
        "UPDATE code_execution_calls SET gate_decision = 'shrugged'",
      ]) {
        await expectLater(
          dbs.of('ws-a').customStatement(statement),
          throwsA(anything),
        );
      }
    });

    test(
      'a call site is a line and a column, both from 1, or neither',
      () async {
        await record('ex-1', calls: [call(idOf('ex-1'), 1)]);
        for (final statement in [
          'UPDATE code_execution_calls SET site_line = 3',
          'UPDATE code_execution_calls SET site_column = 3',
          'UPDATE code_execution_calls SET site_line = 0, site_column = 1',
          'UPDATE code_execution_calls SET site_line = 1, site_column = 0',
        ]) {
          await expectLater(
            dbs.of('ws-a').customStatement(statement),
            throwsA(anything),
            reason: statement,
          );
        }
        await dbs
            .of('ws-a')
            .customStatement(
              'UPDATE code_execution_calls SET site_line = 1, site_column = 1',
            );
        expect(
          (await executions.get('ws-a', idOf('ex-1')))!.calls.single.site,
          ScriptCallSite(1, 1),
        );
      },
    );

    test(
      'a stored site out of range reads as no site, and keeps its row',
      () async {
        await record('ex-1', calls: [call(idOf('ex-1'), 1)]);
        await dbs
            .of('ws-a')
            .customStatement(
              'UPDATE code_execution_calls SET site_line = 2000000, '
              'site_column = 1',
            );
        final calls = (await executions.get('ws-a', idOf('ex-1')))!.calls;
        expect(calls.single.sequence, 1);
        expect(calls.single.site, isNull);
      },
    );

    test('limits and lockdown must be JSON objects', () async {
      await record('ex-1');
      for (final statement in [
        "UPDATE code_executions SET limits_json = '[1]'",
        "UPDATE code_executions SET lockdown_json = 'not json'",
      ]) {
        await expectLater(
          dbs.of('ws-a').customStatement(statement),
          throwsA(anything),
        );
      }
    });
  });

  group('store', () {
    test('commits values, the last write per key winning', () async {
      await commit([
        put('a', 1),
        put('b', {'n': 2}),
        put('a', 'one'),
      ]);

      expect(await read(), {'a': '"one"', 'b': '{"n":2}'});
    });

    test('a null value deletes the key', () async {
      await commit([put('a', 1), put('b', 2)]);
      await commit([drop('a'), drop('missing')]);

      expect(await read(), {'b': '2'});
    });

    test('values are scoped to the conversation and the agent', () async {
      await commit([put('k', 'mine')]);
      await commit([put('k', 'other agent')], agentId: 'agent-2');
      await commit([put('k', 'other conversation')], conversationId: 'conv-2');

      expect(await read(), {'k': '"mine"'});
      expect(await read(agentId: 'agent-2'), {'k': '"other agent"'});
      expect(await read(conversationId: 'conv-2'), {
        'k': '"other conversation"',
      });
      expect(await read(conversationId: 'conv-2', agentId: 'agent-2'), isEmpty);
    });

    test('a value over 256 KiB changes nothing in the batch', () async {
      await commit([put('kept', 1)]);
      const cap = CodeModeLimits.maxStoreValueBytes;

      // A string's JSON is its characters plus two quotes: one byte over.
      await expectLater(
        commit([put('new', 2), put('kept', 3), put('big', sized(cap - 1))]),
        throwsA(
          isA<ValidationException>().having(
            (e) => e.code,
            'code',
            'code_mode_store_limit',
          ),
        ),
      );
      expect(await read(), {'kept': '1'});

      // Exactly at the cap is accepted.
      await commit([put('big', sized(cap - 2))]);
      expect(utf8.encode((await read())['big']!).length, cap);
    });

    test('a batch that would pass 1 MiB in total changes nothing', () async {
      // Four values of about 255 KiB each fill most of the 1 MiB.
      final chunk = sized(255 * 1024);
      await commit([put('a', chunk), put('b', chunk), put('c', chunk)]);
      await commit([put('d', chunk)]);
      final before = await read();

      await expectLater(
        commit([put('e', chunk), put('f', 'small')]),
        throwsA(isA<ValidationException>()),
      );
      expect(await read(), before);

      // A batch that frees as much as it adds fits.
      await commit([drop('a'), put('e', chunk)]);
      expect((await read()).keys, unorderedEquals(['b', 'c', 'd', 'e']));
    });

    test('concurrent commits cannot together pass the total cap', () async {
      final chunk = sized(255 * 1024);
      await commit([put('a', chunk), put('b', chunk)]);

      final results = await Future.wait([
        for (final key in ['c', 'd', 'e'])
          commit([put(key, chunk)]).then((_) => true, onError: (_) => false),
      ]);

      expect(results.where((ok) => ok), hasLength(2));
      expect(
        CodeModeStoreRules.totalBytes(await read()),
        lessThanOrEqualTo(CodeModeLimits.maxStoreTotalBytes),
      );
    });

    test('an empty key is refused', () async {
      await expectLater(
        commit([put('', 1)]),
        throwsA(isA<ValidationException>()),
      );
    });

    test('a value that is not JSON is refused and nothing commits', () async {
      await expectLater(
        commit([
          put('ok', 1),
          const CodeModeStoreWrite(key: 'bad', valueJson: '{'),
        ]),
        throwsA(anything),
      );
      expect(await read(), isEmpty);
    });

    test(
      'values go with their conversation, its space and their agent',
      () async {
        await commit([put('k', 1)]);
        await commit([put('k', 2)], conversationId: 'conv-2');
        await commit(
          [put('k', 3)],
          conversationId: 'conv-2',
          agentId: 'agent-2',
        );
        final db = dbs.of('ws-a');

        await db.customStatement(
          "DELETE FROM conversations WHERE id = 'conv-1'",
        );
        expect(await read(), isEmpty);

        await db.customStatement("DELETE FROM agents WHERE id = 'agent-2'");
        expect(
          await read(conversationId: 'conv-2', agentId: 'agent-2'),
          isEmpty,
        );
        expect(await read(conversationId: 'conv-2'), {'k': '2'});

        await db.customStatement("DELETE FROM spaces WHERE id = 'space-2'");
        expect(await count('ws-a', 'code_mode_store'), 0);
      },
    );

    test('a commit for an unknown conversation or agent is refused', () async {
      await expectLater(
        commit([put('k', 1)], conversationId: 'conv-x'),
        throwsA(anything),
      );
      await expectLater(
        commit([put('k', 1)], agentId: 'agent-x'),
        throwsA(anything),
      );
      expect(await count('ws-a', 'code_mode_store'), 0);
    });
  });

  group('workspace isolation', () {
    test('an execution in one workspace is invisible from the other', () async {
      final done = await record('ex-1', calls: [call(idOf('ex-1'), 1)]);

      expect(await executions.get('ws-b', done.id), isNull);
      expect(
        await executions.highestIdSuffix(
          'ws-b',
          runId: 'run-1',
          toolCallId: 'call-ex-1',
        ),
        0,
      );
      expect(
        await executions.appendCall('ws-b', call(done.id, 2)),
        CodeExecutionAppendOutcome.notRunning,
      );
      expect(
        (await executions.list('ws-b', CodeExecutionQuery())).items,
        isEmpty,
      );
      expect(
        (await executions.list(
          'ws-b',
          CodeExecutionQuery(runId: 'run-1'),
        )).items,
        isEmpty,
      );
      expect(
        (await executions.list('ws-a', CodeExecutionQuery())).items,
        hasLength(1),
      );
    });

    test('the same execution id in two workspaces stays two rows', () async {
      final a = await record('ex-1', status: CodeExecutionStatus.failed);
      final b = await record('ex-1', workspaceId: 'ws-b');

      expect(b.id, a.id);
      expect(
        (await executions.get('ws-a', a.id))!.execution.status,
        CodeExecutionStatus.failed,
      );
      expect(
        (await executions.get('ws-b', b.id))!.execution.status,
        CodeExecutionStatus.completed,
      );
    });

    test(
      'a cursor from one workspace pages nothing extra in another',
      () async {
        for (var i = 0; i < 3; i++) {
          await record('ex-$i', startedAt: t0.add(Duration(seconds: i)));
        }
        final first = await executions.list(
          'ws-a',
          CodeExecutionQuery(limit: 1),
        );

        final elsewhere = await executions.list(
          'ws-b',
          CodeExecutionQuery(cursor: first.nextCursor),
        );
        expect(elsewhere.items, isEmpty);
      },
    );

    test(
      'a stored value in one workspace is invisible from the other',
      () async {
        await commit([put('k', 'a')]);

        expect(await read(workspaceId: 'ws-b'), isEmpty);
        await commit([put('k', 'b')], workspaceId: 'ws-b');
        expect(await read(), {'k': '"a"'});
        expect(await read(workspaceId: 'ws-b'), {'k': '"b"'});
      },
    );

    test('a deleted workspace is refused before its file opens', () async {
      // A workspace this process has not opened: the manager checks the
      // registry's verdict when it opens a file.
      await seedWorkspaceRow(global, 'ws-gone');
      dbs.markDeleted('ws-gone');

      final refused = throwsA(isA<DeletedWorkspaceException>());
      await expectLater(
        begin(admitted('ex-1'), workspaceId: 'ws-gone'),
        refused,
      );
      await expectLater(
        finish(ended(admitted('ex-1')), workspaceId: 'ws-gone'),
        refused,
      );
      await expectLater(
        executions.appendCall('ws-gone', call(idOf('ex-1'), 1)),
        refused,
      );
      await expectLater(
        executions.highestIdSuffix(
          'ws-gone',
          runId: 'run-1',
          toolCallId: 'call-ex-1',
        ),
        refused,
      );
      await expectLater(
        executions.list('ws-gone', CodeExecutionQuery()),
        refused,
      );
      await expectLater(executions.get('ws-gone', idOf('ex-1')), refused);
      await expectLater(read(workspaceId: 'ws-gone'), refused);
      await expectLater(commit([put('k', 1)], workspaceId: 'ws-gone'), refused);
    });
  });
}
