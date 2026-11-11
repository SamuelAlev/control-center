import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cc_connect_core/cc_connect_core.dart';
import 'package:cc_domain/cc_domain.dart' show AuthException;
import 'package:cc_domain/core/domain/value_objects/forge_connection.dart';
import 'package:cc_server_core/src/connect/bounded_body.dart';
import 'package:cc_server_core/src/connect/connect_client.dart';
import 'package:cc_server_core/src/connect/connect_error_messages.dart';
import 'package:cc_server_core/src/connect/connect_settings.dart';
import 'package:cc_server_core/src/forge/forge_audit.dart';
import 'package:cc_server_core/src/identity/provider_token.dart';

part 'connect_sign_in.dart';
part 'own_oauth_client.dart';
part 'sign_in_attempts.dart';
part 'sign_in_types.dart';

/// The HTTP origin of this server's public [url] (`wss://host:9030` →
/// `https://host:9030`), or empty when it has none: where own-app OAuth
/// redirects and the embedded Connect are served.
String providerOAuthHttpOrigin(String url) {
  final uri = Uri.tryParse(url.trim());
  if (url.trim().isEmpty || uri == null || uri.host.isEmpty) {
    return '';
  }
  final scheme = uri.scheme == 'wss' || uri.scheme == 'https'
      ? 'https'
      : 'http';
  return Uri(scheme: scheme, host: uri.host, port: uri.port).toString();
}

/// This server's callback URL for an own-app [lane], under an HTTP [origin]
/// (`https://host:9030`).
///
/// One function, called both where the authorize URL is built and where the
/// redirect lands: OAuth compares the two strings exactly. It is also what the
/// operator registers with the provider, so Settings shows it verbatim.
Uri providerOAuthRedirectUri(String origin, String lane) =>
    Uri.parse('$origin/oauth/$lane/callback');

/// What the own-app callback page shows: the confirmation code and the local
/// deep link that hands it to the client that started the sign-in.
typedef SignInCallbackPage = ({String loginId, String confirmCode, Uri link});

/// Runs every browser sign-in this server offers (GitHub, Google, Linear,
/// Linear app, Slack), in own-app or Connect mode.
///
/// Both modes end the same way. The browser shows an eight-character
/// confirmation code (and a `control-center://oauth-done` link carrying it);
/// nothing is stored until the session that began the attempt (same person,
/// same workspace) presents that code with `oauth.complete`. The code goes
/// from the browser to the client, never the other way, so a sign-in link
/// sent to somebody else cannot land their account in the sender's slot.
///
/// * Own app: the provider redirects to `/oauth/<lane>/callback` with a
///   single-use `state`. The callback only records the provider's code; the
///   code is exchanged when the confirmation code comes back.
/// * Connect: Connect's `/done` page first says what this server will be
///   able to do and asks the person to continue, then shows the code; the
///   claim carries it with this server's PKCE verifier and its signed
///   install identity.
///
/// One provider account acts for one person: a grant for an account another
/// user already holds is refused and revoked.
class ProviderSignInService {
  /// Creates the service.
  ProviderSignInService({
    required ConnectClient connect,
    HttpClient? httpClient,
    DateTime Function()? now,
  }) : this._(
         connect,
         httpClient ?? (HttpClient()..connectionTimeout = _httpTimeout),
         now ?? (() => DateTime.now().toUtc()),
       );

  ProviderSignInService._(this.connect, HttpClient http, this._now)
    : _oauth = _OwnOAuthClient(http, _now),
      _attempts = SignInAttemptStore(now: _now);

  static const Duration _httpTimeout = Duration(seconds: 15);

  /// How long an attempt stays completable.
  static const Duration pendingTtl = Duration(minutes: 10);

  /// Wrong confirmation codes before an attempt is over.
  static const int maxConfirmAttempts = 5;

  /// Linear's token endpoint (public PKCE clients, own or Connect's).
  static final Uri linearTokenEndpoint = Uri.parse(
    'https://api.linear.app/oauth/token',
  );

  /// The Connect client.
  final ConnectClient connect;

  final DateTime Function() _now;
  final _OwnOAuthClient _oauth;
  final SignInAttemptStore _attempts;
  final Map<ConnectOAuthLane, SignInLaneBinding> _bindings = {};
  final Set<String> _claiming = {};

