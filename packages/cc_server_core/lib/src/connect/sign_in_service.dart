import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cc_connect_core/cc_connect_core.dart';
import 'package:cc_domain/cc_domain.dart' show AuthException;
import 'package:cc_domain/core/domain/value_objects/forge_connection.dart';
import 'package:cc_host/cc_host.dart' show CcHostLog;
import 'package:cc_server_core/src/connect/connect_client.dart';
import 'package:cc_server_core/src/identity/provider_token.dart';

/// This server's callback URL for an own-app [lane], under an HTTP [origin]
/// (`https://host:9030`).
///
/// One function, called both where the authorize URL is built and where the
/// redirect lands: OAuth compares the two strings exactly. It is also what the
/// operator registers with the provider, so Settings shows it verbatim.
Uri providerOAuthRedirectUri(String origin, String lane) =>
    Uri.parse('$origin/oauth/$lane/callback');

/// Where a lane's sign-in runs right now.
enum SignInMode {
  /// The server's own app: the browser comes back to this server.
  own,

  /// Control Center Connect: the browser comes back to Connect, which shows
  /// a confirmation code.
  connect,

  /// Nothing configured.
  unavailable;

  /// The wire spelling.
  String get wire => name;
}

/// An own-app OAuth client for one lane. The token and authorize endpoints
/// are the provider's fixed ones; only the client credentials vary.
final class OwnOAuthApp {
  /// Creates the client description.
  const OwnOAuthApp({
    required this.authorize,
    required this.token,
    required this.clientId,
    required this.scopes,
    this.clientSecret = '',
    this.scopeSeparator = ' ',
    this.extraAuthorizeParams = const {},
  });

  /// The provider's authorize endpoint.
  final Uri authorize;

  /// The provider's token endpoint.
  final Uri token;

  /// The operator's client id.
  final String clientId;

  /// The operator's client secret; empty for a public PKCE client.
  final String clientSecret;

  /// The fixed scope set for the lane; empty when the provider takes none.
  final List<String> scopes;

  /// How the provider joins scopes in the authorize URL.
  final String scopeSeparator;

  /// Fixed extra authorize parameters (`prompt`, `actor`, `access_type`).
  final Map<String, String> extraAuthorizeParams;
}

/// Thrown when a lane is configured halfway: partial own credentials never
/// mix with Connect, so the honest answer is a setup error.
final class SignInMisconfigured implements Exception {
  /// Creates the error.
  const SignInMisconfigured(this.message);

  /// What the operator has to fix.
  final String message;

  @override
  String toString() => message;
}

/// The identity behind a freshly minted own-app token.
typedef SignInIdentity = ({String id, String login});

/// A finished sign-in, handed to the lane to store.
final class SignInResult {
  /// Creates the result.
  const SignInResult({
    required this.lane,
    required this.userId,
    required this.workspaceId,
    required this.slot,
    required this.token,
    this.grant,
  });

  /// Which lane.
  final ConnectOAuthLane lane;

  /// The person who signed in (from the authenticated session, never a
  /// client argument).
  final String userId;

  /// The workspace the sign-in was started from, if any.
  final String? workspaceId;

  /// The credential slot: a workspace id, or null for the person's global
  /// slot.
  final String? slot;

  /// The credential. Sealed for a Connect lane (access token for memory
  /// only); a plain token for an own app or a Linear exchange.
  final ProviderToken token;

  /// The raw Connect grant, for lanes that need its extra fields (Slack's
  /// team and bot ids).
  final SealedGrant? grant;
}

/// One lane's server-side half: what app it uses and where its credential
/// lives. The sign-in service owns the browser round-trip and the exchange.
abstract interface class SignInLaneBinding {
  /// The lane.
  ConnectOAuthLane get lane;

  /// The own app for [workspaceId], or null to route through Connect.
  /// Throws [SignInMisconfigured] for partial own credentials.
  Future<OwnOAuthApp?> ownApp(String? workspaceId);

  /// Whether this lane may route through Connect for [workspaceId] at all.
  /// A workspace on its own GitHub App never does.
  Future<bool> allowsConnect(String? workspaceId);

  /// The credential slot a sign-in from [workspaceId] lands in: the
  /// workspace id, or null for the person's global slot.
  Future<String?> slotFor(String? workspaceId);

