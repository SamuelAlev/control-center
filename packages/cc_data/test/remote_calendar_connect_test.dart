import 'package:cc_connect_core/cc_connect_core.dart'
    show ConnectOAuthLane, SignInAttemptStatus, SignInUnavailableReason;
import 'package:cc_data/cc_data.dart';
import 'package:cc_domain/cc_domain.dart';
import 'package:cc_domain/core/domain/value_objects/forge_connection.dart';
import 'package:cc_domain/core/domain/value_objects/forge_host.dart';
import 'package:cc_domain/features/connect/domain/value_objects/connect_health_error.dart';
import 'package:cc_rpc/cc_rpc.dart';
import 'package:test/test.dart';

/// Pins the client data layer behind sign-ins: the generic `oauth.*` surface
/// (lanes, begin/status/complete, connections, disconnect), Google Calendar
/// riding the `google` lane with its workspace, the owner-only `connect.*`
/// ops and the GitHub App setup ops.
void main() {
  late _Host host;
  late RemoteRpcClient client;

  setUp(() {
    final (server, clientChannel) = InProcessRpcChannel.pair();
    host = _Host(server);
    client = RemoteRpcClient(clientChannel)..start();
  });

  tearDown(() async => client.close());

  Map<String, dynamic> attempt({
    String status = 'pending',
    String mode = 'connect',
    String? error,
    String lane = 'google',
  }) => {
    'login_id': 'AAAAAAAAAAAAAAAAAAAAAA',
    'lane': lane,
    'mode': mode,
    'url': 'https://accounts.google.com/o/oauth2/v2/auth?x=1',
    'expires_at': '2026-11-08T12:10:00Z',
    'status': status,
    'account': ?(status == 'succeeded' ? 'sam@example.com' : null),
    'error': ?error,
  };

  group('Google Calendar connect', () {
    test('begins on the google lane, scoped to the workspace', () async {
      host.callResults['oauth.begin'] = attempt();
      final started = await RemoteProviderSignIn(
        client,
      ).begin(ConnectOAuthLane.google, workspaceId: 'ws-1');
      final call = host.lastCall('oauth.begin')!;
      expect(call.args, {'lane': 'google', 'workspace_id': 'ws-1'});
      expect(started.lane, ConnectOAuthLane.google);
      expect(started.mode, SignInLaneMode.connect);
      expect(started.status, SignInAttemptStatus.pending);
      expect(started.expiresAt, DateTime.utc(2026, 11, 8, 12, 10));
    });

    test('disconnect forwards the account_id', () async {
      await RemoteCalendarConnect(client).disconnect('acc-1');
      expect(host.lastCall('calendar.disconnect')!.args['account_id'], 'acc-1');
    });

    test('never calls the deleted device-flow ops', () async {
      host.callResults['oauth.begin'] = attempt();
      await RemoteProviderSignIn(
        client,
      ).begin(ConnectOAuthLane.google, workspaceId: 'ws-1');
      await RemoteCalendarConnect(client).disconnect('acc-1');
      expect(
        host.calls.map((c) => c.op),
        isNot(
          anyOf(
            contains('calendar.connectInfo'),
            contains('calendar.beginConnect'),
            contains('calendar.pollConnect'),
          ),
        ),
      );
    });
  });

  group('RemoteProviderSignIn', () {
    test('lanes parse mode, callback and error; unknown lanes drop', () async {
      host.callResults['oauth.lanes'] = {
        'lanes': [
          {
            'lane': 'github',
            'mode': 'own',
            'redirect_uri': 'https://cc.example/oauth/github/callback',
            'error': '',
          },
          {'lane': 'linear_app', 'mode': 'connect'},
          {'lane': 'google', 'mode': 'unavailable', 'error': 'Not set up.'},
          {'lane': 'myspace', 'mode': 'own'},
        ],
      };
      final lanes = await RemoteProviderSignIn(client).lanes();
      expect(host.lastCall('oauth.lanes')!.args, {'workspace_id': null});
      expect(lanes.map((l) => l.lane), [
        ConnectOAuthLane.github,
        ConnectOAuthLane.linearApp,
        ConnectOAuthLane.google,
      ]);
      expect(lanes[0].mode, SignInLaneMode.own);
      expect(lanes[0].redirectUri, 'https://cc.example/oauth/github/callback');
      expect(lanes[1].mode, SignInLaneMode.connect);
      expect(lanes[2].mode, SignInLaneMode.unavailable);
      expect(lanes[2].error, 'Not set up.');
    });

    test('status and complete carry the login id and workspace', () async {
      host.callResults['oauth.status'] = attempt(
        status: 'failed',
        error: 'access_denied',
      );
      host.callResults['oauth.complete'] = attempt(status: 'succeeded');
      final sign = RemoteProviderSignIn(client);
      final polled = await sign.status(
        'AAAAAAAAAAAAAAAAAAAAAA',
        workspaceId: 'ws-1',
      );
      expect(polled.status, SignInAttemptStatus.failed);
      expect(polled.error, SignInFailure.accessDenied);
      final done = await sign.complete(
        loginId: 'AAAAAAAAAAAAAAAAAAAAAA',
        code: 'ABCD2345',
        workspaceId: 'ws-1',
      );
      expect(host.lastCall('oauth.complete')!.args, {
        'login_id': 'AAAAAAAAAAAAAAAAAAAAAA',
        'code': 'ABCD2345',
        'workspace_id': 'ws-1',
      });
      expect(done.status, SignInAttemptStatus.succeeded);
      expect(done.account, 'sam@example.com');
    });

    test('an unknown failure code reads as unknown, not as success', () {
      final parsed = SignInAttempt.fromJson(
        attempt(status: 'failed', error: 'brand_new_code'),
      );
      expect(parsed.error, SignInFailure.unknown);
      expect(parsed.status.isTerminal, isTrue);
    });

    test('lanes carry why an unavailable lane cannot sign in', () async {
      host.callResults['oauth.lanes'] = {
        'lanes': [
          {
            'lane': 'github',
            'mode': 'unavailable',
            'unavailable_reason': 'connect_pins_pending',
          },
          {
            'lane': 'google',
            'mode': 'unavailable',
            'error': 'Add the client secret.',
            'unavailable_reason': 'misconfigured',
          },
          {'lane': 'linear', 'mode': 'connect'},
          {
            'lane': 'slack',
            'mode': 'unavailable',
            'unavailable_reason': 'from_the_future',
          },
        ],
      };
      final lanes = await RemoteProviderSignIn(
        client,
      ).lanes(workspaceId: 'ws-1');
      expect(
        lanes[0].unavailableReason,
        SignInUnavailableReason.connectPinsPending,
      );
      expect(lanes[1].unavailableReason, SignInUnavailableReason.misconfigured);
      expect(lanes[1].error, 'Add the client secret.');
      expect(lanes[2].unavailableReason, isNull);
      expect(lanes[3].unavailableReason, SignInUnavailableReason.notConfigured);
    });

    test('an attempt the server forgot reads as attempt_unknown', () async {
      host.callResults['oauth.status'] = {
        'login_id': 'AAAAAAAAAAAAAAAAAAAAAA',
        'mode': 'unavailable',
        'url': '',
        'expires_at': '2026-11-09T10:00:00.000Z',
        'status': 'failed',
        'error': 'attempt_unknown',
      };
      final polled = await RemoteProviderSignIn(client).status(
        'AAAAAAAAAAAAAAAAAAAAAA',
        workspaceId: 'ws-1',
        lane: ConnectOAuthLane.github,
      );
      expect(host.lastCall('oauth.status')!.args, {
        'login_id': 'AAAAAAAAAAAAAAAAAAAAAA',
        'workspace_id': 'ws-1',
        'lane': 'github',
      });
      expect(polled.lane, ConnectOAuthLane.github);
      expect(polled.status, SignInAttemptStatus.failed);
      expect(polled.error, SignInFailure.attemptUnknown);
    });

    test(
      'forge connections read status and scope with no oauth overlay',
      () async {
        host.callResults['forge.listConnections'] = {
          'connections': [
            {
              'forge': 'github',
              'status': 'paused',
              'scope': 'workspace',
              'username': 'octo',
              'source': 'connect',
            },
            {
              'forge': 'gitlab',
              'status': 'connected',
              'scope': 'global',
              'username': 'Lab',
              'source': 'settings',
            },
            {'forge': 'bitbucket', 'status': 'whatever'},
          ],
        };
        final list = await RemoteForgeConnections(
          client,
        ).list(workspaceId: 'ws-1');
        expect(host.lastCall('oauth.connections')!.op, isEmpty);
        expect(list[0].status, ForgeConnectionStatus.paused);
        expect(list[0].scope, ForgeCredentialScope.workspace);
        expect(list[0].isUsable, isFalse);
        expect(list[1].isUsable, isTrue);
        expect(list[2].status, ForgeConnectionStatus.notConnected);
        expect(RemoteForgeConnections.viewerLogins(list), {
          ForgeHost.gitlab: 'lab',
        });
      },
    );

    test(
      'connections parse every field and disconnect names the lane',
      () async {
        host.callResults['oauth.connections'] = {
          'connections': [
            {
              'lane': 'linear',
              'status': 'connected',
              'account': 'Sam',
              'account_id': 42,
              'slot': 'global',
              'source': 'connect',
            },
            {
              'lane': 'linear_app',
              'status': 'needs_sign_in',
              'slot': 'workspace',
            },
          ],
        };
        final sign = RemoteProviderSignIn(client);
        final list = await sign.connections(workspaceId: 'ws-1');
        expect(list.first.account, 'Sam');
        expect(list.first.accountId, '42');
        expect(list.first.source, SignInLaneMode.connect);
        expect(list.first.isUsable, isTrue);
        expect(list.last.slot, SignInSlot.workspace);
        expect(list.last.status, ForgeConnectionStatus.needsSignIn);
        expect(list.last.isUsable, isFalse);

        await sign.disconnect(ConnectOAuthLane.linearApp, workspaceId: 'ws-1');
        expect(host.lastCall('oauth.disconnect')!.args, {
          'lane': 'linear_app',
          'workspace_id': 'ws-1',
        });
      },
    );
  });

  group('RemoteConnectSettings', () {
    test('status decodes health, pins and lanes', () async {
      host.callResults['connect.status'] = {
        'mode': 'hosted',
        'url': 'https://connect.example',
        'locked': true,
        'install_id': 'inst_123',
        'usable': false,
        'error': 'hosted_unprovisioned',
        'stale': true,
        'pending_pins': {'k1': 'v1'},
        'epoch': 7,
        'lanes': [
          {'lane': 'github', 'source': 'own', 'error': ''},
          {'lane': 'klipy', 'source': 'connect'},
        ],
      };
      final status = await RemoteConnectSettings(client).status();
      expect(status.mode, ConnectModeSetting.hosted);
      expect(status.locked, isTrue);
      expect(status.installId, 'inst_123');
      expect(status.error, ConnectHealthError.hostedUnprovisioned);
      expect(status.stale, isTrue);
      expect(status.pendingPins, {'k1': 'v1'});
      expect(status.epoch, 7);
      expect(status.lanes.map((l) => l.source), [
        ConnectLaneSource.own,
        ConnectLaneSource.connect,
      ]);
    });

    test('configure sends the mode and only a custom url', () async {
      host.callResults['connect.configure'] = {'mode': 'custom'};
      final settings = RemoteConnectSettings(client);
      await settings.configure(
        ConnectModeSetting.custom,
        url: 'https://connect.example',
      );
      expect(host.lastCall('connect.configure')!.args, {
        'mode': 'custom',
        'url': 'https://connect.example',
      });
      await settings.configure(ConnectModeSetting.off);
      expect(host.lastCall('connect.configure')!.args, {'mode': 'off'});
    });

    test('test, confirmPins and rotateKey hit their ops', () async {
      final settings = RemoteConnectSettings(client);
      await settings.test();
      await settings.confirmPins();
      await settings.rotateKey();
      expect(host.calls.map((c) => c.op), [
        'connect.test',
        'connect.confirmPins',
        'connect.rotateKey',
      ]);
      expect(host.lastCall('connect.rotateKey')!.args, isEmpty);
    });

    test('a forced rotation says so', () async {
      await RemoteConnectSettings(client).rotateKey(force: true);
      expect(host.lastCall('connect.rotateKey')!.args, {'force': true});
    });
  });

  group('RemoteGitHubAppSetup', () {
    test('installations decode', () async {
      host.callResults['github.installations'] = {
        'installations': [
          {
            'installation_id': 9,
            'account_id': 5,
            'account_login': 'acme',
            'target_type': 'Organization',
            'suspended': true,
          },
          {
            'installation_id': 10,
            'account_login': 'sam',
            'target_type': 'User',
          },
        ],
      };
      final setup = RemoteGitHubAppSetup(client);
      final list = await setup.installations(workspaceId: 'ws-1');
      expect(list.first.installationId, '9');
      expect(list.first.isOrganization, isTrue);
      expect(list.first.suspended, isTrue);
      expect(list.last.isOrganization, isFalse);
      expect(list.last.suspended, isFalse);
    });

    test('manifest and install return their urls', () async {
      host.callResults['github.manifest.begin'] = {'url': 'https://a'};
      host.callResults['github.install.begin'] = {'url': 'https://b'};
      final setup = RemoteGitHubAppSetup(client);
      expect(await setup.beginManifest(), 'https://a');
      expect(host.lastCall('github.manifest.begin')!.args, isEmpty);
      await setup.beginManifest(organization: '  acme ');
      expect(host.lastCall('github.manifest.begin')!.args, {
        'organization': 'acme',
      });
      expect(await setup.beginInstall(workspaceId: 'ws-1'), 'https://b');
      expect(host.lastCall('github.install.begin')!.args, {
        'workspace_id': 'ws-1',
      });
    });
  });
}