  /// Registers a lane. Each lane has exactly one binding.
  void register(SignInLaneBinding binding) {
    _bindings[binding.lane] = binding;
  }

  /// The lane's binding, when registered.
  SignInLaneBinding? binding(ConnectOAuthLane lane) => _bindings[lane];

  /// Every registered lane.
  Iterable<SignInLaneBinding> get bindings => _bindings.values;

  /// How [lane] signs in for [workspaceId] right now; when it cannot, why
  /// ([SignInUnavailableReason]) and, for a misconfigured own app, the setup
  /// error to show.
  Future<SignInLaneState> modeFor(
    ConnectOAuthLane lane, {
    String? workspaceId,
  }) async {
    final binding = _bindings[lane];
    if (binding == null) {
      return const SignInLaneState.unavailable(
        SignInUnavailableReason.laneNotOffered,
      );
    }
    try {
      if (await binding.ownApp(workspaceId) != null) {
        return const SignInLaneState(SignInLaneMode.own);
      }
    } on SignInMisconfigured catch (e) {
      return SignInLaneState.unavailable(
        SignInUnavailableReason.misconfigured,
        error: e.message,
      );
    }
    final route = await connect.routeFor(workspaceId);
    if (!await binding.allowsConnect(workspaceId)) {
      return SignInLaneState.unavailable(
        route.workspaceOwnApps
            ? SignInUnavailableReason.ownAppMissing
            : SignInUnavailableReason.laneNotOffered,
      );
    }
    if (route.blockedByEnvironment) {
      return const SignInLaneState.unavailable(
        SignInUnavailableReason.blockedByEnvironment,
      );
    }
    if (route.connectUrlInvalid) {
      return const SignInLaneState.unavailable(
        SignInUnavailableReason.connectUrlInvalid,
      );
    }
    if (!route.target.enabled) {
      // The server on its own apps without one for this lane, or no Connect
      // chosen at all.
      return const SignInLaneState.unavailable(
        SignInUnavailableReason.notConfigured,
      );
    }
    final config = await connect.usableConfig(route.target);
    if (config == null) {
      final state = await connect.configState(route.target);
      return SignInLaneState.unavailable(switch (state) {
        ConnectConfigState(pendingPins: _?) =>
          SignInUnavailableReason.connectPinsPending,
        ConnectConfigState(error: 'hosted_unprovisioned') =>
          SignInUnavailableReason.connectUnprovisioned,
        _ => SignInUnavailableReason.connectUnreachable,
      });
    }
    final available = switch (lane) {
      ConnectOAuthLane.github => config.github?.acceptsNewAuthorizations,
      ConnectOAuthLane.google => config.google?.acceptsNewAuthorizations,
      ConnectOAuthLane.linear ||
      ConnectOAuthLane.linearApp => config.linear?.acceptsNewAuthorizations,
      ConnectOAuthLane.slack => config.slack?.acceptsNewAuthorizations,
    };
    return available ?? false
        ? const SignInLaneState(SignInLaneMode.connect)
        : const SignInLaneState.unavailable(
            SignInUnavailableReason.laneNotOffered,
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
  }) async {
    final binding = _bindings[lane];
    if (binding == null) {
      throw AuthException('${lane.wire} sign-in is not available here.');
    }
    final pkce = PkcePair.generate();
    final slot = await binding.slotFor(workspaceId);
    final OwnOAuthApp? own;
    try {
      own = await binding.ownApp(workspaceId);
    } on SignInMisconfigured catch (e) {
      throw AuthException(e.message);
    }
    final attempt = own != null
        ? _beginOwn(own, lane, userId, workspaceId, slot, pkce, origin)
        : await _beginConnect(lane, userId, workspaceId, slot, pkce);
    _attempts.add(attempt);
    forgeAudit(ForgeAuditEvent.signinBegun, {
      'lane': lane.wire,
      'mode': attempt.mode.name,
      'user_id': userId,
      'workspace_id': workspaceId,
      'attempt': attempt.loginId,
      'expires_s': attempt.expiresAt.difference(_now()).inSeconds,
    });
    return attempt;
  }

