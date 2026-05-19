import 'dart:async';
import 'dart:convert';

import 'package:cc_domain/cc_domain.dart';
import 'package:cc_domain/core/domain/value_objects/workspace_role.dart';
import 'package:cc_host/src/log/cc_host_log.dart';
import 'package:cc_host/src/policy/session_capability.dart';
import 'package:cc_host/src/repo_rpc/repo_op.dart';
import 'package:cc_host/src/repo_rpc/repo_op_dispatcher.dart';
import 'package:cc_host/src/repo_rpc/watch_query.dart';
import 'package:cc_host/src/session/remote_rate_limiter.dart';
import 'package:cc_host/src/session/remote_rpc_session.dart';
import 'package:cc_rpc/cc_rpc.dart';
import 'package:test/test.dart';

/// Direct unit coverage for [RemoteRpcSession] — the per-connection frame pump.
/// The `InProcessRpcHost` integration test covers the happy repo-RPC + subscribe
/// paths; this targets the phone-tier branches that the in-process host (a
/// fullClient self-loop) never reaches: `tools/list` filtering, `tools/call`
/// deny + rate-limit, the "not available" branches, the malformed-frame /
/// handler-exception paths and `_send` failures.
void main() {
  group('RemoteRpcSession frame handling', () {
    late _FakeChannel space;
    late _RecordingDispatcher dispatcher;
    late RemoteRpcSession session;

    setUp(() {
      space = _FakeChannel();
      dispatcher = _RecordingDispatcher();
      session = RemoteRpcSession(
        deviceId: 'phone-1',
        userId: 'user-1',
        space: space,
        dispatcher: dispatcher,
        workspaceResolver: (_) async => const [
          (id: 'ws-A', name: 'Workspace A'),
          (id: 'ws-B', name: 'Workspace B'),
        ],
        capability: SessionCapability.phone,
      );
      unawaited(session.start());
    });

    tearDown(() async {
      await session.stop();
    });

    test('a non-JSON-RPC frame is dropped (no response sent)', () async {
      // 'method' is empty → JsonRpcRequest.fromJson would produce an empty
      // method, but the assert throws earlier. Send a frame that fails decode.
      space.inject({'id': 1}); // no method
      await pumpEventQueue(times: 5);
      expect(space.sent, isEmpty);
    });

    test('a notification (no id) is dispatched but gets no response', () async {
      space.inject({'jsonrpc': '2.0', 'method': 'some/notify'});
      await pumpEventQueue(times: 5);
      expect(dispatcher.handled, ['some/notify']);
      expect(space.sent, isEmpty);
    });

    test('a default-routed method returns the dispatcher response', () async {
      space.inject({'jsonrpc': '2.0', 'method': 'foo/bar', 'id': 7});
      await pumpEventQueue(times: 5);
      expect(dispatcher.handled, ['foo/bar']);
      expect(space.sent.single['id'], 7);
      expect(space.sent.single['result'], {'echoed': 'foo/bar'});
    });

    test(
      'session/list_workspaces resolves the membership-scoped list',
      () async {
        space.inject({
          'jsonrpc': '2.0',
          'method': 'session/list_workspaces',
          'id': 1,
        });
        await pumpEventQueue(times: 5);
        final result = space.sent.single['result'] as Map<String, dynamic>;
        expect(result['count'], 2);
        expect(result['workspaces'], [
          {'id': 'ws-A', 'name': 'Workspace A'},
          {'id': 'ws-B', 'name': 'Workspace B'},
        ]);
      },
    );

    test(
      'a handler exception surfaces a generic internal error (no leak)',
      () async {
        dispatcher.errorOn = 'explode';
        space.inject({'jsonrpc': '2.0', 'method': 'explode', 'id': 9});
        await pumpEventQueue(times: 5);
        final err = space.sent.single['error'] as Map<String, dynamic>;
        expect(err['code'], -32603);
        expect(err['message'], 'Internal error');
        // The raw exception text must never reach the wire.
        expect('$space.sent', isNot(contains('secret-leak')));
      },
    );
  });

  group('RemoteRpcSession start/stop', () {
    test(
      'start is idempotent (a second start replaces the subscription)',
      () async {
        final space = _FakeChannel();
        final session = RemoteRpcSession(
          deviceId: 'd',
          userId: 'u',
          space: space,
          dispatcher: _RecordingDispatcher(),
          workspaceResolver: (_) async => const [],
          capability: SessionCapability.phone,
        );
        await session.start();
        await session.start(); // no-op replacement
        space.inject({'jsonrpc': '2.0', 'method': 'foo', 'id': 1});
        await pumpEventQueue(times: 5);
        expect(space.sent.single['id'], 1);
        await session.stop();
      },
    );

    test(
      'stop cancels the inbound subscription and closes the space',
      () async {
        final space = _FakeChannel();
        final session = RemoteRpcSession(
          deviceId: 'd',
          userId: 'u',
          space: space,
          dispatcher: _RecordingDispatcher(),
          workspaceResolver: (_) async => const [],
          capability: SessionCapability.phone,
        );
        await session.start();
        await session.stop();
        // After stop, frames injected (if any) never reach the dispatcher.
        expect(space.closed, isTrue);
      },
    );
  });

  group('RemoteRpcSession tools/list (phone allow-list filter)', () {
    test('returns only RemoteToolPolicy-allowed tools', () async {
      final space = _FakeChannel();
      final dispatcher = _RecordingDispatcher(
        toolsList: const [
          {'name': 'list_tickets', 'description': 'ok'},
          {'name': 'hire_agent', 'description': 'denied'},
          {'name': 'update_ticket', 'description': 'ok'},
          {'name': 'secret_only', 'description': 'denied'},
        ],
      );
      final session = _session(space, dispatcher);
      addTearDown(session.stop);
      await session.start();

      space.inject({'jsonrpc': '2.0', 'method': 'tools/list', 'id': 1});
      await pumpEventQueue(times: 5);
      final tools = (space.sent.single['result'] as Map)['tools'] as List;
      expect(tools.map((t) => (t as Map)['name']), [
        'list_tickets',
        'update_ticket',
      ]);
    });

    test(
      'passes through when the result has no tools list (non-Map result)',
      () async {
        final space = _FakeChannel();
        final dispatcher = _RecordingDispatcher(rawResult: 'not-a-map');
        final session = _session(space, dispatcher);
        addTearDown(session.stop);
        await session.start();

        space.inject({'jsonrpc': '2.0', 'method': 'tools/list', 'id': 1});
        await pumpEventQueue(times: 5);
        // Returned unchanged — the filter only applies to a real tool list.
        expect(space.sent.single['result'], 'not-a-map');
      },
    );

    test('passes through when result.tools is not a list', () async {
      final space = _FakeChannel();
      final dispatcher = _RecordingDispatcher(
        toolsList: const [],
        toolsIsList: false,
      );
      final session = _session(space, dispatcher);
      addTearDown(session.stop);
      await session.start();

      space.inject({'jsonrpc': '2.0', 'method': 'tools/list', 'id': 1});
      await pumpEventQueue(times: 5);
      expect(space.sent.single['result'], isA<Map>());
    });
  });

  group('RemoteRpcSession tools/call (phone deny + rate limit)', () {
    test(
      'denies a tool not on the remote allow-list with methodNotFound',
      () async {
        final space = _FakeChannel();
        final dispatcher = _RecordingDispatcher();
        final session = _session(space, dispatcher);
        addTearDown(session.stop);
        await session.start();

        space.inject({
          'jsonrpc': '2.0',
          'method': 'tools/call',
          'id': 1,
          'params': {'name': 'hire_agent'},
        });
        await pumpEventQueue(times: 5);
        final err = space.sent.single['error'] as Map<String, dynamic>;
        expect(err['code'], -32601);
        expect(err['message'], contains('not available over remote control'));
      },
    );

    test('denies a non-string tool name', () async {
      final space = _FakeChannel();
      final session = _session(space, _RecordingDispatcher());
      addTearDown(session.stop);
      await session.start();
      space.inject({
        'jsonrpc': '2.0',
        'method': 'tools/call',
        'id': 1,
        'params': {'name': 42},
      });
      await pumpEventQueue(times: 5);
      expect((space.sent.single['error'] as Map)['code'], -32601);
    });

    test('rate-limits a caller past its budget', () async {
      final space = _FakeChannel();
      final session = _session(
        space,
        _RecordingDispatcher(),
        rateLimiter: RemoteRateLimiter(
          maxCallsPerWindow: 1,
          maxMutationsPerWindow: 1,
        ),
      );
      addTearDown(session.stop);
      await session.start();

      // First read tool passes; the second is rejected.
      space.inject({
        'jsonrpc': '2.0',
        'method': 'tools/call',
        'id': 1,
        'params': {'name': 'list_tickets'},
      });
      await pumpEventQueue(times: 5);
      space.inject({
        'jsonrpc': '2.0',
        'method': 'tools/call',
        'id': 2,
        'params': {'name': 'list_tickets'},
      });
      await pumpEventQueue(times: 5);
      expect(space.sent, hasLength(2));
      final denied = space.sent[1]['error'] as Map<String, dynamic>;
      expect(denied['code'], -32005);
      expect(denied['message'], contains('Rate limit'));
    });

    test('forwards an allowed tool to the dispatcher', () async {
      final space = _FakeChannel();
      final dispatcher = _RecordingDispatcher();
      final session = _session(space, dispatcher);
      addTearDown(session.stop);
      await session.start();

      space.inject({
        'jsonrpc': '2.0',
        'method': 'tools/call',
        'id': 1,
        'params': {'name': 'list_tickets'},
      });
      await pumpEventQueue(times: 5);
      expect(dispatcher.handled, ['tools/call']);
      expect(space.sent.single['result'], {'echoed': 'tools/call'});
    });

    test(
      'denies a tool naming a workspace the user is not a member of',
      () async {
        final space = _FakeChannel();
        final dispatcher = _RecordingDispatcher();
        final session = _session(
          space,
          dispatcher,
          // user-1 is a member of ws-mine only.
          resolveRole: (workspaceId, userId) async =>
              workspaceId == 'ws-mine' ? WorkspaceRole.member : null,
        );
        addTearDown(session.stop);
        await session.start();

        space.inject({
          'jsonrpc': '2.0',
          'method': 'tools/call',
          'id': 1,
          'params': {
            'name': 'send_message',
            'arguments': {
              'workspace_id': 'ws-theirs',
              'space_id': 'c1',
              'content': 'pwned',
            },
          },
        });
        await pumpEventQueue(times: 5);
        final err = space.sent.single['error'] as Map<String, dynamic>;
        expect(err['code'], RpcErrorCodes.unauthorized);
        expect(err['message'], contains('Not a member'));
        // The call never reached the tool dispatcher.
        expect(dispatcher.handled, isEmpty);
      },
    );

    test(
      'refuses an unregistered workspace BEFORE the membership lookup',
      () async {
        final space = _FakeChannel();
        final dispatcher = _RecordingDispatcher();
        var roleLookups = 0;
        final session = _session(
          space,
          dispatcher,
          workspaceExists: (_) async => false,
          resolveRole: (workspaceId, userId) async {
            roleLookups++;
            return WorkspaceRole.member;
          },
        );
        addTearDown(session.stop);
        await session.start();

        space.inject({
          'jsonrpc': '2.0',
          'method': 'tools/call',
          'id': 1,
          'params': {
            'name': 'send_message',
            'arguments': {'workspace_id': 'ws-ghost', 'space_id': 'c1'},
          },
        });
        await pumpEventQueue(times: 5);
        final err = space.sent.single['error'] as Map<String, dynamic>;
        expect(err['code'], RpcErrorCodes.notFound);
        // The point of the ordering: resolving the role reads
        // `workspace_members` from the named workspace's own database, and
        // opening one CREATES the file. It must not run for an id the
        // registry does not know.
        expect(roleLookups, 0);
        expect(dispatcher.handled, isEmpty);
      },
    );

    test(
      'forwards a tool naming a workspace the user IS a member of',
      () async {
        final space = _FakeChannel();
        final dispatcher = _RecordingDispatcher();
        final session = _session(
          space,
          dispatcher,
          resolveRole: (workspaceId, userId) async => WorkspaceRole.member,
        );
        addTearDown(session.stop);
        await session.start();

        space.inject({
          'jsonrpc': '2.0',
          'method': 'tools/call',
          'id': 1,
          'params': {
            'name': 'send_message',
            'arguments': {'workspace_id': 'ws-mine', 'space_id': 'c1'},
          },
        });
        await pumpEventQueue(times: 5);
        expect(dispatcher.handled, ['tools/call']);
        expect(space.sent.single['result'], {'echoed': 'tools/call'});
      },
    );

    test(
      'a global tool without workspace_id skips the membership check',
      () async {
        final space = _FakeChannel();
        final dispatcher = _RecordingDispatcher();
        var roleChecks = 0;
        final session = _session(
          space,
          dispatcher,
          resolveRole: (workspaceId, userId) async {
            roleChecks++;
            return null;
          },
        );
        addTearDown(session.stop);
        await session.start();

        space.inject({
          'jsonrpc': '2.0',
          'method': 'tools/call',
          'id': 1,
          // `list_agents` is the global (workspace-less) read the phone is
          // allowed; the newsfeed tools that used to sit here were removed
          // from the allow-list — they are bound to the SERVER OWNER's user.
          'params': {'name': 'list_agents'},
        });
        await pumpEventQueue(times: 5);
        expect(roleChecks, 0);
        expect(dispatcher.handled, ['tools/call']);
      },
    );
  });

  group('RemoteRpcSession inbound bounds', () {
    test(
      'every method consumes the request budget, not just tools/call',
      () async {
        // Regression: only `tools/call` was throttled, so `repo/call`,
        // `tools/list`, `op/list` and `session/list_workspaces` (a DB query per
        // call) could be driven at line rate by an authenticated client.
        final space = _FakeChannel();
        final dispatcher = _RecordingDispatcher();
        final session = _session(
          space,
          dispatcher,
          requestLimiter: RemoteRateLimiter(
            maxCallsPerWindow: 2,
            maxMutationsPerWindow: 2,
          ),
        );
        addTearDown(session.stop);
        await session.start();

        for (var i = 1; i <= 3; i++) {
          space.inject({
            'jsonrpc': '2.0',
            'method': 'session/list_workspaces',
            'id': i,
          });
        }
        await pumpEventQueue(times: 10);

        expect(space.sent, hasLength(3));
        final last = space.sent.last['error'] as Map<String, dynamic>;
        expect(last['code'], RpcErrorCodes.rateLimited);
        expect(dispatcher.handled.length, lessThan(3));
      },
    );

    test(
      'refuses work past the in-flight cap instead of queueing it',
      () async {
        final space = _FakeChannel();
        final gate = Completer<void>();
        final dispatcher = _RecordingDispatcher(onHandle: (_) => gate.future);
        final session = _session(space, dispatcher, maxConcurrentRequests: 1);
        addTearDown(session.stop);
        await session.start();

        space
          ..inject({'jsonrpc': '2.0', 'method': 'tools/list', 'id': 1})
          ..inject({'jsonrpc': '2.0', 'method': 'tools/list', 'id': 2});
        await pumpEventQueue(times: 5);

        // The first is parked in the dispatcher; the second is refused rather
        // than piling up behind it.
        expect(space.sent, hasLength(1));
        expect(
          (space.sent.single['error'] as Map)['code'],
          RpcErrorCodes.rateLimited,
        );
        gate.complete();
        await pumpEventQueue(times: 5);
      },
    );
  });

  group('RemoteRpcSession handler deadline', () {
    test('a hung handler times out and frees its concurrency slot', () async {
      final space = _FakeChannel();
      final gate = Completer<void>();
      // Gate only the FIRST request; later ones must sail through once the
      // deadline has freed the parked slot.
      var gated = false;
      final dispatcher = _RecordingDispatcher(
        onHandle: (_) {
          if (gated) {
            return Future<void>.value();
          }
          gated = true;
          return gate.future;
        },
      );
      // Cap of 1: if the deadline did NOT free the slot, the second request
      // would be refused with -32005 — that is exactly the lockout this
      // deadline exists to make self-healing.
      final session = _session(
        space,
        dispatcher,
        maxConcurrentRequests: 1,
        handlerTimeout: const Duration(milliseconds: 50),
      );
      addTearDown(session.stop);
      await session.start();

      space.inject({'jsonrpc': '2.0', 'method': 'tools/list', 'id': 1});
      await Future<void>.delayed(const Duration(milliseconds: 120));
      await pumpEventQueue(times: 5);

      final err = space.sent.single['error'] as Map<String, dynamic>;
      expect(err['code'], RpcErrorCodes.handlerTimeout);
      expect('$err', contains('timed out'));

      // The slot is free: a fresh request is served, not refused.
      space.inject({'jsonrpc': '2.0', 'method': 'tools/list', 'id': 2});
      await pumpEventQueue(times: 5);
      expect(space.sent, hasLength(2));
      expect(space.sent[1]['result'], isA<Map>());

      // The abandoned handler finishes late; its response is never sent (the
      // id was already answered with the timeout error).
      gate.complete();
      await pumpEventQueue(times: 5);
      expect(space.sent, hasLength(2));
    });

    test(
      'a repo/call uses the op-declared budget over the session default',
      () async {
        final space = _FakeChannel();
        final gate = Completer<void>();
        final repoOps = RepoOpDispatcher(
          registry: RepoOpRegistry([
            RepoOp(
              name: 'slow.op',
              kind: RepoOpKind.read,
              workspaceScoped: false,
              // The op declares 40ms; the session default below is 10 minutes,
              // so only the per-op budget can fire here.
              timeout: const Duration(milliseconds: 40),
              handler: (ctx) async {
                await gate.future;
                return {'ok': true};
              },
            ),
          ]),
          mapException: (_) => null,
        );
        final session = RemoteRpcSession(
          deviceId: 'd',
          userId: 'u',
          space: space,
          dispatcher: _RecordingDispatcher(),
          workspaceResolver: (_) async => const [],
          capability: SessionCapability.fullClient,
          repoOps: repoOps,
          handlerTimeout: const Duration(minutes: 10),
        );
        addTearDown(session.stop);
        await session.start();

        space.inject({
          'jsonrpc': '2.0',
          'method': 'repo/call',
          'id': 1,
          'params': {'op': 'slow.op'},
        });
        await Future<void>.delayed(const Duration(milliseconds: 120));
        await pumpEventQueue(times: 5);

        final err = space.sent.single['error'] as Map<String, dynamic>;
        expect(err['code'], RpcErrorCodes.handlerTimeout);
        gate.complete();
        await pumpEventQueue(times: 5);
      },
    );

    test('the refusal warning names the in-flight ops', () async {
      final warnings = <String>[];
      CcHostLog.sink = (level, message, [_, _]) {
        if (level == CcHostLogLevel.warning) {
          warnings.add(message);
        }
      };
      addTearDown(() => CcHostLog.sink = null);

      final space = _FakeChannel();
      final gate = Completer<void>();
      final repoOps = RepoOpDispatcher(
        registry: RepoOpRegistry([
          RepoOp(
            name: 'slow.op',
            kind: RepoOpKind.read,
            workspaceScoped: false,
            handler: (ctx) async {
              await gate.future;
              return {'ok': true};
            },
          ),
        ]),
        mapException: (_) => null,
      );
      final session = RemoteRpcSession(
        deviceId: 'd',
        userId: 'u',
        space: space,
        dispatcher: _RecordingDispatcher(),
        workspaceResolver: (_) async => const [],
        capability: SessionCapability.fullClient,
        repoOps: repoOps,
        maxConcurrentRequests: 1,
        // Long deadline: the refusal below must come from the cap, not from
        // this request timing out first.
        handlerTimeout: const Duration(minutes: 10),
      );
      addTearDown(session.stop);
      await session.start();

      space
        ..inject({
          'jsonrpc': '2.0',
          'method': 'repo/call',
          'id': 1,
          'params': {'op': 'slow.op'},
        })
        ..inject({'jsonrpc': '2.0', 'method': 'tools/list', 'id': 2});
      await pumpEventQueue(times: 5);

      expect(
        (space.sent.single['error'] as Map)['code'],
        RpcErrorCodes.rateLimited,
      );
      // The warning names the parked op — "N requests already in flight"
      // without names is undiagnosable from a server log.
      expect(warnings, isNotEmpty);
      expect(warnings.last, contains('repo/call slow.op'));
      gate.complete();
      await pumpEventQueue(times: 5);
    });
  });

  group('RemoteRpcSession initialize capabilities', () {
    test('without repoOps returns the base capabilities unchanged', () async {
      final space = _FakeChannel();
      final session = _session(space, _RecordingDispatcher());
      addTearDown(session.stop);
      await session.start();
      space.inject({'jsonrpc': '2.0', 'method': 'initialize', 'id': 1});
      await pumpEventQueue(times: 5);
      final result = space.sent.single['result'] as Map<String, dynamic>;
      // Base dispatcher returns capabilities with no repoRpc/subscriptions —
      // but the build identity is always advertised (stale-binary detection
      // needs it on every session shape, thin client included).
      expect((result['capabilities'] as Map).containsKey('repoRpc'), isFalse);
      expect(
        (result['capabilities'] as Map)['serverVersion'],
        BuildInfo.buildVersion,
      );
      expect((result['capabilities'] as Map)['gitSha'], BuildInfo.buildGitSha);
    });

    test(
      'with repoOps + watchQueries advertises catalogVersion + snapshots',
      () async {
        final space = _FakeChannel();
        final dispatcher = _RecordingDispatcher();
        final repoOps = RepoOpDispatcher(
          registry: RepoOpRegistry(const [], catalogVersion: 9),
          mapException: (_) => null,
        );
        final watchQueries = WatchQueryRegistry(const []);
        final session = RemoteRpcSession(
          deviceId: 'd',
          userId: 'u',
          space: space,
          dispatcher: dispatcher,
          workspaceResolver: (_) async => const [],
          capability: SessionCapability.phone,
          repoOps: repoOps,
          watchQueries: watchQueries,
        );
        addTearDown(session.stop);
        await session.start();
        space.inject({'jsonrpc': '2.0', 'method': 'initialize', 'id': 1});
        await pumpEventQueue(times: 5);
        final caps =
            (space.sent.single['result'] as Map)['capabilities'] as Map;
        expect((caps['repoRpc'] as Map)['catalogVersion'], 9);
        expect(caps['serverVersion'], BuildInfo.buildVersion);
        expect((caps['subscriptions'] as Map)['snapshot'], isTrue);
        // No sync.watch query → delta honestly advertised false.
        expect((caps['subscriptions'] as Map)['delta'], isFalse);
      },
    );

    test('advertises delta when a sync.watch query is registered', () async {
      final space = _FakeChannel();
      final watchQueries = WatchQueryRegistry([
        WatchQuery(
          name: 'sync.watch',
          workspaceScoped: false,
          handler: (_) => const Stream<Map<String, dynamic>>.empty(),
        ),
      ]);
      final session = RemoteRpcSession(
        deviceId: 'd',
        userId: 'u',
        space: space,
        dispatcher: _RecordingDispatcher(),
        workspaceResolver: (_) async => const [],
        capability: SessionCapability.phone,
        repoOps: RepoOpDispatcher(
          registry: RepoOpRegistry(const []),
          mapException: (_) => null,
        ),
        watchQueries: watchQueries,
      );
      addTearDown(session.stop);
      await session.start();
      space.inject({'jsonrpc': '2.0', 'method': 'initialize', 'id': 1});
      await pumpEventQueue(times: 5);
      final subs =
          ((space.sent.single['result'] as Map)['capabilities']
                  as Map)['subscriptions']
              as Map;
      expect(subs['delta'], isTrue);
    });

    test('initialize tolerates a non-Map capabilities block', () async {
      final space = _FakeChannel();
      final dispatcher = _RecordingDispatcher(capsBlock: 'not-a-map');
      final session = RemoteRpcSession(
        deviceId: 'd',
        userId: 'u',
        space: space,
        dispatcher: dispatcher,
        workspaceResolver: (_) async => const [],
        capability: SessionCapability.phone,
        repoOps: RepoOpDispatcher(
          registry: RepoOpRegistry(const []),
          mapException: (_) => null,
        ),
      );
      addTearDown(session.stop);
      await session.start();
      space.inject({'jsonrpc': '2.0', 'method': 'initialize', 'id': 1});
      await pumpEventQueue(times: 5);
      // repoRpc is still injected into a fresh caps map (no crash).
      final caps = (space.sent.single['result'] as Map)['capabilities'] as Map;
      expect((caps['repoRpc'] as Map)['catalogVersion'], 1);
    });
  });

  group('RemoteRpcSession repo/call + op/list availability', () {
    test('without repoOps, repo/call is method-not-found', () async {
      final space = _FakeChannel();
      final session = _session(space, _RecordingDispatcher());
      addTearDown(session.stop);
      await session.start();
      space.inject({'jsonrpc': '2.0', 'method': 'repo/call', 'id': 1});
      await pumpEventQueue(times: 5);
      expect(
        (space.sent.single['error'] as Map)['code'],
        RpcErrorCodes.methodNotFound,
      );
      expect(
        (space.sent.single['error'] as Map)['message'],
        'repo/call not available',
      );
    });

    test('without repoOps, op/list is method-not-found', () async {
      final space = _FakeChannel();
      final session = _session(space, _RecordingDispatcher());
      addTearDown(session.stop);
      await session.start();
      space.inject({'jsonrpc': '2.0', 'method': 'op/list', 'id': 1});
      await pumpEventQueue(times: 5);
      expect(
        (space.sent.single['error'] as Map)['message'],
        'op/list not available',
      );
    });

    test('with repoOps, repo/call routes to the dispatcher', () async {
      final space = _FakeChannel();
      final repoOps = RepoOpDispatcher(
        registry: RepoOpRegistry([
          const RepoOp(
            name: 'thing.get',
            kind: RepoOpKind.read,
            workspaceScoped: false,
            handler: _okHandler,
          ),
        ]),
        mapException: (_) => null,
      );
      final session = RemoteRpcSession(
        deviceId: 'd',
        userId: 'u',
        space: space,
        dispatcher: _RecordingDispatcher(),
        workspaceResolver: (_) async => const [],
        capability: SessionCapability.fullClient,
        repoOps: repoOps,
      );
      addTearDown(session.stop);
      await session.start();
      space.inject({
        'jsonrpc': '2.0',
        'method': 'repo/call',
        'id': 1,
        'params': {'op': 'thing.get'},
      });
      await pumpEventQueue(times: 5);
      expect((space.sent.single['result'] as Map)['data'], {'ok': true});
    });

    test(
      'the session remoteAddress reaches recordActivity as the audit ip',
      () async {
        final space = _FakeChannel();
        final sink = <String?>[];
        final repoOps = RepoOpDispatcher(
          registry: RepoOpRegistry([
            const RepoOp(
              name: 'thing.mutate',
              kind: RepoOpKind.mutate,
              handler: _okHandler,
            ),
          ]),
          mapException: (_) => null,
          recordActivity:
              ({
                required String workspaceId,
                required String userId,
                required String deviceId,
                required String action,
                String? targetType,
                String? targetId,
                String? ip,
              }) async => sink.add(ip),
        );
        final session = RemoteRpcSession(
          deviceId: 'd',
          userId: 'u',
          space: space,
          dispatcher: _RecordingDispatcher(),
          workspaceResolver: (_) async => const [],
          capability: SessionCapability.fullClient,
          repoOps: repoOps,
          remoteAddress: '198.51.100.23',
        );
        addTearDown(session.stop);
        await session.start();
        space.inject({
          'jsonrpc': '2.0',
          'method': 'repo/call',
          'id': 1,
          'params': {
            'op': 'thing.mutate',
            'args': {'workspace_id': 'ws-1'},
          },
        });
        await pumpEventQueue(times: 5);
        expect(sink, ['198.51.100.23']);
      },
    );

    test('a session with no peer address audits a null ip', () async {
      final space = _FakeChannel();
      final sink = <String?>[];
      final repoOps = RepoOpDispatcher(
        registry: RepoOpRegistry([
          const RepoOp(
            name: 'thing.mutate',
            kind: RepoOpKind.mutate,
            handler: _okHandler,
          ),
        ]),
        mapException: (_) => null,
        recordActivity:
            ({
              required String workspaceId,
              required String userId,
              required String deviceId,
              required String action,
              String? targetType,
              String? targetId,
              String? ip,
            }) async => sink.add(ip),
      );
      final session = RemoteRpcSession(
        deviceId: 'd',
        userId: 'u',
        space: space,
        dispatcher: _RecordingDispatcher(),
        workspaceResolver: (_) async => const [],
        capability: SessionCapability.fullClient,
        repoOps: repoOps,
      );
      addTearDown(session.stop);
      await session.start();
      space.inject({
        'jsonrpc': '2.0',
        'method': 'repo/call',
        'id': 1,
        'params': {
          'op': 'thing.mutate',
          'args': {'workspace_id': 'ws-1'},
        },
      });
      await pumpEventQueue(times: 5);
      expect(sink, [isNull]);
    });

    test('with repoOps, op/list returns the catalog', () async {
      final space = _FakeChannel();
      final repoOps = RepoOpDispatcher(
        registry: RepoOpRegistry(const [], catalogVersion: 3),
        mapException: (_) => null,
      );
      final session = RemoteRpcSession(
        deviceId: 'd',
        userId: 'u',
        space: space,
        dispatcher: _RecordingDispatcher(),
        workspaceResolver: (_) async => const [],
        capability: SessionCapability.fullClient,
        repoOps: repoOps,
      );
      addTearDown(session.stop);
      await session.start();
      space.inject({'jsonrpc': '2.0', 'method': 'op/list', 'id': 1});
      await pumpEventQueue(times: 5);
      final result = space.sent.single['result'] as Map<String, dynamic>;
      expect(result['catalog_version'], 3);
    });
  });

  group('RemoteRpcSession sub/* availability', () {
    test('without watchQueries, sub/subscribe is method-not-found', () async {
      final space = _FakeChannel();
      final session = _session(space, _RecordingDispatcher());
      addTearDown(session.stop);
      await session.start();
      space.inject({'jsonrpc': '2.0', 'method': 'sub/subscribe', 'id': 1});
      await pumpEventQueue(times: 5);
      expect(
        (space.sent.single['error'] as Map)['message'],
        'sub/subscribe not available',
      );
    });

    test('without watchQueries, sub/unsubscribe is method-not-found', () async {
      final space = _FakeChannel();
      final session = _session(space, _RecordingDispatcher());
      addTearDown(session.stop);
      await session.start();
      space.inject({'jsonrpc': '2.0', 'method': 'sub/unsubscribe', 'id': 1});
      await pumpEventQueue(times: 5);
      expect(
        (space.sent.single['error'] as Map)['message'],
        'sub/unsubscribe not available',
      );
    });

    test('with watchQueries, sub/subscribe routes to the manager', () async {
      final space = _FakeChannel();
      final watchQueries = WatchQueryRegistry([
        WatchQuery(
          name: 'newsfeed',
          workspaceScoped: false,
          handler: (_) => const Stream<Map<String, dynamic>>.empty(),
        ),
      ]);
      final session = RemoteRpcSession(
        deviceId: 'd',
        userId: 'u',
        space: space,
        dispatcher: _RecordingDispatcher(),
        workspaceResolver: (_) async => const [],
        capability: SessionCapability.fullClient,
        watchQueries: watchQueries,
      );
      addTearDown(session.stop);
      await session.start();
      space.inject({
        'jsonrpc': '2.0',
        'method': 'sub/subscribe',
        'id': 1,
        'params': {'query': 'newsfeed'},
      });
      await pumpEventQueue(times: 5);
      final result = space.sent.single['result'] as Map;
      expect(result['subscriptionId'], isA<String>());
      expect(result['rev'], 0);
    });
  });

  group('RemoteRpcSession _send resilience', () {
    test('drops a response silently when the space is closed', () async {
      final space = _FakeChannel(open: false);
      final session = RemoteRpcSession(
        deviceId: 'd',
        userId: 'u',
        space: space,
        dispatcher: _RecordingDispatcher(),
        workspaceResolver: (_) async => const [],
        capability: SessionCapability.phone,
      );
      addTearDown(session.stop);
      await session.start();
      space.inject({'jsonrpc': '2.0', 'method': 'foo', 'id': 1});
      await pumpEventQueue(times: 5);
      // Space closed → no send attempted.
      expect(space.sent, isEmpty);
    });

    test('swallows a send failure (logged, never rethrown)', () async {
      final space = _FakeChannel(throwOnSend: true);
      final session = RemoteRpcSession(
        deviceId: 'd',
        userId: 'u',
        space: space,
        dispatcher: _RecordingDispatcher(),
        workspaceResolver: (_) async => const [],
        capability: SessionCapability.phone,
      );
      addTearDown(session.stop);
      await session.start();
      // Must not throw even though send throws.
      space.inject({'jsonrpc': '2.0', 'method': 'foo', 'id': 1});
      await pumpEventQueue(times: 5);
    });
  });

  test('encodeFrame JSON-encodes a frame map', () {
    final s = encodeFrame({
      'jsonrpc': '2.0',
      'id': 1,
      'result': {'ok': true},
    });
    expect(jsonDecode(s), {
      'jsonrpc': '2.0',
      'id': 1,
      'result': {'ok': true},
    });
  });
}