  /// Resolves who an own-app access token belongs to.
  Future<SignInIdentity> identify(String accessToken);

  /// Stores a finished sign-in.
  Future<void> store(SignInResult result);

  /// [userId]'s grant in this lane as seen from [workspaceId], or null when
  /// there is none. Workspace-level lanes (`linear_app`, `slack`) answer for
  /// the workspace and ignore [userId].
  Future<LaneConnection?> connection(String userId, String? workspaceId);

  /// Deletes the grant [connection] reports, revoking it upstream where the
  /// provider allows.
  Future<void> disconnect(String userId, String? workspaceId);
}

/// One lane's current grant, as reported to clients. Never carries a token.
final class LaneConnection {
  /// Creates the report.
  const LaneConnection({
    required this.lane,
    required this.connected,
    this.account = '',
    this.accountId = '',
    this.workspaceSlot = false,
    this.source = SignInMode.own,
    this.needsSignIn = false,
  });

  /// Which lane.
  final ConnectOAuthLane lane;

  /// Whether a usable grant is stored.
  final bool connected;

  /// Login, email or display name.
  final String account;

  /// The provider's immutable account id.
  final String accountId;

  /// True when the grant lives in the workspace slot.
  final bool workspaceSlot;

  /// Own app or Connect.
  final SignInMode source;

  /// True when a grant exists but must be renewed by signing in again.
  final bool needsSignIn;

  /// The wire shape.
  Map<String, Object?> toJson() => {
    'lane': lane.wire,
    'connected': connected,
    'account': account,
    'account_id': accountId,
    'slot': workspaceSlot ? 'workspace' : 'global',
    'source': source.wire,
    'needs_sign_in': needsSignIn,
  };
}

/// The lifecycle of one started sign-in.
enum SignInStatus {
  /// Waiting for the browser (own) or the confirmation code (Connect).
  pending,

  /// Stored.
  succeeded,

  /// Refused, expired or failed; [SignInAttempt.error] says why.
  failed;

  /// The wire spelling.
  String get wire => name;
}

/// A started sign-in, as reported to the client that started it.
final class SignInAttempt {
  SignInAttempt._({
    required this.loginId,
    required this.lane,
    required this.mode,
    required this.userId,
    required this.workspaceId,
    required this.slot,
    required this.verifier,
    required this.expiresAt,
    required this.url,
    this.state = '',
    this.redirectUri,
    this.clientId = '',
  });

  /// Opaque handle; for Connect it is Connect's login id (the deep link
  /// carries it back), for an own app a fresh random id.
  final String loginId;

  /// Which lane.
  final ConnectOAuthLane lane;

  /// Own app or Connect.
  final SignInMode mode;

  /// The person.
  final String userId;

  /// The workspace it started from.
  final String? workspaceId;

  /// The credential slot.
  final String? slot;

  /// The PKCE verifier. Never leaves this process.
  final String verifier;

  /// When it stops being completable.
  final DateTime expiresAt;

  /// Where to send the browser.
  final Uri url;

  /// Own-app `state`.
  final String state;

  /// Own-app redirect URI, reused verbatim for the exchange.
  final Uri? redirectUri;

  /// The client id the exchange must use (own app, or Connect's Linear
  /// client for the Linear code exchange).
  final String clientId;

  /// Current status.
  SignInStatus status = SignInStatus.pending;

  /// The connected account, when it succeeded.
  String account = '';

  /// A stable failure code: `access_denied`, `expired`, `scope_mismatch`,
  /// `invalid_code`, `provider_unavailable`, `exchange_failed`, …
  String error = '';

  int _attempts = 0;

  /// The wire shape for the client.
  Map<String, Object?> toJson() => {
    'login_id': loginId,
    'lane': lane.wire,
    'mode': mode.wire,
    'url': url.toString(),
    'expires_at': expiresAt.toUtc().toIso8601String(),
    'status': status.wire,
    if (account.isNotEmpty) 'account': account,
    if (error.isNotEmpty) 'error': error,
  };
}

