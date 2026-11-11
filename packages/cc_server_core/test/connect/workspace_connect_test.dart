import 'dart:convert';
import 'dart:io';

import 'package:cc_connect_core/cc_connect_core.dart' show hostedConnectOrigin;
import 'package:cc_domain/cc_domain.dart';
import 'package:cc_domain/core/domain/entities/workspace.dart';
import 'package:cc_domain/core/domain/repositories/workspace_repository.dart';
import 'package:cc_domain/core/domain/value_objects/workspace_role.dart';
import 'package:cc_host/cc_host.dart';
import 'package:cc_server_core/src/catalog/catalog_wire.dart'
    show workspaceFromWire, workspaceToWire;
import 'package:cc_server_core/src/catalog/workspace_connect_ops.dart';
import 'package:cc_server_core/src/connect/connect_client.dart';
import 'package:cc_server_core/src/connect/connect_settings.dart';
import 'package:cc_server_core/src/file_secrets_store.dart';
import 'package:cc_server_core/src/identity/provider_app_settings.dart';
import 'package:cc_server_core/src/identity/workspace_github_app_settings.dart';
import 'package:cc_server_core/src/identity/workspace_provider_app_settings.dart';
import 'package:cc_server_core/src/rpc_exception_mapper.dart';
import 'package:test/test.dart';

