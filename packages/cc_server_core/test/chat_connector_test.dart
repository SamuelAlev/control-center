import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:cc_domain/cc_domain.dart' show ValidationException;
import 'package:cc_domain/core/domain/entities/agent.dart';
import 'package:cc_domain/core/domain/events/domain_event_bus.dart';
import 'package:cc_domain/core/domain/repositories/agent_repository.dart';
import 'package:cc_domain/core/domain/repositories/user_repository.dart';
import 'package:cc_domain/core/domain/repositories/workspace_membership_repository.dart';
import 'package:cc_domain/features/chat_bridge/domain/entities/chat_space_link.dart';
import 'package:cc_domain/features/chat_bridge/domain/entities/chat_user_link.dart';
import 'package:cc_domain/features/chat_bridge/domain/repositories/chat_link_repositories.dart';
import 'package:cc_domain/features/chat_bridge/domain/value_objects/chat_bot_profile.dart';
import 'package:cc_domain/features/chat_bridge/domain/value_objects/chat_bridge_connection.dart';
import 'package:cc_domain/features/chat_bridge/domain/value_objects/chat_link_method.dart';
import 'package:cc_domain/features/chat_bridge/domain/value_objects/chat_provider.dart';
import 'package:cc_domain/features/messaging/domain/entities/conversation_tree.dart';
import 'package:cc_domain/features/messaging/domain/repositories/messaging_repository.dart';
import 'package:cc_domain/features/ticketing/domain/services/ticket_workflow_service.dart';
import 'package:cc_infra/cc_infra.dart';
import 'package:cc_server_core/src/chat/chat_connector.dart';
import 'package:cc_server_core/src/chat/chat_provider_plugin.dart';
import 'package:cc_server_core/src/chat/file_chat_connection_store.dart';
import 'package:cc_server_core/src/chat/slack_chat_provider_plugin.dart';
import 'package:dio/dio.dart';
import 'package:test/test.dart';