/// Runs every browser sign-in this server offers (GitHub, Google, Linear,
/// Linear app, Slack), in own-app or Connect mode.
///
/// The person always comes from the authenticated session: nothing a client
/// sends can mint a credential for somebody else. Own-app sign-ins come back
/// to `/oauth/<lane>/callback` with a single-use `state`; Connect sign-ins
/// finish when the client presents the confirmation code the approving
/// browser showed, with this server's PKCE verifier and its signed install
/// identity. A deep link the local client did not start is never completed.
class ProviderSignInService {
  /// Creates the service.
  ProviderSignInService({
    required this.connect,
    HttpClient? httpClient,
    DateTime Function()? now,
  }) : _http = httpClient ?? (HttpClient()..connectionTimeout = _httpTimeout),
       _now = now ?? (() => DateTime.now().toUtc());

  static const Duration _httpTimeout = Duration(seconds: 15);
  static const int _maxResponseBytes = 256 * 1024;

  /// Pending-attempt ceiling; the own-app callback is unauthenticated.
  static const int maxPending = 256;

  /// How long an attempt stays completable.
  static const Duration pendingTtl = Duration(minutes: 10);

  /// Wrong confirmation codes before an attempt is dropped.
  static const int maxConfirmAttempts = 5;

  /// The Connect client.
  final ConnectClient connect;

  final HttpClient _http;
  final DateTime Function() _now;
  final Map<ConnectOAuthLane, SignInLaneBinding> _bindings = {};
  final Map<String, SignInAttempt> _attempts = {};
  final Map<String, String> _byState = {};
  final Set<String> _claiming = {};

  /// Registers a lane. Each lane has exactly one binding.
  void register(SignInLaneBinding binding) {
    _bindings[binding.lane] = binding;
  }

  /// The lane's binding, when registered.
  SignInLaneBinding? binding(ConnectOAuthLane lane) => _bindings[lane];

  /// How [lane] signs in for [workspaceId] right now, with the setup error
  /// when it is misconfigured.
  Future<({SignInMode mode, String error})> modeFor(
    ConnectOAuthLane lane, {
    String? workspaceId,
  }) async {
    final binding = _bindings[lane];
    if (binding == null) {
      return (mode: SignInMode.unavailable, error: '');
    }
    try {
      if (await binding.ownApp(workspaceId) != null) {
        return (mode: SignInMode.own, error: '');
      }
    } on SignInMisconfigured catch (e) {
      return (mode: SignInMode.unavailable, error: e.message);
    }
    if (!await binding.allowsConnect(workspaceId)) {
      return (mode: SignInMode.unavailable, error: '');
    }
    final config = await connect.usableConfig();
    final available = switch (lane) {
      ConnectOAuthLane.github => config?.github?.acceptsNewAuthorizations,
      ConnectOAuthLane.google => config?.google?.acceptsNewAuthorizations,
      ConnectOAuthLane.linear ||
      ConnectOAuthLane.linearApp => config?.linear?.acceptsNewAuthorizations,
      ConnectOAuthLane.slack => config?.slack?.acceptsNewAuthorizations,
    };
    return (
      mode: available ?? false ? SignInMode.connect : SignInMode.unavailable,
      error: '',
    );
  }

