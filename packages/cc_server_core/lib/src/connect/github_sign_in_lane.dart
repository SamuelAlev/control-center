import 'package:cc_connect_core/cc_connect_core.dart';
import 'package:cc_domain/core/domain/entities/workspace.dart';
import 'package:cc_domain/core/domain/value_objects/forge_connection.dart';
import 'package:cc_domain/core/domain/value_objects/forge_host.dart';
import 'package:cc_server_core/src/connect/connect_client.dart';
import 'package:cc_server_core/src/connect/connect_settings.dart'
    show ConnectMode, ConnectTarget;
import 'package:cc_server_core/src/connect/sign_in_service.dart';
import 'package:cc_server_core/src/forge/forge_audit.dart';
import 'package:cc_server_core/src/forge/forge_credentials.dart';
import 'package:cc_server_core/src/forge/github_rest.dart';
import 'package:cc_server_core/src/identity/provider_app_settings.dart';
import 'package:cc_server_core/src/identity/provider_token.dart';
import 'package:cc_server_core/src/identity/user_credentials_store.dart';
import 'package:cc_server_core/src/identity/workspace_github_app_settings.dart';

/// GitHub sign-in: a person's own GitHub App user token.
///
/// A workspace on its own apps signs people in to its own App only; one on a
/// Connect of its own signs them in there. Either keeps the grant in the
/// workspace slot. A workspace that inherits uses the server's lane — its
/// own complete App, else its Connect — and the grant lands in the person's
/// global slot, shared by every inheriting workspace.
final class GitHubSignInLane implements SignInLaneBinding {
  /// Creates the lane.
  GitHubSignInLane({
    required this.apps,
    required this.workspaceApps,
    required this.workspaceLookup,
    required this.credentials,
    required this.users,
    required this.connect,
    GitHubRest? rest,
  }) : _rest = rest ?? GitHubRest(timeout: const Duration(seconds: 15));

  /// The server's own apps.
  final ProviderAppSettings apps;

  /// Per-workspace GitHub Apps.
  final WorkspaceGitHubAppSettings workspaceApps;

  /// Loads a workspace.
  final Future<Workspace?> Function(String workspaceId) workspaceLookup;

  /// Where person grants live.
  final ForgeCredentials credentials;

  /// The stored grants, read to keep one GitHub account to one person.
  final UserCredentialsStore users;

  /// Revokes sealed grants on disconnect.
  final ConnectClient connect;

  final GitHubRest _rest;

  static final Uri _authorize = Uri.parse(
    'https://github.com/login/oauth/authorize',
  );
  static final Uri _token = Uri.parse(
    'https://github.com/login/oauth/access_token',
  );

  @override
  ConnectOAuthLane get lane => ConnectOAuthLane.github;

  @override
  Future<OwnOAuthApp?> ownApp(String? workspaceId) async {
    final route = await connect.routeFor(workspaceId);
    if (route.workspaceOwnApps) {
      final workspace = await workspaceLookup(workspaceId!);
      if (workspace == null) {
        return null;
      }
      switch ((await workspaceApps.status(workspace)).state) {
        case OwnAppState.none:
          return null;
        case OwnAppState.partial:
          throw const SignInMisconfigured(
            'This workspace uses its own apps, but its GitHub App is only '
            'partly set up. Add the app id, private key, client id and '
            'client secret.',
          );
        case OwnAppState.complete:
          final creds = await workspaceApps.oauthCredentials(workspace);
          return creds == null ? null : _app(creds);
      }
    }
    if (!route.serverOwnApps) {
      return null;
    }
    try {
      final creds = await apps.oauthCredentials(ProviderApp.github);
      return creds == null ? null : _app(creds);
    } on OwnAppIncomplete catch (e) {
      throw SignInMisconfigured(e.message);
    }
  }

  OwnOAuthApp _app(OAuthAppCredentials creds) => OwnOAuthApp(
    authorize: _authorize,
    token: _token,
    clientId: creds.clientId,
    clientSecret: creds.clientSecret,
    // A GitHub App's user token carries the app's permissions; scopes are
    // an OAuth-App concept.
    scopes: const [],
    // The account chooser: a browser's signed-in GitHub account never
    // connects without the person picking it.
    extraAuthorizeParams: const {'prompt': 'select_account'},
  );

  @override
  Future<bool> allowsConnect(String? workspaceId) async =>
      !(await connect.routeFor(workspaceId)).workspaceOwnApps;

  @override
  Future<String?> slotFor(String? workspaceId) async =>
      (await connect.routeFor(workspaceId)).workspaceSlot ? workspaceId : null;

  @override
  Future<SignInIdentity> identify(String accessToken) async {
    final response = await _rest.send('GET', '/user', bearer: accessToken);
    if (response.status != 200) {
      throw StateError('GitHub /user answered ${response.status}');
    }
    final json = response.json;
    if (json is! Map || json['type'] != 'User') {
      // Organizations and bots cannot sign in as a person.
      return (id: '', login: '');
    }
    final id = json['id'];
    final login = json['login'];
    return (id: id is int ? '$id' : '', login: login is String ? login : '');
  }

