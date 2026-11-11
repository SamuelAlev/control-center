import 'dart:convert';
import 'dart:io';

import 'package:cc_connect_core/cc_connect_core.dart';
import 'package:cc_domain/core/domain/entities/workspace.dart';
import 'package:cc_domain/core/domain/entities/workspace_member.dart';
import 'package:cc_domain/core/domain/repositories/workspace_membership_repository.dart';
import 'package:cc_domain/core/domain/repositories/workspace_repository.dart';
import 'package:cc_domain/core/domain/value_objects/forge_connection.dart';
import 'package:cc_domain/core/domain/value_objects/forge_host.dart';
import 'package:cc_domain/core/domain/value_objects/workspace_role.dart';
import 'package:cc_domain/features/ticketing/domain/entities/ticket_provider.dart';
import 'package:cc_server_core/src/connect/connect_client.dart';
import 'package:cc_server_core/src/connect/connect_settings.dart';
import 'package:cc_server_core/src/connect/credential_offboarding.dart';
import 'package:cc_server_core/src/connect/github_sign_in_lane.dart';
import 'package:cc_server_core/src/connect/linear_sign_in_lane.dart';
import 'package:cc_server_core/src/connect/sign_in_service.dart';
import 'package:cc_server_core/src/file_secrets_store.dart';
import 'package:cc_server_core/src/forge/forge_credentials.dart';
import 'package:cc_server_core/src/identity/provider_app_settings.dart';
import 'package:cc_server_core/src/identity/provider_token.dart';
import 'package:cc_server_core/src/identity/user_credentials_store.dart';
import 'package:cc_server_core/src/identity/workspace_github_app_settings.dart';
import 'package:cc_server_core/src/identity/workspace_provider_app_settings.dart';
import 'package:test/test.dart';

/// A person who leaves a workspace (or the server), and a deleted
/// workspace, keep no provider credential: every lane revokes and deletes
/// through the one offboarding path.
void main() {
  late Directory dir;
  late UserCredentialsStore users;
  late LinearAppGrants linearApps;
  late _RecordingConnect connect;
  late _Revocations linearRevokes;
  late Map<String, Set<String>> membership;
  late Map<String, Workspace> registry;
  late CredentialOffboarding offboarding;

  setUp(() async {
    dir = Directory.systemTemp.createTempSync('cc_offboarding_');
    final secrets = FileSecretsStore(dataDir: dir.path);
    users = UserCredentialsStore(secrets);
    linearApps = LinearAppGrants(secrets);
    registry = {
      for (final id in ['ws-a', 'ws-b'])
        id: Workspace(
          id: id,
          name: id,
          createdAt: DateTime.utc(2026),
          updatedAt: DateTime.utc(2026),
          connectMode: WorkspaceConnectMode.hosted,
        ),
    };
    membership = {
      'ws-a': {'alice', 'bob'},
      'ws-b': {'alice'},
    };
    final settings = ConnectSettings(secrets: secrets)
      ..workspaceLookup = (id) async => registry[id];
    await settings.setChoice(ConnectMode.off);
    connect = _RecordingConnect(settings);
    linearRevokes = await _Revocations.start();
    final apps = ProviderAppSettings(secrets: secrets);
    final workspaceApps = WorkspaceProviderAppSettings(secrets);
    final credentials = ForgeCredentials(users: users)
      ..workspaceOwnsSlot = (id) async =>
          (await settings.routeFor(id)).workspaceSlot;
    LinearSignInLane linear(ConnectOAuthLane lane) => LinearSignInLane(
      lane: lane,
      apps: apps,
      workspaceApps: workspaceApps,
      people: users,
      workspaces: linearApps,
      route: settings.routeFor,
      revokeEndpoint: linearRevokes.uri,
    );
    final signIn = ProviderSignInService(connect: connect)
      ..register(
        GitHubSignInLane(
          apps: apps,
          workspaceApps: WorkspaceGitHubAppSettings(
            secrets: secrets,
            install: apps,
          ),
          workspaceLookup: (id) async => registry[id],
          credentials: credentials,
          users: users,
          connect: connect,
        ),
      )
      ..register(linear(ConnectOAuthLane.linear))
      ..register(linear(ConnectOAuthLane.linearApp));
    offboarding = CredentialOffboarding(
      signIn: signIn,
      users: users,
      members: _Members(membership),
      workspaces: _Workspaces(registry),
    );
  });

  tearDown(() async {
    await linearRevokes.close();
    dir.deleteSync(recursive: true);
  });

  ProviderToken seal(String blob) => ProviderToken(
    seal: blob,
    sealInstallId: 'inst-1',
    connectOrigin: canonicalConnectBaseUrl(hostedConnectOrigin),
    source: ForgeCredentialSource.connect,
    accountLogin: 'octo',
    accountId: '583231',
  );

  ProviderToken grant(String access) => ProviderToken(
    accessToken: access,
    refreshToken: 'refresh-$access',
    expiresAt: DateTime.now().toUtc().add(const Duration(hours: 8)),
    source: ForgeCredentialSource.oauth,
    appId: 'client',
  );

  Future<void> holdEverything(String user) async {
    await users.setForgeToken(user, ForgeHost.github, seal('$user-gh'));
    await users.setForgeToken(
      user,
      ForgeHost.github,
      seal('$user-gh-a'),
      workspaceId: 'ws-a',
    );
    // A pasted token is the person's server-wide one: it has no workspace
    // slot.
    await users.setForgeToken(user, ForgeHost.gitlab, grant('$user-gl'));
    await users.setTicketToken(user, TicketProvider.linear, grant('$user-lin'));
    await users.setTicketToken(
      user,
      TicketProvider.linear,
      grant('$user-lin-a'),
      workspaceId: 'ws-a',
    );
  }

  Future<ProviderToken?> github(String user, [String? ws]) =>
      users.forgeToken(user, ForgeHost.github, workspaceId: ws);
  Future<ProviderToken?> linear(String user, [String? ws]) =>
      users.ticketToken(user, TicketProvider.linear, workspaceId: ws);

  test('a removed member loses what they keep in that workspace, revoked '
      'upstream; their global sign-ins and colleagues stay', () async {
    await holdEverything('alice');
    await holdEverything('bob');
    membership['ws-a']!.remove('alice');

    await offboarding.memberLeft('alice', 'ws-a');

    expect(await github('alice', 'ws-a'), isNull);
    // Still a member of another workspace: the pasted token stays.
    expect(await users.forgeToken('alice', ForgeHost.gitlab), isNotNull);
    expect(await linear('alice', 'ws-a'), isNull);
    expect(connect.revoked.map((r) => r.seal), ['alice-gh-a']);
    expect(linearRevokes.tokens, ['alice-lin-a']);
    expect(await github('alice'), isNotNull);
    expect(await linear('alice'), isNotNull);
    expect(await github('bob', 'ws-a'), isNotNull);
    expect(await linear('bob', 'ws-a'), isNotNull);
  });

  test('a person in no workspace any more loses their global sign-ins '
      'too', () async {
    await holdEverything('alice');
    membership['ws-a']!.remove('alice');
    membership['ws-b']!.remove('alice');

    await offboarding.memberLeft('alice', 'ws-a');

    expect(await github('alice'), isNull);
    expect(await users.forgeToken('alice', ForgeHost.gitlab), isNull);
    expect(await linear('alice'), isNull);
    expect(linearRevokes.tokens.toSet(), {'alice-lin-a', 'alice-lin'});
  });

  test("a deleted workspace loses every member's grants and its own app "
      'actor', () async {
    await holdEverything('alice');
    await holdEverything('bob');
    await linearApps.write('ws-a', grant('app-a'));
    await linearApps.write('ws-b', grant('app-b'));

    await offboarding.workspaceDeleted('ws-a');

    for (final user in ['alice', 'bob']) {
      expect(await github(user, 'ws-a'), isNull);
      expect(await linear(user, 'ws-a'), isNull);
      expect(await github(user), isNotNull);
    }
    expect(await linearApps.read('ws-a'), isNull);
    expect(await linearApps.read('ws-b'), isNotNull);
    expect(connect.revoked.map((r) => r.seal).toSet(), {
      'alice-gh-a',
      'bob-gh-a',
    });
    expect(linearRevokes.tokens.toSet(), {'alice-lin-a', 'bob-lin-a', 'app-a'});
  });

  test('boot reconciles what a missed removal left behind', () async {
    await holdEverything('alice');
    await holdEverything('bob');
    await holdEverything('carol');
    membership['ws-a']!.remove('bob');

    await offboarding.reconcile();

    expect(await github('alice', 'ws-a'), isNotNull);
    expect(await github('alice'), isNotNull);
    expect(await github('bob', 'ws-a'), isNull);
    expect(await github('bob'), isNull);
    expect(await linear('bob'), isNull);
    expect(await github('carol', 'ws-a'), isNull);
    expect(await github('carol'), isNull);
  });
}