RemoteRpcSession _session(
  _FakeChannel space,
  _RecordingDispatcher dispatcher, {
  RemoteRateLimiter? rateLimiter,
  RemoteRateLimiter? requestLimiter,
  WorkspaceRoleResolver? resolveRole,
  WorkspaceExistsChecker? workspaceExists,
  int maxConcurrentRequests = 16,
  Duration handlerTimeout = const Duration(seconds: 60),
}) => RemoteRpcSession(
  deviceId: 'phone-1',
  userId: 'user-1',
  space: space,
  dispatcher: dispatcher,
  workspaceResolver: (_) async => const [],
  capability: SessionCapability.phone,
  rateLimiter: rateLimiter,
  requestLimiter: requestLimiter,
  maxConcurrentRequests: maxConcurrentRequests,
  handlerTimeout: handlerTimeout,
  resolveRole: resolveRole,
  workspaceExists: workspaceExists,
);

const _okHandler = _emptyHandler;

Future<Map<String, dynamic>> _emptyHandler(RepoOpContext ctx) async => {
  'ok': true,
};

/// A controllable [RemoteRpcChannelPort]: tests inject inbound frames and read
/// outbound frames and can force `isOpen` / a throwing `send`.
class _FakeChannel implements RemoteRpcChannelPort {
  _FakeChannel({bool open = true, this.throwOnSend = false}) : _open = open;

