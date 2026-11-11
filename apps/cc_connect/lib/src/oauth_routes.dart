import 'dart:convert';
import 'dart:io';

import 'package:cc_connect/src/binding_store.dart';
import 'package:cc_connect/src/connect_log.dart';
import 'package:cc_connect/src/context.dart';
import 'package:cc_connect/src/credential_seal.dart';
import 'package:cc_connect/src/grant_routes.dart';
import 'package:cc_connect/src/http_io.dart';
import 'package:cc_connect/src/pages.dart';
import 'package:cc_connect/src/provider_slack.dart';
import 'package:cc_connect/src/provider_support.dart';
import 'package:cc_connect/src/quota.dart';
import 'package:cc_connect/src/service_config.dart' show SlackCredentials;
import 'package:cc_connect_core/cc_connect_core.dart';
import 'package:crypto/crypto.dart' as crypto;

const ConnectException _denied = ConnectException(
  ConnectErrorCode.accessDenied,
);
const ConnectException _mismatch = ConnectException(
  ConnectErrorCode.codeMismatch,
);
const ConnectException _stale = ConnectException(ConnectErrorCode.staleRequest);
const ConnectException _invalid = ConnectException(
  ConnectErrorCode.invalidRequest,
);
const ConnectException _unavailable = ConnectException(
  ConnectErrorCode.providerUnavailable,
);

final RegExp _opaqueToken = RegExp(r'^[A-Za-z0-9_-]{43}$');

String _sha(String value) =>
    crypto.sha256.convert(utf8.encode(value)).toString();

/// The browser OAuth flow shared by every lane: `/v1/oauth/{lane}/start`,
/// the provider callbacks, `/done`, `/v1/oauth/{lane}/claim`, and GitHub's
/// post-install `/oauth/github/setup`.
final class OAuthRoutes {
  /// Creates the routes.
  OAuthRoutes(this.ctx);

  /// The shared context.
  final ConnectContext ctx;

  String get _base => ctx.config.publicBaseUrl;

  Uri _callback(String segment) => connectCallbackUri(_base, segment);

  // ------------------------------------------------------------------ start

  /// `POST /v1/oauth/{lane}/start`.
  Future<Object?> start(
    ConnectCaller caller,
    ConnectOAuthLane lane,
    Map<String, Object?> body,
  ) async {
    final OAuthStartRequest request;
    try {
      request = OAuthStartRequest.fromJson(body);
    } on FormatException {
      throw _invalid;
    }
    if (!isPkceChallenge(request.codeChallenge)) {
      throw _invalid;
    }
    final hint = request.loginHint;
    if (hint.isNotEmpty &&
        (lane != ConnectOAuthLane.google ||
            hint.length > 254 ||
            !RegExp(r'^[^\s@<>"]+@[^\s@<>"]+$').hasMatch(hint))) {
      throw _invalid;
    }
    final (clientId, accepts) = switch (lane) {
      ConnectOAuthLane.github => await ctx.githubLane().then(
        (l) => (l.$2.clientId, l.$1.acceptsNewAuthorizations),
      ),
      ConnectOAuthLane.google => await ctx.googleLane().then(
        (l) => (l.$2.clientId, l.$1.acceptsNewAuthorizations),
      ),
      ConnectOAuthLane.linear ||
      ConnectOAuthLane.linearApp => await ctx.linearLane().then(
        (l) => (l.$2.clientId, l.$1.acceptsNewAuthorizations),
      ),
      ConnectOAuthLane.slack => await ctx.slackLane().then(
        (l) => (l.$2.clientId, l.$1.acceptsNewAuthorizations),
      ),
    };
    if (!accepts) {
      throw _unavailable;
    }
    // Logins live [loginTtl], so this also caps the logins one address has
    // outstanding (up to twice the limit across a window boundary).
    await ctx.quotas.admit([
      Quota(
        'logins_ip',
        caller.address,
        window: loginTtl,
        limit: ctx.config.rateLimits.loginsPerIpPer10Minutes,
        logFields: {'ip': caller.network},
      ),
    ]);
    final login = StagedLogin(
      id: newLoginId(),
      lane: lane,
      installId: caller.installId,
      workspaceId: request.workspaceId,
      codeChallenge: request.codeChallenge,
      confirmCode: newConfirmCode(),
      expiresAt: ctx.now().add(loginTtl),
      startNetwork: caller.network,
      oidcNonce: lane == ConnectOAuthLane.slack ? b64url(randomBytes(16)) : '',
    );
    final state = b64url(randomBytes(32));
    if (!await ctx.saveLogin(login)) {
      // A login id collision: never overwrite somebody's login.
      throw _unavailable;
    }
    await ctx.state.set(
      'state:$state',
      jsonEncode({'login': login.id, 'hop': ConnectCallbackHop.first.wire}),
      loginTtl,
    );
    final url = _authorizeUrl(
      lane: lane,
      clientId: clientId,
      state: state,
      login: login,
      loginHint: hint,
    );
    // Self-check with the exact validator every server runs before it shows
    // the URL: a Connect that builds a URL its servers refuse is broken.
    try {
      validateAuthorizeUrl(
        lane: lane,
        url: url,
        connectBaseUrl: _base,
        expectedClientId: clientId,
        codeChallenge: request.codeChallenge,
      );
    } on AuthorizeUrlRejected {
      ctx.log.event('oauth.url_self_check_failed', {'lane': lane.wire});
      throw _unavailable;
    }
    ctx.log.event('oauth.started', {
      'lane': lane.wire,
      'install': ctx.log.tag(caller.installId),
    });
    return OAuthStartResponse(
      loginId: login.id,
      authorizeUrl: url,
      expiresAt: login.expiresAt,
    ).toJson();
  }

