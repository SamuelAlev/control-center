import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cc_connect_core/cc_connect_core.dart';
import 'package:cc_domain/cc_domain.dart' show AuthException;
import 'package:cc_server_core/src/connect/bounded_body.dart';
import 'package:cc_server_core/src/connect/connect_settings.dart';
import 'package:cc_server_core/src/connect/sign_in_service.dart';
import 'package:cc_server_core/src/forge/forge_audit.dart';
import 'package:cc_server_core/src/google_calendar_server.dart';
import 'package:cc_server_core/src/identity/provider_app_settings.dart';
import 'package:cc_server_core/src/identity/provider_token.dart';
import 'package:cc_server_core/src/identity/workspace_provider_app_settings.dart';

/// Google's OAuth authorize endpoint.
final Uri googleAuthorizeEndpoint = Uri.parse(
  'https://accounts.google.com/o/oauth2/v2/auth',
);

/// Google's OAuth token endpoint.
final Uri googleTokenEndpoint = Uri.parse(
  'https://oauth2.googleapis.com/token',
);

/// Google's OAuth token revocation endpoint.
final Uri googleRevokeEndpoint = Uri.parse(
  'https://oauth2.googleapis.com/revoke',
);

/// Google's OpenID Connect userinfo endpoint.
final Uri googleUserinfoEndpoint = Uri.parse(
  'https://openidconnect.googleapis.com/v1/userinfo',
);

/// The Google Calendar lane of the browser sign-in.
///
/// A workspace on its own apps signs its members in to its own Google client
/// and never anything else (none saved: the lane is off). A workspace that
/// inherits uses the operator's Google client from [ProviderAppSettings]
/// (`ProviderApp.google`) while the server is on its own apps, else the
/// server's Connect; one on a Connect of its own uses that Connect. A calendar account always belongs to a member in
/// a workspace, so a sign-in without a workspace is refused, and the
/// credential lands in that workspace's calendar account for the person who
/// signed in.
final class GoogleSignInLane implements SignInLaneBinding {
  /// Creates the lane. The endpoints are fixed in production; tests point
  /// them at a loopback server.
  GoogleSignInLane({
    required this._apps,
    required this._workspaceApps,
    required this._accounts,
    required this._route,
    HttpClient? httpClient,
    Uri? authorizeEndpoint,
    Uri? tokenEndpoint,
    Uri? userinfoEndpoint,
    Uri? revokeEndpoint,
  }) : _http = httpClient ?? (HttpClient()..connectionTimeout = _timeout),
       _authorize = authorizeEndpoint ?? googleAuthorizeEndpoint,
       _token = tokenEndpoint ?? googleTokenEndpoint,
       _userinfo = userinfoEndpoint ?? googleUserinfoEndpoint,
       _revoke = revokeEndpoint ?? googleRevokeEndpoint;

  static const Duration _timeout = Duration(seconds: 15);
  static const int _maxResponseBytes = 64 * 1024;

  final ProviderAppSettings _apps;
  final WorkspaceProviderAppSettings _workspaceApps;
  final CalendarAccountService _accounts;
  final Future<ConnectRoute> Function(String? workspaceId) _route;
  final HttpClient _http;
  final Uri _authorize;
  final Uri _token;
  final Uri _userinfo;
  final Uri _revoke;

  @override
  ConnectOAuthLane get lane => ConnectOAuthLane.google;

  @override
  Future<OwnOAuthApp?> ownApp(String? workspaceId) async {
    final route = await _route(workspaceId);
    final OAuthAppCredentials? credentials;
    try {
      credentials = route.workspaceOwnApps
          ? await _workspaceApps.oauthCredentials(
              workspaceId!,
              WorkspaceAppProvider.google,
            )
          : route.serverOwnApps
          ? await _apps.oauthCredentials(ProviderApp.google)
          : null;
    } on OwnAppIncomplete catch (e) {
      throw SignInMisconfigured(e.message);
    } on WorkspaceAppIncomplete catch (e) {
      throw SignInMisconfigured(e.message);
    }
    if (credentials == null) {
      return null;
    }
    return OwnOAuthApp(
      authorize: _authorize,
      token: _token,
      clientId: credentials.clientId,
      clientSecret: credentials.clientSecret,
      scopes: googleConnectScopes,
      // A refresh token is issued only with offline access, and only on a
      // fresh consent; the account chooser stops a browser's default
      // account from connecting silently.
      extraAuthorizeParams: const {
        'access_type': 'offline',
        'prompt': 'consent select_account',
      },
    );
  }

  @override
  Future<bool> allowsConnect(String? workspaceId) async =>
      !(await _route(workspaceId)).workspaceOwnApps;