/// A workspace's own Control Center Connect choice: who may read and change
/// it, what a workspace admin may point it at, whose trust a pin change
/// moves, and which Connect may open a seal.
void main() {
  late Directory dir;
  late FileSecretsStore secrets;
  late _Workspaces registry;

  setUp(() {
    dir = Directory.systemTemp.createTempSync('cc_ws_connect_');
    secrets = FileSecretsStore(dataDir: dir.path);
    registry = _Workspaces({
      for (final id in ['ws-a', 'ws-b']) id: _workspace(id),
    });
  });

  tearDown(() => dir.deleteSync(recursive: true));

  ConnectSettings settingsFor({Map<String, String> env = const {}}) =>
      ConnectSettings(secrets: secrets, environment: env)
        ..workspaceLookup = registry.getById;

  group('workspaceConnect.* ops', () {
    const roles = {
      'ws-a': {
        'ada': WorkspaceRole.admin,
        'mia': WorkspaceRole.member,
        'vic': WorkspaceRole.viewer,
      },
      'ws-b': {'bea': WorkspaceRole.owner},
    };
    late ConnectSettings settings;
    late ConnectClient client;
    late RepoOpDispatcher dispatcher;
    late List<String> changed;

    void build({Map<String, String> env = const {}}) {
      settings = settingsFor(env: env);
      // No hosted root keys: the hosted Connect reads as unprovisioned
      // instead of being dialed from a test.
      client = ConnectClient(
        settings: settings,
        timeout: const Duration(milliseconds: 300),
        trustedRootKeys: const [],
      );
      changed = [];
      settings.addWorkspaceListener(changed.add);
      dispatcher = RepoOpDispatcher(
        registry: RepoOpRegistry(
          buildWorkspaceConnectOps(
            workspaceRepository: registry,
            settings: settings,
            connect: client,
            apps: ProviderAppSettings(secrets: secrets),
            workspaceGitHub: WorkspaceGitHubAppSettings(
              secrets: secrets,
              install: ProviderAppSettings(secrets: secrets),
            ),
            workspaceApps: WorkspaceProviderAppSettings(secrets),
          ),
        ),
        mapException: mapAppExceptionToRpc,
        resolveRole: (ws, user) async => roles[ws]?[user],
        workspaceExists: (ws) async => roles.containsKey(ws),
      );
    }

    setUp(build);

    Future<Map<String, dynamic>> call(
      String op,
      String user,
      Map<String, dynamic> args,
    ) => dispatcher.call(
      id: 1,
      params: {'op': op, 'args': args},
      deviceId: 'dev-$user',
      userId: user,
      sessionCapability: SessionCapability.fullClient,
    );

    int? code(Map<String, dynamic> res) =>
        (res['error'] as Map?)?['code'] as int?;

    Map<String, Object?> data(Map<String, dynamic> res) {
      expect(res['error'], isNull, reason: '$res');
      return ((res['result'] as Map)['data'] as Map).cast<String, Object?>();
    }

    test('a member reads the status without the install id or pins', () async {
      final status = data(
        await call('workspaceConnect.status', 'mia', {'workspace_id': 'ws-a'}),
      );
      expect(status['mode'], 'inherit');
      expect(status['url'], '');
      expect(status['server_mode'], 'unset');
      expect(status['server_url'], '');
      expect(status['effective_mode'], 'server_own');
      expect(status['locked'], isFalse);
      expect(status['health'], 'off');
      expect(status['epoch'], 0);
      expect(status.containsKey('install_id'), isFalse);
      expect(status.containsKey('pending_pins'), isFalse);
      final lanes = (status['lanes'] as List).cast<Map<String, Object?>>();
      expect(
        [for (final l in lanes) l['provider']],
        ['github', 'google', 'linear', 'slack', 'klipy'],
      );
      for (final lane in lanes) {
        expect(lane['source'], 'off', reason: '${lane['provider']}');
      }
    });

    test('an admin also sees the install id', () async {
      await settings.setChoice(ConnectMode.hosted);
      final status = data(
        await call('workspaceConnect.status', 'ada', {'workspace_id': 'ws-a'}),
      );
      expect(status['server_mode'], 'hosted');
      expect(status['server_url'], hostedConnectOrigin);
      expect(status['effective_mode'], 'hosted');
      expect(status['install_id'], isA<String>());
      expect(status['install_id'], isNotEmpty);
      expect(status['health'], 'down', reason: 'no hosted root keys here');
      expect(status['error'], 'hosted_unprovisioned');
    });

    test('only an admin changes the choice, tests or confirms pins', () async {
      for (final user in ['mia', 'vic']) {
        for (final op in [
          'workspaceConnect.set',
          'workspaceConnect.test',
          'workspaceConnect.confirmPins',
        ]) {
          final res = await call(op, user, {
            'workspace_id': 'ws-a',
            'mode': 'own',
          });
          expect(code(res), RpcErrorCodes.unauthorized, reason: '$user $op');
        }
      }
      expect(
        code(
          await call('workspaceConnect.status', 'vic', {
            'workspace_id': 'ws-a',
          }),
        ),
        RpcErrorCodes.unauthorized,
        reason: 'a viewer is not told where sign-ins go',
      );
      expect(registry.byId['ws-a']!.connectMode, WorkspaceConnectMode.inherit);
      expect(changed, isEmpty);
    });

    test("another workspace's owner reaches none of it", () async {
      for (final op in [
        'workspaceConnect.status',
        'workspaceConnect.set',
        'workspaceConnect.test',
        'workspaceConnect.confirmPins',
      ]) {
        final res = await call(op, 'bea', {
          'workspace_id': 'ws-a',
          'mode': 'own',
        });
        expect(code(res), RpcErrorCodes.unauthorized, reason: op);
      }
      expect(registry.byId['ws-a']!.connectMode, WorkspaceConnectMode.inherit);
      // Their own workspace is theirs, and stays apart from A.
      data(
        await call('workspaceConnect.set', 'bea', {
          'workspace_id': 'ws-b',
          'mode': 'own',
        }),
      );
      expect(registry.byId['ws-b']!.connectMode, WorkspaceConnectMode.own);
      expect(registry.byId['ws-a']!.connectMode, WorkspaceConnectMode.inherit);
      expect(changed, ['ws-b']);
    });

    test('an unknown workspace is refused before any lookup', () async {
      final res = await call('workspaceConnect.status', 'ada', {
        'workspace_id': 'ws-ghost',
      });
      expect(code(res), RpcErrorCodes.notFound);
    });

    test('set stores the choice, announces it once, and reports it', () async {
      final own = data(
        await call('workspaceConnect.set', 'ada', {
          'workspace_id': 'ws-a',
          'mode': 'own',
        }),
      );
      expect(own['mode'], 'own');
      expect(own['effective_mode'], 'own');
      expect(registry.byId['ws-a']!.connectMode, WorkspaceConnectMode.own);
      expect(changed, ['ws-a']);

      // The same choice again changes nothing.
      await call('workspaceConnect.set', 'ada', {
        'workspace_id': 'ws-a',
        'mode': 'own',
      });
      expect(changed, ['ws-a']);

      final hosted = data(
        await call('workspaceConnect.set', 'ada', {
          'workspace_id': 'ws-a',
          'mode': 'hosted',
        }),
      );
      expect(hosted['mode'], 'hosted');
      expect(hosted['effective_mode'], 'hosted');
      expect(changed, ['ws-a', 'ws-a']);
    });

    test('the hosted URL entered as custom is the hosted choice', () async {
      final status = data(
        await call('workspaceConnect.set', 'ada', {
          'workspace_id': 'ws-a',
          'mode': 'custom',
          'url': hostedConnectOrigin,
        }),
      );
      expect(status['mode'], 'hosted');
      expect(status['url'], '');
      expect(registry.byId['ws-a']!.connectUrl, isEmpty);
    });

    test('an unknown mode is refused', () async {
      final res = await call('workspaceConnect.set', 'ada', {
        'workspace_id': 'ws-a',
        'mode': 'app',
      });
      expect(code(res), RpcErrorCodes.validation);
    });

    test('a custom URL must be public HTTPS', () async {
      for (final url in [
        '',
        'http://connect.example.com',
        'https://127.0.0.1',
        'https://localhost:8443',
        'https://169.254.169.254',
        'https://10.1.2.3',
        'https://192.168.1.10',
        'https://[::1]',
        'https://[fd00::1]',
      ]) {
        final res = await call('workspaceConnect.set', 'ada', {
          'workspace_id': 'ws-a',
          'mode': 'custom',
          'url': url,
        });
        expect(code(res), RpcErrorCodes.validation, reason: url);
      }
      expect(registry.byId['ws-a']!.connectMode, WorkspaceConnectMode.inherit);
      expect(changed, isEmpty);
    });

    test('CC_CONNECT_URL forbids a workspace Connect, not its own apps or '
        "the server's choice", () async {
      build(env: const {'CC_CONNECT_URL': 'hosted'});
      for (final mode in ['hosted', 'custom']) {
        final res = await call('workspaceConnect.set', 'ada', {
          'workspace_id': 'ws-a',
          'mode': mode,
          'url': 'https://connect.example.com',
        });
        expect(code(res), RpcErrorCodes.validation, reason: mode);
      }
      for (final mode in ['own', 'inherit']) {
        final status = data(
          await call('workspaceConnect.set', 'ada', {
            'workspace_id': 'ws-a',
            'mode': mode,
          }),
        );
        expect(status['mode'], mode);
        expect(status['locked'], isTrue);
      }
    });

    test('confirmPins is refused unless the workspace runs its own custom '
        'Connect', () async {
      final res = await call('workspaceConnect.confirmPins', 'ada', {
        'workspace_id': 'ws-a',
      });
      expect(code(res), RpcErrorCodes.validation);
    });

    test('the workspace JSON carries the mode; the URL rides status', () {
      final ws = registry.byId['ws-a']!.copyWith(
        connectMode: WorkspaceConnectMode.custom,
        connectUrl: 'https://connect.example.com',
      );
      final wire = workspaceToWire(ws);
      expect(wire['connect_mode'], 'custom');
      expect(wire.containsKey('connect_url'), isFalse);
      expect(wire.containsKey('github_auth_mode'), isFalse);
      expect(workspaceFromWire(wire).connectMode, WorkspaceConnectMode.custom);
    });
  });

  group('trust per workspace', () {
    late _FakeConnect fake;

    setUp(() async => fake = await _FakeConnect.start());
    tearDown(() => fake.close());

    test('a pin change confirmed in one workspace moves no one else', () async {
      final settings = settingsFor();
      // A loopback Connect stands in for a public one: the guarded
      // transport is swapped for a plain client so the test can reach it.
      final client = ConnectClient(
        settings: settings,
        guardedHttpClient: HttpClient(),
        timeout: const Duration(seconds: 2),
      );
      await settings.setChoice(ConnectMode.custom, url: fake.base);
      for (final id in ['ws-a', 'ws-b']) {
        registry.byId[id] = registry.byId[id]!.copyWith(
          connectMode: WorkspaceConnectMode.custom,
          connectUrl: fake.base,
        );
      }
      final server = await client.serverTarget();
      final a = await client.targetFor('ws-a');
      final b = await client.targetFor('ws-b');
      expect({server.cacheKey, a.cacheKey, b.cacheKey}, hasLength(3));
      expect(a.origin, server.origin);

      // First use pins the same identifiers in three trust stores.
      for (final target in [server, a, b]) {
        expect((await client.configState(target)).usable, isTrue);
      }

      fake.githubClientId = 'Iv1.rotated';
      for (final target in [server, a, b]) {
        final state = await client.configState(target, refresh: true);
        expect(state.error, 'pins_changed');
        expect(state.usable, isFalse);
      }

      await client.confirmPendingPins(a);
      expect((await client.configState(a, refresh: true)).usable, isTrue);
      expect(
        (await client.configState(b, refresh: true)).error,
        'pins_changed',
      );
      expect(
        (await client.configState(server, refresh: true)).error,
        'pins_changed',
      );

      // Deleting B drops its trust store and nothing else.
      expect(await settings.deleteWorkspaceTrust('ws-b'), greaterThan(0));
      expect(await settings.pins(b), isNull);
      expect(await settings.pins(a), {
        'github.app_id': '7',
        'github.client_id': 'Iv1.rotated',
      });
      expect(await settings.pins(server), isNotNull);
    });

    test('a workspace-chosen Connect on a private address is refused on '
        'every connection, whatever was stored', () async {
      final settings = settingsFor();
      final client = ConnectClient(
        settings: settings,
        timeout: const Duration(seconds: 2),
      );
      // Stored directly, as if DNS had answered publicly at save time.
      registry.byId['ws-a'] = registry.byId['ws-a']!.copyWith(
        connectMode: WorkspaceConnectMode.custom,
        connectUrl: fake.base,
      );
      final target = await client.targetFor('ws-a');
      expect(target.guarded, isTrue);
      final state = await client.configState(target);
      expect(state.usable, isFalse);
      expect(state.error, 'unreachable');
      expect(fake.requests, 0);

      // The server owner's own choice of the same address is not guarded.
      await settings.setChoice(ConnectMode.custom, url: fake.base);
      final server = await client.serverTarget();
      expect(server.guarded, isFalse);
      expect((await client.configState(server)).usable, isTrue);
      expect(fake.requests, 1);
    });
  });

  group('seal standing', () {
    test('a seal opens only at the Connect its workspace uses now, for the '
        'same install identity', () async {
      final settings = settingsFor();
      final client = ConnectClient(
        settings: settings,
        trustedRootKeys: const [],
      );
      await settings.setChoice(ConnectMode.hosted);
      final installId = (await client.installIdFor(hostedConnectOrigin))!;
      // One origin, one install identity, whoever chose it.
      registry.byId['ws-a'] = registry.byId['ws-a']!.copyWith(
        connectMode: WorkspaceConnectMode.hosted,
      );
      expect(
        await client.installIdFor(hostedConnectOrigin, workspaceId: 'ws-a'),
        installId,
      );

      Future<SealStanding> standing(String origin, String id, String? ws) =>
          client.sealStanding(
            connectOrigin: origin,
            sealInstallId: id,
            workspaceId: ws,
          );

      expect(
        await standing(hostedConnectOrigin, installId, 'ws-a'),
        SealStanding.usable,
      );
      expect(
        await standing(hostedConnectOrigin, 'rotated-away', 'ws-a'),
        SealStanding.dead,
      );

      // ws-a moves to a custom Connect: the hosted seal is parked, kept for
      // a switch back.
      registry.byId['ws-a'] = registry.byId['ws-a']!.copyWith(
        connectMode: WorkspaceConnectMode.custom,
        connectUrl: 'https://connect.example.com',
      );
      expect(
        await standing(hostedConnectOrigin, installId, 'ws-a'),
        SealStanding.parked,
      );
      // ...while the server-wide slot still follows the server's hosted
      // choice.
      expect(
        await standing(hostedConnectOrigin, installId, null),
        SealStanding.usable,
      );

      // Own apps: no Connect at all.
      registry.byId['ws-a'] = registry.byId['ws-a']!.copyWith(
        connectMode: WorkspaceConnectMode.own,
      );
      expect(
        await standing(hostedConnectOrigin, installId, 'ws-a'),
        SealStanding.parked,
      );
    });
  });
}