/// [ChatConnector]: the lifecycle seam the RPC ops and the boot reconciler use.
///
/// The behaviour worth pinning is where credentials end up. An app-management
/// credential rotates on every use and the replacement must land somewhere durable
/// *before* it is used — during guided create that is the setup file and once the
/// workspace is connected it is the connection itself. A rotation written to the
/// wrong one silently un-manages the provider-side app.
///
/// The connector is exercised through the Slack plugin because that is the only
/// provider registered today; nothing under test here names Slack, which is the
/// point — a second plugin inherits all of it.
void main() {
  const slack = ChatProvider.slack;
  late Directory dataDir;
  late FileChatConnectionStore store;
  late _SlackStub api;
  late ChatConnector connector;
  late _FakeUserLinks userLinks;

  setUp(() {
    dataDir = Directory.systemTemp.createTempSync('cc_chat_connector_');
    store = FileChatConnectionStore(dataDir: dataDir.path);
    api = _SlackStub();
    userLinks = _FakeUserLinks();
    connector = ChatConnector(
      registry: ChatProviderRegistry([
        SlackChatProviderPlugin(dioFactory: api.dio),
      ]),
      store: store,
      streamRegistry: ActiveStreamRegistry(),
      messaging: _FakeMessaging(),
      messages: _FakeMessages(),
      agents: _FakeAgents(),
      spaceLinks: _FakeSpaceLinks(),
      userLinks: userLinks,
      users: _FakeUsers(),
      members: _FakeMembers(),
      tickets: _FakeTickets(),
      listWorkspaceIds: () async => ['w-1', 'w-2'],
      eventBus: DomainEventBus(),
    );
  });

  tearDown(() async {
    await connector.stop();
    dataDir.deleteSync(recursive: true);
  });

  Future<ChatConnectionStatus> connect({
    String workspaceId = 'w-1',
    String botToken = 'xoxb-1',
    String appToken = 'xapp-1',
    String? configRefreshToken,
  }) => connector.connect(
    workspaceId: workspaceId,
    provider: slack,
    credentials: {
      'botToken': botToken,
      'appToken': appToken,
      'configRefreshToken': ?configRefreshToken,
    },
  );

  test('a workspace with no chat app reports disconnected', () async {
    expect(await connector.status('w-1', slack), ChatConnectionStatus.none(slack));
  });

  test('every offered provider gets a status, connected or not', () async {
    final statuses = await connector.statuses('w-1');

    // This is what the settings surface renders one card per: a provider the
    // workspace has never touched still has to appear.
    expect(statuses.map((s) => s.provider), [slack]);
    expect(statuses.single.isConnected, isFalse);
  });

  test('connect verifies the credentials before storing anything', () async {
    api.fail('auth.test', 'invalid_auth');

    await expectLater(connect(botToken: 'xoxb-typo'), throwsA(isA<Exception>()));
    // A typo must not become a socket that quietly never works.
    expect(store.has('w-1', slack), isFalse);
  });

  test('connect refuses a credential the descriptor cannot accept', () async {
    await expectLater(
      connect(botToken: 'nope-1'),
      throwsA(isA<ValidationException>()),
    );
    // The prefix rule lives in the descriptor, so it is refused before a request
    // is even made.
    expect(api.calls, isEmpty);
    expect(store.has('w-1', slack), isFalse);
  });

  test('connect stores the identity the provider reported', () async {
    final status = await connect(configRefreshToken: 'xoxe-1');

    expect(status.teamName, 'Acme');
    expect(status.botName, 'controlcenter');
    expect(status.appId, 'A1');
    // The settings card enables "customize bot" from exactly this.
    expect(status.canManageApp, isTrue);
    final stored = await store.load('w-1', slack);
    expect(stored?.credential('botToken'), 'xoxb-1');
    expect(stored?.credential('appToken'), 'xapp-1');
    expect(stored?.credential('configRefreshToken'), 'xoxe-1');
    expect(stored?.provider, slack);
  });

  test('connect completes a guided create’s hand-off', () async {
    await store.saveSetup(
      'w-1',
      slack,
      const ChatAppSetup(managementCredential: 'xoxe-rotated', appId: 'A1'),
    );

    // The user pastes only the credentials the provider has no API for; the
    // app-management credential is already here and must survive.
    await connect();

    expect(
      (await store.load('w-1', slack))?.credential('configRefreshToken'),
      'xoxe-rotated',
    );
    // And the half-finished state is gone, so it cannot be replayed later.
    expect(await store.loadSetup('w-1', slack), isNull);
  });

  test('reconnecting keeps the app-management credential', () async {
    await connect(configRefreshToken: 'xoxe-1');

    // Re-pasting a fresh bot token (a reinstall) should not cost the user the
    // ability to manage the app.
    await connect(botToken: 'xoxb-2', appToken: 'xapp-2');

    final stored = await store.load('w-1', slack);
    expect(stored?.credential('botToken'), 'xoxb-2');
    expect(stored?.credential('configRefreshToken'), 'xoxe-1');
  });

  test('disconnect forgets the credentials and any pending setup', () async {
    await connect();
    await store.saveSetup(
      'w-1',
      slack,
      const ChatAppSetup(managementCredential: 'x'),
    );

    await connector.disconnect('w-1', slack);

    expect(store.has('w-1', slack), isFalse);
    expect(await store.loadSetup('w-1', slack), isNull);
    expect(await connector.status('w-1', slack), ChatConnectionStatus.none(slack));
  });

  test('a connected workspace is isolated from its neighbour', () async {
    await connect();

    expect(
      await connector.status('w-2', slack),
      ChatConnectionStatus.none(slack),
    );
    expect(store.has('w-2', slack), isFalse);
  });

  test('status counts the workspace’s linked members', () async {
    userLinks.rows.add(_link());
    await connect();

    expect((await connector.status('w-1', slack)).linkedMemberCount, 1);
  });

  test('an unregistered provider is refused at the registry', () {
    final empty = ChatProviderRegistry(const []);

    expect(
      () => empty.of(slack),
      throwsA(
        isA<ValidationException>().having(
          (e) => e.message,
          'message',
          contains('not available'),
        ),
      ),
    );
  });

  group('app management', () {
    test('guided create persists the rotated credential across the gap',
        () async {
      final creation = await connector.createApp(
        workspaceId: 'w-1',
        provider: slack,
        managementCredential: 'xoxe-1',
        profile: _profile,
      );

      expect(creation.appId, 'A1');
      // The steps the provider has no API for are named, not hardcoded client-side.
      expect(creation.remainingSteps.map((s) => s.id), ['appToken', 'install']);
      expect(creation.step('appToken')?.url, contains('/apps/A1'));
      // The provider killed `xoxe-1` when it answered: the replacement is what is
      // stored and it is stored even though no connection exists yet.
      final setup = await store.loadSetup('w-1', slack);
      expect(setup?.managementCredential, 'xoxe-2');
      expect(setup?.appId, 'A1');
      // Nothing is "connected" — there are no runtime credentials until install.
      expect(store.has('w-1', slack), isFalse);
    });

    test('a rotation on a connected workspace updates the connection', () async {
      await connect(configRefreshToken: 'xoxe-1');

      await connector.botProfile('w-1', slack);

      // The live credential is on the connection, so the next call reads the
      // rotated one rather than replaying a dead one from a stale setup file.
      expect(
        (await store.load('w-1', slack))?.credential('configRefreshToken'),
        'xoxe-2',
      );
      expect(await store.loadSetup('w-1', slack), isNull);
    });

    test('an app id nobody recorded is refused with an explanation', () async {
      await store.saveSetup(
        'w-1',
        slack,
        const ChatAppSetup(managementCredential: 'xoxe-1'),
      );

      await expectLater(
        connector.botProfile('w-1', slack),
        throwsA(
          isA<ValidationException>().having(
            (e) => e.message,
            'message',
            contains('which Slack app'),
          ),
        ),
      );
    });

    test('updating the profile reports a scope change as a step', () async {
      await connect(configRefreshToken: 'xoxe-1');
      api.permissionsUpdated = true;

      final remaining = await connector.updateBotProfile(
        workspaceId: 'w-1',
        provider: slack,
        profile: _profile,
      );

      // Scope changes are inert until somebody reinstalls, so the caller is
      // handed the link rather than left believing the edit is live.
      expect(remaining, isNotNull);
      expect(remaining!.id, 'install');
      expect(remaining.url, contains('install'));
    });

    test('a profile edit that changes no permission leaves no step', () async {
      await connect(configRefreshToken: 'xoxe-1');

      final remaining = await connector.updateBotProfile(
        workspaceId: 'w-1',
        provider: slack,
        profile: _profile,
      );

      expect(remaining, isNull);
    });
  });

  group('user links', () {
    test('a minted code is workspace- and provider-scoped', () {
      final code = connector.beginUserLink(
        workspaceId: 'w-1',
        provider: slack,
        userId: 'u-1',
      );

      expect(code.code, hasLength(6));
      expect(connector.linkCodes.consume('w-2', code.code, provider: slack), isNull);
      expect(connector.linkCodes.consume('w-1', code.code, provider: slack), isNotNull);
    });

    test('unlinking also revokes an outstanding code', () async {
      final code = connector.beginUserLink(
        workspaceId: 'w-1',
        provider: slack,
        userId: 'u-1',
      );
      userLinks.rows.add(_link());

      expect(await connector.unlinkUser('w-1', 'u-1', provider: slack), 1);
      expect(userLinks.rows, isEmpty);
      // Otherwise the code a removed member still holds would re-link them.
      expect(connector.linkCodes.consume('w-1', code.code, provider: slack), isNull);
    });

    test('the roster can be read for one provider or all of them', () async {
      userLinks.rows.add(_link());

      expect(await connector.listUserLinks('w-1'), hasLength(1));
      expect(
        await connector.listUserLinks('w-1', provider: slack),
        hasLength(1),
      );
    });
  });

  group('boot', () {
    test('skips a workspace with no connection file', () async {
      await connector.start();

      expect(api.calls, isEmpty);
    });

    test('does not dial a disabled connection', () async {
      await store.save(
        ChatBridgeConnection(
          provider: slack,
          workspaceId: 'w-1',
          credentials: const {'botToken': 'xoxb-1', 'appToken': 'xapp-1'},
          appId: 'A1',
          teamId: 'T1',
          teamName: 'Acme',
          botUserId: 'UBOT',
          botName: 'controlcenter',
          enabled: false,
          connectedAt: DateTime.utc(2026),
        ),
      );

      await connector.start();

      expect(api.calls, isEmpty);
      // The credentials stay — disabling is not disconnecting.
      expect(store.has('w-1', slack), isTrue);
    });
  });
}

