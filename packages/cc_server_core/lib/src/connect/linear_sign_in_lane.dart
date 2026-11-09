import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cc_connect_core/cc_connect_core.dart';
import 'package:cc_domain/cc_domain.dart' show AuthException;
import 'package:cc_domain/features/ticketing/domain/entities/ticket_provider.dart';
import 'package:cc_host/cc_host.dart' show CcHostLog;
import 'package:cc_server_core/src/connect/sign_in_service.dart';
import 'package:cc_server_core/src/file_secrets_store.dart';
import 'package:cc_server_core/src/identity/provider_app_settings.dart';
import 'package:cc_server_core/src/identity/provider_token.dart';
import 'package:cc_server_core/src/identity/user_credentials_store.dart';
import 'package:cc_server_core/src/identity/workspace_provider_app_settings.dart';

/// Linear's OAuth authorize endpoint.
final Uri linearAuthorizeEndpoint = Uri.parse(
  'https://linear.app/oauth/authorize',
);

/// Linear's GraphQL endpoint.
final Uri linearGraphQlEndpoint = Uri.parse('https://api.linear.app/graphql');

/// Linear's token revocation endpoint.
final Uri linearRevokeEndpoint = Uri.parse(
  'https://api.linear.app/oauth/revoke',
);

/// Each workspace's Linear app-actor grant (`linear_app`): the identity ticket
/// sync, pipelines and agents write to Linear as, so automated issues and
/// comments appear as Control Center rather than as a person.
final class LinearAppGrants {
  /// Creates the store over the server's secrets file.
  LinearAppGrants(this._secrets);

  final FileSecretsStore _secrets;

  static const String _prefix = 'workspace_linear_app_';

  /// The secrets-file key of [workspaceId]'s grant.
  static String keyFor(String workspaceId) => '$_prefix$workspaceId';

  /// [workspaceId]'s grant, or null.
  Future<ProviderToken?> read(String workspaceId) async =>
      ProviderToken.tryParse(await _secrets.readFresh(keyFor(workspaceId)));

  /// Stores [token] for [workspaceId].
  Future<void> write(String workspaceId, ProviderToken token) =>
      _secrets.writePsk(keyFor(workspaceId), token.encode());

  /// Removes [workspaceId]'s grant.
  Future<void> delete(String workspaceId) =>
      _secrets.deletePsk(keyFor(workspaceId));

  /// Every workspace holding a grant.
  Future<List<String>> workspaces() async => [
    for (final key in await _secrets.keysMatching(
      (key) => key.startsWith(_prefix),
    ))
      key.substring(_prefix.length),
  ];
}

/// The `linear` (a member's own account) and `linear_app` (the workspace's
/// Control Center app actor, `actor=app`) lanes of the browser sign-in.
///
/// Linear is a public PKCE client in every mode: own mode uses the operator's
/// Linear client id, otherwise Connect relays only the one-time code and this
/// server exchanges it directly, so Connect never sees a Linear token.
///
/// A workspace on its own Linear app signs its members in to that app and
/// keeps each person's grant in the workspace's slot, apart from the global
/// grant every inheriting workspace shares; it never routes through Connect
/// or this server's app.
final class LinearSignInLane implements SignInLaneBinding {
  /// Creates one of the two lanes.
  LinearSignInLane({
    required this.lane,
    required this._apps,
    required this._workspaceApps,
    required this._people,
    required this._workspaces,
    HttpClient? httpClient,
    Uri? graphQlEndpoint,
    Uri? revokeEndpoint,
  }) : _http = httpClient ?? (HttpClient()..connectionTimeout = _timeout),
       _graphQl = graphQlEndpoint ?? linearGraphQlEndpoint,
       _revoke = revokeEndpoint ?? linearRevokeEndpoint {
    if (lane != ConnectOAuthLane.linear && lane != ConnectOAuthLane.linearApp) {
      throw ArgumentError.value(lane, 'lane', 'not a Linear lane');
    }
  }

  static const Duration _timeout = Duration(seconds: 15);
  static const int _maxResponseBytes = 64 * 1024;

  @override
  final ConnectOAuthLane lane;

  final ProviderAppSettings _apps;
  final WorkspaceProviderAppSettings _workspaceApps;
  final UserCredentialsStore _people;
  final LinearAppGrants _workspaces;
  final HttpClient _http;
  final Uri _graphQl;
  final Uri _revoke;