  @override
  Future<Set<String>> accountHolders(String accountId) async => {
    for (final held in await users.forgeTokens(ForgeHost.github))
      if (held.token.accountId == accountId) held.userId,
  };

  @override
  Future<void> revokeOwnGrant(ProviderToken token, String? slot) =>
      _revokeOwnGrant(token, token.accessToken, slot);

  @override
  Future<void> store(SignInResult result) => credentials.storeSignIn(
    ForgeHost.github,
    result.userId,
    result.token,
    workspaceId: result.slot,
  );

  @override
  Future<LaneConnection?> connection(String userId, String? workspaceId) async {
    final current = await credentials.connection(
      ForgeHost.github,
      userId: userId,
      workspaceId: workspaceId,
    );
    final stored = await credentials.storedCredential(
      ForgeHost.github,
      userId,
      workspaceId: workspaceId,
    );
    final source = stored?.token.source ?? current.source;
    return LaneConnection(
      lane: lane,
      status: current.status,
      account: current.username.isNotEmpty
          ? current.username
          : stored?.token.accountLogin ?? '',
      accountId: stored?.token.accountId ?? '',
      workspaceSlot: current.scope == ForgeCredentialScope.workspace,
      source: source == ForgeCredentialSource.connect
          ? SignInLaneMode.connect
          : SignInLaneMode.own,
    );
  }

  /// Revokes and deletes every member's GitHub grant kept in
  /// [workspaceId]'s own slot (only those [where] accepts, when given): the
  /// workspace's sign-in target changed (its Connect choice, its own App's
  /// client, or whether it shares the server's target), so those grants
  /// belong to a service it no longer signs in with.
  ///
  /// Best effort upstream, like [disconnect]: a grant this server cannot
  /// revoke any more (the App's secret is gone, the Connect unreachable)
  /// is still deleted here and lapses with its refresh token.
  Future<int> resetWorkspaceSlot(
    String workspaceId, {
    bool Function(ProviderToken token)? where,
  }) async {
    final removed = await credentials.clearWorkspaceSlot(
      ForgeHost.github,
      workspaceId,
      where: where,
    );
    for (final entry in removed) {
      final token = entry.token;
      if (token.isSealed) {
        await _revokeSeal(token.seal, token.connectOrigin, workspaceId);
      } else {
        await _revokeOwnGrantWith(
          await _workspaceAppFor(workspaceId, token.appId),
          token.accessToken,
        );
      }
    }
    for (final entry in removed) {
      forgeAudit(ForgeAuditEvent.grantCleared, {
        'lane': lane.wire,
        'user_id': entry.userId,
        'workspace_id': workspaceId,
        'reason': 'slot_reset',
      }, token: entry.token.isSealed ? null : entry.token.accessToken);
    }
    return removed.length;
  }

  /// The Connect a workspace-slot seal from [origin] was made at: Control
  /// Center's hosted Connect, or the custom Connect [workspaceId] chose
  /// (under its own trust store). A seal only ever goes back to its origin.
  ConnectTarget _slotSealTarget(String origin, String workspaceId) =>
      origin == canonicalConnectBaseUrl(hostedConnectOrigin)
      ? const ConnectTarget(
          mode: ConnectMode.hosted,
          baseUrl: hostedConnectOrigin,
        )
      : ConnectTarget(
          mode: ConnectMode.custom,
          baseUrl: origin,
          pinScope: workspaceId,
          guarded: true,
        );

  Future<void> _revokeSeal(String seal, String origin, String slot) async {
    if (seal.isEmpty || origin.isEmpty) {
      return;
    }
    try {
      await connect.githubRevoke(
        _slotSealTarget(origin, slot),
        GitHubRevokeRequest(workspaceId: slot, seal: seal),
      );
    } on Object catch (e) {
      forgeAudit(ForgeAuditEvent.grantRevokeSkipped, {
        'lane': lane.wire,
        'workspace_id': slot,
        'reason': 'connect_failed:${errorKindOf(e)}',
      });
    }
  }

  /// The workspace's own App, whatever its Connect choice now, when it is
  /// still the client that issued a grant ([clientId]).
  Future<OwnOAuthApp?> _workspaceAppFor(
    String workspaceId,
    String clientId,
  ) async {
    final workspace = await workspaceLookup(workspaceId);
    if (workspace == null || clientId.isEmpty) {
      return null;
    }
    final creds = await workspaceApps.storedOAuthCredentials(workspace.id);
    return creds == null || creds.clientId != clientId ? null : _app(creds);
  }