  SignInAttempt _beginOwn(
    OwnOAuthApp own,
    ConnectOAuthLane lane,
    String userId,
    String? workspaceId,
    String? slot,
    PkcePair pkce,
    String origin,
  ) {
    if (origin.isEmpty) {
      throw const AuthException(
        'This server does not advertise a reachable URL, so a sign-in has '
        'nowhere to come back to.',
      );
    }
    final redirect = providerOAuthRedirectUri(origin, lane.wire);
    final state = b64url(randomBytes(32));
    return SignInAttempt._(
      loginId: newLoginId(),
      lane: lane,
      mode: SignInLaneMode.own,
      userId: userId,
      workspaceId: workspaceId,
      slot: slot,
      verifier: pkce.verifier,
      expiresAt: _now().add(pendingTtl),
      url: own.authorize.replace(
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
      ),
      state: state,
      redirectUri: redirect,
      clientId: own.clientId,
    );
  }

  /// The caller's own attempt. Another person's login id reads as unknown.
  SignInAttempt status({
    required String loginId,
    required String userId,
    String? workspaceId,
  }) {
    final attempt = lookup(
      loginId: loginId,
      userId: userId,
      workspaceId: workspaceId,
    );
    if (attempt == null) {
      throw const AuthException('This sign-in is no longer valid.');
    }
    return attempt;
  }

  /// Like [status], but null for an attempt this server does not know (a
  /// restart, an eviction, another person's or another workspace's login
  /// id), so `oauth.status` can answer it as failed
  /// ([unknownSignInAttemptJson]).
  SignInAttempt? lookup({
    required String loginId,
    required String userId,
    String? workspaceId,
  }) {
    final attempt = _attempts[loginId];
    if (attempt == null ||
        attempt.userId != userId ||
        attempt.workspaceId != workspaceId) {
      return null;
    }
    if (attempt.status == SignInAttemptStatus.pending &&
        !_now().isBefore(attempt.expiresAt) &&
        // A code that matched is being exchanged; its outcome ends it.
        !_claiming.contains(loginId)) {
      return _fail(attempt, SignInFailure.expired, reason: 'expired');
    }
    return attempt;
  }

  /// The wire shape of an attempt this server does not know: failed with
  /// [SignInFailure.attemptUnknown], so the client stops waiting and offers
  /// a new sign-in instead of an error. [lane] is the one the client says
  /// it started, when it says.
  Map<String, Object?> unknownSignInAttemptJson(
    String loginId, {
    ConnectOAuthLane? lane,
  }) => {
    'login_id': loginId,
    'lane': ?lane?.wire,
    'mode': SignInLaneMode.unavailable.name,
    'url': '',
    'expires_at': _now().toIso8601String(),
    'status': SignInAttemptStatus.failed.wire,
    'error': SignInFailure.attemptUnknown.wire,
  };