  Uri _authorizeUrl({
    required ConnectOAuthLane lane,
    required String clientId,
    required String state,
    required StagedLogin login,
    required String loginHint,
  }) {
    final redirect = _callback(lane.firstCallbackSegment).toString();
    switch (lane) {
      case ConnectOAuthLane.github:
        return Uri.https('github.com', '/login/oauth/authorize', {
          'client_id': clientId,
          'redirect_uri': redirect,
          'response_type': 'code',
          'state': state,
          'code_challenge': login.codeChallenge,
          'code_challenge_method': 'S256',
          'prompt': 'select_account',
        });
      case ConnectOAuthLane.google:
        return Uri.https('accounts.google.com', '/o/oauth2/v2/auth', {
          'client_id': clientId,
          'redirect_uri': redirect,
          'response_type': 'code',
          'scope': googleConnectScopes.join(' '),
          'state': state,
          'code_challenge': login.codeChallenge,
          'code_challenge_method': 'S256',
          'access_type': 'offline',
          'prompt': 'consent select_account',
          'include_granted_scopes': 'false',
          if (loginHint.isNotEmpty) 'login_hint': loginHint,
        });
      case ConnectOAuthLane.linear || ConnectOAuthLane.linearApp:
        return Uri.https('linear.app', '/oauth/authorize', {
          'client_id': clientId,
          'redirect_uri': redirect,
          'response_type': 'code',
          'scope': linearConnectScopes.join(','),
          'state': state,
          'code_challenge': login.codeChallenge,
          'code_challenge_method': 'S256',
          'actor': lane == ConnectOAuthLane.linearApp ? 'app' : 'user',
          'prompt': 'consent',
        });
      case ConnectOAuthLane.slack:
        return Uri.https('slack.com', '/openid/connect/authorize', {
          'client_id': clientId,
          'redirect_uri': redirect,
          'response_type': 'code',
          'scope': slackOidcScopes.join(' '),
          'state': state,
          'nonce': login.oidcNonce,
        });
    }
  }

  // --------------------------------------------------------------- callback

  /// Answers the expired page and logs `oauth.callback_refused`.
  Future<void> _callbackRefused(HttpResponse response, String reason) {
    ctx.log.event('oauth.callback_refused', {
      'reason': reason,
    }, ConnectLogLevel.warn);
    return sendStaticPage(response, StaticPage.expired);
  }