/// A Connect that records the seals revoked through it.
final class _RecordingConnect extends ConnectClient {
  _RecordingConnect(ConnectSettings settings)
    : super(settings: settings, trustedRootKeys: const []);

  final List<GitHubRevokeRequest> revoked = [];

  @override
  Future<void> githubRevoke(
    ConnectTarget target,
    GitHubRevokeRequest request,
  ) async => revoked.add(request);
}

/// Linear's revoke endpoint on loopback.
final class _Revocations {
  _Revocations._(this._server) {
    _server.listen((request) async {
      tokens.add(
        Uri.splitQueryString(
              await utf8.decoder.bind(request).join(),
            )['token'] ??
            '',
      );
      await request.response.close();
    });
  }

  static Future<_Revocations> start() async =>
      _Revocations._(await HttpServer.bind(InternetAddress.loopbackIPv4, 0));

  final HttpServer _server;
  final List<String> tokens = [];

  Uri get uri =>
      Uri.parse('http://${_server.address.address}:${_server.port}/revoke');

  Future<void> close() => _server.close(force: true);
}

final class _Members implements WorkspaceMembershipRepository {
  _Members(this.byWorkspace);

  final Map<String, Set<String>> byWorkspace;

  WorkspaceMember _member(String workspaceId, String userId) => WorkspaceMember(
    id: '$workspaceId-$userId',
    workspaceId: workspaceId,
    userId: userId,
    role: WorkspaceRole.member,
    joinedAt: DateTime.utc(2026),
  );

  @override
  Future<WorkspaceMember?> getMember(String workspaceId, String userId) async =>
      byWorkspace[workspaceId]?.contains(userId) ?? false
      ? _member(workspaceId, userId)
      : null;

  @override
  Future<List<WorkspaceMember>> getForUser(String userId) async => [
    for (final MapEntry(key: workspaceId, value: users) in byWorkspace.entries)
      if (users.contains(userId)) _member(workspaceId, userId),
  ];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

final class _Workspaces implements WorkspaceRepository {
  _Workspaces(this.byId);

  final Map<String, Workspace> byId;

  @override
  Future<Workspace?> getById(String id) async => byId[id];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
