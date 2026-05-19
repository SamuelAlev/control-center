import 'package:cc_domain/cc_domain.dart'
    show NotFoundException, RepoOpKind, ValidationException;
import 'package:cc_domain/core/domain/entities/user.dart';
import 'package:cc_domain/core/domain/repositories/user_repository.dart';
import 'package:cc_domain/core/domain/value_objects/workspace_role.dart';
import 'package:cc_domain/features/chat_bridge/domain/entities/chat_user_link.dart';
import 'package:cc_domain/features/chat_bridge/domain/value_objects/chat_app_creation.dart';
import 'package:cc_domain/features/chat_bridge/domain/value_objects/chat_bot_profile.dart';
import 'package:cc_domain/features/chat_bridge/domain/value_objects/chat_bridge_connection.dart';
import 'package:cc_domain/features/chat_bridge/domain/value_objects/chat_link_method.dart';
import 'package:cc_domain/features/chat_bridge/domain/value_objects/chat_provider.dart';
import 'package:cc_harness/tools.dart' show ActionClass;
import 'package:cc_host/cc_host.dart';
import 'package:cc_infra/cc_infra.dart' show ChatLinkCode, ChatLinkCodeStore;
import 'package:cc_server_core/src/chat/chat_connector.dart';
import 'package:cc_server_core/src/chat/chat_provider_plugin.dart';
import 'package:cc_server_core/src/chat/chat_rpc_ops.dart';
import 'package:cc_server_core/src/chat/slack_chat_provider_plugin.dart';
import 'package:dio/dio.dart';
import 'package:test/test.dart';

