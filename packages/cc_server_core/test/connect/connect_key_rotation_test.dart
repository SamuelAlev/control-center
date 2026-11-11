import 'dart:convert';
import 'dart:io';

import 'package:cc_connect_core/cc_connect_core.dart';
import 'package:cc_domain/core/domain/entities/workspace.dart';
import 'package:cc_host/cc_host.dart' show CcHostLog;
import 'package:cc_server_core/src/connect/connect_client.dart';
import 'package:cc_server_core/src/connect/connect_settings.dart';
import 'package:cc_server_core/src/connect/install_key_rotation.dart';
import 'package:cc_server_core/src/connect/sign_in_service.dart';
import 'package:cc_server_core/src/file_secrets_store.dart';
import 'package:test/test.dart';

/// Rotating the install key revokes the grants each Connect sealed, then
/// retires the old key there, signed with it and carrying one of those
/// seals, before the new seed is written. A Connect holding no seal is
/// skipped; one that cannot retire the key stops the rotation unless it is
/// forced, and a forced rotation is logged with what it left behind.
void main() {
  late Directory dir;
  late ConnectSettings settings;
  late _Lane github;
  late _Connect server;
  late _Connect workspace;
  late InstallKeyRotation rotation;
  late List<String> lines;

  setUp(() async {
    dir = Directory.systemTemp.createTempSync('cc_connect_key_rotation_');
    settings = ConnectSettings(secrets: FileSecretsStore(dataDir: dir.path));
    server = await _Connect.start(settings);
    workspace = await _Connect.start(settings);
    await settings.setChoice(ConnectMode.custom, url: server.base);
    final own = Workspace(
      id: 'ws-own',
      name: 'Own Connect',
      createdAt: DateTime.utc(2026),
      updatedAt: DateTime.utc(2026),
      connectMode: WorkspaceConnectMode.custom,
      connectUrl: workspace.base,
    );
    final inheriting = Workspace(
      id: 'ws-inherit',
      name: 'Server Connect',
      createdAt: DateTime.utc(2026),
      updatedAt: DateTime.utc(2026),
    );
    settings
      ..workspaceLookup = ((id) async => id == own.id ? own : inheriting)
      ..workspaceList = (() async => [own, inheriting]);
    github = _Lane()
      ..seals[server.base] = [
        const SealRequest(seal: 'v1.server-seal', workspaceId: 'global'),
      ]
      ..seals[workspace.base] = [
        const SealRequest(seal: 'v1.workspace-seal', workspaceId: 'ws-own'),
      ];
    rotation = InstallKeyRotation(
      signIn: ProviderSignInService(
        // Workspace-chosen targets go through the guarded client, which
        // refuses loopback; these Connects are on loopback.
        connect: ConnectClient(
          settings: settings,
          guardedHttpClient: HttpClient(),
        ),
      )..register(github),
    );

    lines = [];
    final previous = CcHostLog.sink;
    CcHostLog.sink = (level, message, [error, stack]) => lines.add(message);
    addTearDown(() => CcHostLog.sink = previous);
  });

  tearDown(() async {
    await server.close();
    await workspace.close();
    dir.deleteSync(recursive: true);
  });

  Future<String> installIdAt(List<int> seed, String base) async =>
      (await ConnectInstallIdentity.derive(
        masterSeed: seed,
        connectUrl: base,
      )).installId;

  Map<String, Object?> event(String name) {
    final line = lines.firstWhere((l) => l.contains(name));
    return jsonDecode(line.substring(line.indexOf('{')))
        as Map<String, Object?>;
  }

  test('each Connect revokes its grants, then retires the old key with one '
      'of its seals, signed with it, before the seed changes', () async {
    final old = List.of(await settings.installSeed());

    await rotation.rotate(userId: 'owner');

    for (final (connect, seal, slot) in [
      (server, 'v1.server-seal', 'global'),
      (workspace, 'v1.workspace-seal', 'ws-own'),
    ]) {
      expect(
        [for (final c in connect.calls) c.path],
        ['/v1/github/revoke', connectInstallRetirePath],
      );
      final retire = connect.calls.last;
      expect(retire.method, 'POST');
      expect(retire.body, {'seal': seal, 'workspace_id': slot});
      expect(retire.installId, await installIdAt(old, connect.base));
      expect(retire.seedAtCall, old, reason: 'retired before the new seed');
    }
    expect(await settings.installSeed(), isNot(old));
    final rotated = event('connect.key_rotated');
    expect(rotated['retired'], 2);
    expect(rotated.containsKey('forced'), isFalse);
  });

  test('a Connect holding no seal is skipped', () async {
    github.seals.remove(workspace.base);
    final old = List.of(await settings.installSeed());

    await rotation.rotate();

    expect(workspace.calls, isEmpty);
    expect(server.calls.last.path, connectInstallRetirePath);
    expect(await settings.installSeed(), isNot(old));
  });

  test('a failed revoke is logged and does not block', () async {
    workspace.revokeAnswer = (
      HttpStatus.serviceUnavailable,
      {'error': 'provider_unavailable'},
    );
    final old = List.of(await settings.installSeed());

    await rotation.rotate();

    expect(workspace.calls.last.path, connectInstallRetirePath);
    expect(await settings.installSeed(), isNot(old));
    expect(
      event('grant.revoke_skipped')['reason'],
      startsWith('key_rotation:'),
    );
  });

  test('install_blocked means already retired', () async {
    final old = List.of(await settings.installSeed());
    workspace.retireAnswer = (
      HttpStatus.forbidden,
      {'error': 'install_blocked'},
    );

    await rotation.rotate();

    expect(await settings.installSeed(), isNot(old));
  });

  for (final (name, answer) in [
    ('rate_limited', (HttpStatus.tooManyRequests, {'error': 'rate_limited'})),
    (
      'provider_unavailable',
      (HttpStatus.serviceUnavailable, {'error': 'provider_unavailable'}),
    ),
    ('access_denied', (HttpStatus.forbidden, {'error': 'access_denied'})),
  ]) {
    test('a $name retire leaves the old seed', () async {
      final old = List.of(await settings.installSeed());
      workspace.retireAnswer = answer;

      await expectLater(
        rotation.rotate(),
        throwsA(
          isA<ConnectRetireFailed>().having(
            (e) => e.failures.single,
            'failure',
            (origin: workspace.base, error: ConnectErrorCode.fromWire(name)),
          ),
        ),
      );
      expect(await settings.installSeed(), old);
      expect(lines.where((l) => l.contains('connect.key_rotated')), isEmpty);
    });
  }

  test('an unreachable Connect leaves the old seed', () async {
    final old = List.of(await settings.installSeed());
    await workspace.close();

    await expectLater(rotation.rotate(), throwsA(isA<ConnectRetireFailed>()));
    expect(await settings.installSeed(), old);
  });

  test(
    'force rotates anyway and logs what still accepts the old key',
    () async {
      final old = List.of(await settings.installSeed());
      workspace.retireAnswer = (
        HttpStatus.tooManyRequests,
        {'error': 'rate_limited'},
      );

      final unretired = await rotation.rotate(userId: 'owner', force: true);

      expect(unretired, [
        (origin: workspace.base, error: ConnectErrorCode.rateLimited),
      ]);
      expect(await settings.installSeed(), isNot(old));
      final rotated = event('connect.key_rotated');
      expect(rotated['forced'], isTrue);
      expect(rotated['retired'], 1);
      expect(rotated['unretired'], '${workspace.base} rate_limited');
      expect(rotated['user_id'], 'owner');
    },
  );
}

