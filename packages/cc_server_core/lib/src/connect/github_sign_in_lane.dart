import 'dart:convert';
import 'dart:io';

import 'package:cc_connect_core/cc_connect_core.dart';
import 'package:cc_domain/core/domain/entities/workspace.dart';
import 'package:cc_domain/core/domain/value_objects/forge_connection.dart';
import 'package:cc_domain/core/domain/value_objects/forge_host.dart';
import 'package:cc_host/cc_host.dart' show CcHostLog;
import 'package:cc_server_core/src/connect/connect_client.dart';
import 'package:cc_server_core/src/connect/sign_in_service.dart';
import 'package:cc_server_core/src/forge/forge_credentials.dart';
import 'package:cc_server_core/src/identity/provider_app_settings.dart';
import 'package:cc_server_core/src/identity/workspace_github_app_settings.dart';

/// GitHub sign-in: a person's own GitHub App user token.
///
/// A workspace on its own App signs people in to that App and keeps the
/// grant in the workspace slot; it never routes through Connect. Every other
/// workspace uses the server's lane — its own complete App, else Connect —
/// and the grant lands in the person's global slot, shared by every
/// inheriting workspace.
final class GitHubSignInLane implements SignInLaneBinding {
  /// Creates the lane.
  GitHubSignInLane({
    required this.apps,
    required this.workspaceApps,
    required this.workspaceLookup,
    required this.credentials,
    required this.connect,
    HttpClient? httpClient,
  }) : _http = httpClient ?? (HttpClient()..connectionTimeout = _timeout);

  static const Duration _timeout = Duration(seconds: 15);

  /// The server's own apps.
  final ProviderAppSettings apps;

  /// Per-workspace GitHub Apps.
  final WorkspaceGitHubAppSettings workspaceApps;

  /// Loads a workspace.
  final Future<Workspace?> Function(String workspaceId) workspaceLookup;

  /// Where person grants live.
  final ForgeCredentials credentials;

  /// Revokes sealed grants on disconnect.
  final ConnectClient connect;

  final HttpClient _http;

  static final Uri _authorize = Uri.parse(
    'https://github.com/login/oauth/authorize',
  );
  static final Uri _token = Uri.parse(
    'https://github.com/login/oauth/access_token',
  );

  @override
  ConnectOAuthLane get lane => ConnectOAuthLane.github;

  Future<Workspace?> _ownAppWorkspace(String? workspaceId) async {
    if (workspaceId == null || workspaceId.isEmpty) {
      return null;
    }
    final workspace = await workspaceLookup(workspaceId);
    return workspace?.githubAuthMode == GithubAuthMode.app ? workspace : null;
  }

  @override
  Future<OwnOAuthApp?> ownApp(String? workspaceId) async {
    final workspace = await _ownAppWorkspace(workspaceId);
    if (workspace != null) {
      final creds = await workspaceApps.oauthCredentials(workspace);
      if (creds == null) {
        throw const SignInMisconfigured(
          'This workspace uses its own GitHub App, but its client id or '
          'client secret is missing.',
        );
      }
      return _app(creds);
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
  );

  @override
  Future<bool> allowsConnect(String? workspaceId) async =>
      await _ownAppWorkspace(workspaceId) == null;

  @override
  Future<String?> slotFor(String? workspaceId) async =>
      (await _ownAppWorkspace(workspaceId))?.id;

  @override
  Future<SignInIdentity> identify(String accessToken) async {
    final request = await _http.getUrl(Uri.parse('https://api.github.com/user'));
    request.followRedirects = false;
    request.headers
      ..set(HttpHeaders.authorizationHeader, 'Bearer $accessToken')
      ..set(HttpHeaders.acceptHeader, 'application/vnd.github+json')
      ..set(HttpHeaders.userAgentHeader, 'control-center')
      ..set('X-GitHub-Api-Version', '2022-11-28');
    final response = await request.close().timeout(_timeout);
    final body = await utf8.decodeStream(response.timeout(_timeout));
    if (response.statusCode != 200) {
      throw HttpException('GitHub /user answered ${response.statusCode}');
    }
    final json = jsonDecode(body);
    if (json is! Map || json['type'] != 'User') {
      // Organizations and bots cannot sign in as a person.
      return (id: '', login: '');
    }
    final id = json['id'];
    final login = json['login'];
    return (
      id: id is int ? '$id' : '',
      login: login is String ? login : '',
    );
  }

  @override
  Future<void> store(SignInResult result) => credentials.storeSignIn(
    ForgeHost.github,
    result.userId,
    result.token,
    workspaceId: result.slot,
  );

  @override
  Future<LaneConnection?> connection(String userId, String? workspaceId) async {
    final stored = await credentials.storedCredential(
      ForgeHost.github,
      userId,
      workspaceId: workspaceId,
    );
    if (stored == null) {
      return null;
    }
    final live = await credentials.personCredential(
      ForgeHost.github,
      userId,
      workspaceId: workspaceId,
    );
    return LaneConnection(
      lane: lane,
      connected: live != null,
      account: stored.token.accountLogin,
      accountId: stored.token.accountId,
      workspaceSlot: stored.workspaceId != null,
      source: stored.token.source == ForgeCredentialSource.connect
          ? SignInMode.connect
          : SignInMode.own,
      needsSignIn: live == null,
    );
  }

  /// Revokes a Connect grant upstream (`/v1/github/revoke`, the whole
  /// authorization) before deleting the stored seal: once the seal is gone
  /// this server can never revoke it. Best effort — an unreachable Connect
  /// still signs the person out here. Cached child tokens are
  /// `GitHubClients.forgetPerson`'s.
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
      try {
        await connect.githubRevoke(
          GitHubRevokeRequest(
            workspaceId: stored.workspaceId ?? globalWorkspaceScope,
            seal: stored.token.seal,
          ),
        );
      } on ConnectException catch (e) {
        CcHostLog.warning(
          'github: revoking the Connect grant on disconnect failed '
          '(${e.code.wire}); it lapses when its refresh token does',
        );
      }
    }
    await credentials.clearToken(
      ForgeHost.github,
      userId: userId,
      workspaceId: stored.workspaceId,
    );
  }
}