  /// `GET /oauth/{segment}/callback`.
  Future<void> callback(HttpRequest request, String segment) async {
    final response = request.response;
    final Map<String, String> query;
    try {
      query = request.uri.queryParameters;
    } on FormatException {
      return _callbackRefused(response, 'query');
    }
    final state = query['state'];
    if (state == null || !_opaqueToken.hasMatch(state)) {
      return _callbackRefused(response, 'state_shape');
    }
    final mapping = await ctx.state.take('state:$state');
    if (mapping == null) {
      return _callbackRefused(response, 'state_unknown');
    }
    final decoded = jsonDecode(mapping);
    final loginId = decoded is Map ? decoded['login'] : null;
    final hop = ConnectCallbackHop.fromWire(
      decoded is Map ? decoded['hop'] : null,
    );
    final login = loginId is String ? await ctx.login(loginId) : null;
    if (login == null) {
      return _callbackRefused(response, 'login_unknown');
    }
    final route = ConnectOAuthLane.fromCallbackSegment(segment);
    if (route == null ||
        hop == null ||
        route.lane != login.lane ||
        route.hop != hop ||
        login.nextHop != hop) {
      await ctx.burnLogin(login.id);
      return _callbackRefused(response, 'hop_mismatch');
    }
    final code = query['code'];
    if (query.containsKey('error') ||
        code == null ||
        code.isEmpty ||
        code.length > 1024) {
      await ctx.burnLogin(login.id);
      ctx.log.event('oauth.declined', {'lane': login.lane.wire});
      return sendStaticPage(response, StaticPage.declined);
    }
    if (login.lane == ConnectOAuthLane.slack &&
        hop == ConnectCallbackHop.first) {
      return _slackPrecheck(response, login, code);
    }
    final authorized = login.advance(
      Authorized(providerCode: code, slack: login.slackPrecheck),
    );
    if (!await ctx.saveLogin(authorized)) {
      // Burned or advanced by another request meanwhile.
      return _callbackRefused(response, 'login_changed');
    }
    final cookie = b64url(randomBytes(32));
    await ctx.state.set(
      'done:${_sha(cookie)}',
      login.id,
      login.expiresAt.difference(ctx.now()),
    );
    ctx.log.event('oauth.callback', {'lane': login.lane.wire});
    return sendSeeOther(
      response,
      Uri.parse('$_base/oauth/${login.lane.wire}/done'),
      cookieValue: cookie,
      cookieMaxAge: login.expiresAt.difference(ctx.now()),
    );
  }

  /// Slack step 1: the OIDC answer names the team without touching its bot
  /// installation. Only an unbound team, or one bound to this same install,
  /// continues to the bot install (which rotates the team's bot token).
  Future<void> _slackPrecheck(
    HttpResponse response,
    StagedLogin login,
    String code,
  ) async {
    try {
      final (_, creds, api) = await ctx.slackLane();
      final identity = await api.oidcIdentity(
        code: code,
        redirectUri: _callback(
          ConnectOAuthLane.slack.callbackSegment(ConnectCallbackHop.first)!,
        ).toString(),
        nonce: login.oidcNonce,
      );
      final bound = await ctx.bindings.slack(identity.teamId, fresh: true);
      if (bound != null && bound.installId != login.installId) {
        await ctx.burnLogin(login.id);
        ctx.log.event('slack.precheck_refused', {
          'team': ctx.log.tag(identity.teamId),
          'install': ctx.log.tag(login.installId),
        });
        return await sendStaticPage(response, StaticPage.teamBoundElsewhere);
      }
      final checked = login.advance(
        SlackPrechecked(teamId: identity.teamId, userId: identity.userId),
      );
      if (!await ctx.saveLogin(checked)) {
        await ctx.burnLogin(login.id);
        return await sendStaticPage(response, StaticPage.expired);
      }
      final state = b64url(randomBytes(32));
      await ctx.state.set(
        'state:$state',
        jsonEncode({'login': login.id, 'hop': ConnectCallbackHop.bot.wire}),
        login.expiresAt.difference(ctx.now()),
      );
      return await sendSeeOther(
        response,
        Uri.https('slack.com', '/oauth/v2/authorize', {
          'client_id': creds.clientId,
          'scope': slackBotScopes.join(','),
          'redirect_uri': _callback(
            ConnectOAuthLane.slack.callbackSegment(ConnectCallbackHop.bot)!,
          ).toString(),
          'state': state,
          'team': identity.teamId,
        }),
      );
    } on ConnectException catch (error) {
      await ctx.burnLogin(login.id);
      ctx.log.event('oauth.callback_refused', {
        'reason': 'slack_precheck',
        'error': error.code.wire,
      }, ConnectLogLevel.warn);
      return sendStaticPage(
        response,
        error.code == ConnectErrorCode.accessDenied
            ? StaticPage.declined
            : StaticPage.failed,
      );
    }
  }