/// The chat ops' contract with the client.
///
/// Four properties are load-bearing. A chat app speaks for a whole workspace, so
/// wiring one is admin-only; the workspace always comes from the session, so no
/// argument can redirect an op at somebody else's workspace; a link code is only
/// ever minted for the caller, because minting one for another member would be an
/// account-takeover primitive; and **no op names a provider** — the client is
/// driven by `chat.providers`, which is what makes adding Discord a server-only
/// change.
void main() {
  const slack = ChatProvider.slack;
  late _FakeConnector connector;
  late List<RepoOp> ops;

  setUp(() {
    connector = _FakeConnector();
    ops = buildChatOps(connector: connector, users: _FakeUsers());
  });

  RepoOp op(String name) => ops.firstWhere((o) => o.name == name);

  Future<Map<String, dynamic>> call(
    String name,
    Map<String, dynamic> args, {
    String userId = 'user-1',
    WorkspaceRole? role,
  }) => op(name).handler(
    RepoOpContext(
      args: {'provider': slack.wire, ...args},
      workspaceId: 'ws-1',
      deviceId: 'device-1',
      userId: userId,
      role: role,
    ),
  );

  group('surface', () {
    test('wiring a chat app is an admin action', () {
      for (final name in [
        'chat.connect',
        'chat.disconnect',
        'chat.createApp',
        'chat.botProfile',
        'chat.updateBotProfile',
      ]) {
        expect(op(name).minRole, WorkspaceRole.admin, reason: name);
      }
      // Reading status and linking your own account are member actions.
      expect(op('chat.providers').minRole, isNot(WorkspaceRole.admin));
      expect(op('chat.status').minRole, isNot(WorkspaceRole.admin));
      expect(op('chat.beginUserLink').minRole, isNot(WorkspaceRole.admin));
    });

    test('every op that touches secrets or the network declares it', () {
      expect(op('chat.connect').actionClasses, {
        ActionClass.secretAccess,
        ActionClass.networkEgress,
      });
      expect(op('chat.disconnect').actionClasses, {ActionClass.secretAccess});
      expect(op('chat.createApp').actionClasses, {
        ActionClass.secretAccess,
        ActionClass.networkEgress,
      });
      expect(op('chat.updateBotProfile').actionClasses, {
        ActionClass.networkEgress,
      });
      // Disconnect throws credentials away; the client must be able to confirm it.
      expect(op('chat.disconnect').kind, RepoOpKind.destructive);
    });

    test('no op is named after a provider', () {
      expect(ops.map((o) => o.name), everyElement(startsWith('chat.')));
    });

    test('an unknown provider is refused before the registry is touched', () {
      expect(
        () => op('chat.status').handler(
          const RepoOpContext(
            args: {'provider': 'irc'},
            workspaceId: 'ws-1',
            deviceId: 'device-1',
            userId: 'user-1',
          ),
        ),
        throwsA(
          isA<ValidationException>().having(
            (e) => e.message,
            'message',
            contains('Unknown chat provider'),
          ),
        ),
      );
    });
  });

  group('chat.providers', () {
    test(
      'describes every offered provider so the UI needs no per-provider code',
      () async {
        final providers =
            (await call('chat.providers', const {}))['providers']
                as List<dynamic>;

        final entry = providers.single as Map<String, dynamic>;
        final descriptor = entry['descriptor'] as Map<String, dynamic>;
        expect(descriptor['provider'], slack.wire);
        expect(descriptor['displayName'], 'Slack');
        // The connect dialog's boxes, in order, with their format rules attached.
        final fields = (descriptor['credentialFields'] as List)
            .cast<Map<String, dynamic>>();
        expect(fields.map((f) => f['id']), [
          'botToken',
          'appToken',
          'configRefreshToken',
        ]);
        expect(fields.first['expectedPrefix'], 'xoxb-');
        expect(fields.last['required'], isFalse);
        // Capabilities travel with it, so the client can hide what a provider
        // cannot do instead of offering a button that fails.
        expect(entry['status'], isNotNull);
        expect((descriptor['capabilities'] as Map)['streaming'], isTrue);
      },
    );

    test('never carries a credential back out', () async {
      connector.storedCredential = 'xoxb-secret';

      final result = await call('chat.providers', const {});

      expect(result.toString(), isNot(contains('xoxb-secret')));
    });
  });

  group('chat.connect', () {
    test('forwards the credentials map untouched', () async {
      final result = await call('chat.connect', {
        'credentials': {'botToken': 'xoxb-1', 'appToken': 'xapp-1'},
      });

      expect(connector.connected, [
        {'botToken': 'xoxb-1', 'appToken': 'xapp-1'},
      ]);
      expect(
        (result['status'] as Map)['state'],
        ChatConnectionState.connected.wire,
      );
      // The reply describes the connection; it never echoes a credential back.
      expect(result.toString(), isNot(contains('xoxb-')));
    });

    test('a non-string credential cannot be smuggled through', () async {
      await call('chat.connect', {
        'credentials': {'botToken': 'xoxb-1', 'appToken': 42},
      });

      // Dropped rather than stringified: the descriptor then refuses the missing
      // required field, which is the error the user can act on.
      expect(connector.connected.single.keys, ['botToken']);
    });

    test('a credentials argument of the wrong shape is refused', () async {
      await expectLater(
        call('chat.connect', {'credentials': 'xoxb-1'}),
        throwsA(isA<ValidationException>()),
      );
      expect(connector.connected, isEmpty);
      expect(op('chat.connect').requiredArgs, ['provider', 'credentials']);
    });
  });

  group('user links', () {
    test('a code is minted for the caller, never for an argument', () async {
      final result = await call('chat.beginUserLink', {
        'user_id': 'somebody-else',
      });

      expect(connector.minted, [('ws-1', slack, 'user-1')]);
      expect(result['code'], isNotEmpty);
      expect(result['expires_at'], isNotNull);
    });

    test('unlinking yourself needs no role', () async {
      connector.links['user-1'] = 1;

      expect(await call('chat.unlinkUser', const {}), {'ok': true});
      expect(connector.unlinked, ['user-1']);
    });

    test('unlinking a teammate is admin-only', () async {
      connector.links['user-2'] = 1;

      await expectLater(
        call('chat.unlinkUser', {
          'user_id': 'user-2',
        }, role: WorkspaceRole.member),
        throwsA(isA<ValidationException>()),
      );
      expect(connector.unlinked, isEmpty);

      await call('chat.unlinkUser', {
        'user_id': 'user-2',
      }, role: WorkspaceRole.admin);
      expect(connector.unlinked, ['user-2']);
    });

    test('unlinking nothing is a not-found, not a silent success', () async {
      await expectLater(
        call('chat.unlinkUser', const {}),
        throwsA(isA<NotFoundException>()),
      );
    });

    test('the roster joins each link to the user it points at', () async {
      connector.roster.add(
        ChatUserLink(
          id: 'ul-1',
          workspaceId: 'ws-1',
          provider: slack,
          externalTeamId: 'T1',
          externalUserId: 'U1',
          userId: 'user-1',
          method: ChatLinkMethod.email,
          linkedAt: DateTime.utc(2026),
        ),
      );

      final links =
          (await call('chat.listUserLinks', const {}))['links']
              as List<dynamic>;

      final row = links.single as Map<String, dynamic>;
      expect(row['provider'], slack.wire);
      expect(row['externalUserId'], 'U1');
      expect(row['userDisplayName'], 'Alex Doe');
      expect(row['method'], 'email');
    });

    test('the roster spans providers when none is named', () async {
      await op('chat.listUserLinks').handler(
        const RepoOpContext(
          args: {},
          workspaceId: 'ws-1',
          deviceId: 'device-1',
          userId: 'user-1',
        ),
      );

      // One table for every provider: the settings roster is not per-card.
      expect(connector.rosterProviders, [null]);
    });

    test('the roster is watchable, with the same shape as the read', () async {
      // The link is made in the chat app, so a client that minted the code
      // cannot learn it landed from any response of its own — this stream is the
      // only way the settings surface and the link dialog find out.
      connector.roster.add(
        ChatUserLink(
          id: 'ul-1',
          workspaceId: 'ws-1',
          provider: slack,
          externalTeamId: 'T1',
          externalUserId: 'U1',
          userId: 'user-1',
          method: ChatLinkMethod.code,
          linkedAt: DateTime.utc(2026),
        ),
      );
      final query = buildChatWatchQueries(
        connector: connector,
        users: _FakeUsers(),
      ).singleWhere((q) => q.name == 'chat.watchUserLinks');

      final snapshot = await query
          .handler(
            const WatchQueryContext(
              args: {},
              workspaceId: 'ws-1',
              deviceId: 'device-1',
              userId: 'user-1',
            ),
          )
          .first;

      final row = (snapshot['links'] as List).single as Map<String, dynamic>;
      expect(row['externalUserId'], 'U1');
      expect(row['userDisplayName'], 'Alex Doe');
      expect(row['method'], 'code');
      // Unnamed provider means the whole roster here too.
      expect(connector.rosterProviders, [null]);
    });
  });

  group('app management', () {
    test('createApp returns the steps the provider has no API for', () async {
      final result = await call('chat.createApp', {
        'management_credential': 'xoxe-1',
        'profile': {'appName': 'Ops bot', 'command': '/OPS'},
      });

      final creation = ChatAppCreation.fromJson(
        (result['creation'] as Map).cast<String, dynamic>(),
      );
      expect(creation.appId, 'A1');
      expect(creation.step('install')?.url, isNotEmpty);
      expect(connector.createdProfile?.appName, 'Ops bot');
      // Slack accepts one lowercase word; the client's input is normalized.
      expect(connector.createdProfile?.command, 'ops');
    });

    test('a credential of the wrong format is refused locally', () async {
      await expectLater(
        call('chat.createApp', {'management_credential': 'xoxb-1'}),
        throwsA(
          isA<ValidationException>().having(
            (e) => e.message,
            'message',
            contains('`xoxe-`'),
          ),
        ),
      );
      // The descriptor's rule is enforced before the provider is dialed.
      expect(connector.createdProfile, isNull);
    });

    test('an empty field means "leave it alone", not "clear it"', () async {
      await call('chat.updateBotProfile', {
        'workspace_name': 'Acme',
        'profile': {
          'appName': '',
          'botDisplayName': 'acme-bot',
          'description': '',
          'agentDescription': '',
          'command': 'cc',
          'agentEnabled': true,
        },
      });

      final sent = connector.updatedProfile!;
      expect(sent.botDisplayName, 'acme-bot');
      // A provider refuses an empty name, so the default fills the gap instead of
      // the user getting a rejection for a box they never touched.
      expect(sent.appName, isNotEmpty);
      expect(sent.description, isNotEmpty);
      expect(sent.agentDescription, isNotEmpty);
    });

    test('updateBotProfile hands back the step that is left', () async {
      connector.remainingStep = const ChatSetupStep(
        id: 'install',
        title: 'Reinstall the app',
        url: 'https://example.test/install',
      );

      final result = await call('chat.updateBotProfile', const {});

      // The client shows this verbatim, which is how a provider-specific
      // reinstall link reaches the UI without the UI naming a provider.
      final step = (result['remaining_step'] as Map).cast<String, dynamic>();
      expect(step['id'], 'install');
      expect(step['url'], 'https://example.test/install');
    });

    test('a fully-applied edit leaves no step behind', () async {
      final result = await call('chat.updateBotProfile', const {});

      expect(result.containsKey('remaining_step'), isFalse);
    });
  });

  group('chat.setupLink', () {
    test('is admin-only and dials nothing', () {
      // The link creates an app that speaks for the whole workspace, so it sits
      // at the same bar as chat.createApp — even though composing it is free.
      expect(op('chat.setupLink').minRole, WorkspaceRole.admin);
      expect(op('chat.setupLink').kind, RepoOpKind.read);
      expect(op('chat.setupLink').actionClasses, isEmpty);
      expect(op('chat.setupLink').requiredArgs, ['provider']);
    });

    test('carries the edited profile into the url', () async {
      final result = await call('chat.setupLink', {
        'profile': {'appName': 'Ops bot', 'command': '/OPS'},
      });

      final manifest =
          Uri.parse(
            result['url']! as String,
          ).queryParameters['manifest_json']!;
      expect(manifest, contains('Ops bot'));
      // Normalized on the way through, exactly as the token path normalizes it,
      // so the two setup routes cannot produce differently-named commands.
      expect(manifest, contains('/ops'));
    });

    test('an untouched dialog still yields a usable app', () async {
      final result = await call('chat.setupLink', {'workspace_name': 'Acme'});

      // Nothing typed is the common case (the user clicks straight through), so
      // the defaults have to be complete enough for Slack to accept them.
      expect(result['url'], startsWith('https://api.slack.com/apps?new_app=1'));
      expect(
        Uri.parse(result['url']! as String).queryParameters['manifest_json'],
        contains('Acme'),
      );
    });

    test('a provider with no such link refuses instead of returning empty', () {
      final linkless = buildChatOps(
        connector: _FakeConnector(plugins: [_LinklessPlugin()]),
        users: _FakeUsers(),
      ).firstWhere((o) => o.name == 'chat.setupLink');

      // An empty url would reach the client as a button that opens nothing.
      expect(
        () => linkless.handler(
          RepoOpContext(
            args: {'provider': slack.wire},
            workspaceId: 'ws-1',
            deviceId: 'device-1',
            userId: 'user-1',
          ),
        ),
        throwsA(
          isA<ValidationException>().having(
            (e) => e.message,
            'message',
            contains('Slack'),
          ),
        ),
      );
    });

    test('a profile the provider would reject never becomes a url', () async {
      // Slack would answer the deep link with its own error page, where the user
      // has no way to tell which field was too long.
      await expectLater(
        call('chat.setupLink', {
          'profile': {'appName': 'x' * 36, 'command': 'cc'},
        }),
        throwsA(isA<ValidationException>()),
      );
    });
  });
}