  /// Starts a sign-in for [userId] on [lane].
  ///
  /// [origin] is this server's advertised HTTP origin, needed for own-app
  /// redirects. Throws [AuthException] when the lane is unavailable.
  Future<SignInAttempt> begin({
    required ConnectOAuthLane lane,
    required String userId,
    required String origin,
    String? workspaceId,
    ConnectOAuthPurpose purpose = ConnectOAuthPurpose.signIn,
    int? installationId,
  }) async {
    final binding = _bindings[lane];
    if (binding == null) {
      throw AuthException('${lane.wire} sign-in is not available here.');
    }
    _evict();
    final pkce = PkcePair.generate();
    final slot = await binding.slotFor(workspaceId);
    final OwnOAuthApp? own;
    try {
      own = await binding.ownApp(workspaceId);
    } on SignInMisconfigured catch (e) {
      throw AuthException(e.message);
    }
    final SignInAttempt attempt;
    if (own != null) {
      if (origin.isEmpty) {
        throw const AuthException(
          'This server does not advertise a reachable URL, so a sign-in has '
          'nowhere to come back to.',
        );
      }
      final redirect = providerOAuthRedirectUri(origin, lane.wire);
      final state = b64url(randomBytes(32));
      final url = own.authorize.replace(
        queryParameters: {
          'client_id': own.clientId,
          'redirect_uri': redirect.toString(),
          'response_type': 'code',
          'state': state,
          'code_challenge': pkce.challenge,
          'code_challenge_method': 'S256',
          if (own.scopes.isNotEmpty)
            'scope': own.scopes.join(own.scopeSeparator),
          ...own.extraAuthorizeParams,
        },
      );
      attempt = SignInAttempt._(
        loginId: newLoginId(),
        lane: lane,
        mode: SignInMode.own,
        userId: userId,
        workspaceId: workspaceId,
        slot: slot,
        verifier: pkce.verifier,
        expiresAt: _now().add(pendingTtl),
        url: url,
        state: state,
        redirectUri: redirect,
        clientId: own.clientId,
      );
      _byState[state] = attempt.loginId;
    } else {
      final mode = await modeFor(lane, workspaceId: workspaceId);
      if (mode.mode != SignInMode.connect) {
        throw AuthException(
          mode.error.isNotEmpty
              ? mode.error
              : '${lane.wire} sign-in is not set up on this server. Turn on '
                    'Control Center Connect or add your own app in Settings.',
        );
      }
      final config = (await connect.usableConfig())!;
      final clientId = switch (lane) {
        ConnectOAuthLane.github => config.github!.clientId,
        ConnectOAuthLane.google => config.google!.clientId,
        ConnectOAuthLane.linear ||
        ConnectOAuthLane.linearApp => config.linear!.clientId,
        ConnectOAuthLane.slack => config.slack!.clientId,
      };
      final OAuthStartResponse started;
      try {
        started = await connect.startOAuth(
          lane,
          OAuthStartRequest(
            workspaceId: slot ?? globalWorkspaceScope,
            codeChallenge: pkce.challenge,
            purpose: purpose,
            installationId: installationId,
          ),
          expectedClientId: clientId,
        );
      } on ConnectException catch (e) {
        throw AuthException(_connectMessage(e.code));
      }
      final expires = started.expiresAt.isBefore(_now().add(pendingTtl))
          ? started.expiresAt
          : _now().add(pendingTtl);
      attempt = SignInAttempt._(
        loginId: started.loginId,
        lane: lane,
        mode: SignInMode.connect,
        userId: userId,
        workspaceId: workspaceId,
        slot: slot,
        verifier: pkce.verifier,
        expiresAt: expires,
        url: started.authorizeUrl,
        clientId: clientId,
      );
    }
    if (_attempts.length >= maxPending) {
      final oldest = _attempts.values.toList()
        ..sort((a, b) => a.expiresAt.compareTo(b.expiresAt));
      for (final stale in oldest.take(_attempts.length - maxPending + 1)) {
        _drop(stale);
      }
    }
    _attempts[attempt.loginId] = attempt;
    return attempt;
  }

  /// The caller's own attempt. Another person's login id reads as unknown.
  SignInAttempt status({
    required String loginId,
    required String userId,
    String? workspaceId,
  }) {
    final attempt = _attempts[loginId];
    if (attempt == null ||
        attempt.userId != userId ||
        attempt.workspaceId != workspaceId) {
      throw const AuthException('This sign-in is no longer valid.');
    }
    if (attempt.status == SignInStatus.pending &&
        !_now().isBefore(attempt.expiresAt)) {
      attempt
        ..status = SignInStatus.failed
        ..error = 'expired';
    }
    return attempt;
  }

  /// Finishes a Connect sign-in with the confirmation code the approving
  /// browser showed (typed, or carried by the deep link).
  Future<SignInAttempt> complete({
    required String loginId,
    required String confirmCode,
    required String userId,
    String? workspaceId,
  }) async {
    final attempt = status(
      loginId: loginId,
      userId: userId,
      workspaceId: workspaceId,
    );
    if (attempt.mode != SignInMode.connect) {
      throw const AuthException('This sign-in finishes in the browser.');
    }
    if (attempt.status != SignInStatus.pending) {
      return attempt;
    }
    final code = normaliseConfirmCode(confirmCode);
    if (code == null) {
      _countAttempt(attempt);
      throw const AuthException('That code is not valid. Check it and retry.');
    }
    // A login claims once at Connect: a second completion while the first is
    // in flight (the deep link and a typed code) would come back
    // `stale_request` and mark a succeeding sign-in failed.
    if (!_claiming.add(attempt.loginId)) {
      return attempt;
    }
    try {
      return await _claim(attempt, code);
    } finally {
      _claiming.remove(attempt.loginId);
    }
  }

