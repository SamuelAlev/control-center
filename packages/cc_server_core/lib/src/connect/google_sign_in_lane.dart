import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cc_connect_core/cc_connect_core.dart';
import 'package:cc_domain/cc_domain.dart' show AuthException;
import 'package:cc_server_core/src/connect/bounded_body.dart';
import 'package:cc_server_core/src/connect/sign_in_service.dart';
import 'package:cc_server_core/src/google_calendar_server.dart';
import 'package:cc_server_core/src/identity/provider_app_settings.dart';
import 'package:cc_server_core/src/identity/workspace_provider_app_settings.dart';

/// Google's OAuth authorize endpoint.
final Uri googleAuthorizeEndpoint = Uri.parse(
  'https://accounts.google.com/o/oauth2/v2/auth',
);

/// Google's OAuth token endpoint.
final Uri googleTokenEndpoint = Uri.parse(
  'https://oauth2.googleapis.com/token',
);

/// Google's OpenID Connect userinfo endpoint.
final Uri googleUserinfoEndpoint = Uri.parse(
  'https://openidconnect.googleapis.com/v1/userinfo',
);

/// The Google Calendar lane of the browser sign-in.
///
/// A workspace on its own Google client signs its members in to that client
/// and never anything else. Otherwise own mode uses the operator's Google
/// client from [ProviderAppSettings] (`ProviderApp.google`), else the lane
/// routes through Connect. A calendar account always belongs to a member in
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
    HttpClient? httpClient,
    Uri? authorizeEndpoint,
    Uri? tokenEndpoint,
    Uri? userinfoEndpoint,
  }) : _http = httpClient ?? (HttpClient()..connectionTimeout = _timeout),
       _authorize = authorizeEndpoint ?? googleAuthorizeEndpoint,
       _token = tokenEndpoint ?? googleTokenEndpoint,
       _userinfo = userinfoEndpoint ?? googleUserinfoEndpoint;

  static const Duration _timeout = Duration(seconds: 15);
  static const int _maxResponseBytes = 64 * 1024;

  final ProviderAppSettings _apps;
  final WorkspaceProviderAppSettings _workspaceApps;
  final CalendarAccountService _accounts;
  final HttpClient _http;
  final Uri _authorize;
  final Uri _token;
  final Uri _userinfo;

  @override
  ConnectOAuthLane get lane => ConnectOAuthLane.google;

  Future<bool> _workspaceOwnsApp(String? workspaceId) async =>
      workspaceId != null &&
      await _workspaceApps.ownsApp(workspaceId, WorkspaceAppProvider.google);

  @override
  Future<OwnOAuthApp?> ownApp(String? workspaceId) async {
    final OAuthAppCredentials? credentials;
    try {
      credentials = await _workspaceOwnsApp(workspaceId)
          ? await _workspaceApps.oauthCredentials(
              workspaceId!,
              WorkspaceAppProvider.google,
            )
          : await _apps.oauthCredentials(ProviderApp.google);
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
      !await _workspaceOwnsApp(workspaceId);

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
}