  /// Finishes a sign-in with the confirmation code the browser showed
  /// (typed, or carried by the deep link), from the session that began it.
  ///
  /// A wrong code is not an exception: the attempt comes back pending with
  /// [SignInAttempt.codeError] set, or failed with
  /// [SignInFailure.invalidCode] once the codes ran out. A code typed before
  /// the browser came back counts as wrong.
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
    if (attempt.status != SignInAttemptStatus.pending) {
      return attempt;
    }
    final code = normaliseConfirmCode(confirmCode);
    if (code == null) {
      return _wrongCode(attempt, 'malformed');
    }
    // One completion at a time: a second one while the first is in flight
    // (the deep link and a typed code) would spend the login twice.
    if (!_claiming.add(loginId)) {
      return attempt;
    }
    try {
      final current =
          _attempts.update(loginId, (a) => a._copy(clearCodeError: true)) ??
          attempt;
      return attempt.mode == SignInLaneMode.own
          ? await _completeOwn(current, code)
          : await _claimConnect(
              current,
              code,
              deferred: attempt.codeError == SignInFailure.rateLimited,
            );
    } finally {
      _claiming.remove(loginId);
    }
  }

  Future<SignInAttempt> _completeOwn(SignInAttempt attempt, String code) async {
    if (!attempt.callbackSeen) {
      return _wrongCode(attempt, 'browser_not_back');
    }
    if (!_sameCode(code, attempt.confirmCode)) {
      return _wrongCode(attempt, 'mismatch');
    }
    final binding = _bindings[attempt.lane]!;
    final OwnOAuthApp? own;
    try {
      own = await binding.ownApp(attempt.workspaceId);
    } on SignInMisconfigured catch (e) {
      return _fail(
        attempt,
        SignInFailure.misconfigured,
        message: e.message,
        reason: 'misconfigured',
      );
    }
    if (own == null || own.clientId != attempt.clientId) {
      return _fail(
        attempt,
        SignInFailure.misconfigured,
        message: 'The app credentials changed while you were signing in.',
        reason: 'app_changed',
      );
    }
    try {
      final token = await _oauth.exchange(
        lane: attempt.lane,
        tokenEndpoint: own.token,
        clientId: own.clientId,
        clientSecret: own.clientSecret,
        code: attempt.providerCode,
        redirectUri: attempt.redirectUri!,
        verifier: attempt.verifier,
        expectedScopes: own.scopes,
        binding: binding,
      );
      return await _finish(attempt, binding, _resultOf(attempt, token));
    } on _ExchangeRefused catch (e) {
      return _fail(
        attempt,
        e.code,
        message: e.message,
        reason: e.reason,
        requestId: e.requestId,
      );
    }
  }

  /// Records the provider's redirect to `/oauth/<lane>/callback` for an
  /// own-app attempt and returns what the page shows. Nothing is exchanged
  /// or stored here: the request is unauthenticated, and only the session
  /// that began the attempt may finish it with the code this returns.
  ///
  /// Throws [AuthException] with a fixed message (never anything from the
  /// request).
  SignInCallbackPage handleCallback(Uri requestUri) {
    final query = requestUri.queryParameters;
    final state = query['state'];
    // Single use: a replayed callback (history, a shared link, a logged
    // referrer) finds nothing.
    final loginId = state == null || state.length > 128
        ? null
        : _attempts.takeState(state);
    final attempt = loginId == null ? null : _attempts[loginId];
    if (attempt == null ||
        attempt.mode != SignInLaneMode.own ||
        attempt.status != SignInAttemptStatus.pending ||
        attempt.callbackSeen) {
      forgeAudit(ForgeAuditEvent.signinCallbackRefused, {
        'reason': 'unknown_state',
      });
      throw const AuthException('This sign-in link is no longer valid.');
    }
    final segments = requestUri.pathSegments;
    if (segments.length != 3 || segments[1] != attempt.lane.wire) {
      _refuseCallback(attempt, SignInFailure.invalidRequest, 'lane_mismatch');
      throw const AuthException('This sign-in link is no longer valid.');
    }
    if (!_now().isBefore(attempt.expiresAt)) {
      _refuseCallback(attempt, SignInFailure.expired, 'expired');
      throw const AuthException('This sign-in took too long. Try again.');
    }
    final error = query['error'];
    final code = query['code'];
    if (error != null || code == null || code.isEmpty) {
      final shaped = _OwnOAuthClient._oauthError(error);
      _refuseCallback(
        attempt,
        SignInFailure.accessDenied,
        shaped == null ? 'no_code' : 'provider_error:$shaped',
      );
      throw const AuthException('The sign-in was cancelled or refused.');
    }
    if (code.length > 2048) {
      _refuseCallback(attempt, SignInFailure.invalidRequest, 'code_too_long');
      throw const AuthException('This sign-in link is no longer valid.');
    }
    final confirm = newConfirmCode();
    _attempts.update(
      attempt.loginId,
      (a) => a._copy(providerCode: code, confirmCode: confirm),
    );
    return (
      loginId: attempt.loginId,
      confirmCode: confirm,
      link: oauthDoneDeepLink(loginId: attempt.loginId, code: confirm),
    );
  }

  void _refuseCallback(
    SignInAttempt attempt,
    SignInFailure failure,
    String reason,
  ) {
    forgeAudit(ForgeAuditEvent.signinCallbackRefused, {
      'lane': attempt.lane.wire,
      'user_id': attempt.userId,
      'attempt': attempt.loginId,
      'reason': reason,
    });
    _fail(attempt, failure, reason: reason);
  }

  /// Renews an expired credential for [lane].
  ///
  /// Sealed credentials refresh through the Connect that sealed them, and
  /// only while that is still the Connect [workspaceId] (the credential's
  /// slot; null for the server-wide one) routes through; own ones against
  /// the provider. Only a refused grant is [RefreshRejected]: everything
  /// transient is [RefreshUnavailable].
  Future<RefreshOutcome> refresh(
    ConnectOAuthLane lane,
    ProviderToken expired, {
    String? slot,
    String? workspaceId,
  }) async {
    if (expired.isSealed) {
      return _refreshSealed(
        lane,
        expired,
        slot: slot,
        workspaceId: workspaceId,
      );
    }
    RefreshOutcome refused(RefreshOutcome outcome, String reason) {
      forgeAudit(
        outcome is RefreshRejected
            ? ForgeAuditEvent.grantRefreshRejected
            : ForgeAuditEvent.grantRefreshUnavailable,
        {'lane': lane.wire, 'path': 'own', 'reason': reason},
      );
      return outcome;
    }

    if (!expired.canRefresh) {
      return refused(const RefreshRejected(), 'no_refresh_token');
    }
    final binding = _bindings[lane];
    if (binding == null) {
      return refused(const RefreshUnavailable(), 'lane_not_registered');
    }
    OwnOAuthApp? own;
    try {
      own = await binding.ownApp(workspaceId);
    } on SignInMisconfigured {
      return refused(const RefreshUnavailable(), 'misconfigured');
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
        final connectClientId = (await connect.usableConfig(
          await connect.targetFor(workspaceId),
        ))?.linear?.clientId;
        if (connectClientId == null) {
          return refused(const RefreshUnavailable(), 'connect_unavailable');
        }
        if (connectClientId != clientId) {
          return refused(const RefreshRejected(), 'app_changed');
        }
      }
    }
    if (tokenEndpoint == null || clientId.isEmpty) {
      // The own app that issued this grant is gone; nothing can renew it.
      return refused(const RefreshRejected(), 'app_removed');
    }
    if (own != null &&
        expired.appId.isNotEmpty &&
        own.clientId != expired.appId) {
      // The app was replaced (the server's, or the workspace's own); this
      // grant belongs to the old one and must not refresh under another.
      return refused(const RefreshRejected(), 'app_changed');
    }
    return _oauth.refresh(
      lane,
      expired,
      tokenEndpoint: tokenEndpoint,
      clientId: clientId,
      clientSecret: clientSecret,
    );
  }

  /// Stores a finished sign-in once nothing stands against it: the provider
  /// account is not another person's here, and the attempt is still the
  /// caller's to finish. A grant this server does not keep is revoked.
  Future<SignInAttempt> _finish(
    SignInAttempt attempt,
    SignInLaneBinding binding,
    SignInResult result,
  ) async {
    final token = result.token;
    if (token.accountId.isNotEmpty) {
      final others = (await binding.accountHolders(token.accountId))
        ..remove(attempt.userId);
      if (others.isNotEmpty) {
        forgeAudit(ForgeAuditEvent.signinAccountAlreadyBound, {
          'lane': attempt.lane.wire,
          'user_id': attempt.userId,
          'attempt': attempt.loginId,
        });
        await _revokeUnkept(attempt, binding, result, 'account_already_bound');
        return _fail(
          attempt,
          SignInFailure.accountAlreadyBound,
          message:
              'This account is already connected to another person on this '
              'server. An account can act for one person only.',
          reason: 'account_already_bound',
        );
      }
    }
    if (_attempts[attempt.loginId]?.status != SignInAttemptStatus.pending) {
      // Ended while the grant was on its way: nobody will use it.
      await _revokeUnkept(attempt, binding, result, 'attempt_ended');
      return _attempts[attempt.loginId] ?? attempt;
    }
    try {
      await binding.store(result);
    } on Object catch (e) {
      await _revokeUnkept(attempt, binding, result, 'store_failed');
      return _fail(
        attempt,
        SignInFailure.storeFailed,
        reason: 'store_failed:${errorKindOf(e)}',
      );
    }
    final done = _attempts.update(
      attempt.loginId,
      (a) => a._succeeded(token.accountLogin),
    );
    forgeAudit(ForgeAuditEvent.signinCompleted, {
      'lane': attempt.lane.wire,
      'mode': attempt.mode.name,
      'user_id': attempt.userId,
      'workspace_id': attempt.workspaceId,
      'slot': result.slot == null ? 'global' : 'workspace',
      'attempt': attempt.loginId,
      'account_id': token.accountId,
    }, token: token.accessToken);
    return done ?? _attempts[attempt.loginId] ?? attempt;
  }

  SignInResult _resultOf(
    SignInAttempt attempt,
    ProviderToken token, {
    SealedGrant? grant,
  }) => SignInResult(
    lane: attempt.lane,
    userId: attempt.userId,
    workspaceId: attempt.workspaceId,
    slot: attempt.slot,
    token: token,
    grant: grant,
    target: attempt.target,
  );

  /// Revokes a grant this server obtained but does not keep, best effort:
  /// a sealed one at its Connect, an own one with the app that issued it.
  Future<void> _revokeUnkept(
    SignInAttempt attempt,
    SignInLaneBinding binding,
    SignInResult result,
    String why,
  ) async {
    final token = result.token;
    try {
      if (!token.isSealed) {
        await binding.revokeOwnGrant(token, result.slot);
        return;
      }
      final request = SealRequest(
        seal: token.seal,
        workspaceId: result.slot ?? globalWorkspaceScope,
      );
      switch (attempt.lane) {
        case ConnectOAuthLane.github:
          await connect.githubRevoke(
            result.target,
            GitHubRevokeRequest(
              workspaceId: request.workspaceId,
              seal: token.seal,
            ),
          );
        case ConnectOAuthLane.slack:
          await connect.slackRevoke(result.target, request);
        case ConnectOAuthLane.google ||
            ConnectOAuthLane.linear ||
            ConnectOAuthLane.linearApp:
          forgeAudit(ForgeAuditEvent.grantRevokeSkipped, {
            'lane': attempt.lane.wire,
            'reason': 'no_revoke_endpoint',
            'why': why,
          });
      }
    } on ConnectException catch (e) {
      forgeAudit(ForgeAuditEvent.grantRevokeSkipped, {
        'lane': attempt.lane.wire,
        'reason': 'connect:${e.code.wire}',
        'why': why,
      });
    } on Object catch (e) {
      forgeAudit(ForgeAuditEvent.grantRevokeSkipped, {
        'lane': attempt.lane.wire,
        'reason': 'revoke_failed:${errorKindOf(e)}',
        'why': why,
      });
    }
  }

  SignInAttempt _wrongCode(SignInAttempt attempt, String reason) {
    final next =
        _attempts.update(
          attempt.loginId,
          (a) => a._wrongCode(maxConfirmAttempts),
        ) ??
        _attempts[attempt.loginId] ??
        attempt;
    forgeAudit(ForgeAuditEvent.signinCodeRejected, {
      'lane': attempt.lane.wire,
      'user_id': attempt.userId,
      'attempt': attempt.loginId,
      'tries': next.wrongCodes,
      'reason': reason,
    });
    if (next.status == SignInAttemptStatus.failed) {
      forgeAudit(ForgeAuditEvent.signinFailed, {
        'lane': attempt.lane.wire,
        'user_id': attempt.userId,
        'attempt': attempt.loginId,
        'reason': 'invalid_code',
      });
    }
    return next;
  }

  /// Ends [attempt] as failed (if it is still pending) and logs why.
  SignInAttempt _fail(
    SignInAttempt attempt,
    SignInFailure failure, {
    required String reason,
    String message = '',
    String requestId = '',
  }) {
    final next = _attempts.update(
      attempt.loginId,
      (a) => a._failed(failure, message: message),
    );
    if (next != null) {
      forgeAudit(ForgeAuditEvent.signinFailed, {
        'lane': attempt.lane.wire,
        'mode': attempt.mode.name,
        'user_id': attempt.userId,
        'workspace_id': attempt.workspaceId,
        'attempt': attempt.loginId,
        'error': failure.wire,
        'reason': reason,
        'upstream_request_id': requestId.isEmpty ? null : requestId,
      });
    }
    return next ?? _attempts[attempt.loginId] ?? attempt;
  }

  /// Compares two confirmation codes in time independent of where they
  /// differ.
  static bool _sameCode(String a, String b) {
    if (a.isEmpty || a.length != b.length) {
      return false;
    }
    var diff = 0;
    for (var i = 0; i < a.length; i++) {
      diff |= a.codeUnitAt(i) ^ b.codeUnitAt(i);
    }
    return diff == 0;
  }
}

/// A closed, log-safe name for what kind of error [e] is: never its message,
/// which may quote a provider body or a credential.
String errorKindOf(Object e) => switch (e) {
  TimeoutException() => 'timeout',
  SocketException() || HttpException() => 'network',
  FileSystemException() => 'filesystem',
  FormatException() => 'format',
  AuthException() => 'refused',
  ConnectException(:final code) => 'connect:${code.wire}',
  _ => 'error',
};