  Future<SignInAttempt> _claim(SignInAttempt attempt, String code) async {
    final binding = _bindings[attempt.lane]!;
    final Map<String, Object?> claimed;
    try {
      claimed = await connect.claim(
        attempt.lane,
        OAuthClaimRequest(
          loginId: attempt.loginId,
          confirmCode: code,
          codeVerifier: attempt.verifier,
          workspaceId: attempt.slot ?? globalWorkspaceScope,
        ),
      );
    } on ConnectException catch (e) {
      // Connect answers a wrong code `access_denied` and counts it against
      // the same budget; anything that consumed the login answers
      // `stale_request` on the retry.
      if (e.code == ConnectErrorCode.invalidRequest ||
          e.code == ConnectErrorCode.accessDenied) {
        _countAttempt(attempt);
        if (attempt.status != SignInStatus.pending) {
          return attempt;
        }
        throw const AuthException(
          'That code did not match. Check it and retry.',
        );
      }
      attempt
        ..status = SignInStatus.failed
        ..error = e.code.wire;
      return attempt;
    }
    try {
      final ProviderToken token;
      SealedGrant? grant;
      switch (attempt.lane) {
        case ConnectOAuthLane.linear || ConnectOAuthLane.linearApp:
          // Connect relays only Linear's one-time code; this server exchanges
          // it directly, so Connect never sees a Linear token.
          final linear = LinearCodeGrant.fromJson(claimed);
          token = await _exchangeCode(
            lane: attempt.lane,
            tokenEndpoint: linearTokenEndpoint,
            clientId: attempt.clientId,
            clientSecret: '',
            code: linear.code,
            redirectUri: Uri.parse(linear.redirectUri),
            verifier: attempt.verifier,
            expectedScopes: linearConnectScopes,
            binding: binding,
          );
        default:
          grant = SealedGrant.fromJson(claimed);
          final installId = (await connect.identity())?.installId ?? '';
          final choice = await connect.settings.choice();
          token = ProviderToken(
            accessToken: grant.accessToken,
            expiresAt: grant.expiresAt,
            source: ForgeCredentialSource.connect,
            accountLogin: grant.accountLogin,
            accountId: grant.accountId,
            seal: grant.seal,
            sealInstallId: installId,
            connectOrigin: canonicalConnectBaseUrl(choice.baseUrl),
            appId: grant.appId,
          );
      }
      await binding.store(
        SignInResult(
          lane: attempt.lane,
          userId: attempt.userId,
          workspaceId: attempt.workspaceId,
          slot: attempt.slot,
          token: token,
          grant: grant,
        ),
      );
      attempt
        ..status = SignInStatus.succeeded
        ..account = token.accountLogin;
    } on FormatException {
      attempt
        ..status = SignInStatus.failed
        ..error = 'provider_unavailable';
    } on _ExchangeRefused catch (e) {
      attempt
        ..status = SignInStatus.failed
        ..error = e.code;
    }
    return attempt;
  }