/// Records a `repo/call` invocation.
class _Call {
  const _Call({required this.op, required this.args});
  final String op;
  final Map<String, dynamic> args;
}

class _Host {
  _Host(this.space) {
    space.incoming.listen(_onFrame);
  }

  final RemoteRpcChannelPort space;
  final List<_Call> calls = [];
  final Map<String, Map<String, dynamic>> callResults = {};

  _Call? lastCall(String op) => calls.lastWhere(
    (c) => c.op == op,
    orElse: () => const _Call(op: '', args: {}),
  );

  void _onFrame(Map<String, dynamic> frame) {
    final id = frame['id'];
    final method = frame['method'] as String?;
    final params = (frame['params'] as Map?)?.cast<String, dynamic>() ?? {};
    switch (method) {
      case 'initialize':
        _reply(id, {'capabilities': <String, dynamic>{}});
      case RpcMethods.subscribe:
        _reply(id, {'subscriptionId': 's1', 'rev': 0});
      case RpcMethods.unsubscribe:
        _reply(id, {'ok': true});
      case RpcMethods.repoCall:
        final op = params['op'] as String;
        final args = (params['args'] as Map?)?.cast<String, dynamic>() ?? {};
        calls.add(_Call(op: op, args: args));
        _reply(id, {
          'op': op,
          'data': callResults[op] ?? const <String, dynamic>{},
        });
      default:
        _reply(id, const <String, dynamic>{});
    }
  }

  void _reply(dynamic id, Map<String, dynamic> result) =>
      space.send({'jsonrpc': '2.0', 'id': id, 'result': result});
}
