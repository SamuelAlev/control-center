import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:cc_domain/cc_domain.dart' show AuthException;
import 'package:cc_domain/core/domain/value_objects/forge_connection.dart';
import 'package:cc_domain/core/domain/value_objects/forge_host.dart';
import 'package:cc_domain/features/ticketing/domain/entities/ticket_provider.dart';
import 'package:cc_server_core/src/identity/provider_app_settings.dart';
import 'package:cc_server_core/src/identity/provider_token.dart';
import 'package:cc_server_core/src/identity/user_credentials_store.dart';

/// This server's callback URL for [provider], derived from an HTTP [origin]
/// (`https://host:9030`).
///
/// ONE function, called by both the op that builds the authorize URL and the
/// endpoint that handles the redirect. OAuth compares the two strings exactly
/// and rejects the exchange on any difference, so two places composing "the
/// same" URL is a bug waiting for a trailing slash.
///
/// This is also the URL the operator registers with the provider — the
/// settings screen shows it verbatim rather than asking them to assemble it.
Uri providerOAuthRedirectUri(String origin, String provider) =>
    Uri.parse('$origin/oauth/$provider/callback');

/// What the human needs in order to finish a device-code sign-in: a short code
/// and where to type it. Deliberately carries no `device_code` — that is the
/// server's half of the exchange.
class DeviceLoginPrompt {
  /// Creates a [DeviceLoginPrompt].
  const DeviceLoginPrompt({
    required this.userCode,
    required this.verificationUri,
    required this.expiresIn,
    required this.interval,
  });

  /// The code the human types into the provider's page.
  final String userCode;

  /// Where they type it.
  final String verificationUri;

  /// How long the code stays valid.
  final Duration expiresIn;

  /// How often the server polls, which is also how long the UI should wait
  /// before its first check.
  final Duration interval;

  /// The wire shape.
  Map<String, Object?> toJson() => {
    'mode': 'device',
    'user_code': userCode,
    'verification_uri': verificationUri,
    'expires_in': expiresIn.inSeconds,
    'interval': interval.inSeconds,
  };
}

/// A live device-code poll. Cancelled when the same user starts another one.
class _DevicePoll {
  _DevicePoll({required this.deadline, required this.interval});

  final DateTime deadline;
  final Duration interval;

  bool cancelled = false;

  void cancel() => cancelled = true;
}

/// One provider's OAuth wiring. Hand-written per provider because the three
/// things that differ — where to send the browser, what the token endpoint
/// wants, and how to ask "who is this?" — differ in ways no generic client
/// abstracts away.
class _OAuthWiring {
  const _OAuthWiring({
    required this.authorize,
    required this.token,
    required this.accountProbe,
    this.deviceCode,
    this.scope = '',
    this.extraAuthorizeParams = const {},
  });

  final Uri authorize;
  final Uri token;

  /// Where a DEVICE flow starts, for the providers that support one. Null
  /// means this provider can only be signed in to by browser redirect.
  final Uri? deviceCode;

  final String scope;
  final Map<String, String> extraAuthorizeParams;

  /// Resolves the account name behind a freshly minted token.
  final Future<String> Function(HttpClient http, String token) accountProbe;
}

/// Signs a USER in to a provider and stores the resulting credential as
/// theirs.
///
/// The shape is the same as `OidcService`'s, for the same reasons: the browser
/// round-trip is started by an authenticated RPC that mints an unguessable,
/// single-use `state` bound server-side to `(user, provider)`, and the callback
/// — which is necessarily unauthenticated, because it arrives from the
/// provider — carries nothing but that state. No client ever sends a user id
/// into this flow, so no client can mint a credential for somebody else.
///
/// What comes back is stored, never returned: the callback's reply is a page
/// telling the human to close the tab, and the app learns the outcome by
/// re-reading its connection list.
class ProviderOAuthService {
  /// Creates a [ProviderOAuthService].
  ProviderOAuthService({
    required ProviderAppSettings apps,
    required UserCredentialsStore users,
    HttpClient? httpClient,
    DateTime Function()? now,
  }) : _apps = apps,
       _users = users,
       _http = httpClient ?? (HttpClient()..connectionTimeout = _httpTimeout),
       _now = now ?? (() => DateTime.now().toUtc());