/// Records what each op forwarded, so the tests assert the handler's contract
/// rather than a provider's behaviour (that is covered against the API client).
class _FakeConnector implements ChatConnector {
  _FakeConnector({List<ChatProviderPlugin>? plugins})
    : registry = ChatProviderRegistry(
        plugins ?? [SlackChatProviderPlugin(dioFactory: Dio.new)],
      );

  final List<Map<String, String>> connected = [];
  final List<(String, ChatProvider, String)> minted = [];
  final List<String> unlinked = [];
  final List<ChatUserLink> roster = [];
  final List<ChatProvider?> rosterProviders = [];
  final Map<String, int> links = {};
  ChatBotProfile? createdProfile;
  ChatBotProfile? updatedProfile;
  ChatSetupStep? remainingStep;
  String? storedCredential;

  @override
  final ChatLinkCodeStore linkCodes = ChatLinkCodeStore();

  @override
  final ChatProviderRegistry registry;

  @override
  Future<ChatConnectionStatus> status(
    String workspaceId,
    ChatProvider provider,
  ) async => ChatConnectionStatus(
    provider: provider,
    state: ChatConnectionState.connected,
  );

  @override
  Future<List<ChatConnectionStatus>> statuses(String workspaceId) async => [
    for (final provider in registry.providers)
      await status(workspaceId, provider),
  ];