/// A GitHub lane holding the [seals] each Connect made; nothing else used.
final class _Lane implements SignInLaneBinding {
  final Map<String, List<SealRequest>> seals = {};

  @override
  ConnectOAuthLane get lane => ConnectOAuthLane.github;

  @override
  Future<List<SealRequest>> connectSeals(
    String connectOrigin,
    List<String> workspaceIds,
  ) async => seals[connectOrigin] ?? const [];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// One request a Connect received.
typedef _Call = ({
  String method,
  String path,
  Object? body,
  String? installId,
  List<int> seedAtCall,
});

/// A Connect on loopback that records each request and answers it.
final class _Connect {
  _Connect._(this._server, this._settings) {
    _server.listen(_handle);
  }

  static Future<_Connect> start(ConnectSettings settings) async => _Connect._(
    await HttpServer.bind(InternetAddress.loopbackIPv4, 0),
    settings,
  );

  final HttpServer _server;
  final ConnectSettings _settings;
  final List<_Call> calls = [];
  (int, Map<String, Object?>) retireAnswer = (HttpStatus.ok, {'ok': true});
  (int, Map<String, Object?>) revokeAnswer = (HttpStatus.ok, {'ok': true});

  String get base => 'http://127.0.0.1:${_server.port}';

  Future<void> _handle(HttpRequest request) async {
    final text = await utf8.decoder.bind(request).join();
    final input = request.headers.value('signature-input') ?? '';
    final keyId = RegExp('keyid="([^"]+)"').firstMatch(input)?.group(1);
    calls.add((
      method: request.method,
      path: request.uri.path,
      body: text.isEmpty ? null : jsonDecode(text),
      installId: keyId == null ? null : installIdForKeyId(keyId),
      seedAtCall: List.of(await _settings.installSeed()),
    ));
    final (status, json) = request.uri.path == connectInstallRetirePath
        ? retireAnswer
        : revokeAnswer;
    request.response
      ..statusCode = status
      ..headers.contentType = ContentType.json
      ..write(jsonEncode(json));
    await request.response.close();
  }

  Future<void> close() => _server.close(force: true);
}