  /// Bound on every provider round-trip. A wedged provider must not pin the
  /// login path open indefinitely.
  static const Duration _httpTimeout = Duration(seconds: 15);

  /// Upper bound on a token/identity response.
  static const int _maxResponseBytes = 256 * 1024;

  /// Upper bound on concurrent pending logins. The callback endpoint is
  /// unauthenticated, so the pending map needs flood backpressure.
  static const int maxPendingLogins = 256;

  /// How long a started login stays completable.
  static const Duration pendingTtl = Duration(minutes: 10);

  final ProviderAppSettings _apps;
  final UserCredentialsStore _users;
  final HttpClient _http;
  final DateTime Function() _now;
  final _random = Random.secure();

  final _pending =
      <String, ({String userId, ProviderApp provider, DateTime expiresAt})>{};

  /// Live device-code polls, one per `(user, provider)`.
  final _devicePolls = <String, _DevicePoll>{};

  static final Map<ProviderApp, _OAuthWiring> _wiring = {
    ProviderApp.github: _OAuthWiring(
      authorize: Uri.parse('https://github.com/login/oauth/authorize'),
      token: Uri.parse('https://github.com/login/oauth/access_token'),
      deviceCode: Uri.parse('https://github.com/login/device/code'),
      // A GitHub App's user token carries the app's own permissions; sending a
      // `scope` here is an OAuth-App concept and GitHub ignores it.
      accountProbe: _probeGitHubLogin,
    ),
    ProviderApp.linear: _OAuthWiring(
      authorize: Uri.parse('https://linear.app/oauth/authorize'),
      token: Uri.parse('https://api.linear.app/oauth/token'),
      scope: 'read,write,issues:create',
      // `actor=user` makes everything the token does appear as the human, not
      // as the app — the whole point of signing in rather than sharing a key.
      extraAuthorizeParams: {'actor': 'user'},
      accountProbe: _probeLinearName,
    ),
  };

  /// The providers this server can actually run a sign-in for — the ones whose
  /// app credentials are configured. The client shows a "sign in" button for
  /// exactly these and a "paste a token" affordance for the rest.
  Future<List<ProviderApp>> availableProviders() async {
    final available = <ProviderApp>[];
    for (final provider in ProviderApp.values) {
      if ((await _apps.oauthCredentials(provider)) != null) {
        available.add(provider);
      }
    }
    return available;
  }

  /// Starts a login for [userId] and returns the URL to open in their browser.
  ///
  /// [redirectUri] is this server's `/oauth/<provider>/callback`, and must
  /// match what is registered with the provider — a mismatch is the single
  /// most common setup failure, so the callback surfaces the provider's own
  /// error rather than a generic one.
  Future<Uri> beginLogin({
    required ProviderApp provider,
    required String userId,
    required Uri redirectUri,
  }) async {
    final credentials = await _apps.oauthCredentials(provider);
    if (credentials == null) {
      throw AuthException(
        'This server has no ${provider.wire} app configured, so it cannot '
        'run a sign-in. Add one in Settings → Server, or paste a token.',
      );
    }
    _evictExpired();
    if (_pending.length >= maxPendingLogins) {
      final ordered = _pending.entries.toList()
        ..sort((a, b) => a.value.expiresAt.compareTo(b.value.expiresAt));
      for (final entry in ordered.take(
        _pending.length - maxPendingLogins + 1,
      )) {
        _pending.remove(entry.key);
      }
    }
    final state = _randomToken();
    _pending[state] = (
      userId: userId,
      provider: provider,
      expiresAt: _now().add(pendingTtl),
    );
    final wiring = _wiring[provider]!;
    return wiring.authorize.replace(
      queryParameters: {
        'client_id': credentials.clientId,
        'redirect_uri': redirectUri.toString(),
        'response_type': 'code',
        'state': state,
        if (wiring.scope.isNotEmpty) 'scope': wiring.scope,
        ...wiring.extraAuthorizeParams,
      },
    );
  }