  // ------------------------------------------------------------------- done

  /// The login whose provider redirect this browser completed, by its
  /// `/done` cookie; null when absent, expired or on another lane.
  Future<(StagedLogin, String)?> _doneLogin(
    HttpRequest request,
    ConnectOAuthLane lane,
  ) async {
    final cookie = requestCookie(request, connectCookieNameFor(_base));
    if (cookie == null || !_opaqueToken.hasMatch(cookie)) {
      return null;
    }
    final key = 'done:${_sha(cookie)}';
    final loginId = await ctx.state.get(key);
    final login = loginId == null ? null : await ctx.login(loginId);
    if (login == null || login.lane != lane || login.providerCode == null) {
      return null;
    }
    return (login, key);
  }

  /// `GET /oauth/{lane}/done`: the consent page, for the browser that holds
  /// the login cookie only. It shows what the server will be able to do and
  /// asks to continue or cancel; it shows no code and no deep link. When
  /// [network] (this browser's truncated address) is not the one the login
  /// was started from, it says so; that changes nothing else.
  Future<void> done(
    HttpRequest request,
    ConnectOAuthLane lane, {
    required String network,
  }) async {
    final response = request.response;
    final found = await _doneLogin(request, lane);
    if (found == null) {
      return sendStaticPage(response, StaticPage.expired);
    }
    final login = found.$1;
    // The answer must carry this page's token, so it never rests on the
    // browser sending fetch metadata. A reload replaces it.
    final token = b64url(randomBytes(32));
    await ctx.state.set(
      _consentKey(login.id),
      token,
      login.expiresAt.difference(ctx.now()),
    );
    return sendPage(
      response,
      200,
      renderConsentPage(
        lane: lane,
        otherNetwork: network != login.startNetwork,
        action: Uri.parse('$_base/oauth/${lane.wire}/done'),
        token: token,
      ),
      form: true,
    );
  }

  static String _consentKey(String loginId) => 'consent:$loginId';

  /// Why a browser form post cannot be shown to come from Connect's own
  /// page, or null when it can. `Sec-Fetch-Site`, when sent, must be
  /// `same-origin`; `Origin`, when it names an origin, must be this
  /// service's public origin; and at least one of the two must be there. A
  /// browser that renders the page sends at least one of them on the form
  /// post, so a request with neither is not that page. This is on top of the
  /// page's single-use form token.
  ///
  /// `Origin: null` names no origin: a browser writes it when the posting
  /// page's referrer policy withholds the origin. It proves nothing and
  /// refutes nothing, so it counts as not sent. Connect's own form page asks
  /// for the real origin ([sendPage]); this covers a browser that withholds
  /// it anyway.
  String? _foreignPostReason(HttpRequest request) {
    final site = request.headers['sec-fetch-site'];
    if (site != null && (site.length != 1 || site.single != 'same-origin')) {
      return 'cross_site';
    }
    final sent = request.headers['origin'];
    final origin = sent != null && sent.length == 1 && sent.single == 'null'
        ? null
        : sent;
    if (origin != null &&
        (origin.length != 1 || !_isOwnOrigin(origin.single))) {
      return 'origin';
    }
    if (site == null && origin == null) {
      return 'no_origin';
    }
    return null;
  }

  bool _isOwnOrigin(String value) {
    final Uri parsed;
    try {
      parsed = Uri.parse(value.trim());
    } on FormatException {
      return false;
    }
    final own = Uri.parse(_base);
    // `Uri.origin` is defined for http and https only.
    return (parsed.scheme == 'https' || parsed.scheme == 'http') &&
        parsed.host.isNotEmpty &&
        (parsed.path.isEmpty || parsed.path == '/') &&
        !parsed.hasQuery &&
        !parsed.hasFragment &&
        parsed.userInfo.isEmpty &&
        parsed.origin == own.origin;
  }