  @override
  Future<String?> slotFor(String? workspaceId) async {
    if (workspaceId == null || workspaceId.isEmpty) {
      throw const AuthException(
        'Google Calendar connects to a workspace. Open a workspace and try '
        'again.',
      );
    }
    return workspaceId;
  }

  @override
  Future<SignInIdentity> identify(String accessToken) async {
    final request = await _http.getUrl(_userinfo).timeout(_timeout);
    request.followRedirects = false;
    request.headers
      ..set(HttpHeaders.authorizationHeader, 'Bearer $accessToken')
      ..set(HttpHeaders.acceptHeader, 'application/json');
    final response = await request.close().timeout(_timeout);
    final body = await readBoundedText(
      response,
      maxBytes: _maxResponseBytes,
      timeout: _timeout,
    );
    if (response.statusCode != HttpStatus.ok) {
      throw HttpException('userinfo HTTP ${response.statusCode}');
    }
    final decoded = jsonDecode(body);
    if (decoded is! Map) {
      throw const FormatException('userinfo');
    }
    final sub = decoded['sub'];
    final email = decoded['email'];
    return (id: sub is String ? sub : '', login: email is String ? email : '');
  }

  @override
  Future<Set<String>> accountHolders(String accountId) =>
      _accounts.holdersOf(accountId);

  /// Revokes an own-client grant at Google (the refresh token, which takes
  /// its access tokens with it). Best effort.
  @override
  Future<void> revokeOwnGrant(ProviderToken token, String? slot) =>
      revoke(token);

  /// Revokes [token] at Google, best effort. A sealed grant has nothing this
  /// server can present.
  Future<void> revoke(ProviderToken token) async {
    final value = token.refreshToken.isNotEmpty
        ? token.refreshToken
        : token.accessToken;
    if (token.isSealed || value.isEmpty) {
      return;
    }
    try {
      final request = await _http.postUrl(_revoke).timeout(_timeout);
      request.followRedirects = false;
      request.headers.contentType = ContentType(
        'application',
        'x-www-form-urlencoded',
      );
      request.write(Uri(queryParameters: {'token': value}).query);
      final response = await request.close().timeout(_timeout);
      await response.drain<void>().timeout(_timeout);
      if (response.statusCode >= 300) {
        forgeAudit(ForgeAuditEvent.grantRevokeSkipped, {
          'lane': lane.wire,
          'reason': 'http_${response.statusCode}',
        }, token: token.accessToken);
      }
    } on Object catch (e) {
      forgeAudit(ForgeAuditEvent.grantRevokeSkipped, {
        'lane': lane.wire,
        'reason': 'revoke_failed:${errorKindOf(e)}',
      }, token: token.accessToken);
    }
  }

  @override
  Future<void> store(SignInResult result) async {
    final workspaceId = result.slot ?? result.workspaceId;
    if (workspaceId == null || workspaceId.isEmpty) {
      throw const AuthException(
        'Google Calendar connects to a workspace. Open a workspace and try '
        'again.',
      );
    }
    var token = result.token;
    if (token.accountLogin.isEmpty && token.accessToken.isNotEmpty) {
      // A Connect grant may carry only the account id; the address keys the
      // calendar account, so ask Google with the fresh access token.
      final who = await identify(token.accessToken);
      token = token.copyWith(
        accountLogin: who.login,
        accountId: token.accountId.isEmpty ? who.id : token.accountId,
      );
    }
    if (token.accountLogin.isEmpty) {
      throw const FormatException('google: no account email');
    }
    await _accounts.connect(
      workspaceId: workspaceId,
      userId: result.userId,
      email: token.accountLogin,
      token: token,
    );
  }

  /// Calendar accounts are listed by the `calendar.*` ops, not as a lane
  /// grant.
  @override
  Future<LaneConnection?> connection(
    String userId,
    String? workspaceId,
  ) async => null;

  /// Accounts are removed one by one with `calendar.disconnect`.
  @override
  Future<void> disconnect(String userId, String? workspaceId) async {}

  @override
  Future<List<SealRequest>> connectSeals(
    String connectOrigin,
    List<String> workspaceIds,
  ) => _accounts.connectSeals(connectOrigin);

  /// Disconnects the person's calendar accounts (their events go with the
  /// rows) and revokes each own-client grant at Google; a sealed grant has
  /// nothing this server can present and lapses.
  @override
  Future<int> offboard({String? userId, String? workspaceId}) async {
    final removed = await _accounts.disconnectWhere(
      userId: userId,
      workspaceId: workspaceId,
    );
    for (final token in removed) {
      await revoke(token);
    }
    return removed.length;
  }
}