  /// Whether [provider] signs in by DEVICE code rather than by browser
  /// redirect.
  ///
  /// The two are not interchangeable: a device flow needs no callback URL
  /// registered anywhere, which is what makes it work for a server on
  /// `127.0.0.1`, behind NAT, or reached from a phone — and it is the only
  /// flow whose setup is a checkbox rather than a URL the operator has to get
  /// byte-identical.
  static bool usesDeviceFlow(ProviderApp provider) =>
      _wiring[provider]?.deviceCode != null;

  /// Starts a device-code login for [userId].
  ///
  /// Returns the code the human types and where to type it. The server then
  /// polls the provider in the background and stores the credential when they
  /// finish — the app learns the outcome by re-reading its connection list,
  /// exactly as with the redirect flow.
  ///
  /// The `device_code` itself never leaves this process: it is half of the
  /// exchange, and a client that held it could complete somebody else's login.
  Future<DeviceLoginPrompt> beginDeviceLogin({
    required ProviderApp provider,
    required String userId,
  }) async {
    final wiring = _wiring[provider]!;
    final deviceUrl = wiring.deviceCode;
    if (deviceUrl == null) {
      throw AuthException('${provider.wire} has no device sign-in.');
    }
    final credentials = await _apps.oauthCredentials(provider);
    if (credentials == null) {
      throw AuthException(
        'This server has no ${provider.wire} app configured, so it cannot '
        'run a sign-in. Add one in Settings → Server, or paste a token.',
      );
    }

    final response = await _postForm(deviceUrl, {
      'client_id': credentials.clientId,
      if (wiring.scope.isNotEmpty) 'scope': wiring.scope,
    });
    final deviceCode = response['device_code'];
    final userCode = response['user_code'];
    final verification = response['verification_uri'];
    if (deviceCode is! String ||
        userCode is! String ||
        verification is! String) {
      throw const AuthException(
        'The provider did not return a device code. If this is a GitHub App, '
        'enable "Device flow" in its settings.',
      );
    }
    final interval = (response['interval'] as num?)?.toInt() ?? 5;
    final expiresIn = (response['expires_in'] as num?)?.toInt() ?? 900;

    // One live device login per (user, provider): starting a second one means
    // the human abandoned the first, and two pollers would race to store two
    // different credentials for the same person.
    final key = '$userId:${provider.wire}';
    _devicePolls.remove(key)?.cancel();
    final poll = _DevicePoll(
      deadline: _now().add(Duration(seconds: expiresIn)),
      interval: Duration(seconds: interval.clamp(1, 60)),
    );
    _devicePolls[key] = poll;
    unawaited(
      _pollDeviceLogin(
        key: key,
        poll: poll,
        provider: provider,
        userId: userId,
        credentials: credentials,
        deviceCode: deviceCode,
      ),
    );

    return DeviceLoginPrompt(
      userCode: userCode,
      verificationUri: verification,
      expiresIn: Duration(seconds: expiresIn),
      interval: poll.interval,
    );
  }