  /// `POST /oauth/{lane}/done`: the consent page's answer, same cookie and
  /// the page's single-use `token`. `action=continue` shows the confirm code
  /// and the deep link; `action=cancel` burns the login, so its provider
  /// code is never exchanged. A request that does not prove it came from
  /// Connect's own page ([_foreignPostReason]), or one without the page's
  /// token, is refused and leaves the login as it was.
  Future<void> doneAction(HttpRequest request, ConnectOAuthLane lane) async {
    final response = request.response;
    Future<void> refused(String reason) {
      ctx.log.event('oauth.done_refused', {
        'lane': lane.wire,
        'reason': reason,
      }, ConnectLogLevel.warn);
      return sendStaticPage(response, StaticPage.expired);
    }

    final foreign = _foreignPostReason(request);
    if (foreign != null) {
      return refused(foreign);
    }
    final body = await readCappedBody(request, 256);
    Map<String, String> form = const {};
    if (body != null) {
      try {
        form = Uri.splitQueryString(utf8.decode(body));
      } on FormatException {
        form = const {};
      }
    }
    final action = form['action'];
    if (action != 'continue' && action != 'cancel') {
      return refused('action');
    }
    final found = await _doneLogin(request, lane);
    if (found == null) {
      return refused('login_unknown');
    }
    final (login, key) = found;
    final token = form['token'] ?? '';
    final expected = await ctx.state.get(_consentKey(login.id));
    if (expected == null ||
        !_opaqueToken.hasMatch(token) ||
        !constantTimeEquals(token, expected) ||
        // Single use: of two answers racing with one token, one wins.
        !await ctx.state.deleteIf(_consentKey(login.id), expected)) {
      return refused('token');
    }
    if (action == 'cancel') {
      await ctx.burnLogin(login.id);
      await ctx.state.delete(key);
      ctx.log.event('oauth.cancelled', {'lane': lane.wire});
      return sendStaticPage(response, StaticPage.cancelled);
    }
    return sendPage(
      response,
      200,
      renderDonePage(
        code: login.confirmCode,
        deepLink: oauthDoneDeepLink(loginId: login.id, code: login.confirmCode),
      ),
    );
  }

  // ------------------------------------------------------------------ claim

