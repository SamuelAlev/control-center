import 'dart:convert';
import 'dart:io';

import 'package:cc_domain/cc_domain.dart'
    show AuthException, ServerOwnerRequiredException;
import 'package:cc_domain/core/domain/ports/secret_store_port.dart';
import 'package:cc_domain/features/mcp/domain/entities/mcp_server_definition.dart';
import 'package:cc_domain/features/mcp/domain/ports/mcp_tool_port.dart';
import 'package:cc_domain/features/mcp/domain/ports/workspace_mcp_server_control.dart';
import 'package:cc_domain/features/mcp/domain/repositories/mcp_server_definition_repository.dart';
import 'package:cc_domain/features/mcp/domain/services/mcp_tool_registry.dart';
import 'package:cc_domain/features/mcp/domain/value_objects/mcp_server_draft.dart';
import 'package:cc_mcp_client/cc_mcp_client.dart';
// ignore: implementation_imports
import 'package:cc_server_core/src/mcp_servers/mcp_server_authorizations.dart';
// ignore: implementation_imports
import 'package:cc_server_core/src/mcp_servers/mcp_server_secrets.dart';
// ignore: implementation_imports
import 'package:cc_server_core/src/mcp_servers/workspace_mcp_servers.dart';
import 'package:test/test.dart';

const _owner = 'user-owner';
const _admin = 'user-admin';
const _member = 'user-member';
const _shared = McpServerScope.workspace;
const _mine = McpServerScope.personal;
const _ws = 'ws-1';

/// Each workspace's rows in memory, refusing a name clash like the database.
class _MemoryRepository implements WorkspaceMcpServerRepository {
  final Map<String, Map<String, McpServerDefinition>> rows = {};

  @override
  Future<List<McpServerDefinition>> list(String workspaceId) async =>
      (rows[workspaceId]?.values.toList() ?? [])
        ..sort((a, b) => a.name.compareTo(b.name));

  @override
  Future<McpServerDefinition?> get(String workspaceId, String id) async =>
      rows[workspaceId]?[id];

  @override
  Future<void> save(McpServerDefinition definition) async {
    final ws = rows.putIfAbsent(definition.workspaceId, () => {});
    if (ws.values.any(
      (d) =>
          d.id != definition.id &&
          d.userId == definition.userId &&
          d.name == definition.name,
    )) {
      throw const McpServerDefinitionException.nameTaken();
    }
    ws[definition.id] = definition;
  }

  @override
  Future<bool> delete(String workspaceId, String id) async =>
      rows[workspaceId]?.remove(id) != null;
}

class _Tool extends McpTool {
  _Tool(this.name);

  @override
  final String name;

  @override
  String get description => name;

  @override
  Map<String, dynamic> get inputSchema => const {'type': 'object'};

  @override
  Future<CallResult> run(Map<String, dynamic> arguments) async =>
      CallResult.success(name);
}