  /// Polls the provider until the human approves, refuses, or the code
  /// expires. Never throws: a failure simply leaves the user unconnected, and
  /// the UI already reports that.
  Future<void> _pollDeviceLogin({
    required String key,
    required _DevicePoll poll,
    required ProviderApp provider,
    required String userId,
    required OAuthAppCredentials credentials,
    required String deviceCode,
  }) async {
    var interval = poll.interval;
    try {
      while (!poll.cancelled && _now().isBefore(poll.deadline)) {
        await Future<void>.delayed(interval);
        if (poll.cancelled) {
          return;
        }
        Map<String, dynamic> answer;
        try {
          answer = await _postForm(_wiring[provider]!.token, {
            'client_id': credentials.clientId,
            'device_code': deviceCode,
            'grant_type': 'urn:ietf:params:oauth:grant-type:device_code',
          });
        } on Object {
          // A transient network failure is not a refusal; keep waiting until
          // the code itself expires.
          continue;
        }
        final error = answer['error'];
        if (error == 'authorization_pending') {
          continue;
        }
        if (error == 'slow_down') {
          // The provider is telling us our interval is too tight. Honour the
          // new one rather than being rate-limited into failing a login the
          // human completed.
          interval =
              Duration(seconds: (answer['interval'] as num?)?.toInt() ?? 5) +
              const Duration(seconds: 1);
          continue;
        }
        if (error != null) {
          // `expired_token`, `access_denied`, `incorrect_device_code` — all
          // terminal, and all end the same way: no credential.
          return;
        }
        final access = answer['access_token'];
        if (access is! String || access.isEmpty) {
          return;
        }
        final expiresIn = (answer['expires_in'] as num?)?.toInt();
        final refreshExpiresIn = (answer['refresh_token_expires_in'] as num?)
            ?.toInt();
        final token = ProviderToken(
          accessToken: access,
          refreshToken: answer['refresh_token'] as String? ?? '',
          expiresAt: expiresIn == null
              ? null
              : _now().add(Duration(seconds: expiresIn)),
          refreshExpiresAt: refreshExpiresIn == null
              ? null
              : _now().add(Duration(seconds: refreshExpiresIn)),
          source: ForgeCredentialSource.oauth,
        );
        final account = await _wiring[provider]!
            .accountProbe(_http, access)
            .catchError((_) => '');
        await _store(userId, provider, token.withAccount(account));
        return;
      }
    } finally {
      if (identical(_devicePolls[key], poll)) {
        _devicePolls.remove(key);
      }
    }
  }

  /// Completes a login from the provider's redirect back to
  /// `/oauth/<provider>/callback?code=…&state=…`.
  ///
  /// Returns the provider and the account that was connected, for the page the
  /// human is looking at. Throws [AuthException] with a reason worth reading:
  /// this is the one screen where a setup mistake is visible.
  Future<({ProviderApp provider, String account})> handleCallback({
    required Uri requestUri,
    required Uri redirectUri,
  }) async {
    final error =
        requestUri.queryParameters['error_description'] ??
        requestUri.queryParameters['error'];
    if (error != null && error.isNotEmpty) {
      throw AuthException('The provider refused the sign-in: $error');
    }
    final state = requestUri.queryParameters['state'];
    final code = requestUri.queryParameters['code'];
    // Single use: removing it here means a replayed callback URL — from
    // browser history, a shared link, a logged referrer — mints nothing.
    final pending = state == null ? null : _pending.remove(state);
    if (pending == null || code == null || code.isEmpty) {
      throw const AuthException('This sign-in link is no longer valid.');
    }
    if (_now().isAfter(pending.expiresAt)) {
      throw const AuthException('This sign-in took too long — try again.');
    }

    final credentials = await _apps.oauthCredentials(pending.provider);
    if (credentials == null) {
      throw const AuthException(
        'The app credentials changed while you were signing in.',
      );
    }
    final token = await _exchange(
      provider: pending.provider,
      credentials: credentials,
      redirectUri: redirectUri,
      body: {'grant_type': 'authorization_code', 'code': code},
    );
    final account = await _wiring[pending.provider]!.accountProbe(
      _http,
      token.accessToken,
    );
    await _store(pending.userId, pending.provider, token.withAccount(account));
    return (provider: pending.provider, account: account);
  }

  /// Exchanges an expired credential for a fresh one. Wired into
  /// `ForgeCredentials.refreshUserToken`, so an expiring GitHub user token is
  /// renewed on the next call instead of surfacing as a 401.
  ///
  /// Returns null when the refresh is not possible or the provider rejects it;
  /// the caller then drops the credential and the UI asks for a new sign-in.
  Future<ProviderToken?> refresh(
    String userId,
    ForgeHost forge,
    ProviderToken expired,
  ) async {
    final provider = _providerForForge(forge);
    if (provider == null || !expired.canRefresh) {
      return null;
    }
    final credentials = await _apps.oauthCredentials(provider);
    // Refreshing IS a confidential-client exchange even where signing in is
    // not: without a client secret an expiring token simply cannot be renewed,
    // and the caller drops it and asks for a fresh sign-in.
    if (credentials == null || credentials.clientSecret.isEmpty) {
      return null;
    }
    try {
      final refreshed = await _exchange(
        provider: provider,
        credentials: credentials,
        redirectUri: null,
        body: {
          'grant_type': 'refresh_token',
          'refresh_token': expired.refreshToken,
        },
      );
      return refreshed.withAccount(expired.accountLogin);
    } on Object {
      return null;
    }
  }