  /// Completes an own-app sign-in from `/oauth/<lane>/callback`.
  ///
  /// Returns the attempt for the page the person is looking at. Throws
  /// [AuthException] with a reason worth reading.
  Future<SignInAttempt> handleCallback(Uri requestUri) async {
    final query = requestUri.queryParameters;
    final state = query['state'];
    // Single use: a replayed callback (history, a shared link, a logged
    // referrer) mints nothing.
    final loginId = state == null ? null : _byState.remove(state);
    final attempt = loginId == null ? null : _attempts[loginId];
    if (attempt == null || attempt.mode != SignInMode.own) {
      throw const AuthException('This sign-in link is no longer valid.');
    }
    final segments = requestUri.pathSegments;
    if (segments.length != 3 || segments[1] != attempt.lane.wire) {
      attempt
        ..status = SignInStatus.failed
        ..error = 'invalid_request';
      throw const AuthException('This sign-in link is no longer valid.');
    }
    if (!_now().isBefore(attempt.expiresAt)) {
      attempt
        ..status = SignInStatus.failed
        ..error = 'expired';
      throw const AuthException('This sign-in took too long — try again.');
    }
    final error = query['error'];
    final code = query['code'];
    if (error != null || code == null || code.isEmpty) {
      attempt
        ..status = SignInStatus.failed
        ..error = 'access_denied';
      throw const AuthException('The sign-in was cancelled or refused.');
    }
    final binding = _bindings[attempt.lane]!;
    final OwnOAuthApp? own;
    try {
      own = await binding.ownApp(attempt.workspaceId);
    } on SignInMisconfigured catch (e) {
      attempt
        ..status = SignInStatus.failed
        ..error = 'misconfigured';
      throw AuthException(e.message);
    }
    if (own == null || own.clientId != attempt.clientId) {
      attempt
        ..status = SignInStatus.failed
        ..error = 'misconfigured';
      throw const AuthException(
        'The app credentials changed while you were signing in.',
      );
    }
    try {
      final token = await _exchangeCode(
        lane: attempt.lane,
        tokenEndpoint: own.token,
        clientId: own.clientId,
        clientSecret: own.clientSecret,
        code: code,
        redirectUri: attempt.redirectUri!,
        verifier: attempt.verifier,
        expectedScopes: own.scopes,
        binding: binding,
      );
      await binding.store(
        SignInResult(
          lane: attempt.lane,
          userId: attempt.userId,
          workspaceId: attempt.workspaceId,
          slot: attempt.slot,
          token: token,
        ),
      );
      attempt
        ..status = SignInStatus.succeeded
        ..account = token.accountLogin;
      return attempt;
    } on _ExchangeRefused catch (e) {
      attempt
        ..status = SignInStatus.failed
        ..error = e.code;
      throw AuthException(e.message);
    }
  }

  /// Renews an expired credential for [lane].
  ///
  /// Sealed credentials refresh through the Connect that sealed them; own
  /// ones against the provider. Only a refused grant is [RefreshRejected]:
  /// everything transient is [RefreshUnavailable].
  Future<RefreshOutcome> refresh(
    ConnectOAuthLane lane,
    ProviderToken expired, {
    String? slot,
    String? workspaceId,
  }) async {
    if (expired.isSealed) {
      final choice = await connect.settings.choice();
      if (!choice.enabled ||
          canonicalConnectBaseUrl(choice.baseUrl) != expired.connectOrigin) {
        // Connect off or pointed elsewhere: the grant is fine, only
        // unreachable from here until the setting comes back.
        return const RefreshUnavailable();
      }
      try {
        final grant = await connect.refresh(
          lane.provider,
          SealRequest(
            seal: expired.seal,
            workspaceId: slot ?? globalWorkspaceScope,
          ),
        );
        return Refreshed(
          expired.copyWith(
            accessToken: grant.accessToken,
            expiresAt: grant.expiresAt,
            seal: grant.seal.isEmpty ? expired.seal : grant.seal,
            accountLogin: grant.accountLogin.isEmpty
                ? expired.accountLogin
                : grant.accountLogin,
          ),
        );
      } on ConnectException catch (e) {
        return e.code.clearsGrant
            ? const RefreshRejected()
            : const RefreshUnavailable();
      }
    }
    if (!expired.canRefresh) {
      return const RefreshRejected();
    }
    final binding = _bindings[lane];
    if (binding == null) {
      return const RefreshUnavailable();
    }
    OwnOAuthApp? own;
    try {
      own = await binding.ownApp(workspaceId);
    } on SignInMisconfigured {
      return const RefreshUnavailable();
    }
    var tokenEndpoint = own?.token;
    var clientId = own?.clientId ?? '';
    var clientSecret = own?.clientSecret ?? '';
    if (lane.provider == ConnectProvider.linear) {
      // Linear grants are public PKCE clients: the refresh needs only the
      // client id the grant was issued to, which may be Connect's.
      tokenEndpoint = linearTokenEndpoint;
      clientId = expired.appId.isNotEmpty ? expired.appId : clientId;
      clientSecret = own?.clientId == clientId ? own!.clientSecret : '';
      if (own == null) {
        // No own app answers here, so only Connect's client may renew: a
        // grant of an app no longer in force (removed, or a server app left
        // inactive by a Connect choice) must not keep refreshing.
        final connectClientId =
            (await connect.usableConfig())?.linear?.clientId;
        if (connectClientId == null) {
          return const RefreshUnavailable();
        }
        if (connectClientId != clientId) {
          return const RefreshRejected();
        }
      }
    }
    if (tokenEndpoint == null || clientId.isEmpty) {
      // The own app that issued this grant is gone; nothing can renew it.
      return const RefreshRejected();
    }
    if (own != null &&
        expired.appId.isNotEmpty &&
        own.clientId != expired.appId) {
      // The app was replaced (the server's, or the workspace's own); this
      // grant belongs to the old one and must not refresh under another.
      return const RefreshRejected();
    }
    try {
      final decoded = await _postToken(tokenEndpoint, {
        'grant_type': 'refresh_token',
        'refresh_token': expired.refreshToken,
        'client_id': clientId,
        if (clientSecret.isNotEmpty) 'client_secret': clientSecret,
      });
      final error = decoded['error'];
      if (error == 'invalid_grant') {
        return const RefreshRejected();
      }
      if (error != null) {
        return const RefreshUnavailable();
      }
      final fresh = _tokenFrom(decoded, appId: clientId);
      if (fresh == null) {
        return const RefreshUnavailable();
      }
      return Refreshed(
        fresh.copyWith(
          refreshToken: fresh.refreshToken.isEmpty
              ? expired.refreshToken
              : fresh.refreshToken,
          refreshExpiresAt: fresh.refreshExpiresAt ?? expired.refreshExpiresAt,
          accountLogin: expired.accountLogin,
          accountId: expired.accountId,
        ),
      );
    } on Object catch (e) {
      CcHostLog.warning('sign-in: ${lane.wire} refresh unavailable ($e)');
      return const RefreshUnavailable();
    }
  }