Workspace _workspace(String id) => Workspace(
  id: id,
  name: id,
  createdAt: DateTime.utc(2026),
  updatedAt: DateTime.utc(2026),
);

/// The workspace registry the ops read and write.
final class _Workspaces implements WorkspaceRepository {
  _Workspaces(this.byId);

  final Map<String, Workspace> byId;

  @override
  Future<Workspace?> getById(String id) async => byId[id];

  @override
  Future<String> upsert(Workspace workspace) async {
    byId[workspace.id] = workspace;
    return workspace.id;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// A self-hosted Connect on loopback serving `/v1/config` with a GitHub lane
/// whose client id the test can rotate.
final class _FakeConnect {
  _FakeConnect._(this._server) {
    _server.listen(_handle);
  }

  static Future<_FakeConnect> start() async =>
      _FakeConnect._(await HttpServer.bind(InternetAddress.loopbackIPv4, 0));

  final HttpServer _server;
  String githubClientId = 'Iv1.first';
  int requests = 0;

  String get base => 'http://127.0.0.1:${_server.port}';

  Future<void> _handle(HttpRequest request) async {
    requests++;
    final response = request.response..headers.contentType = ContentType.json;
    if (request.uri.path == '/v1/config') {
      response.write(
        jsonEncode({
          'protocol': 1,
          'epoch': 1,
          'issued_at': DateTime.now().toUtc().toIso8601String(),
          'github': {
            'app_id': 7,
            'client_id': githubClientId,
            'app_slug': 'cc-test',
          },
        }),
      );
    } else {
      response.statusCode = HttpStatus.notFound;
    }
    await response.close();
  }

  Future<void> close() => _server.close(force: true);
}