  /// Stores a token the user pasted rather than minted, so both paths land in
  /// the same place with the same probe for who the token belongs to.
  Future<String> storePastedToken({
    required String userId,
    required ProviderApp provider,
    required String token,
  }) async {
    final account = await _wiring[provider]!
        .accountProbe(_http, token)
        .catchError((_) => '');
    await _store(
      userId,
      provider,
      ProviderToken(
        accessToken: token,
        source: ForgeCredentialSource.settings,
        accountLogin: account,
      ),
    );
    return account;
  }

  ProviderApp? _providerForForge(ForgeHost forge) =>
      forge == ForgeHost.github ? ProviderApp.github : null;

  Future<void> _store(
    String userId,
    ProviderApp provider,
    ProviderToken token,
  ) async {
    switch (provider) {
      case ProviderApp.github:
        await _users.setForgeToken(userId, ForgeHost.github, token);
      case ProviderApp.linear:
        await _users.setTicketToken(userId, TicketProvider.linear, token);
    }
  }

  Future<ProviderToken> _exchange({
    required ProviderApp provider,
    required OAuthAppCredentials credentials,
    required Uri? redirectUri,
    required Map<String, String> body,
  }) async {
    final wiring = _wiring[provider]!;
    final request = await _http.postUrl(wiring.token);
    // Never follow redirects: on a 307/308 dart:io would RE-POST the body —
    // the authorization code AND the client secret — to an arbitrary Location.
    request.followRedirects = false;
    request.headers.contentType = ContentType(
      'application',
      'x-www-form-urlencoded',
    );
    // GitHub answers form-encoded unless asked otherwise, and the form shape
    // hides an `error` field inside a 200.
    request.headers.set(HttpHeaders.acceptHeader, 'application/json');
    request.write(
      Uri(
        queryParameters: {
          ...body,
          'client_id': credentials.clientId,
          // Empty for a device-flow app, which authenticates with the client
          // id alone. Sending an empty `client_secret` makes GitHub treat the
          // request as a malformed confidential-client one.
          if (credentials.clientSecret.isNotEmpty)
            'client_secret': credentials.clientSecret,
          if (redirectUri != null) 'redirect_uri': redirectUri.toString(),
        },
      ).query,
    );
    final response = await request.close().timeout(_httpTimeout);
    final raw = await _readBounded(response);
    if (response.statusCode != 200) {
      final excerpt = raw.length > 300 ? raw.substring(0, 300) : raw;
      throw AuthException(
        'The provider rejected the sign-in '
        '(HTTP ${response.statusCode}: $excerpt)',
      );
    }
    final decoded = jsonDecode(raw);
    if (decoded is! Map) {
      throw const AuthException('The provider returned an unreadable reply.');
    }
    final error = decoded['error_description'] ?? decoded['error'];
    if (error is String && error.isNotEmpty) {
      throw AuthException('The provider refused the sign-in: $error');
    }
    final access = decoded['access_token'];
    if (access is! String || access.isEmpty) {
      throw const AuthException('The provider returned no token.');
    }
    final expiresIn = (decoded['expires_in'] as num?)?.toInt();
    final refreshExpiresIn = (decoded['refresh_token_expires_in'] as num?)
        ?.toInt();
    return ProviderToken(
      accessToken: access,
      refreshToken: decoded['refresh_token'] as String? ?? '',
      expiresAt: expiresIn == null
          ? null
          : _now().add(Duration(seconds: expiresIn)),
      refreshExpiresAt: refreshExpiresIn == null
          ? null
          : _now().add(Duration(seconds: refreshExpiresIn)),
      source: ForgeCredentialSource.oauth,
    );
  }