  bool get _isApp => lane == ConnectOAuthLane.linearApp;

  Future<bool> _workspaceOwnsApp(String? workspaceId) async =>
      workspaceId != null &&
      await _workspaceApps.ownsApp(workspaceId, WorkspaceAppProvider.linear);

  @override
  Future<OwnOAuthApp?> ownApp(String? workspaceId) async {
    final OAuthAppCredentials? credentials;
    try {
      credentials = await _workspaceOwnsApp(workspaceId)
          ? await _workspaceApps.oauthCredentials(
              workspaceId!,
              WorkspaceAppProvider.linear,
            )
          : await _apps.oauthCredentials(ProviderApp.linear);
    } on OwnAppIncomplete catch (e) {
      throw SignInMisconfigured(e.message);
    } on WorkspaceAppIncomplete catch (e) {
      throw SignInMisconfigured(e.message);
    }
    if (credentials == null) {
      return null;
    }
    return OwnOAuthApp(
      authorize: linearAuthorizeEndpoint,
      token: ProviderSignInService.linearTokenEndpoint,
      clientId: credentials.clientId,
      scopes: linearConnectScopes,
      scopeSeparator: ',',
      // A fresh consent every time, so a browser's existing Linear session
      // never connects silently; the app lane authorizes the app actor.
      extraAuthorizeParams: {'prompt': 'consent', if (_isApp) 'actor': 'app'},
    );
  }

  @override
  Future<bool> allowsConnect(String? workspaceId) async =>
      !await _workspaceOwnsApp(workspaceId);

  @override
  Future<String?> slotFor(String? workspaceId) async {
    if (!_isApp) {
      return await _workspaceOwnsApp(workspaceId) ? workspaceId : null;
    }
    if (workspaceId == null || workspaceId.isEmpty) {
      throw const AuthException(
        'The Linear app connects to a workspace. Open a workspace and try '
        'again.',
      );
    }
    return workspaceId;
  }

  @override
  Future<SignInIdentity> identify(String accessToken) async {
    final data = await linearGraphQl(
      _http,
      _graphQl,
      'Bearer $accessToken',
      _isApp
          ? '{ viewer { id } organization { id name urlKey } }'
          : '{ viewer { id name email } }',
    );
    if (_isApp) {
      final org = data['organization'];
      if (org is! Map) {
        throw const FormatException('linear: no organization');
      }
      final id = org['id'];
      final name = org['name'];
      return (id: id is String ? id : '', login: name is String ? name : '');
    }
    final viewer = data['viewer'];
    if (viewer is! Map) {
      throw const FormatException('linear: no viewer');
    }
    final id = viewer['id'];
    final email = viewer['email'];
    final name = viewer['name'];
    return (
      id: id is String ? id : '',
      login: email is String && email.isNotEmpty
          ? email
          : (name is String ? name : ''),
    );
  }

  @override
  Future<void> store(SignInResult result) async {
    if (_isApp) {
      final workspaceId = result.slot;
      if (workspaceId == null || workspaceId.isEmpty) {
        throw const AuthException(
          'The Linear app connects to a workspace. Open a workspace and try '
          'again.',
        );
      }
      final previous = await _workspaces.read(workspaceId);
      await _workspaces.write(workspaceId, result.token);
      if (previous != null &&
          previous.accessToken.isNotEmpty &&
          previous.accessToken != result.token.accessToken) {
        unawaited(revoke(previous.accessToken));
      }
      return;
    }
    final previous = await _people.ticketToken(
      result.userId,
      TicketProvider.linear,
      workspaceId: result.slot,
    );
    await _people.setTicketToken(
      result.userId,
      TicketProvider.linear,
      result.token,
      workspaceId: result.slot,
    );
    if (previous != null &&
        previous.accessToken.isNotEmpty &&
        previous.accessToken != result.token.accessToken) {
      unawaited(revoke(previous.accessToken));
    }
  }