  /// Linear's token endpoint (public PKCE clients, own or Connect's).
  static final Uri linearTokenEndpoint = Uri.parse(
    'https://api.linear.app/oauth/token',
  );

  Future<ProviderToken> _exchangeCode({
    required ConnectOAuthLane lane,
    required Uri tokenEndpoint,
    required String clientId,
    required String clientSecret,
    required String code,
    required Uri redirectUri,
    required String verifier,
    required List<String> expectedScopes,
    required SignInLaneBinding binding,
  }) async {
    final Map<String, Object?> decoded;
    try {
      decoded = await _postToken(tokenEndpoint, {
        'grant_type': 'authorization_code',
        'code': code,
        'redirect_uri': redirectUri.toString(),
        'code_verifier': verifier,
        'client_id': clientId,
        if (clientSecret.isNotEmpty) 'client_secret': clientSecret,
      });
    } on Object {
      throw const _ExchangeRefused(
        'provider_unavailable',
        'The provider could not be reached. Try again.',
      );
    }
    final error = decoded['error'];
    if (error != null) {
      throw _ExchangeRefused(
        'exchange_failed',
        'The provider refused the sign-in ($error).',
      );
    }
    final token = _tokenFrom(decoded, appId: clientId);
    if (token == null) {
      throw const _ExchangeRefused(
        'exchange_failed',
        'The provider returned no token.',
      );
    }
    if (expectedScopes.isNotEmpty) {
      final raw = decoded['scope'];
      final granted = raw is List
          ? [for (final s in raw) '$s']
          : splitScopes(raw is String ? raw : null);
      if (!scopesExactlyMatch(granted, expectedScopes)) {
        throw const _ExchangeRefused(
          'scope_mismatch',
          'The provider granted different access than Control Center asks '
              'for, so the sign-in was refused. Try again and approve the '
              'requested access as shown.',
        );
      }
    }
    if (lane == ConnectOAuthLane.github) {
      // A GitHub App user token must expire; a non-expiring one would be a
      // standing credential nobody can rotate.
      if (!token.accessToken.startsWith('ghu_') || token.expiresAt == null) {
        throw const _ExchangeRefused(
          'exchange_failed',
          'This GitHub App issues tokens that never expire. Turn on '
              '"Expire user authorization tokens" in the app settings.',
        );
      }
    }
    final SignInIdentity who;
    try {
      who = await binding.identify(token.accessToken);
    } on Object {
      throw const _ExchangeRefused(
        'provider_unavailable',
        'The provider did not say who signed in. Try again.',
      );
    }
    if (who.id.isEmpty) {
      throw const _ExchangeRefused(
        'exchange_failed',
        'The provider did not say who signed in.',
      );
    }
    return token.copyWith(accountId: who.id, accountLogin: who.login);
  }