  /// `POST /v1/oauth/{lane}/claim`.
  Future<Object?> claim(
    ConnectCaller caller,
    ConnectOAuthLane lane,
    Map<String, Object?> body,
  ) async {
    final OAuthClaimRequest request;
    try {
      request = OAuthClaimRequest.fromJson(body);
    } on FormatException {
      throw _invalid;
    }
    void refused(String reason, [int? attempts]) => ctx.log.event(
      'oauth.claim_refused',
      {'lane': lane.wire, 'reason': reason, 'count': attempts},
      ConnectLogLevel.warn,
    );
    final login = await ctx.login(request.loginId);
    if (login == null) {
      refused('login_unknown');
      throw _stale;
    }
    // Another install's login is answered like a wrong code, without
    // spending that login's attempts; so is a claim before the provider
    // redirected back (no code has been shown yet, so none can be right).
    final providerCode = login.providerCode;
    if (login.installId != caller.installId ||
        login.lane != lane ||
        login.workspaceId != request.workspaceId) {
      refused('other_login');
      throw _mismatch;
    }
    if (providerCode == null) {
      refused('not_authorized_yet');
      throw _mismatch;
    }
    final attempts = await ctx.state.increment(
      'attempts:${login.id}',
      login.expiresAt.difference(ctx.now()),
    );
    if (attempts > maxClaimAttempts) {
      await ctx.burnLogin(login.id);
      refused('attempts', attempts);
      throw _mismatch;
    }
    final code = normaliseConfirmCode(request.confirmCode);
    final verifierOk =
        isPkceVerifier(request.codeVerifier) &&
        constantTimeEquals(
          pkceChallengeFor(request.codeVerifier),
          login.codeChallenge,
        );
    final codeOk = code != null && constantTimeEquals(code, login.confirmCode);
    if (!codeOk || !verifierOk) {
      if (attempts >= maxClaimAttempts) {
        await ctx.burnLogin(login.id);
      }
      refused(codeOk ? 'verifier' : 'code', attempts);
      throw _mismatch;
    }
    if (lane == ConnectOAuthLane.github) {
      // Before the login is spent, so a refused claim can be retried. Sign-ins
      // have an App-wide ceiling of their own, so they never hold the one
      // refreshes and children spend.
      await ctx.quotas.admit(ctx.githubExchangeQuotas(caller));
    }
    // Slack: one bot exchange per team at a time, since every
    // `oauth.v2.access` rotates the team's single bot token. Held before the
    // login is spent, so a claim that finds it busy can be retried.
    final team = login.slackPrecheck?.teamId;
    final reservation = team == null ? null : _slackClaimKey(team);
    final exchanging = '$_slackExchanging${login.id}';
    if (lane == ConnectOAuthLane.slack) {
      if (reservation == null) {
        refused('slack_precheck');
        throw _mismatch;
      }
      if (!await ctx.state.putIfAbsent(
        reservation,
        exchanging,
        _slackExchangeTtl,
      )) {
        refused('slack_exchange_busy');
        throw const ConnectException(
          ConnectErrorCode.rateLimited,
          reason: 'slack_exchange_busy',
        );
      }
    }
    try {
      // Single use: of two concurrent correct claims exactly one proceeds.
      if (await ctx.state.take('login:${login.id}') == null) {
        refused('spent');
        throw _stale;
      }
      await ctx.state.delete('attempts:${login.id}');
      return await _exchangeClaim(
        caller,
        lane,
        login,
        providerCode,
        request,
        caller.binding(login.workspaceId),
      );
    } on ConnectException catch (e) {
      if (e.code == ConnectErrorCode.staleRequest) {
        rethrow;
      }
      // The code and verifier were right; the provider, or what it handed
      // back, was not. Say why: nothing else would.
      ctx.log.event('oauth.claim_failed', {
        'lane': lane.wire,
        'error': e.code.wire,
        'reason': e.reason,
      }, ConnectLogLevel.warn);
      // The login is spent either way. A grant the provider refused (wrong
      // scopes, another app, an identity mismatch) is "sign in again", never
      // `access_denied`: the server must not read it as a wrong code.
      if (e.code == ConnectErrorCode.accessDenied) {
        throw ConnectException(ConnectErrorCode.needsSignIn, reason: e.reason);
      }
      rethrow;
    } finally {
      if (reservation != null) {
        // Only this claim's own mark: one that lapsed may have been taken.
        try {
          await ctx.state.deleteIf(reservation, exchanging);
        } on Object {
          // Lapses after [_slackExchangeTtl].
        }
      }
    }
  }

  Future<Object?> _exchangeClaim(
    ConnectCaller caller,
    ConnectOAuthLane lane,
    StagedLogin login,
    String providerCode,
    OAuthClaimRequest request,
    SealBinding binding,
  ) async {
    final result = switch (lane) {
      ConnectOAuthLane.github => await _claimGitHub(
        providerCode,
        request.codeVerifier,
        binding,
      ),
      ConnectOAuthLane.google => await _claimGoogle(
        login,
        providerCode,
        request.codeVerifier,
        binding,
      ),
      ConnectOAuthLane.linear || ConnectOAuthLane.linearApp => LinearCodeGrant(
        code: providerCode,
        redirectUri: _callback(lane.firstCallbackSegment).toString(),
      ).toJson(),
      ConnectOAuthLane.slack => await _claimSlack(
        caller,
        login,
        providerCode,
        binding,
      ),
    };
    ctx.log.event('oauth.claimed', {'lane': lane.wire});
    return result;
  }

