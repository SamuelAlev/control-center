import 'dart:convert';
import 'dart:io';

import 'package:cc_connect/src/binding_store.dart';
import 'package:cc_connect/src/context.dart';
import 'package:cc_connect/src/credential_seal.dart';
import 'package:cc_connect/src/grant_routes.dart';
import 'package:cc_connect/src/http_io.dart';
import 'package:cc_connect/src/pages.dart';
import 'package:cc_connect/src/provider_slack.dart';
import 'package:cc_connect/src/provider_support.dart';
import 'package:cc_connect/src/redis_state_store.dart';
import 'package:cc_connect/src/service_config.dart' show SlackCredentials;
import 'package:cc_connect/src/upstream_http.dart';
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
  OAuthRoutes(this.ctx, this.grants);

  /// The shared context.
  final ConnectContext ctx;

  /// Grant plumbing (GitHub seal resolution and binding).
  final GrantRoutes grants;

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
    final login = StagedLogin(
      id: newLoginId(),
      lane: lane,
      installId: caller.installId,
      workspaceId: request.workspaceId,
      codeChallenge: request.codeChallenge,
      confirmCode: newConfirmCode(),
      expiresAt: ctx.now().add(loginTtl),
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
          'prompt': 'consent',
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

  /// `GET /oauth/{segment}/callback`.
  Future<void> callback(HttpRequest request, String segment) async {
    final response = request.response;
    final Map<String, String> query;
    try {
      query = request.uri.queryParameters;
    } on FormatException {
      return sendStaticPage(response, StaticPage.expired);
    }
    final state = query['state'];
    if (state == null || !_opaqueToken.hasMatch(state)) {
      return sendStaticPage(response, StaticPage.expired);
    }
    final mapping = await ctx.state.take('state:$state');
    if (mapping == null) {
      return sendStaticPage(response, StaticPage.expired);
    }
    final decoded = jsonDecode(mapping);
    final loginId = decoded is Map ? decoded['login'] : null;
    final hop = ConnectCallbackHop.fromWire(
      decoded is Map ? decoded['hop'] : null,
    );
    final login = loginId is String ? await ctx.login(loginId) : null;
    if (login == null) {
      return sendStaticPage(response, StaticPage.expired);
    }
    final route = ConnectOAuthLane.fromCallbackSegment(segment);
    if (route == null ||
        hop == null ||
        route.lane != login.lane ||
        route.hop != hop ||
        login.nextHop != hop) {
      await ctx.burnLogin(login.id);
      return sendStaticPage(response, StaticPage.expired);
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
      return sendStaticPage(response, StaticPage.expired);
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
      // One bot install per team at a time: every `oauth.v2.access` rotates
      // the team's single bot token, so only the login holding this
      // reservation may exchange.
      final reservation = _slackClaimKey(identity.teamId);
      final ttl = login.expiresAt.difference(ctx.now());
      if (!await ctx.state.putIfAbsent(reservation, login.id, ttl)) {
        final holder = await ctx.state.get(reservation);
        // A reservation whose login was abandoned (expired or burned) is
        // free; one mid-exchange or still live is not. Taking it over is
        // compare-and-set: of two logins that both found it abandoned, one
        // wins and the other is told an install is in progress.
        final abandoned =
            holder != null &&
            !holder.startsWith(_slackExchanging) &&
            await ctx.login(holder) == null;
        if (!abandoned ||
            !await ctx.state.replace(reservation, holder, login.id, ttl)) {
          await ctx.burnLogin(login.id);
          return await sendStaticPage(response, StaticPage.slackInProgress);
        }
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
      return sendStaticPage(
        response,
        error.code == ConnectErrorCode.accessDenied
            ? StaticPage.declined
            : StaticPage.failed,
      );
    }
  }

  // ------------------------------------------------------------------- done

  /// `GET /oauth/{lane}/done`: the confirm code, for the browser that holds
  /// the login cookie only.
  Future<void> done(HttpRequest request, ConnectOAuthLane lane) async {
    final response = request.response;
    final cookie = requestCookie(request, connectCookieNameFor(_base));
    if (cookie == null || !_opaqueToken.hasMatch(cookie)) {
      return sendStaticPage(response, StaticPage.expired);
    }
    final loginId = await ctx.state.get('done:${_sha(cookie)}');
    final login = loginId == null ? null : await ctx.login(loginId);
    if (login == null || login.lane != lane || login.providerCode == null) {
      return sendStaticPage(response, StaticPage.expired);
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
    final login = await ctx.login(request.loginId);
    if (login == null) {
      throw _stale;
    }
    // Another install's login is answered like a wrong code, without
    // spending that login's attempts; so is a claim before the provider
    // redirected back (no code has been shown yet, so none can be right).
    final providerCode = login.providerCode;
    if (login.installId != caller.installId ||
        login.lane != lane ||
        login.workspaceId != request.workspaceId ||
        providerCode == null) {
      throw _mismatch;
    }
    final attempts = await ctx.state.increment(
      'attempts:${login.id}',
      login.expiresAt.difference(ctx.now()),
    );
    if (attempts > maxClaimAttempts) {
      await ctx.burnLogin(login.id);
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
      ctx.log.event('oauth.claim_refused', {
        'lane': lane.wire,
        'count': attempts,
        'install': ctx.log.tag(caller.installId),
      });
      throw _mismatch;
    }
    // Single use: of two concurrent correct claims exactly one proceeds.
    if (await ctx.state.take('login:${login.id}') == null) {
      throw _stale;
    }
    await ctx.state.delete('attempts:${login.id}');
    final binding = caller.binding(login.workspaceId);
    try {
      return await _exchangeClaim(
        caller,
        lane,
        login,
        providerCode,
        request,
        binding,
      );
    } on ConnectException catch (e) {
      // The code and verifier were right; the provider, or what it handed
      // back, was not. Say why: nothing else would.
      ctx.log.event('oauth.claim_failed', {
        'lane': lane.wire,
        'error': e.code.wire,
        'reason': e.reason,
        'install': ctx.log.tag(caller.installId),
      });
      // The login is spent either way. A grant the provider refused (wrong
      // scopes, another app, an identity mismatch) is "sign in again", never
      // `access_denied`: the server must not read it as a wrong code.
      if (e.code == ConnectErrorCode.accessDenied) {
        throw ConnectException(ConnectErrorCode.needsSignIn, reason: e.reason);
      }
      rethrow;
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
    ctx.log.event('oauth.claimed', {
      'lane': lane.wire,
      'install': ctx.log.tag(caller.installId),
    });
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
    final reservation = _slackClaimKey(precheck.teamId);
    final exchanging = '$_slackExchanging${login.id}';
    // Compare-and-set from this login's reservation to "exchanging": when it
    // lapsed or another login holds it, exchanging now would rotate a token
    // someone else may already hold.
    if (!await ctx.state.replace(
      reservation,
      login.id,
      exchanging,
      _slackExchangeTtl,
    )) {
      throw _denied;
    }
    try {
      return await _exchangeSlack(
        caller,
        login,
        precheck,
        providerCode,
        binding,
        creds,
        api,
      );
    } finally {
      // Only this exchange's own mark: one that lapsed may have been taken.
      try {
        await ctx.state.deleteIf(reservation, exchanging);
      } on Object {
        // Lapses after [_slackExchangeTtl].
      }
    }
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

  /// `GET /oauth/github/setup`: GitHub's post-install redirect. The `state`
  /// is a single-use install ticket from `/v1/github/install/start`; the
  /// ticket's own seal proves who installed, and only an org admin (or the
  /// personal account itself) binds the installation to the ticket's server.
  Future<void> githubSetup(HttpRequest request) async {
    final response = request.response;
    final Map<String, String> query;
    try {
      query = request.uri.queryParameters;
    } on FormatException {
      return sendStaticPage(response, StaticPage.expired);
    }
    final state = query['state'];
    final action = query['setup_action'];
    if (state == null || !_opaqueToken.hasMatch(state)) {
      return sendStaticPage(
        response,
        action == 'update' ? StaticPage.githubUpdated : StaticPage.expired,
      );
    }
    final raw = await ctx.state.take('ticket:$state');
    final ticket = raw == null ? null : jsonDecode(raw);
    if (ticket is! Map ||
        ticket['install_id'] is! String ||
        ticket['workspace_id'] is! String ||
        ticket['seal'] is! String) {
      return sendStaticPage(response, StaticPage.expired);
    }
    // Unsigned (GitHub redirects here), so the allowlist the signed routes
    // apply is applied to the ticket's install instead: blocking a server
    // also voids the tickets it already holds.
    if (!ctx.config.access.permits(ticket['install_id'] as String)) {
      ctx.log.event('github.setup_blocked', {
        'install': ctx.log.tag(ticket['install_id'] as String),
      });
      return sendStaticPage(response, StaticPage.installBlocked);
    }
    if (action == 'request') {
      return sendStaticPage(response, StaticPage.githubRequested);
    }
    final installationId = int.tryParse(query['installation_id'] ?? '');
    if (installationId == null || installationId <= 0) {
      return sendStaticPage(response, StaticPage.githubNotInstalled);
    }
    try {
      final lane = await ctx.githubLane();
      final grant = await grants.resolveGitHub(
        ConnectCaller(installId: ticket['install_id'] as String),
        ticket['workspace_id'] as String,
        ticket['seal'] as String,
        lane: lane,
        minRemaining: const Duration(minutes: 1),
        rotate: false,
      );
      final outcome = await grants.authorizeInstallation(
        grant,
        installationId,
        ticket['install_id'] as String,
        lane: lane,
      );
      return await sendStaticPage(response, switch (outcome) {
        AuthorizeOutcome.bound => StaticPage.githubInstalled,
        AuthorizeOutcome.notInstalled => StaticPage.githubNotInstalled,
        AuthorizeOutcome.suspended => StaticPage.githubNotInstalled,
        AuthorizeOutcome.notAdmin => StaticPage.githubNotAdmin,
      });
    } on ConnectException catch (error) {
      return sendStaticPage(
        response,
        error.code == ConnectErrorCode.providerUnavailable ||
                error.code == ConnectErrorCode.rateLimited
            ? StaticPage.failed
            : StaticPage.expired,
      );
    } on StateStoreUnavailable {
      return sendStaticPage(response, StaticPage.failed);
    } on BindingStoreUnavailable {
      return sendStaticPage(response, StaticPage.failed);
    } on UpstreamUnavailable {
      return sendStaticPage(response, StaticPage.failed);
    }
  }
}