  ProviderToken? _tokenFrom(Map<String, Object?> decoded, {String appId = ''}) {
    final access = decoded['access_token'];
    if (access is! String || access.isEmpty) {
      return null;
    }
    final expiresIn = (decoded['expires_in'] as num?)?.toInt();
    final refreshExpiresIn = (decoded['refresh_token_expires_in'] as num?)
        ?.toInt();
    final refresh = decoded['refresh_token'];
    return ProviderToken(
      accessToken: access,
      refreshToken: refresh is String ? refresh : '',
      expiresAt: expiresIn == null
          ? null
          : _now().add(Duration(seconds: expiresIn)),
      refreshExpiresAt: refreshExpiresIn == null
          ? null
          : _now().add(Duration(seconds: refreshExpiresIn)),
      source: ForgeCredentialSource.oauth,
      appId: appId,
      issuedAt: _now(),
    );
  }

  Future<Map<String, Object?>> _postToken(
    Uri url,
    Map<String, String> body,
  ) async {
    final request = await _http.postUrl(url);
    // A 307/308 would re-POST the code and the client secret elsewhere.
    request.followRedirects = false;
    request.headers.contentType = ContentType(
      'application',
      'x-www-form-urlencoded',
    );
    request.headers.set(HttpHeaders.acceptHeader, 'application/json');
    request.write(Uri(queryParameters: body).query);
    final response = await request.close().timeout(_httpTimeout);
    final raw = await _readBounded(response);
    Object? decoded;
    try {
      decoded = jsonDecode(raw);
    } on FormatException {
      decoded = null;
    }
    if (decoded is Map<String, Object?>) {
      if (response.statusCode >= 500) {
        throw HttpException('HTTP ${response.statusCode}');
      }
      return decoded;
    }
    throw HttpException('HTTP ${response.statusCode}');
  }

  static Future<String> _readBounded(HttpClientResponse response) async {
    final chunks = <int>[];
    await for (final chunk in response.timeout(_httpTimeout)) {
      chunks.addAll(chunk);
      if (chunks.length > _maxResponseBytes) {
        throw const HttpException('oversized reply');
      }
    }
    return utf8.decode(chunks, allowMalformed: true);
  }

  void _countAttempt(SignInAttempt attempt) {
    attempt._attempts++;
    if (attempt._attempts >= maxConfirmAttempts) {
      attempt
        ..status = SignInStatus.failed
        ..error = 'invalid_code';
    }
  }

  void _drop(SignInAttempt attempt) {
    _attempts.remove(attempt.loginId);
    if (attempt.state.isNotEmpty) {
      _byState.remove(attempt.state);
    }
  }

  void _evict() {
    // Keep finished attempts until their expiry so a client cannot miss the
    // outcome; drop everything past it.
    final now = _now();
    for (final attempt in _attempts.values.toList()) {
      if (now.isAfter(attempt.expiresAt.add(const Duration(minutes: 5)))) {
        _drop(attempt);
      }
    }
  }

  static String _connectMessage(ConnectErrorCode code) => switch (code) {
    ConnectErrorCode.installBlocked =>
      'Control Center Connect refused this server. Check Settings → Connect.',
    ConnectErrorCode.rateLimited =>
      'Too many sign-ins right now. Try again in a minute.',
    ConnectErrorCode.accessDenied =>
      'Control Center Connect answered with an unexpected sign-in link, so '
          'it was not opened.',
    _ => 'Control Center Connect is unreachable right now. Try again shortly.',
  };
}

final class _ExchangeRefused implements Exception {
  const _ExchangeRefused(this.code, this.message);

  final String code;
  final String message;
}