  Future<Map<String, Object?>> _claimGitHub(
    String providerCode,
    String verifier,
    SealBinding binding,
  ) async {
    final (_, creds, api) = await ctx.githubLane();
    final tokens = await api.exchangeCode(
      code: providerCode,
      redirectUri: _callback(
        ConnectOAuthLane.github.firstCallbackSegment,
      ).toString(),
      codeVerifier: verifier,
    );
    final user = await api.user(tokens.access);
    // The account is known only now. Over its budget the token just minted
    // is revoked upstream rather than handed out.
    try {
      await ctx.quotas.admit(
        ctx.githubAccountQuotas(binding.installId, user.id),
      );
    } on ConnectException {
      try {
        await api.deleteToken(tokens.access);
      } on Object {
        // Still refused: the token is never handed out either way.
      }
      rethrow;
    }
    ctx.log.event('github.signed_in', {
      'github_user_id': user.id,
      'hashed_token': githubHashedToken(tokens.access),
    });
    final seal = await ctx.sealer.seal(
      provider: ConnectProvider.github,
      accountId: '${user.id}',
      appId: '${creds.appId}',
      generation: creds.clientSecret.generation,
      binding: binding,
      payload: githubSealPayload(tokens),
    );
    return SealedGrant(
      seal: seal,
      accessToken: tokens.access,
      expiresAt: tokens.accessExpiresAt,
      accountId: '${user.id}',
      accountLogin: user.login,
      appId: '${creds.appId}',
    ).toJson();
  }

  Future<Map<String, Object?>> _claimGoogle(
    StagedLogin login,
    String providerCode,
    String verifier,
    SealBinding binding,
  ) async {
    final (_, creds, api) = await ctx.googleLane();
    final tokens = await api.exchangeCode(
      code: providerCode,
      redirectUri: _callback(
        ConnectOAuthLane.google.firstCallbackSegment,
      ).toString(),
      codeVerifier: verifier,
    );
    Future<Never> refuse(String reason) async {
      await api.revoke(
        tokens.refresh.isNotEmpty ? tokens.refresh : tokens.access,
      );
      throw ConnectException(ConnectErrorCode.accessDenied, reason: reason);
    }

    // A widened or narrowed grant is revoked upstream and refused.
    if (!scopesExactlyMatch(tokens.scopes, googleConnectScopes)) {
      return refuse(
        logSlug([
          'google_scopes',
          ...tokens.scopes.map((s) => normaliseScope(s).split('/').last),
        ]),
      );
    }
    if (tokens.refresh.isEmpty) {
      return refuse('google_no_refresh_token');
    }
    final claims = tokens.idClaims;
    final sub = claims?['sub'];
    final email = claims?['email'];
    final issuer = claims?['iss'];
    if (claims == null ||
        !jwtAudienceIs(claims, creds.clientId) ||
        !jwtUnexpired(claims, ctx.now()) ||
        !(issuer == 'https://accounts.google.com' ||
            issuer == 'accounts.google.com') ||
        claims['email_verified'] == false ||
        sub is! String ||
        sub.isEmpty ||
        email is! String ||
        email.isEmpty) {
      return refuse('google_id_token');
    }
    final seal = await ctx.sealer.seal(
      provider: ConnectProvider.google,
      accountId: sub,
      appId: creds.clientId,
      generation: creds.clientSecret.generation,
      binding: binding,
      payload: {'refresh': tokens.refresh},
    );
    return SealedGrant(
      seal: seal,
      accessToken: tokens.access,
      expiresAt: tokens.expiresAt,
      accountId: sub,
      accountLogin: email,
      appId: creds.clientId,
    ).toJson();
  }

  Future<Map<String, Object?>> _claimSlack(
    ConnectCaller caller,
    StagedLogin login,
    String providerCode,
    SealBinding binding,
  ) async {
    final (_, creds, api) = await ctx.slackLane();
    final precheck = login.slackPrecheck;
    if (precheck == null) {
      throw _denied;
    }
    return _exchangeSlack(
      caller,
      login,
      precheck,
      providerCode,
      binding,
      creds,
      api,
    );
  }

  static String _slackClaimKey(String teamId) => 'slackclaim:$teamId';

  /// How long an exchange holds a team's reservation: a code exchange,
  /// `auth.test`, an admin lookup and the bind, each bounded by the upstream
  /// timeout, with room to spare.
  static const Duration _slackExchangeTtl = Duration(minutes: 2);

  static const String _slackExchanging = 'exchanging:';