ChatUserLink _link() => ChatUserLink(
  id: 'ul-1',
  workspaceId: 'w-1',
  provider: ChatProvider.slack,
  externalTeamId: 'T1',
  externalUserId: 'U1',
  userId: 'u-1',
  method: ChatLinkMethod.code,
  linkedAt: DateTime.utc(2026),
);

const _profile = ChatBotProfile(
  appName: 'Control Center',
  botDisplayName: 'control-center',
  description: 'Agents from chat.',
  agentDescription: 'Mention me.',
  command: 'cc',
);

/// The provider's HTTP API, scripted. Every connector path that talks to Slack
/// goes through a `Dio` from [dio], so the whole HTTP surface is observable here.
class _SlackStub {
  final List<String> calls = [];
  final Map<String, String> _failures = {};
  bool permissionsUpdated = false;

  void fail(String method, String error) => _failures[method] = error;

  Dio dio() => Dio()..httpClientAdapter = _Adapter(this);

  Map<String, dynamic> handle(String method) {
    calls.add(method);
    if (_failures[method] case final error?) {
      return {'ok': false, 'error': error};
    }
    return switch (method) {
      'auth.test' => {
        'ok': true,
        'team': 'Acme',
        'team_id': 'T1',
        'user_id': 'UBOT',
        'user': 'controlcenter',
        'app_id': 'A1',
        'bot_id': 'B1',
      },
      // Loopback port 1: the dial fails immediately, so a connect test never
      // waits on a real WebSocket.
      'apps.connections.open' => {'ok': true, 'url': 'wss://127.0.0.1:1/ws'},
      'tooling.tokens.rotate' => {
        'ok': true,
        'token': 'xoxe.xoxp-access',
        'refresh_token': 'xoxe-2',
      },
      'apps.manifest.create' => {'ok': true, 'app_id': 'A1'},
      'apps.manifest.export' => {
        'ok': true,
        'manifest': {
          'display_information': {'name': 'Control Center'},
          'features': {
            'bot_user': {'display_name': 'control-center'},
          },
        },
      },
      'apps.manifest.update' => {
        'ok': true,
        'permissions_updated': permissionsUpdated,
      },
      _ => {'ok': true},
    };
  }
}