  /// Revokes upstream before deleting: once it is gone this server can never
  /// revoke it.
  ///
  /// * Connect: `/v1/github/revoke` revokes this sign-in only (the seal's
  ///   own user token and the child tokens Connect recorded for it); the
  ///   person's sign-ins on other servers keep working.
  /// * Own App: `DELETE /applications/{client_id}/grant` with the client
  ///   credentials of the App that issued it revokes that App's whole grant
  ///   for the person.
  ///
  /// Best effort: an unreachable Connect or GitHub still signs the person
  /// out here. Cached child tokens are `GitHubClients.forgetPerson`'s.
  @override
  Future<void> disconnect(String userId, String? workspaceId) async {
    final stored = await credentials.storedCredential(
      ForgeHost.github,
      userId,
      workspaceId: workspaceId,
    );
    if (stored == null) {
      return;
    }
    if (stored.token.isSealed) {
      await _revokeSealAtCurrent(stored.token, userId, stored.workspaceId);
    } else {
      // The grant is revoked with a live access token; an expired one is
      // renewed first (GitHub answers 404 for a dead token).
      final live = await credentials.personCredential(
        ForgeHost.github,
        userId,
        workspaceId: workspaceId,
      );
      await _revokeOwnGrant(
        stored.token,
        live?.accessToken ?? stored.token.accessToken,
        stored.workspaceId,
      );
    }
    await credentials.clearToken(
      ForgeHost.github,
      userId: userId,
      workspaceId: stored.workspaceId,
    );
  }

  @override
  Future<List<SealRequest>> connectSeals(
    String connectOrigin,
    List<String> workspaceIds,
  ) async => [
    for (final held in await users.forgeTokens(ForgeHost.github))
      if (held.token.isSealed && held.token.connectOrigin == connectOrigin)
        SealRequest(
          seal: held.token.seal,
          workspaceId: held.workspaceId ?? globalWorkspaceScope,
        ),
  ];

  @override
  Future<int> offboard({String? userId, String? workspaceId}) async {
    assert(userId != null || workspaceId != null, 'offboard whom?');
    var removed = 0;
    for (final held in await users.forgeTokens(ForgeHost.github)) {
      if ((userId != null && held.userId != userId) ||
          (workspaceId != null && held.workspaceId != workspaceId)) {
        continue;
      }
      final token = held.token;
      final slot = held.workspaceId;
      if (token.isSealed) {
        if (slot != null) {
          await _revokeSeal(token.seal, token.connectOrigin, slot);
        } else {
          await _revokeSealAtCurrent(token, held.userId, null);
        }
      } else if (slot != null) {
        await _revokeOwnGrantWith(
          await _workspaceAppFor(slot, token.appId),
          token.accessToken,
        );
      } else {
        await _revokeOwnGrant(token, token.accessToken, null);
      }
      await credentials.clearToken(
        ForgeHost.github,
        userId: held.userId,
        workspaceId: slot,
      );
      removed++;
    }
    return removed;
  }

  /// Revokes [token]'s seal (this sign-in only) at the Connect [slot] uses
  /// now, only when that is the Connect that made it: a parked seal never
  /// goes to another Connect.
  Future<void> _revokeSealAtCurrent(
    ProviderToken token,
    String userId,
    String? slot,
  ) async {
    try {
      final target = await connect.targetFor(slot);
      if (target.origin != token.connectOrigin) {
        throw const ConnectException(ConnectErrorCode.providerUnavailable);
      }
      await connect.githubRevoke(
        target,
        GitHubRevokeRequest(
          workspaceId: slot ?? globalWorkspaceScope,
          seal: token.seal,
        ),
      );
    } on Object catch (e) {
      forgeAudit(ForgeAuditEvent.grantRevokeSkipped, {
        'lane': lane.wire,
        'user_id': userId,
        'reason': e is ConnectException
            ? 'connect:${e.code.wire}'
            : 'connect_failed:${errorKindOf(e)}',
      });
    }
  }

  /// Revokes [token]'s grant (with [accessToken], its live access token)
  /// with the own App for [slot], only when that App issued it: a grant of a
  /// replaced or removed App is left to lapse, never sent to another App.
  Future<void> _revokeOwnGrant(
    ProviderToken token,
    String accessToken,
    String? slot,
  ) async {
    if (accessToken.isEmpty) {
      return;
    }
    OwnOAuthApp? own;
    try {
      own = await ownApp(slot);
    } on SignInMisconfigured {
      own = null;
    }
    if (own == null || token.appId.isEmpty || own.clientId != token.appId) {
      forgeAudit(ForgeAuditEvent.grantRevokeSkipped, {
        'lane': lane.wire,
        'workspace_id': slot,
        'reason': own == null ? 'app_removed' : 'app_changed',
      }, token: accessToken);
      return;
    }
    await _revokeOwnGrantWith(own, accessToken);
  }

  Future<void> _revokeOwnGrantWith(OwnOAuthApp? own, String accessToken) async {
    if (accessToken.isEmpty) {
      return;
    }
    if (own == null || own.clientSecret.isEmpty) {
      forgeAudit(ForgeAuditEvent.grantRevokeSkipped, {
        'lane': lane.wire,
        'reason': 'app_removed',
      }, token: accessToken);
      return;
    }
    final response = await _rest.send(
      'DELETE',
      '/applications/${Uri.encodeComponent(own.clientId)}/grant',
      basic: (clientId: own.clientId, clientSecret: own.clientSecret),
      body: {'access_token': accessToken},
    );
    if (!response.ok && response.status != 404 && response.status != 422) {
      forgeAudit(ForgeAuditEvent.grantRevokeSkipped, {
        'lane': lane.wire,
        'reason': 'http_${response.status}',
      }, token: accessToken);
    }
  }
}