  /// POSTs a form and decodes the JSON answer.
  ///
  /// A 200 with an `error` field is NORMAL in the device flow
  /// (`authorization_pending` is most of the poll), so this returns the body
  /// rather than throwing on it — the caller decides which errors are
  /// terminal. Non-200 does throw: that is the provider refusing outright.
  Future<Map<String, dynamic>> _postForm(
    Uri url,
    Map<String, String> body,
  ) async {
    final request = await _http.postUrl(url);
    // Never follow redirects: a 307/308 would RE-POST the body — which
    // carries the device code — to an arbitrary Location.
    request.followRedirects = false;
    request.headers.contentType = ContentType(
      'application',
      'x-www-form-urlencoded',
    );
    request.headers.set(HttpHeaders.acceptHeader, 'application/json');
    request.write(Uri(queryParameters: body).query);
    final response = await request.close().timeout(_httpTimeout);
    final raw = await _readBounded(response);
    if (response.statusCode != 200) {
      final excerpt = raw.length > 300 ? raw.substring(0, 300) : raw;
      throw AuthException(
        'The provider rejected the request '
        '(HTTP ${response.statusCode}: $excerpt)',
      );
    }
    final decoded = jsonDecode(raw);
    return decoded is Map<String, dynamic> ? decoded : const {};
  }

  void _evictExpired() {
    final now = _now();
    _pending.removeWhere((_, value) => now.isAfter(value.expiresAt));
  }

  String _randomToken() {
    final bytes = List<int>.generate(32, (_) => _random.nextInt(256));
    return base64Url.encode(bytes).replaceAll('=', '');
  }

  static Future<String> _probeGitHubLogin(HttpClient http, String token) async {
    final json = await _getJson(
      http,
      Uri.parse('https://api.github.com/user'),
      headers: {
        HttpHeaders.authorizationHeader: 'Bearer $token',
        HttpHeaders.acceptHeader: 'application/vnd.github+json',
        HttpHeaders.userAgentHeader: 'control-center',
      },
    );
    return json['login'] as String? ?? '';
  }

  static Future<String> _probeLinearName(HttpClient http, String token) async {
    final request = await http.postUrl(
      Uri.parse('https://api.linear.app/graphql'),
    );
    request.followRedirects = false;
    request.headers.contentType = ContentType('application', 'json');
    request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $token');
    request.write(jsonEncode({'query': '{ viewer { name displayName } }'}));
    final response = await request.close().timeout(_httpTimeout);
    final body = await _readBounded(response);
    if (response.statusCode != 200) {
      return '';
    }
    final decoded = jsonDecode(body);
    if (decoded is! Map) {
      return '';
    }
    final data = decoded['data'];
    final viewer = data is Map ? data['viewer'] : null;
    if (viewer is! Map) {
      return '';
    }
    return (viewer['displayName'] ?? viewer['name']) as String? ?? '';
  }

  static Future<Map<String, dynamic>> _getJson(
    HttpClient http,
    Uri uri, {
    Map<String, String> headers = const {},
  }) async {
    final request = await http.getUrl(uri);
    request.followRedirects = false;
    headers.forEach(request.headers.set);
    final response = await request.close().timeout(_httpTimeout);
    final body = await _readBounded(response);
    if (response.statusCode != 200) {
      throw const AuthException('The provider rejected the credential.');
    }
    final decoded = jsonDecode(body);
    return decoded is Map<String, dynamic> ? decoded : const {};
  }

  /// Reads [response] fully, bounded in both size and time. A buggy or hostile
  /// endpoint must not pin memory or the connection.
  static Future<String> _readBounded(HttpClientResponse response) async {
    final chunks = <int>[];
    await for (final chunk in response.timeout(_httpTimeout)) {
      chunks.addAll(chunk);
      if (chunks.length > _maxResponseBytes) {
        throw const AuthException('The provider returned an oversized reply.');
      }
    }
    return utf8.decode(chunks, allowMalformed: true);
  }
}
