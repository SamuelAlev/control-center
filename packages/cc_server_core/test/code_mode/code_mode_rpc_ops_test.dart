import 'dart:convert';

import 'package:cc_domain/cc_domain.dart'
    show
        AuthException,
        CodeExecutionDetailDto,
        CodeExecutionPageDto,
        CodeModeStatusDto,
        RpcErrorCodes;
import 'package:cc_domain/core/domain/entities/workspace.dart';
import 'package:cc_domain/core/domain/value_objects/workspace_role.dart';
import 'package:cc_domain/features/code_mode/domain/entities/code_execution.dart';
import 'package:cc_domain/features/code_mode/domain/entities/code_execution_call.dart';
import 'package:cc_domain/features/code_mode/domain/value_objects/code_execution_status.dart';
import 'package:cc_domain/features/code_mode/domain/value_objects/code_mode.dart';
import 'package:cc_domain/features/code_mode/domain/value_objects/code_mode_limits.dart';
import 'package:cc_domain/testing/fake_workspace_repository.dart';
import 'package:cc_host/cc_host.dart';
import 'package:cc_persistence/cc_persistence.dart';
import 'package:cc_server_core/src/code_mode/code_mode_rpc_ops.dart';
import 'package:cc_server_core/src/code_mode/server_code_mode.dart';
import 'package:cc_server_core/src/rpc_exception_mapper.dart';
import 'package:drift/drift.dart' show Variable;
import 'package:test/test.dart';

import '../helpers/seed_spaces.dart';
import '../helpers/test_database.dart';