  final bool throwOnSend;
  final StreamController<Map<String, dynamic>> _incoming =
      StreamController<Map<String, dynamic>>.broadcast();
  final List<Map<String, dynamic>> sent = [];
  bool _open;
  bool closed = false;

  void inject(Map<String, dynamic> frame) => _incoming.add(frame);

  @override
  Stream<Map<String, dynamic>> get incoming => _incoming.stream;

  @override
  Stream<RemoteChannelState> get state =>
      const Stream<RemoteChannelState>.empty();

  @override
  bool get isOpen => _open;

  @override
  Future<void> send(Map<String, dynamic> frame) async {
    if (throwOnSend) {
      throw StateError('secret-leak: send failed');
    }
    sent.add(frame);
  }

  @override
  Future<void> close() async {
    _open = false;
    closed = true;
    if (!_incoming.isClosed) {
      await _incoming.close();
    }
  }
}

/// A minimal [RpcDispatcher]: returns a configurable `initialize` / `tools/list`
/// shape and echoes everything else. [errorOn], when matched, throws so the
/// session's handler-exception path fires.
class _RecordingDispatcher implements RpcDispatcher {
  _RecordingDispatcher({
    this.toolsList = const [],
    this.toolsIsList = true,
    this.rawResult,
    this.capsBlock,
    this.onHandle,
  });

