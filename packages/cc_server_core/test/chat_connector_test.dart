import 'dart:async';
import 'dart:io';

import 'package:cc_connect_core/cc_connect_core.dart'
    show ConnectOAuthLane, SealedGrant;
import 'package:cc_domain/cc_domain.dart'
    show AuthException, NotFoundException, ValidationException;
import 'package:cc_domain/core/domain/entities/agent.dart';
import 'package:cc_domain/core/domain/events/domain_event_bus.dart';
import 'package:cc_domain/core/domain/repositories/agent_repository.dart';
import 'package:cc_domain/core/domain/repositories/user_repository.dart';
import 'package:cc_domain/core/domain/repositories/workspace_membership_repository.dart';
import 'package:cc_domain/core/domain/value_objects/principal.dart';
import 'package:cc_domain/features/chat_bridge/domain/entities/chat_space_link.dart';
import 'package:cc_domain/features/chat_bridge/domain/entities/chat_user_link.dart';
import 'package:cc_domain/features/chat_bridge/domain/repositories/chat_link_repositories.dart';
import 'package:cc_domain/features/chat_bridge/domain/value_objects/chat_bot_profile.dart';
import 'package:cc_domain/features/chat_bridge/domain/value_objects/chat_bridge_connection.dart';
import 'package:cc_domain/features/chat_bridge/domain/value_objects/chat_link_method.dart';
import 'package:cc_domain/features/chat_bridge/domain/value_objects/chat_provider.dart';
import 'package:cc_domain/features/messaging/domain/entities/conversation_tree.dart';
import 'package:cc_domain/features/messaging/domain/repositories/messaging_repository.dart';
import 'package:cc_domain/features/ticketing/domain/entities/ticket.dart';
import 'package:cc_domain/features/ticketing/domain/entities/ticket_priority.dart';
import 'package:cc_domain/features/ticketing/domain/entities/ticket_provider.dart';
import 'package:cc_domain/features/ticketing/domain/entities/ticket_status.dart';
import 'package:cc_domain/features/ticketing/domain/services/ticket_workflow_service.dart';
import 'package:cc_infra/cc_infra.dart';
import 'package:cc_infra/testing/http_client.dart';
import 'package:cc_server_core/src/chat/chat_connector.dart';
import 'package:cc_server_core/src/chat/chat_provider_plugin.dart';
import 'package:cc_server_core/src/chat/file_chat_connection_store.dart';
import 'package:cc_server_core/src/chat/slack_chat_provider_plugin.dart';
import 'package:cc_server_core/src/chat/slack_connect.dart';
import 'package:cc_server_core/src/connect/sign_in_service.dart';
import 'package:cc_server_core/src/connect/slack_sign_in_lane.dart';
import 'package:cc_server_core/src/identity/provider_token.dart';
import 'package:rhttp/rhttp.dart';
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
  late _FakeGrants grants;
  late _FakeTickets tickets;
  late SlackChatProviderPlugin plugin;

  setUp(() {
    dataDir = Directory.systemTemp.createTempSync('cc_chat_connector_');
    store = FileChatConnectionStore(dataDir: dataDir.path);
    api = _SlackStub();
    userLinks = _FakeUserLinks();
    grants = _FakeGrants();
    tickets = _FakeTickets();
    plugin = SlackChatProviderPlugin(
      httpClientFactory: api.client,
      connect: grants,
    );
    connector = ChatConnector(
      registry: ChatProviderRegistry([plugin]),
      store: store,
      streamRegistry: ActiveStreamRegistry(),
      messaging: _FakeMessaging(),
      messages: _FakeMessages(),
      agents: _FakeAgents(),
      spaceLinks: _FakeSpaceLinks(),
      userLinks: userLinks,
      users: _FakeUsers(),
      members: _FakeMembers(),
      tickets: tickets,
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
    expect(
      await connector.status('w-1', slack),
      ChatConnectionStatus.none(slack),
    );
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

    await expectLater(
      connect(botToken: 'xoxb-typo'),
      throwsA(isA<Exception>()),
    );
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
    expect(
      await connector.status('w-1', slack),
      ChatConnectionStatus.none(slack),
    );
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
    test('guided create persists the rotated credential across the gap', () async {
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

    test(
      'a rotation on a connected workspace updates the connection',
      () async {
        await connect(configRefreshToken: 'xoxe-1');

        await connector.botProfile('w-1', slack);

        // The live credential is on the connection, so the next call reads the
        // rotated one rather than replaying a dead one from a stale setup file.
        expect(
          (await store.load('w-1', slack))?.credential('configRefreshToken'),
          'xoxe-2',
        );
        expect(await store.loadSetup('w-1', slack), isNull);
      },
    );

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
      expect(
        connector.linkCodes.lookup('w-2', code.code, provider: slack),
        isNull,
      );
      expect(
        connector.linkCodes.lookup('w-1', code.code, provider: slack),
        isNotNull,
      );
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
      expect(
        connector.linkCodes.lookup('w-1', code.code, provider: slack),
        isNull,
      );
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

  group('shared app (Connect)', () {
    Future<ChatConnectionStatus> adopt({
      String workspaceId = 'w-1',
      String seal = 'seal-1',
      DateTime? expiresAt,
    }) async => connector.adoptConnection(
      await plugin.connectionFromGrant(
        workspaceId: workspaceId,
        token: _sealedToken(seal: seal, expiresAt: expiresAt),
        grant: _grant(seal: seal),
      ),
    );

    test('a sign-in is stored as the seal alone', () async {
      final status = await adopt();

      expect(status.mode, ChatConnectionMode.connect);
      expect(status.teamName, 'Acme');
      // There is no app of the workspace's own to reshape.
      expect(status.canManageApp, isFalse);
      final stored = await store.load('w-1', slack);
      expect(stored?.mode, ChatConnectionMode.connect);
      expect(stored?.botId, 'B1');
      expect(stored?.credentials.keys, [SlackChatProviderPlugin.grantField]);
      // The 12-hour bot token lives in memory only.
      final grant = stored!.credential(SlackChatProviderPlugin.grantField)!;
      expect(grant, isNot(contains('xoxe.xoxb-')));
      expect(ProviderToken.tryParse(grant)?.seal, 'seal-1');
      // Events arrive through the relay, attached for this team.
      expect(grants.attached, ['T1']);
      expect(api.calls, isNot(contains('apps.connections.open')));
    });

    test('a token that is not a rotating bot token is refused', () async {
      await expectLater(
        plugin.connectionFromGrant(
          workspaceId: 'w-1',
          token: const ProviderToken(accessToken: 'xoxb-1', seal: 'seal-1'),
          grant: _grant(),
        ),
        throwsA(isA<FormatException>()),
      );
    });

    test('a grant whose token belongs to another bot is refused', () async {
      await expectLater(
        plugin.connectionFromGrant(
          workspaceId: 'w-1',
          token: _sealedToken(),
          grant: _grant(botId: 'B-other'),
        ),
        throwsA(isA<FormatException>()),
      );
      expect(store.has('w-1', slack), isFalse);
    });

    test('pasting tokens is refused while the shared app runs', () async {
      await adopt();

      await expectLater(connect(), throwsA(isA<ValidationException>()));
      expect(
        (await store.load('w-1', slack))?.mode,
        ChatConnectionMode.connect,
      );
    });

    test('the shared app is refused while the workspace has its own', () async {
      await connect();

      await expectLater(adopt(), throwsA(isA<ValidationException>()));
      expect((await store.load('w-1', slack))?.mode, ChatConnectionMode.own);
    });

    test('the newest workspace to install a team takes it over', () async {
      await adopt();
      await adopt(workspaceId: 'w-2', seal: 'seal-2');

      expect(store.has('w-1', slack), isFalse);
      expect(store.has('w-2', slack), isTrue);
      // The fresh grant rides the same team binding: nothing is revoked.
      expect(grants.revoked, isEmpty);
    });

    test('app management is refused for the shared app', () async {
      await adopt();

      await expectLater(
        connector.botProfile('w-1', slack),
        throwsA(isA<ValidationException>()),
      );
    });

    test('disconnecting releases the shared app upstream', () async {
      await adopt();

      await connector.disconnect('w-1', slack);

      expect(grants.revoked, ['w-1:seal-1']);
      expect(store.has('w-1', slack), isFalse);
    });

    test('disconnecting an own app releases nothing upstream', () async {
      await connect();

      await connector.disconnect('w-1', slack);

      expect(grants.revoked, isEmpty);
    });

    test('only an own app counts as an own connection', () async {
      expect(await connector.anyOwnConnection(slack), isFalse);
      await adopt();
      expect(await connector.anyOwnConnection(slack), isFalse);

      await connect(workspaceId: 'w-2');

      expect(await connector.anyOwnConnection(slack), isTrue);
    });

    test('a rejected renewal forgets the grant', () async {
      grants.next = const SlackGrantRejected('needs_sign_in');

      // Already expired: the first Slack call renews.
      await adopt(
        expiresAt: DateTime.now().toUtc().subtract(const Duration(minutes: 1)),
      );
      // Cleared out of band, through the file store.
      await _eventually(() => !store.has('w-1', slack));

      expect(grants.renewals, 1);
      expect(store.has('w-1', slack), isFalse);
      expect(
        await connector.status('w-1', slack),
        ChatConnectionStatus.none(slack),
      );
      // A gone grant has nothing upstream left to release.
      expect(grants.revoked, isEmpty);
    });

    test('an unavailable renewal keeps the grant', () async {
      grants.next = const SlackGrantUnavailable('connect_unreachable');

      await adopt(
        expiresAt: DateTime.now().toUtc().subtract(const Duration(minutes: 1)),
      );
      await pumpEventQueue();

      expect(grants.renewals, 1);
      expect(store.has('w-1', slack), isTrue);
    });

    test('a renewal stores the new seal in place', () async {
      grants.next = SlackGrantRenewed(
        _sealedToken(
          seal: 'seal-2',
          accessToken: 'xoxe.xoxb-2',
          expiresAt: DateTime.now().toUtc().add(const Duration(hours: 12)),
        ),
      );

      await adopt(
        expiresAt: DateTime.now().toUtc().subtract(const Duration(minutes: 1)),
      );
      Future<String?> storedSeal() async => ProviderToken.tryParse(
        (await store.load(
          'w-1',
          slack,
        ))?.credential(SlackChatProviderPlugin.grantField),
      )?.seal;
      await _eventually(() async => await storedSeal() == 'seal-2');

      final stored = await store.load('w-1', slack);
      expect(
        ProviderToken.tryParse(
          stored?.credential(SlackChatProviderPlugin.grantField),
        )?.seal,
        'seal-2',
      );
      // Saved without a restart: the relay was attached once.
      expect(grants.attached, ['T1']);
    });
  });

  group('the Slack sign-in lane', () {
    late SlackSignInLane lane;

    setUp(() => lane = SlackSignInLane(connector: connector, plugin: plugin));

    SignInResult result({String? slot = 'w-1', SealedGrant? grant}) =>
        SignInResult(
          lane: ConnectOAuthLane.slack,
          userId: 'u-1',
          workspaceId: slot,
          slot: slot,
          token: _sealedToken(),
          grant: grant ?? _grant(),
        );

    test('always routes through Connect, into the workspace', () async {
      expect(await lane.ownApp('w-1'), isNull);
      expect(await lane.allowsConnect('w-1'), isTrue);
      expect(await lane.slotFor('w-1'), 'w-1');
      // The grant belongs to a workspace; there is no personal Slack slot.
      await expectLater(lane.slotFor(null), throwsA(isA<AuthException>()));
      expect(await lane.allowsConnect(null), isFalse);
    });

    test('a server without Connect never offers it', () async {
      final offline = SlackSignInLane(
        connector: connector,
        plugin: SlackChatProviderPlugin(httpClientFactory: api.client),
      );

      expect(await offline.allowsConnect('w-1'), isFalse);
    });

    test('a finished sign-in opens the shared app', () async {
      await lane.store(result());

      final connection = await lane.connection('u-1', 'w-1');
      expect(connection?.connected, isTrue);
      expect(connection?.account, 'Acme');
      expect(connection?.accountId, 'T1');
      expect(connection?.workspaceSlot, isTrue);
      expect(connection?.source, SignInMode.connect);
      expect(grants.attached, ['T1']);
    });

    test('a workspace on its own app refuses the shared one', () async {
      await connect();

      expect(await lane.allowsConnect('w-1'), isFalse);
      await expectLater(lane.store(result()), throwsA(isA<AuthException>()));
      // And the own app is not this lane's to report or remove.
      expect(await lane.connection('u-1', 'w-1'), isNull);
      await lane.disconnect('u-1', 'w-1');
      expect(store.has('w-1', slack), isTrue);
    });

    test('a grant Slack cannot vouch for is a failed sign-in', () async {
      api.fail('auth.test', 'invalid_auth');

      await expectLater(lane.store(result()), throwsA(isA<FormatException>()));
      expect(store.has('w-1', slack), isFalse);
    });

    test('a sign-in without a grant or workspace stores nothing', () async {
      await expectLater(
        lane.store(result(slot: null)),
        throwsA(isA<FormatException>()),
      );
      expect(store.has('w-1', slack), isFalse);
    });

    test('disconnecting releases the shared app', () async {
      await lane.store(result());

      await lane.disconnect('u-1', 'w-1');

      expect(store.has('w-1', slack), isFalse);
      expect(grants.revoked, ['w-1:seal-1']);
    });
  });

  group('confirming a code', () {
    void claim({
      String workspaceId = 'w-1',
      String externalUserId = 'U9',
      String teamId = 'T1',
    }) {
      final code = connector.beginUserLink(
        workspaceId: workspaceId,
        provider: slack,
        userId: 'u-1',
      );
      connector.linkCodes.claim(
        workspaceId,
        code.code,
        provider: slack,
        claim: ChatLinkClaim(
          externalTeamId: teamId,
          externalUserId: externalUserId,
          label: 'Alex',
          conversationId: 'D9',
          claimedAt: DateTime.utc(2026),
        ),
      );
    }

    test('links the profile the member confirmed', () async {
      await connect();
      claim();

      final link = await connector.confirmUserLink(
        workspaceId: 'w-1',
        userId: 'u-1',
        provider: slack,
        externalUserId: 'U9',
      );

      expect(link.method, ChatLinkMethod.code);
      expect(link.externalTeamId, 'T1');
      expect(userLinks.rows.single.externalUserId, 'U9');
      expect(connector.pendingUserLink('w-1', 'u-1', provider: slack), isNull);
      // The bot says so in the conversation the code arrived in.
      await pumpEventQueue();
      expect(api.calls, contains('chat.postMessage'));
    });

    test('a different profile than the one shown is refused', () async {
      await connect();
      claim();

      await expectLater(
        connector.confirmUserLink(
          workspaceId: 'w-1',
          userId: 'u-1',
          provider: slack,
          externalUserId: 'U-other',
        ),
        throwsA(isA<NotFoundException>()),
      );
      expect(userLinks.rows, isEmpty);
      // The claim stays for the member to decline.
      expect(
        connector.pendingUserLink('w-1', 'u-1', provider: slack)?.claim,
        isNotNull,
      );
    });

    test(
      'a claim from another team than the connected one is refused',
      () async {
        await connect();
        claim(teamId: 'T-other');

        await expectLater(
          connector.confirmUserLink(
            workspaceId: 'w-1',
            userId: 'u-1',
            provider: slack,
            externalUserId: 'U9',
          ),
          throwsA(isA<NotFoundException>()),
        );
        expect(userLinks.rows, isEmpty);
      },
    );

    test('a workspace with no connection confirms nothing', () async {
      claim();

      await expectLater(
        connector.confirmUserLink(
          workspaceId: 'w-1',
          userId: 'u-1',
          provider: slack,
          externalUserId: 'U9',
        ),
        throwsA(isA<NotFoundException>()),
      );
    });

    test('declining burns the code', () async {
      await connect();
      claim();

      connector.declineUserLink('w-1', 'u-1', provider: slack);

      expect(connector.pendingUserLink('w-1', 'u-1', provider: slack), isNull);
    });

    test('the pending code is watchable as the claim arrives', () async {
      final seen = <ChatLinkCode?>[];
      final sub = connector
          .watchPendingUserLink('w-1', 'u-1', provider: slack)
          .listen(seen.add);
      addTearDown(sub.cancel);
      await pumpEventQueue();

      claim();
      await pumpEventQueue();

      expect(seen.first, isNull);
      expect(seen.last?.claim?.externalUserId, 'U9');
    });
  });

  group('ticket drafts', () {
    ChatTicketDraft draft({String userId = 'u-1'}) =>
        connector.ticketDrafts.add(
          workspaceId: 'w-1',
          provider: slack,
          reporterUserId: userId,
          title: 'Fix the flaky login test',
          description: 'It fails on CI.',
        );

    test(
      'confirming creates a backlog ticket reported by the member',
      () async {
        final d = draft();

        final ticket = await connector.confirmTicketDraft(
          workspaceId: 'w-1',
          userId: 'u-1',
          draftId: d.id,
          title: '  Fix the login test  ',
        );

        expect(ticket.title, 'Fix the login test');
        final created = tickets.created.single;
        expect(created.description, 'It fails on CI.');
        expect(created.status, TicketStatus.backlog);
        expect(created.createdByType, 'user');
        expect(created.createdById, 'u-1');
        expect(connector.ticketDraftsFor('w-1', 'u-1'), isEmpty);
      },
    );

    test('an empty title is refused and keeps the draft', () async {
      final d = draft();

      await expectLater(
        connector.confirmTicketDraft(
          workspaceId: 'w-1',
          userId: 'u-1',
          draftId: d.id,
          title: '   ',
        ),
        throwsA(isA<ValidationException>()),
      );
      expect(tickets.created, isEmpty);
      expect(connector.ticketDraftsFor('w-1', 'u-1'), hasLength(1));
    });

    test('a ticket that fails to create keeps its draft', () async {
      final d = draft();
      tickets.failNext = true;

      await expectLater(
        connector.confirmTicketDraft(
          workspaceId: 'w-1',
          userId: 'u-1',
          draftId: d.id,
        ),
        throwsA(isA<StateError>()),
      );
      expect(connector.ticketDraftsFor('w-1', 'u-1').single.id, d.id);

      await connector.confirmTicketDraft(
        workspaceId: 'w-1',
        userId: 'u-1',
        draftId: d.id,
      );
      expect(tickets.created, hasLength(1));
      expect(connector.ticketDraftsFor('w-1', 'u-1'), isEmpty);
    });

    test('only the reporter can confirm their draft', () async {
      final d = draft();

      await expectLater(
        connector.confirmTicketDraft(
          workspaceId: 'w-1',
          userId: 'u-2',
          draftId: d.id,
        ),
        throwsA(isA<NotFoundException>()),
      );
      expect(tickets.created, isEmpty);
      expect(connector.ticketDraftsFor('w-1', 'u-1'), hasLength(1));
    });

    test('a draft never crosses workspaces', () async {
      final d = draft();

      await expectLater(
        connector.confirmTicketDraft(
          workspaceId: 'w-2',
          userId: 'u-1',
          draftId: d.id,
        ),
        throwsA(isA<NotFoundException>()),
      );
      expect(connector.ticketDraftsFor('w-2', 'u-1'), isEmpty);
    });

    test('discarding creates nothing', () async {
      final d = draft();

      expect(connector.discardTicketDraft('w-1', 'u-1', d.id), isTrue);
      expect(connector.discardTicketDraft('w-1', 'u-1', d.id), isFalse);
      expect(tickets.created, isEmpty);
    });

    test('a member watches only their own drafts', () async {
      final seen = <int>[];
      final sub = connector
          .watchTicketDrafts('w-1', 'u-1')
          .listen((drafts) => seen.add(drafts.length));
      addTearDown(sub.cancel);
      await pumpEventQueue();

      draft(userId: 'u-2');
      draft();
      await pumpEventQueue();

      expect(seen, [0, 1]);
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

/// Waits up to two seconds for [condition]: a file-store write that happens out
/// of band lands on the IO thread, not in the microtask queue.
Future<void> _eventually(FutureOr<bool> Function() condition) async {
  for (var i = 0; i < 200 && !await condition(); i++) {
    await Future<void>.delayed(const Duration(milliseconds: 10));
  }
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

ProviderToken _sealedToken({
  String seal = 'seal-1',
  String accessToken = 'xoxe.xoxb-1',
  DateTime? expiresAt,
}) => ProviderToken(
  accessToken: accessToken,
  expiresAt: expiresAt ?? DateTime.now().toUtc().add(const Duration(hours: 12)),
  seal: seal,
  sealInstallId: 'install-1',
  connectOrigin: 'https://connect.example',
  appId: 'A1',
);

SealedGrant _grant({String seal = 'seal-1', String botId = 'B1'}) =>
    SealedGrant(
      seal: seal,
      accessToken: 'xoxe.xoxb-1',
      expiresAt: DateTime.utc(2099),
      appId: 'A1',
      teamId: 'T1',
      teamName: 'Acme',
      botUserId: 'UBOT',
      botId: botId,
    );

/// Connect's side of the shared app, scripted: what a renewal returns, which
/// seals were revoked and which teams are attached to the relay.
class _FakeGrants implements SlackConnectGrants {
  SlackGrantRenewal next = const SlackGrantUnavailable('connect_unreachable');
  int renewals = 0;
  final List<String> revoked = [];
  final List<String> attached = [];

  @override
  SlackRelayAttach get attach => (teamId, {required onItem, required onState}) {
    attached.add(teamId);
    onState(ChatConnectionState.connected, null);
    return () => attached.remove(teamId);
  };

  @override
  Future<SlackGrantRenewal> renew(
    ProviderToken sealed, {
    required String workspaceId,
  }) async {
    renewals++;
    return next;
  }

  @override
  Future<void> revoke(
    ProviderToken sealed, {
    required String workspaceId,
  }) async => revoked.add('$workspaceId:${sealed.seal}');
}

/// The provider's HTTP API, scripted. Every connector path that talks to Slack
/// goes through a client from [client], so the whole HTTP surface is observable
/// here.
class _SlackStub {
  final List<String> calls = [];
  final Map<String, String> _failures = {};
  bool permissionsUpdated = false;

  void fail(String method, String error) => _failures[method] = error;

  /// A fresh transport, as the plugin hands one to each call site.
  RhttpClient client() => TestHttpClient(
    handler: (request) => httpTextResponse(
      request,
      handle(httpRequestUri(request).pathSegments.last),
    ),
  );

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
      'bots.info' => {
        'ok': true,
        'bot': {
          'id': 'B1',
          'app_id': 'A1',
          'user_id': 'UBOT',
          'name': 'controlcenter',
        },
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
  Future<Never?> getById(String id) async => null;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeMembers implements WorkspaceMembershipRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeTickets implements TicketWorkflowService {
  final List<
    ({
      String title,
      String? description,
      TicketStatus status,
      String? createdByType,
      String? createdById,
    })
  >
  created = [];

  /// Makes the next [createTicket] throw, as a failed write would.
  bool failNext = false;

  @override
  Future<Ticket> createTicket({
    required String workspaceId,
    required String title,
    String? id,
    String? description,
    TicketStatus status = TicketStatus.open,
    String? createdByType,
    String? createdById,
    TicketProvider provider = TicketProvider.local,
    TicketPriority priority = TicketPriority.none,
    List<String> labels = const [],
    String? assignedAgentId,
    PrincipalType assigneeType = PrincipalType.agent,
    String? assignedTeamId,
    String? delegatedByAgentId,
    int delegationDepth = 0,
    String? delegationRootTicketId,
    String? parentTicketId,
    String? projectId,
    String? spaceId,
    Map<String, String> providerExtras = const {},
  }) async {
    if (failNext) {
      failNext = false;
      throw StateError('ticket store unavailable');
    }
    created.add((
      title: title,
      description: description,
      status: status,
      createdByType: createdByType,
      createdById: createdById,
    ));
    return Ticket(
      id: 't-${created.length}',
      workspaceId: workspaceId,
      title: title,
      status: status,
      createdAt: DateTime.utc(2026),
      updatedAt: DateTime.utc(2026),
    );
  }

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
  Future<ChatUserLink?> forExternalUser(
    String workspaceId, {
    required ChatProvider provider,
    required String externalTeamId,
    required String externalUserId,
  }) async => rows
      .where(
        (r) =>
            r.workspaceId == workspaceId &&
            r.provider == provider &&
            r.externalTeamId == externalTeamId &&
            r.externalUserId == externalUserId,
      )
      .firstOrNull;

  @override
  Future<void> upsert(ChatUserLink link) async {
    rows
      ..removeWhere((r) => r.id == link.id)
      ..add(link);
  }

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