  Future<Map<String, Object?>> _exchangeSlack(
    ConnectCaller caller,
    StagedLogin login,
    SlackPrechecked precheck,
    String providerCode,
    SealBinding binding,
    SlackCredentials creds,
    SlackApi api,
  ) async {
    final current = await ctx.bindings.slack(precheck.teamId, fresh: true);
    if (current != null && current.installId != caller.installId) {
      throw const ConnectException(ConnectErrorCode.teamBoundElsewhere);
    }
    final grant = await api.oauthAccess(
      code: providerCode,
      redirectUri: _callback(
        ConnectOAuthLane.slack.callbackSegment(ConnectCallbackHop.bot)!,
      ).toString(),
    );
    Future<Never> refuse(ConnectErrorCode code) async {
      // Never call `auth.revoke` on a workspace already bound to a different
      // server: Slack revokes the team's shared bot installation and emits
      // `tokens_revoked`, which would release the rightful owner's binding.
      final existing = grant.teamId.isEmpty
          ? null
          : await ctx.bindings.slack(grant.teamId, fresh: true);
      if (existing == null || existing.installId == caller.installId) {
        await api.revoke(grant.access);
      }
      throw ConnectException(code);
    }

    if (grant.appId != creds.appId ||
        grant.isEnterpriseInstall ||
        !scopesExactlyMatch(grant.scopes, slackBotScopes) ||
        grant.teamId != precheck.teamId ||
        (grant.authedUserId.isNotEmpty &&
            precheck.userId.isNotEmpty &&
            grant.authedUserId != precheck.userId)) {
      return refuse(ConnectErrorCode.accessDenied);
    }
    final auth = await api.authTest(grant.access);
    if (auth.teamId != grant.teamId || auth.userId != grant.botUserId) {
      return refuse(ConnectErrorCode.accessDenied);
    }
    // The first server a workspace connects to reads what the bot can see
    // there, so only one of its admins or owners decides which one.
    if (current == null &&
        !await api.isWorkspaceAdmin(
          grant.access,
          teamId: grant.teamId,
          userId: precheck.userId,
        )) {
      ctx.log.event('slack.bind_refused_not_admin', {
        'team': ctx.log.tag(grant.teamId),
        'install': ctx.log.tag(caller.installId),
      });
      return refuse(ConnectErrorCode.notAdmin);
    }
    final bound = await ctx.bindings.bindSlack(
      SlackTeamBinding(
        teamId: grant.teamId,
        installId: caller.installId,
        botId: auth.botId,
        botUserId: grant.botUserId,
        appId: creds.appId,
        boundAt: ctx.now(),
      ),
    );
    if (bound.installId != caller.installId) {
      // Bound by another server between the pre-check and now.
      return refuse(ConnectErrorCode.teamBoundElsewhere);
    }
    ctx.log.event('slack.bound', {
      'team': ctx.log.tag(grant.teamId),
      'install': ctx.log.tag(caller.installId),
    });
    final seal = await sealSlackGrant(
      ctx,
      grant: grant,
      botId: auth.botId,
      generation: creds.clientSecret.generation,
      binding: binding,
    );
    return SealedGrant(
      seal: seal,
      accessToken: grant.access,
      expiresAt: grant.accessExpiresAt,
      accountId: grant.teamId,
      appId: grant.appId,
      teamId: grant.teamId,
      teamName: grant.teamName,
      botUserId: grant.botUserId,
      botId: auth.botId,
      authedUserId: grant.authedUserId,
    ).toJson();
  }

  // ------------------------------------------------------------ GitHub setup

  /// `GET /oauth/github/setup`: GitHub's post-install redirect. It records
  /// nothing: an installation needs no per-server binding (the account's
  /// install is its consent, and every token is a member's own, clamped to
  /// their role), so this only tells the person what happened.
  Future<void> githubSetup(HttpRequest request) async {
    final String? action;
    try {
      action = request.uri.queryParameters['setup_action'];
    } on FormatException {
      return sendStaticPage(request.response, StaticPage.githubInstalled);
    }
    return sendStaticPage(request.response, switch (action) {
      'request' => StaticPage.githubRequested,
      'update' => StaticPage.githubUpdated,
      _ => StaticPage.githubInstalled,
    });
  }
}