/// The `codeMode.*` pack through the real dispatcher: the workspace is
/// checked, then membership and role, then the space gate; ids are looked up
/// in the caller's workspace only; every refusal carries its `data.kind`.
void main() {
  late GlobalDatabase global;
  late WorkspaceDatabaseManager dbs;
  late FakeWorkspaceRepository workspaces;
  late DaoWorkspaceSettingsRepository settings;
  late DaoCodeExecutionRepository executions;
  late CodeRunnerAvailability availability;
  late Set<String> hiddenSpaces;
  late List<String> spaceChecks;
  late int hostHeap;

  final t0 = DateTime.utc(2026, 11, 17, 9);

  // ws-a: alice (admin), bob (member), vic (viewer). ws-b: mallory (admin).
  const roles = {
    'ws-a': {
      'alice': WorkspaceRole.admin,
      'bob': WorkspaceRole.member,
      'vic': WorkspaceRole.viewer,
    },
    'ws-b': {'mallory': WorkspaceRole.admin},
  };

  CodeExecution execution(
    String workspaceId,
    String runId,
    String toolCallId, {
    int minute = 0,
    String? spaceId,
    CodeExecutionStatus status = CodeExecutionStatus.completed,
    CodeExecutionSurface surface = CodeExecutionSurface.harness,
  }) => CodeExecution(
    id: CodeExecution.idFor(runId: runId, toolCallId: toolCallId),
    runId: runId,
    toolCallId: toolCallId,
    surface: surface,
    startedAt: t0.add(Duration(minutes: minute)),
    durationMs: 40,
    status: status,
    sourceHash: 'ab' * 32,
    sourceBytes: 12,
    limits: CodeModeLimits.defaults,
    agentId: 'agent-$workspaceId',
    spaceId: spaceId,
    description: 'script $toolCallId in $workspaceId',
    errorKind: status == CodeExecutionStatus.completed
        ? null
        : CodeExecutionErrorKind.scriptError,
  );

  Future<CodeExecution> save(
    String workspaceId,
    CodeExecution e, {
    List<CodeExecutionCall> calls = const [],
  }) async {
    final db = dbs.of(workspaceId);
    await db.customStatement(
      'INSERT OR IGNORE INTO agents '
      '(id, name, title, agent_md_path, workspace_id, skills) '
      "VALUES (?, ?, 'Agent', '', ?, '')",
      [e.agentId, e.agentId, workspaceId],
    );
    await db.customStatement(
      'INSERT OR IGNORE INTO agent_run_logs (id, agent_id, workspace_id) '
      'VALUES (?, ?, ?)',
      [e.runId, e.agentId, workspaceId],
    );
    if (e.spaceId case final space?) {
      await seedSpace(db, space);
    }
    final source = 'return 1 + 1; // ${e.id}';
    await executions.begin(
      workspaceId,
      CodeExecution(
        id: e.id,
        runId: e.runId,
        toolCallId: e.toolCallId,
        surface: e.surface,
        startedAt: e.startedAt,
        durationMs: 0,
        status: CodeExecutionStatus.running,
        sourceHash: e.sourceHash,
        sourceBytes: e.sourceBytes,
        limits: e.limits,
        agentId: e.agentId,
        spaceId: e.spaceId,
        description: e.description,
      ),
      source: source,
    );
    await executions.finish(
      workspaceId,
      e,
      payload: CodeExecutionPayload(
        executionId: e.id,
        source: source,
        output: '2',
        console: '',
      ),
      calls: calls,
    );
    return e;
  }

  setUp(() async {
    global = createTestGlobalDatabase();
    dbs = createTestWorkspaceDatabases(global: global);
    workspaces = FakeWorkspaceRepository();
    for (final id in ['ws-a', 'ws-b']) {
      await workspaces.upsert(
        Workspace(id: id, name: id, createdAt: t0, updatedAt: t0),
      );
    }
    await workspaces.upsert(
      Workspace(
        id: 'ws-gone',
        name: 'gone',
        createdAt: t0,
        updatedAt: t0,
        deletedAt: t0,
      ),
    );
    settings = DaoWorkspaceSettingsRepository(dbs);
    executions = DaoCodeExecutionRepository(dbs);
    availability = const CodeRunnerAvailability.available();
    hiddenSpaces = {};
    spaceChecks = [];
    hostHeap = 512 * 1024 * 1024;
  });

  tearDown(() async {
    await dbs.closeAll();
    await global.close();
  });

  RepoOpDispatcher dispatcher() {
    final resolver = CodeModeSettings(
      availability: () => availability,
      workspaces: workspaces,
      settings: settings,
    );
    return RepoOpDispatcher(
      registry: RepoOpRegistry(
        buildCodeModeOps(
          settings: resolver,
          settingsStore: settings,
          executions: executions,
          host: CodeModeHostFacts(
            availability: () => availability,
            publicReason: () => switch (availability) {
              CodeRunnerUnavailable() => 'lockdown is partial on <path>',
              CodeRunnerAvailable() => null,
            },
            runnerVersion: () => 'cc_codemode 0.1.0 quickjs-ng 0.16.2',
            maxProcesses: 6,
            maxParkedProcesses: 24,
            maxWorkspaceProcesses: 5,
            maxHeapBytes: hostHeap,
          ),
          spaceInWorkspace: (ws, space) async =>
              (await dbs
                  .of(ws)
                  .customSelect(
                    'SELECT 1 FROM spaces WHERE id = ?',
                    variables: [Variable.withString(space)],
                  )
                  .getSingleOrNull()) !=
              null,
          requireSpace: (ws, user, space) async {
            spaceChecks.add('$ws:$user:$space');
            if (hiddenSpaces.contains(space)) {
              throw const AuthException(
                'You cannot read this space.',
                code: 'space_read_refused',
              );
            }
          },
          hiddenSpaces: (ws, user) async => hiddenSpaces,
        ),
      ),
      mapException: mapAppExceptionToRpc,
      // The production order: the registry first, then the role.
      workspaceExists: (id) async =>
          (await workspaces.getById(id))?.isDeleted == false,
      resolveRole: (ws, user) async => roles[ws]?[user],
    );
  }

  Future<Map<String, dynamic>> call(
    String user,
    String op,
    String workspaceId, [
    Map<String, dynamic> args = const {},
  ]) => dispatcher().call(
    id: 1,
    params: {
      'op': op,
      'args': {'workspace_id': workspaceId, ...args},
    },
    deviceId: 'device-$user',
    userId: user,
    sessionCapability: SessionCapability.fullClient,
  );

  Map<String, dynamic> result(Map<String, dynamic> response) {
    expect(response['error'], isNull, reason: '${response['error']}');
    return ((response['result'] as Map)['data'] as Map).cast<String, dynamic>();
  }

  ({int? code, Object? kind}) error(Map<String, dynamic> response) {
    final err = response['error'] as Map?;
    expect(err, isNotNull, reason: 'expected a refusal, got $response');
    return (code: err!['code'] as int?, kind: (err['data'] as Map?)?['kind']);
  }

  group('codeMode.status', () {
    test('a member reads the answer for the workspace', () async {
      final raw = result(await call('bob', 'codeMode.status', 'ws-a'));
      final status = CodeModeStatusDto.fromJson(
        (raw['status'] as Map).cast<String, dynamic>(),
      );
      expect(status.available, isTrue);
      expect(status.reason, isNull);
      // No mode: availability, the caps and the limits are the answer.
      expect(
        (raw['status'] as Map).keys,
        isNot(anyOf(contains('resolution'), contains('server_switch'))),
      );
      expect(status.limits, CodeModeLimits.defaults);
      expect(status.limitOverrides, isEmpty);
      expect(status.runnerVersion, startsWith('cc_codemode'));
      expect(status.maxProcesses, 6);
      expect(status.maxParkedProcesses, 24);
      expect(status.maxWorkspaceProcesses, 5);
      expect(status.maxHeapBytes, 512 * 1024 * 1024);
    });

    test('the heap limit shown is clamped to the server ceiling', () async {
      hostHeap = 64 * 1024 * 1024;
      final status = CodeModeStatusDto.fromJson(
        (result(await call('bob', 'codeMode.status', 'ws-a'))['status'] as Map)
            .cast<String, dynamic>(),
      );
      expect(status.maxHeapBytes, 64 * 1024 * 1024);
      expect(status.limits.heapBytes, 64 * 1024 * 1024);
    });

    test(
      'an unavailable runner is reported with the public reason only',
      () async {
        availability = const CodeRunnerAvailability.unavailable(
          'lockdown partial: /Users/someone/Library/cc_codemode',
        );
        final raw = result(await call('bob', 'codeMode.status', 'ws-a'));
        expect(jsonEncode(raw), isNot(contains('/Users/')));
        final status = CodeModeStatusDto.fromJson(
          (raw['status'] as Map).cast<String, dynamic>(),
        );
        expect(status.available, isFalse);
        expect(status.reason, 'lockdown is partial on <path>');
      },
    );

    test(
      'a viewer, a non-member and an unknown workspace are refused',
      () async {
        expect(
          error(await call('vic', 'codeMode.status', 'ws-a')).code,
          RpcErrorCodes.unauthorized,
        );
        expect(
          error(await call('mallory', 'codeMode.status', 'ws-a')).code,
          RpcErrorCodes.unauthorized,
        );
        for (final ws in ['ws-unknown', 'ws-gone']) {
          expect(
            error(await call('alice', 'codeMode.status', ws)).code,
            RpcErrorCodes.notFound,
            reason: ws,
          );
          expect(dbs.openIds, isNot(contains(ws)), reason: ws);
        }
      },
    );
  });

  group('codeMode.listExecutions', () {
    test('pages newest first with an opaque cursor', () async {
      for (var i = 0; i < 5; i++) {
        await save('ws-a', execution('ws-a', 'run-1', 'call_$i', minute: i));
      }
      final seen = <String>[];
      String? cursor;
      var pages = 0;
      do {
        final page = CodeExecutionPageDto.fromJson(
          result(
            await call('bob', 'codeMode.listExecutions', 'ws-a', {
              'limit': 2,
              'cursor': ?cursor,
            }),
          ),
        );
        seen.addAll(page.items.map((e) => e.toolCallId));
        cursor = page.nextCursor;
        pages++;
      } while (cursor != null && pages < 10);
      expect(seen, ['call_4', 'call_3', 'call_2', 'call_1', 'call_0']);
      expect(pages, 3);
    });

    test('summaries carry no source, output or calls', () async {
      await save('ws-a', execution('ws-a', 'run-1', 'call_1'));
      final raw = result(await call('bob', 'codeMode.listExecutions', 'ws-a'));
      final text = jsonEncode(raw);
      expect(text, isNot(contains('return 1 + 1')));
      expect(text, isNot(contains('"calls"')));
      expect(text, isNot(contains('"payload"')));
    });

    test('filters by run, agent, status, surface and time', () async {
      await save('ws-a', execution('ws-a', 'run-1', 'c1', minute: 1));
      await save(
        'ws-a',
        execution(
          'ws-a',
          'run-2',
          'c2',
          minute: 2,
          status: CodeExecutionStatus.timedOut,
        ),
      );
      await save(
        'ws-a',
        execution(
          'ws-a',
          'run-2',
          'c3',
          minute: 3,
          surface: CodeExecutionSurface.mcp,
        ),
      );
      Future<List<String>> ids(Map<String, dynamic> args) async => [
        for (final e in CodeExecutionPageDto.fromJson(
          result(await call('bob', 'codeMode.listExecutions', 'ws-a', args)),
        ).items)
          e.toolCallId,
      ];
      expect(await ids({'run_id': 'run-2'}), ['c3', 'c2']);
      expect(await ids({'agent_id': 'agent-ws-a'}), ['c3', 'c2', 'c1']);
      expect(
        await ids({
          'statuses': [CodeExecutionStatus.timedOut.wire],
        }),
        ['c2'],
      );
      expect(await ids({'surface': CodeExecutionSurface.mcp.wire}), ['c3']);
      expect(
        await ids({
          'since': t0.add(const Duration(minutes: 2)).toIso8601String(),
        }),
        ['c3', 'c2'],
      );
      expect(
        await ids({
          'until': t0.add(const Duration(minutes: 2)).toIso8601String(),
        }),
        ['c1'],
      );
    });

    test('a malformed query is refused with its kind', () async {
      for (final args in <Map<String, dynamic>>[
        {'limit': 0},
        {'limit': 201},
        {'limit': 'ten'},
        {
          'statuses': ['exploded'],
        },
        {'statuses': 'completed'},
        // A refused call is never recorded, so there is nothing to filter.
        {
          'statuses': ['refused'],
        },
        {'tool_call_id': 3},
        {'surface': 'cli'},
        {'since': 'yesterday'},
        {'run_id': 7},
      ]) {
        final refusal = error(
          await call('bob', 'codeMode.listExecutions', 'ws-a', args),
        );
        expect(refusal.code, RpcErrorCodes.validation, reason: '$args');
        expect(refusal.kind, 'code_mode_invalid_query', reason: '$args');
      }
      final cursor = error(
        await call('bob', 'codeMode.listExecutions', 'ws-a', {
          'cursor': 'not-a-cursor',
        }),
      );
      expect(cursor.code, RpcErrorCodes.validation);
      expect(cursor.kind, 'invalid_cursor');
    });

    test('executions in a space the caller cannot read are left out', () async {
      await save(
        'ws-a',
        execution('ws-a', 'run-1', 'open', minute: 1, spaceId: 'space-open'),
      );
      await save(
        'ws-a',
        execution('ws-a', 'run-1', 'closed', minute: 2, spaceId: 'space-x'),
      );
      await save('ws-a', execution('ws-a', 'run-1', 'nospace', minute: 3));
      hiddenSpaces = {'space-x'};
      final page = CodeExecutionPageDto.fromJson(
        result(await call('bob', 'codeMode.listExecutions', 'ws-a')),
      );
      expect(page.items.map((e) => e.toolCallId), ['nospace', 'open']);

      final refused = error(
        await call('bob', 'codeMode.listExecutions', 'ws-a', {
          'space_id': 'space-x',
        }),
      );
      expect(refused.code, RpcErrorCodes.unauthorized);
      expect(refused.kind, 'space_read_refused');
      expect(spaceChecks, contains('ws-a:bob:space-x'));

      final allowed = CodeExecutionPageDto.fromJson(
        result(
          await call('bob', 'codeMode.listExecutions', 'ws-a', {
            'space_id': 'space-open',
          }),
        ),
      );
      expect(allowed.items.map((e) => e.toolCallId), ['open']);
    });

    test('pages and cursors are made of visible rows only: a cursor never '
        'names an execution in a hidden space', () async {
      for (var i = 0; i < 8; i++) {
        await save(
          'ws-a',
          execution(
            'ws-a',
            'run-1',
            'c$i',
            minute: i,
            spaceId: i.isOdd ? 'space-x' : 'space-open',
          ),
        );
      }
      hiddenSpaces = {'space-x'};
      final seen = <String>[];
      String? cursor;
      do {
        final page = CodeExecutionPageDto.fromJson(
          result(
            await call('bob', 'codeMode.listExecutions', 'ws-a', {
              'limit': 2,
              'cursor': ?cursor,
            }),
          ),
        );
        seen.addAll(page.items.map((e) => e.toolCallId));
        cursor = page.nextCursor;
        // Hidden rows are left out by the query, not after it, so every
        // page but the last is full.
        if (cursor != null) {
          expect(page.items, hasLength(2), reason: 'a page is full');
        }
      } while (cursor != null);
      expect(seen, ['c6', 'c4', 'c2', 'c0']);
    });

    test('a space_id filter must name a space of the workspace', () async {
      await save(
        'ws-b',
        execution('ws-b', 'run-1', 'b1', spaceId: 'space-of-b'),
      );
      final refusal = error(
        await call('bob', 'codeMode.listExecutions', 'ws-a', {
          'space_id': 'space-of-b',
        }),
      );
      expect(refusal.code, isNot(RpcErrorCodes.validation));
      expect(
        spaceChecks,
        isEmpty,
        reason: 'refused before the read gate is asked',
      );
    });

    test('tool_call_id finds every execution of one repl call, newest '
        'first', () async {
      await save('ws-a', execution('ws-a', 'run-1', 'same', minute: 1));
      await save('ws-a', execution('ws-a', 'run-2', 'same', minute: 3));
      await save('ws-a', execution('ws-a', 'run-1', 'other', minute: 2));
      final page = CodeExecutionPageDto.fromJson(
        result(
          await call('bob', 'codeMode.listExecutions', 'ws-a', {
            'tool_call_id': 'same',
          }),
        ),
      );
      expect(page.items.map((e) => e.runId), ['run-2', 'run-1']);
    });
  });

  group('codeMode.getExecution', () {
    test('returns the source, output and calls, by an opaque id', () async {
      // An id with both separators the service may produce.
      final e = await save(
        'ws-a',
        execution('ws-a', 'run-1', 'call_1#2', spaceId: 'space-open'),
        calls: [
          CodeExecutionCall(
            executionId: CodeExecution.idFor(
              runId: 'run-1',
              toolCallId: 'call_1#2',
            ),
            sequence: 1,
            toolCallId: CodeExecutionCall.nestedToolCallId('call_1#2', 1),
            toolName: 'read',
            startOffsetMs: 3,
            durationMs: 2,
            status: NestedCallStatus.completed,
            gateDecision: NestedCallGateDecision.allowed,
            approvalWaitMs: 0,
            argumentBytes: 10,
            resultBytes: 20,
            argumentsJson: '{"path":"a.txt"}',
          ),
        ],
      );
      expect(e.id, contains('/'));
      final detail = CodeExecutionDetailDto.fromJson(
        (result(
                  await call('bob', 'codeMode.getExecution', 'ws-a', {
                    'id': e.id,
                  }),
                )['execution']
                as Map)
            .cast<String, dynamic>(),
      );
      expect(detail.execution, e);
      expect(detail.payload!.source, contains('return 1 + 1'));
      expect(detail.payload!.output, '2');
      expect(detail.calls.single.toolName, 'read');
      expect(spaceChecks, ['ws-a:bob:space-open']);
    });

    test('a space the caller cannot read refuses the execution', () async {
      final e = await save(
        'ws-a',
        execution('ws-a', 'run-1', 'call_1', spaceId: 'space-x'),
      );
      hiddenSpaces = {'space-x'};
      final refused = error(
        await call('bob', 'codeMode.getExecution', 'ws-a', {'id': e.id}),
      );
      expect(refused.code, RpcErrorCodes.unauthorized);
      expect(refused.kind, 'space_read_refused');
    });

    test('an unknown id is not found, with its kind', () async {
      final missing = error(
        await call('bob', 'codeMode.getExecution', 'ws-a', {
          'id': 'run-9/call_9',
        }),
      );
      expect(missing.code, RpcErrorCodes.notFound);
      expect(
        error(
          await call('bob', 'codeMode.getExecution', 'ws-a', {'id': 5}),
        ).kind,
        'code_mode_invalid_query',
      );
    });
  });

  group('workspace isolation', () {
    late CodeExecution inB;
    late CodeExecution inA;

    setUp(() async {
      inA = await save('ws-a', execution('ws-a', 'run-shared', 'call_1'));
      // The same run and call ids in ws-b, so only the workspace tells them
      // apart.
      inB = await save('ws-b', execution('ws-b', 'run-shared', 'call_1'));
      await save('ws-b', execution('ws-b', 'run-b', 'call_b', minute: 5));
      await settings.set('ws-b', kCodeModeLimitsSettingKey, _bLimits);
    });

    test('a member of A cannot list, get or read the status of B', () async {
      for (final op in [
        'codeMode.status',
        'codeMode.listExecutions',
        'codeMode.getExecution',
        'codeMode.setWorkspaceSetting',
      ]) {
        expect(
          error(
            await call('bob', op, 'ws-b', {
              'id': inB.id,
              'key': kCodeModeLimitsSettingKey,
              'value': const <String, Object>{},
            }),
          ).code,
          RpcErrorCodes.unauthorized,
          reason: op,
        );
      }
      expect(await settings.get('ws-b', kCodeModeLimitsSettingKey), _bLimits);
    });

    test("an id of B's asked for in A reads A's row, or nothing", () async {
      final detail = CodeExecutionDetailDto.fromJson(
        (result(
                  await call('bob', 'codeMode.getExecution', 'ws-a', {
                    'id': inB.id,
                  }),
                )['execution']
                as Map)
            .cast<String, dynamic>(),
      );
      expect(detail.execution.description, inA.description);
      expect(
        error(
          await call('bob', 'codeMode.getExecution', 'ws-a', {
            'id': CodeExecution.idFor(runId: 'run-b', toolCallId: 'call_b'),
          }),
        ).code,
        RpcErrorCodes.notFound,
      );
    });

    test("A's list never holds B's executions, by any filter", () async {
      for (final args in <Map<String, dynamic>>[
        {},
        {'run_id': 'run-b'},
        {'agent_id': 'agent-ws-b'},
        {'run_id': 'run-shared'},
      ]) {
        final page = CodeExecutionPageDto.fromJson(
          result(await call('bob', 'codeMode.listExecutions', 'ws-a', args)),
        );
        expect(
          page.items.every((e) => e.description.contains('ws-a')),
          isTrue,
          reason: '$args',
        );
      }
    });

    test("a cursor from B's list pages A's executions only", () async {
      final fromB = CodeExecutionPageDto.fromJson(
        result(
          await call('mallory', 'codeMode.listExecutions', 'ws-b', {
            'limit': 1,
          }),
        ),
      );
      expect(fromB.nextCursor, isNotNull);
      final inAWithBCursor = CodeExecutionPageDto.fromJson(
        result(
          await call('bob', 'codeMode.listExecutions', 'ws-a', {
            'cursor': fromB.nextCursor,
          }),
        ),
      );
      expect(
        inAWithBCursor.items.every((e) => e.description.contains('ws-a')),
        isTrue,
      );
    });

    test("B's setting is not A's status", () async {
      final status = CodeModeStatusDto.fromJson(
        (result(await call('bob', 'codeMode.status', 'ws-a'))['status'] as Map)
            .cast<String, dynamic>(),
      );
      expect(status.limits, CodeModeLimits.defaults);
      expect(status.limitOverrides, isEmpty);
    });
  });

  group('codeMode.setWorkspaceSetting', () {
    Future<Map<String, dynamic>> set(String user, String key, Object? value) =>
        call(user, 'codeMode.setWorkspaceSetting', 'ws-a', {
          'key': key,
          'value': value,
        });

    test('a member or viewer may not write it', () async {
      for (final user in ['bob', 'vic', 'mallory']) {
        expect(
          error(
            await set(user, kCodeModeLimitsSettingKey, {
              CodeModeLimits.wallClock.key: CodeModeLimits.wallClock.floor,
            }),
          ).code,
          RpcErrorCodes.unauthorized,
          reason: user,
        );
      }
      expect(await settings.get('ws-a', kCodeModeLimitsSettingKey), isNull);
    });

    test(
      'limits are checked against their bounds and stored as overrides',
      () async {
        const wall = CodeModeLimits.wallClock;
        final stored = result(
          await set('alice', kCodeModeLimitsSettingKey, {
            wall.key: wall.floor,
            CodeModeLimits.cpu.key: CodeModeLimits.cpu.defaultValue,
          }),
        );
        expect(stored['value'], {wall.key: wall.floor});
        expect(
          jsonDecode((await settings.get('ws-a', kCodeModeLimitsSettingKey))!),
          {wall.key: wall.floor},
        );

        final unknown = error(
          await set('alice', kCodeModeLimitsSettingKey, {'turbo': 1}),
        );
        expect(unknown.kind, 'code_mode_limit_unknown');
        final tooHigh = error(
          await set('alice', kCodeModeLimitsSettingKey, {
            wall.key: wall.ceiling + 1,
          }),
        );
        expect(tooHigh.kind, 'code_mode_limit_out_of_range');
        final notAnObject = error(
          await set('alice', kCodeModeLimitsSettingKey, '{"wall_clock_ms":1}'),
        );
        expect(notAnObject.kind, 'code_mode_limit_out_of_range');
        // The refused writes left the stored overrides alone.
        expect(
          jsonDecode((await settings.get('ws-a', kCodeModeLimitsSettingKey))!),
          {wall.key: wall.floor},
        );

        // Writing the defaults clears the row.
        result(
          await set('alice', kCodeModeLimitsSettingKey, {
            wall.key: wall.defaultValue,
          }),
        );
        expect(await settings.get('ws-a', kCodeModeLimitsSettingKey), isNull);
      },
    );

    test('any other key is refused, the old mode key among them', () async {
      for (final key in ['theme', 'code_mode']) {
        expect(
          error(await set('alice', key, 'hybrid')).kind,
          'code_mode_unknown_setting',
          reason: key,
        );
      }
    });
  });
}

/// ws-b's stored limit overrides, which ws-a never sees.
final _bLimits = jsonEncode({
  CodeModeLimits.wallClock.key: CodeModeLimits.wallClock.floor,
});