  /// Optional gate: awaited before the response is produced, so a test can
  /// hold a request in flight.
  final Future<void> Function(JsonRpcRequest request)? onHandle;

  final List<Map<String, dynamic>> toolsList;
  final bool toolsIsList;
  final Object? rawResult;
  final Object? capsBlock;
  String? errorOn;
  final List<String> handled = [];

  @override
  Future<Map<String, dynamic>> handleRequest(JsonRpcRequest request) async {
    handled.add(request.method);
    if (onHandle != null) {
      await onHandle!(request);
    }
    if (errorOn != null && request.method == errorOn) {
      throw StateError('secret-leak: boom');
    }
    if (request.method == 'initialize') {
      final result = <String, dynamic>{
        'protocolVersion': '2025-01-01',
        if (capsBlock != null)
          'capabilities': capsBlock
        else
          'capabilities': <String, dynamic>{'tools': <String, dynamic>{}},
      };
      return {'jsonrpc': '2.0', 'id': request.id, 'result': result};
    }
    if (request.method == 'tools/list') {
      if (rawResult != null) {
        return {'jsonrpc': '2.0', 'id': request.id, 'result': rawResult};
      }
      return {
        'jsonrpc': '2.0',
        'id': request.id,
        'result': <String, dynamic>{
          'tools': toolsIsList ? toolsList : 'not-a-list',
        },
      };
    }
    return {
      'jsonrpc': '2.0',
      'id': request.id,
      'result': <String, dynamic>{'echoed': request.method},
    };
  }
}