  @override
  Future<LaneConnection?> connection(String userId, String? workspaceId) async {
    final ProviderToken? token;
    final String? slot;
    if (_isApp) {
      if (workspaceId == null || workspaceId.isEmpty) {
        return null;
      }
      slot = workspaceId;
      token = await _workspaces.read(workspaceId);
    } else {
      slot = await slotFor(workspaceId);
      token = await _people.ticketToken(
        userId,
        TicketProvider.linear,
        workspaceId: slot,
      );
    }
    if (token == null) {
      return LaneConnection(lane: lane, connected: false);
    }
    final String? ownClientId;
    final workspaceOwn = await _workspaceOwnsApp(workspaceId);
    if (workspaceOwn) {
      ownClientId = await _workspaceApps.ownClientId(
        workspaceId!,
        WorkspaceAppProvider.linear,
      );
    } else {
      final server = await _apps.status(ProviderApp.linear);
      ownClientId = server.effectiveState == OwnAppState.complete
          ? server.clientId
          : null;
    }
    return LaneConnection(
      lane: lane,
      connected: true,
      account: token.accountLogin,
      accountId: token.accountId,
      workspaceSlot: slot != null,
      source: ownClientId != null && ownClientId == token.appId
          ? SignInMode.own
          : SignInMode.connect,
      // A grant another app issued is not this workspace's to use.
      needsSignIn:
          (!token.canRefresh && token.isExpired) ||
          (workspaceOwn && ownClientId != token.appId),
    );
  }

  @override
  Future<void> disconnect(String userId, String? workspaceId) async {
    final ProviderToken? token;
    if (_isApp) {
      if (workspaceId == null || workspaceId.isEmpty) {
        return;
      }
      token = await _workspaces.read(workspaceId);
      await _workspaces.delete(workspaceId);
    } else {
      final slot = await slotFor(workspaceId);
      token = await _people.ticketToken(
        userId,
        TicketProvider.linear,
        workspaceId: slot,
      );
      await _people.clearTicketToken(
        userId,
        TicketProvider.linear,
        workspaceId: slot,
      );
    }
    final access = token?.accessToken ?? '';
    if (access.isNotEmpty) {
      await revoke(access);
    }
  }

  /// Revokes [accessToken] at Linear. Best effort: a token that cannot be
  /// revoked still expires.
  Future<void> revoke(String accessToken) async {
    try {
      final request = await _http.postUrl(_revoke).timeout(_timeout);
      request.followRedirects = false;
      request.headers
        ..set(HttpHeaders.authorizationHeader, 'Bearer $accessToken')
        ..contentType = ContentType('application', 'x-www-form-urlencoded');
      request.write(Uri(queryParameters: {'token': accessToken}).query);
      final response = await request.close().timeout(_timeout);
      await response.drain<void>().timeout(_timeout);
    } on Object catch (e) {
      CcHostLog.warning('linear: revoke failed ($e)');
    }
  }
}

/// Runs one GraphQL [query] against Linear with [authorization] (`Bearer …`
/// for an OAuth token, the raw key for an API key) and returns `data`.
/// Throws on transport errors, non-200 answers and GraphQL `errors`.
Future<Map<String, Object?>> linearGraphQl(
  HttpClient http,
  Uri endpoint,
  String authorization,
  String query,
) async {
  const timeout = Duration(seconds: 15);
  final request = await http.postUrl(endpoint).timeout(timeout);
  request.followRedirects = false;
  request.headers
    ..set(HttpHeaders.authorizationHeader, authorization)
    ..set(HttpHeaders.acceptHeader, 'application/json')
    ..contentType = ContentType.json;
  request.write(jsonEncode({'query': query}));
  final response = await request.close().timeout(timeout);
  final chunks = <int>[];
  await for (final chunk in response.timeout(timeout)) {
    chunks.addAll(chunk);
    if (chunks.length > LinearSignInLane._maxResponseBytes) {
      throw const HttpException('oversized reply');
    }
  }
  if (response.statusCode != HttpStatus.ok) {
    throw HttpException('linear HTTP ${response.statusCode}');
  }
  final decoded = jsonDecode(utf8.decode(chunks, allowMalformed: true));
  if (decoded is! Map) {
    throw const FormatException('linear: not an object');
  }
  if (decoded['errors'] is List && (decoded['errors'] as List).isNotEmpty) {
    throw const FormatException('linear: GraphQL errors');
  }
  final data = decoded['data'];
  if (data is! Map<String, Object?>) {
    throw const FormatException('linear: no data');
  }
  return data;
}