  @override
  Future<ChatConnectionStatus> connect({
    required String workspaceId,
    required ChatProvider provider,
    required Map<String, String> credentials,
  }) async {
    connected.add(credentials);
    return status(workspaceId, provider);
  }

  @override
  ChatLinkCode beginUserLink({
    required String workspaceId,
    required ChatProvider provider,
    required String userId,
  }) {
    minted.add((workspaceId, provider, userId));
    return linkCodes.mint(
      workspaceId: workspaceId,
      provider: provider,
      userId: userId,
    );
  }

  @override
  Future<List<ChatUserLink>> listUserLinks(
    String workspaceId, {
    ChatProvider? provider,
  }) async {
    rosterProviders.add(provider);
    return roster;
  }

  @override
  Stream<List<ChatUserLink>> watchUserLinks(
    String workspaceId, {
    ChatProvider? provider,
  }) {
    rosterProviders.add(provider);
    return Stream.value(roster);
  }

  @override
  Future<int> unlinkUser(
    String workspaceId,
    String userId, {
    required ChatProvider provider,
  }) async {
    final removed = links.remove(userId) ?? 0;
    if (removed > 0) {
      unlinked.add(userId);
    }
    return removed;
  }

  @override
  Future<ChatAppCreation> createApp({
    required String workspaceId,
    required ChatProvider provider,
    required String managementCredential,
    required ChatBotProfile profile,
  }) async {
    createdProfile = profile;
    return const ChatAppCreation(
      appId: 'A1',
      settingsUrl: 'https://example.test/apps/A1',
      remainingSteps: [
        ChatSetupStep(
          id: 'install',
          title: 'Install the app',
          url: 'https://example.test/apps/A1/install',
        ),
      ],
    );
  }

  @override
  Future<ChatSetupStep?> updateBotProfile({
    required String workspaceId,
    required ChatProvider provider,
    required ChatBotProfile profile,
  }) async {
    updatedProfile = profile;
    return remainingStep;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// A provider whose console has no pre-filled-app entry point — the shape every
/// non-Slack plugin is expected to have until proven otherwise.
class _LinklessPlugin implements ChatProviderPlugin {
  @override
  ChatProvider get provider => ChatProvider.slack;

  @override
  String? setupLinkFor(ChatBotProfile profile) => null;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeUsers implements UserRepository {
  @override
  Future<User?> getById(String id) async => User(
    id: id,
    handle: 'alex',
    displayName: 'Alex Doe',
    createdAt: DateTime.utc(2026),
  );

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