void main() {
  late _MemoryRepository repository;
  late InMemorySecretStore secrets;
  late McpToolRegistry registry;
  late Map<(String, String?), McpClientService> clients;
  late WorkspaceMcpServers servers;
  var ids = 0;

  setUp(() {
    repository = _MemoryRepository();
    secrets = InMemorySecretStore();
    registry = McpToolRegistry(const []);
    clients = {};
    servers = WorkspaceMcpServers(
      repository: repository,
      secrets: McpServerSecrets(secrets),
      registry: registry,
      serverOwnerUserId: _owner,
      clientFactory: (workspaceId, userId, publishTools, tokenStore) =>
          clients[(workspaceId, userId)] = McpClientService(
            publishTools: publishTools,
            tokenStore: tokenStore,
          ),
      newId: () => 'srv-${ids++}',
    );
  });
  tearDown(() => servers.shutdown());

  /// The servers the workspace's client was handed (dialled or tracked).
  Set<String> handed(String workspaceId, [String? userId]) => {
    for (final s
        in clients[(workspaceId, userId)]?.serverStatuses ??
            const <McpServerStatusSnapshot>[])
      s.name,
  };

  // Disabled, so nothing is spawned or dialled: a disabled server the client
  // was handed is still tracked, which is what these tests look at.
  McpServerDraft stdio({String? id, String command = 'my-mcp'}) =>
      McpServerDraft(
        id: id,
        name: 'local',
        transport: McpServerTransport.stdio,
        command: command,
        enabled: false,
        envSet: const {'API_TOKEN': 'shh'},
      );

  test('an admin\'s stdio server waits for the server owner and is never '
      'handed to the client until approved', () async {
    final saved = await servers.save(
      workspaceId: _ws,
      scope: _shared,
      draft: stdio().copyEnabled(true),
      actorUserId: _admin,
    );
    expect(saved.hostApproved, isFalse);
    expect(saved.lifecycle, WorkspaceMcpServerEntry.awaitingApproval);
    expect(handed(_ws), isEmpty);

    await expectLater(
      servers.approve(
        workspaceId: _ws,
        id: saved.definition.id,
        actorUserId: _admin,
      ),
      throwsStateError,
    );

    // Approved while disabled, so it is tracked but never started.
    await servers.save(
      workspaceId: _ws,
      scope: _shared,
      draft: stdio(id: saved.definition.id),
      actorUserId: _admin,
    );
    final approved = await servers.approve(
      workspaceId: _ws,
      id: saved.definition.id,
      actorUserId: _owner,
    );
    expect(approved.hostApproved, isTrue);
    expect(approved.definition.hostApprovedBy, _owner);
    expect(handed(_ws), {'local'});
  });

  test('an admin\'s change to the launch drops the approval; toggling it '
      'does not', () async {
    final saved = await servers.save(
      workspaceId: _ws,
      scope: _shared,
      draft: stdio(),
      actorUserId: _owner,
    );
    expect(saved.hostApproved, isTrue, reason: 'the owner saved it');
    final id = saved.definition.id;

    final toggled = await servers.save(
      workspaceId: _ws,
      scope: _shared,
      draft: McpServerDraft(
        id: id,
        name: 'local',
        transport: McpServerTransport.stdio,
        command: 'my-mcp',
        enabled: false,
      ),
      actorUserId: _admin,
    );
    expect(toggled.hostApproved, isTrue);

    final edited = await servers.save(
      workspaceId: _ws,
      scope: _shared,
      draft: stdio(id: id, command: 'something-else'),
      actorUserId: _admin,
    );
    expect(edited.hostApproved, isFalse);
    expect(handed(_ws), isEmpty);
  });

  test('a new value for an existing variable is a launch change', () async {
    final saved = await servers.save(
      workspaceId: _ws,
      scope: _shared,
      draft: stdio(),
      actorUserId: _owner,
    );
    final edited = await servers.save(
      workspaceId: _ws,
      scope: _shared,
      draft: stdio(id: saved.definition.id),
      actorUserId: _admin,
    );
    expect(edited.hostApproved, isFalse);
  });

  test('values stay in the secrets store and out of every entry', () async {
    final saved = await servers.save(
      workspaceId: _ws,
      scope: _shared,
      draft: McpServerDraft(
        name: 'remote',
        transport: McpServerTransport.http,
        url: 'https://mcp.example.com/mcp',
        enabled: false,
        headerSet: const {'Authorization': 'Bearer top-secret'},
      ),
      actorUserId: _admin,
    );
    expect(saved.definition.headerNames, ['Authorization']);
    expect('${saved.toJson()}', isNot(contains('top-secret')));
    expect(
      '${(await servers.list(_ws, _shared, actorUserId: _admin)).map((e) => e.toJson())}',
      isNot(contains('top-secret')),
    );
    expect(secrets.values.values, contains('Bearer top-secret'));

    // Moving it to a process drops the header value it can no longer use.
    await servers.save(
      workspaceId: _ws,
      scope: _shared,
      draft: stdio(id: saved.definition.id),
      actorUserId: _admin,
    );
    expect(secrets.values.values, isNot(contains('Bearer top-secret')));
    expect(secrets.values.values, contains('shh'));

    await servers.delete(
      workspaceId: _ws,
      scope: _shared,
      id: saved.definition.id,
      actorUserId: _admin,
    );
    expect(secrets.values, isEmpty);
    expect(await servers.list(_ws, _shared, actorUserId: _admin), isEmpty);
  });

  test('an unapproved remote server is confined to public addresses; the '
      'owner\'s approval lifts it', () async {
    final definition = McpServerDefinition(
      id: 's',
      workspaceId: _ws,
      name: 'remote',
      transport: McpServerTransport.http,
      url: 'http://127.0.0.1:9/mcp',
      createdAt: DateTime.utc(2026),
      updatedAt: DateTime.utc(2026),
    );
    final store = McpServerSecrets(secrets);
    final confined = await store.configFor(
      definition,
      source: WorkspaceMcpServers.source,
      publicOnly: true,
    );
    expect(confined.publicOnly, isTrue);
    expect(
      (await store.configFor(definition, source: 'x')).publicOnly,
      isFalse,
    );
  });

  test('a workspace\'s servers and values are gone with it, and other '
      'workspaces keep theirs', () async {
    await servers.save(
      workspaceId: _ws,
      scope: _shared,
      draft: stdio(),
      actorUserId: _owner,
    );
    await servers.save(
      workspaceId: 'ws-2',
      scope: _shared,
      draft: stdio(),
      actorUserId: _owner,
    );
    registry.setWorkspaceTools(_ws, [_Tool('mcp__local__t')]);
    await servers.forgetWorkspace(_ws);
    expect(
      registry.toolNames(view: const McpToolView(workspaceId: _ws)),
      isEmpty,
    );
    expect(secrets.values.keys, everyElement(contains('ws:ws-2:')));
    expect(secrets.values, isNotEmpty);
  });

  group('a member\'s own servers', () {
    McpServerDraft remote({
      String? id,
      String url = 'https://mcp.example.com/mcp',
    }) => McpServerDraft(
      id: id,
      name: 'figma',
      transport: McpServerTransport.http,
      url: url,
      enabled: false,
      headerSet: const {'X-Key': 'mine-only'},
    );

    test('are listed, changed and removed only by that member', () async {
      final saved = await servers.save(
        workspaceId: _ws,
        scope: _mine,
        draft: remote(),
        actorUserId: _member,
      );
      final id = saved.definition.id;
      expect(saved.definition.userId, _member);
      expect(handed(_ws, _member), {'figma'});
      expect(handed(_ws), isEmpty, reason: 'not the workspace\'s client');

      expect(await servers.list(_ws, _shared, actorUserId: _admin), isEmpty);
      expect(await servers.list(_ws, _mine, actorUserId: _admin), isEmpty);
      expect(
        (await servers.list(
          _ws,
          _mine,
          actorUserId: _member,
        )).single.definition.id,
        id,
      );

      // Not by an admin through the workspace scope, nor by another member
      // through their own, nor by the owner.
      for (final (scope, actor) in [
        (_shared, _admin),
        (_mine, _admin),
        (_mine, _owner),
        (_shared, _member),
      ]) {
        await expectLater(
          servers.save(
            workspaceId: _ws,
            scope: scope,
            draft: remote(id: id),
            actorUserId: actor,
          ),
          throwsA(isA<McpServerNotFoundException>()),
          reason: '$scope by $actor',
        );
        await expectLater(
          servers.delete(
            workspaceId: _ws,
            scope: scope,
            id: id,
            actorUserId: actor,
          ),
          throwsA(isA<McpServerNotFoundException>()),
        );
        await expectLater(
          servers.reconnect(
            workspaceId: _ws,
            scope: scope,
            id: id,
            actorUserId: actor,
          ),
          throwsA(isA<McpServerNotFoundException>()),
        );
        await expectLater(
          servers.beginAuthorization(
            workspaceId: _ws,
            scope: scope,
            id: id,
            actorUserId: actor,
            origin: 'https://cc.example.com',
          ),
          throwsA(isA<McpServerNotFoundException>()),
        );
      }
      await expectLater(
        servers.approve(workspaceId: _ws, id: id, actorUserId: _owner),
        throwsA(isA<McpServerNotFoundException>()),
        reason: 'approval is for the workspace\'s servers',
      );

      await servers.delete(
        workspaceId: _ws,
        scope: _mine,
        id: id,
        actorUserId: _member,
      );
      expect(secrets.values, isEmpty);
      expect(handed(_ws, _member), isEmpty);
    });

    test('share a name with the workspace\'s and another member\'s, and '
        'keep their values apart', () async {
      for (final (scope, actor) in [
        (_shared, _admin),
        (_mine, _member),
        (_mine, _admin),
      ]) {
        await servers.save(
          workspaceId: _ws,
          scope: scope,
          draft: remote(),
          actorUserId: actor,
        );
      }
      expect(handed(_ws), {'figma'});
      expect(handed(_ws, _member), {'figma'});
      expect(handed(_ws, _admin), {'figma'});
      expect(secrets.values, hasLength(3));
      expect(
        secrets.values.keys.where((k) => k.contains('wsu:$_ws:$_member:')),
        hasLength(1),
      );
    });

    test(
      'reach only the registry layer of that member in that workspace',
      () async {
        await servers.save(
          workspaceId: _ws,
          scope: _mine,
          draft: remote(),
          actorUserId: _member,
        );
        registry.setPersonalTools(_ws, _member, [_Tool('mcp__figma__t')]);
        await servers.forgetWorkspace(_ws);
        expect(
          registry.toolNames(
            view: const McpToolView(workspaceId: _ws, personalUserId: _member),
          ),
          isEmpty,
        );
        expect(secrets.values, isEmpty);
      },
    );

    test('never run a command on the host unless they are the server '
        'owner\'s', () async {
      await expectLater(
        servers.save(
          workspaceId: _ws,
          scope: _mine,
          draft: stdio(),
          actorUserId: _member,
        ),
        throwsA(isA<ServerOwnerRequiredException>()),
      );
      expect(repository.rows[_ws] ?? const {}, isEmpty);

      final own = await servers.save(
        workspaceId: _ws,
        scope: _mine,
        draft: stdio(),
        actorUserId: _owner,
      );
      expect(own.hostApproved, isTrue);
      expect(handed(_ws, _owner), {'local'});
    });
  });

  group('browser sign-in', () {
    late HttpServer provider;
    late String base;
    late List<String> bearerSeen;
    late Map<String, String> tokenForm;

    setUp(() async {
      provider = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      base = 'http://127.0.0.1:${provider.port}';
      bearerSeen = [];
      tokenForm = {};
      provider.listen((request) async {
        final res = request.response;
        void json(Object body) => res
          ..headers.contentType = ContentType.json
          ..write(jsonEncode(body));
        switch (request.uri.path) {
          case '/mcp':
            bearerSeen.add(
              request.headers.value(HttpHeaders.authorizationHeader) ?? '',
            );
            res.statusCode = HttpStatus.unauthorized;
          case '/.well-known/oauth-authorization-server':
            json({
              'issuer': base,
              'authorization_endpoint': '$base/authorize',
              'token_endpoint': '$base/token',
              'registration_endpoint': '$base/register',
            });
          case '/register':
            json({'client_id': 'client-1'});
          case '/token':
            tokenForm = Uri.splitQueryString(
              await utf8.decoder.bind(request).join(),
            );
            json({'access_token': 'at-1', 'token_type': 'Bearer'});
          default:
            res.statusCode = HttpStatus.notFound;
        }
        await res.close();
      });
    });
    tearDown(() => provider.close(force: true));

    Future<String> addServer(McpServerScope scope, String actor) async {
      final saved = await servers.save(
        workspaceId: _ws,
        scope: scope,
        draft: McpServerDraft(
          name: 'figma',
          transport: McpServerTransport.http,
          url: '$base/mcp',
        ),
        actorUserId: actor,
      );
      // `save` returns once the connect settles or the client's startup gate
      // closes; on a slow machine the first dial is still in flight then.
      var entry = saved;
      final deadline = DateTime.now().add(const Duration(seconds: 10));
      while (entry.lifecycle == McpServerLifecycle.connecting.wire &&
          DateTime.now().isBefore(deadline)) {
        await Future<void>.delayed(const Duration(milliseconds: 20));
        entry = (await servers.list(
          _ws,
          scope,
          actorUserId: actor,
        )).firstWhere((e) => e.definition.id == saved.definition.id);
      }
      expect(entry.needsAuth, isTrue, reason: entry.lifecycle);
      return saved.definition.id;
    }

    /// What the provider's redirect would carry back for [authorization].
    Uri callbackOf(McpServerAuthorization authorization, {String code = 'pc'}) {
      final sent = Uri.parse(authorization.url).queryParameters;
      expect(sent['redirect_uri'], 'https://cc.example.com/oauth/mcp/callback');
      expect(sent['client_id'], 'client-1');
      expect(sent['code_challenge_method'], 'S256');
      return Uri.parse(
        sent['redirect_uri']!,
      ).replace(queryParameters: {'state': sent['state'], 'code': code});
    }

    test('stores nothing until the person who began it presents the code, '
        'then signs that audience in alone', () async {
      // The owner's own server: approved, so it may reach this loopback
      // provider over http.
      final id = await addServer(_mine, _owner);
      final begun = await servers.beginAuthorization(
        workspaceId: _ws,
        scope: _mine,
        id: id,
        actorUserId: _owner,
        origin: 'https://cc.example.com',
      );
      expect(begun.status, McpServerAuthorizationStatus.pending);

      // A code typed before the browser came back is a wrong code.
      final early = await servers.completeAuthorization(
        workspaceId: _ws,
        scope: _mine,
        attemptId: begun.attemptId,
        code: 'AAAAAAAA',
        actorUserId: _owner,
      );
      expect(early.status, McpServerAuthorizationStatus.wrongCode);
      expect(early.triesLeft, McpServerAuthorizations.maxWrongCodes - 1);

      final callback = callbackOf(begun);
      final confirm = servers.authorizations.handleCallback(callback);
      expect(tokenForm, isEmpty, reason: 'the callback exchanges nothing');
      expect(
        secrets.values.keys.where((k) => k.startsWith('mcp_oauth:')),
        isEmpty,
      );
      expect(
        () => servers.authorizations.handleCallback(callback),
        throwsA(isA<AuthException>()),
        reason: 'a state is single use',
      );

      // Someone else holding the attempt id and the code finishes nothing.
      await expectLater(
        servers.completeAuthorization(
          workspaceId: _ws,
          scope: _mine,
          attemptId: begun.attemptId,
          code: confirm,
          actorUserId: _member,
        ),
        throwsA(isA<McpServerNotFoundException>()),
      );
      await expectLater(
        servers.completeAuthorization(
          workspaceId: 'ws-2',
          scope: _mine,
          attemptId: begun.attemptId,
          code: confirm,
          actorUserId: _owner,
        ),
        throwsA(isA<McpServerNotFoundException>()),
      );
      expect(tokenForm, isEmpty);

      bearerSeen.clear();
      final done = await servers.completeAuthorization(
        workspaceId: _ws,
        scope: _mine,
        attemptId: begun.attemptId,
        code: confirm.toLowerCase(),
        actorUserId: _owner,
      );
      expect(done.status, McpServerAuthorizationStatus.done);
      expect(tokenForm['code'], 'pc');
      expect(
        tokenForm['redirect_uri'],
        'https://cc.example.com/oauth/mcp/callback',
      );
      expect(tokenForm['code_verifier'], isNotEmpty);
      expect(
        bearerSeen,
        contains('Bearer at-1'),
        reason: 'reconnected with it',
      );
      expect(secrets.values.keys.where((k) => k.startsWith('mcp_oauth:')), [
        'mcp_oauth:wsu:$_ws:$_owner:$base',
      ]);

      // The workspace's server at the same address does not get the member's
      // sign-in.
      bearerSeen.clear();
      await addServer(_shared, _owner);
      expect(bearerSeen, isNotEmpty);
      expect(bearerSeen, everyElement(isEmpty));

      // Removing the server removes its sign-in.
      await servers.delete(
        workspaceId: _ws,
        scope: _mine,
        id: id,
        actorUserId: _owner,
      );
      expect(secrets.values.keys.where((k) => k.contains(':wsu:')), isEmpty);
    });

    test('wrong codes run out and the attempt fails for good', () async {
      final id = await addServer(_shared, _owner);
      final begun = await servers.beginAuthorization(
        workspaceId: _ws,
        scope: _shared,
        id: id,
        actorUserId: _owner,
        origin: 'https://cc.example.com',
      );
      final confirm = servers.authorizations.handleCallback(callbackOf(begun));
      McpServerAuthorization? last;
      for (var i = 0; i < McpServerAuthorizations.maxWrongCodes; i++) {
        last = await servers.completeAuthorization(
          workspaceId: _ws,
          scope: _shared,
          attemptId: begun.attemptId,
          code: confirm == 'ZZZZZZZZ' ? 'YYYYYYYY' : 'ZZZZZZZZ',
          actorUserId: _owner,
        );
      }
      expect(last!.status, McpServerAuthorizationStatus.failed);
      final after = await servers.completeAuthorization(
        workspaceId: _ws,
        scope: _shared,
        attemptId: begun.attemptId,
        code: confirm,
        actorUserId: _owner,
      );
      expect(after.status, McpServerAuthorizationStatus.failed);
      expect(tokenForm, isEmpty);
    });

    test(
      'a refused or unknown callback shows nothing and fails closed',
      () async {
        final id = await addServer(_shared, _owner);
        final begun = await servers.beginAuthorization(
          workspaceId: _ws,
          scope: _shared,
          id: id,
          actorUserId: _owner,
          origin: 'https://cc.example.com',
        );
        expect(
          () => servers.authorizations.handleCallback(
            Uri.parse(
              'https://cc.example.com/oauth/mcp/callback?state=nope&code=x',
            ),
          ),
          throwsA(isA<AuthException>()),
        );
        final state = Uri.parse(begun.url).queryParameters['state'];
        expect(
          () => servers.authorizations.handleCallback(
            Uri.parse(
              'https://cc.example.com/oauth/mcp/callback'
              '?state=$state&error=access_denied',
            ),
          ),
          throwsA(isA<AuthException>()),
        );
        final after = await servers.completeAuthorization(
          workspaceId: _ws,
          scope: _shared,
          attemptId: begun.attemptId,
          code: 'AAAAAAAA',
          actorUserId: _owner,
        );
        expect(after.status, McpServerAuthorizationStatus.failed);
      },
    );

    test('a sign-in with no address to come back to is refused', () async {
      final id = await addServer(_shared, _owner);
      await expectLater(
        servers.beginAuthorization(
          workspaceId: _ws,
          scope: _shared,
          id: id,
          actorUserId: _owner,
          origin: '',
        ),
        throwsA(isA<AuthException>()),
      );
    });
  });

  test('a name clash and an unknown id are refused', () async {
    await servers.save(
      workspaceId: _ws,
      scope: _shared,
      draft: stdio(),
      actorUserId: _admin,
    );
    await expectLater(
      servers.save(
        workspaceId: _ws,
        scope: _shared,
        draft: stdio(),
        actorUserId: _admin,
      ),
      throwsA(isA<McpServerDefinitionException>()),
    );
    await expectLater(
      servers.save(
        workspaceId: _ws,
        scope: _shared,
        draft: stdio(id: 'ghost'),
        actorUserId: _admin,
      ),
      throwsA(isA<McpServerNotFoundException>()),
    );
    await expectLater(
      servers.delete(
        workspaceId: 'ws-2',
        scope: _shared,
        id: 'srv-0',
        actorUserId: _admin,
      ),
      throwsA(isA<McpServerNotFoundException>()),
      reason: 'another workspace cannot reach it by id',
    );
  });
}

extension on McpServerDraft {
  McpServerDraft copyEnabled(bool enabled) => McpServerDraft(
    id: id,
    name: name,
    transport: transport,
    command: command,
    args: args,
    url: url,
    enabled: enabled,
    envSet: envSet,
    envRemove: envRemove,
    headerSet: headerSet,
    headerRemove: headerRemove,
  );
}