class _Adapter implements HttpClientAdapter {
  _Adapter(this.stub);

  final _SlackStub stub;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async => ResponseBody.fromString(
    jsonEncode(stub.handle(options.path.split('/').last)),
    200,
    headers: const {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    },
  );

  @override
  void close({bool force = false}) {}
}

class _FakeMessaging implements MessagingService {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeMessages implements MessagingRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  /// The tree is not exercised by this fake — a branch it silently accepted
  /// would be a pointer move nothing could observe, so it refuses instead.
  @override
  Future<ConversationTree> conversationTree({
    required String workspaceId,
    required String conversationId,
  }) async => throw UnimplementedError();

  @override
  Future<void> branchConversationAt({
    required String workspaceId,
    required String conversationId,
    required String messageId,
  }) async => throw UnimplementedError();

  @override
  Future<String> forkConversation({
    required String workspaceId,
    required String spaceId,
    required String conversationId,
    String? messageId,
    String? title,
  }) async => throw UnimplementedError();
}

class _FakeAgents implements AgentRepository {
  @override
  Stream<List<Agent>> watchByWorkspace(String workspaceId) =>
      Stream.value(const []);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeUsers implements UserRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeMembers implements WorkspaceMembershipRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeTickets implements TicketWorkflowService {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeSpaceLinks implements ChatSpaceLinkRepository {
  @override
  Future<List<ChatSpaceLink>> forWorkspace(
    String workspaceId, {
    ChatProvider? provider,
  }) async => const [];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeUserLinks implements ChatUserLinkRepository {
  final List<ChatUserLink> rows = [];

  @override
  Future<List<ChatUserLink>> forWorkspace(
    String workspaceId, {
    ChatProvider? provider,
  }) async => rows
      .where(
        (r) =>
            r.workspaceId == workspaceId &&
            (provider == null || r.provider == provider),
      )
      .toList();

  @override
  Future<int> deleteForUser(
    String workspaceId,
    String userId, {
    required ChatProvider provider,
  }) async {
    final before = rows.length;
    rows.removeWhere(
      (r) =>
          r.workspaceId == workspaceId &&
          r.userId == userId &&
          r.provider == provider,
    );
    return before - rows.length;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
