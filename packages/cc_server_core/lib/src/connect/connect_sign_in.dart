part of 'sign_in_service.dart';

/// The Connect half of the sign-in: start the login at Connect, claim the
/// grant with the confirmation code, renew a sealed grant.
extension _ConnectSignIn on ProviderSignInService {
  Future<SignInAttempt> _beginConnect(
    ConnectOAuthLane lane,
    String userId,
    String? workspaceId,
    String? slot,
    PkcePair pkce,
  ) async {
    final mode = await modeFor(lane, workspaceId: workspaceId);
    if (mode.mode != SignInLaneMode.connect) {
      throw AuthException(
        mode.error.isNotEmpty
            ? mode.error
            : '${lane.wire} sign-in is not set up for this workspace. Choose '
                  'Control Center Connect or add your own app in Settings.',
      );
    }
    final target = await connect.targetFor(workspaceId);
    final config = await connect.usableConfig(target);
    if (config == null) {
      // The workspace's choice changed between the two reads.
      throw AuthException(
        '${lane.wire} sign-in is not set up for this workspace right now.',
      );
    }
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
        target,
        lane,
        OAuthStartRequest(
          workspaceId: slot ?? globalWorkspaceScope,
          codeChallenge: pkce.challenge,
        ),
        expectedClientId: clientId,
      );
    } on ConnectException catch (e) {
      throw AuthException(
        connectErrorMessage(e.code, ConnectErrorContext.signIn),
      );
    }
    final latest = _now().add(ProviderSignInService.pendingTtl);
    return SignInAttempt._(
      loginId: started.loginId,
      lane: lane,
      mode: SignInLaneMode.connect,
      userId: userId,
      workspaceId: workspaceId,
      slot: slot,
      verifier: pkce.verifier,
      expiresAt: started.expiresAt.isBefore(latest)
          ? started.expiresAt
          : latest,
      url: started.authorizeUrl,
      clientId: clientId,
      target: target,
    );
  }

  /// Claims the grant at Connect with the confirmation [code].
  ///
  /// Connect counts a wrong code against the same budget; anything that
  /// consumed the login answers `stale_request` on a retry. From a matched
  /// code on, the attempt ends succeeded or failed, never pending.
  ///
  /// [deferred]: the last claim was answered `rate_limited`. If Connect had
  /// taken the login by then (an account over budget is refused after the
  /// exchange, and Connect revokes the new token itself), this claim
  /// answers `stale_request`, and the attempt ends as
  /// [SignInFailure.rateLimited]: nothing stored, try again later.
  Future<SignInAttempt> _claimConnect(
    SignInAttempt attempt,
    String code, {
    bool deferred = false,
  }) async {
    final binding = _bindings[attempt.lane]!;
    final Map<String, Object?> claimed;
    try {
      claimed = await connect.claim(
        attempt.target,
        attempt.lane,
        OAuthClaimRequest(
          loginId: attempt.loginId,
          confirmCode: code,
          codeVerifier: attempt.verifier,
          workspaceId: attempt.slot ?? globalWorkspaceScope,
        ),
      );
    } on ConnectException catch (e) {
      if (e.code == ConnectErrorCode.codeMismatch) {
        return _wrongCode(attempt, 'mismatch');
      }
      if (e.code == ConnectErrorCode.rateLimited) {
        return _deferClaim(attempt);
      }
      if (deferred && e.code == ConnectErrorCode.staleRequest) {
        return _fail(
          attempt,
          SignInFailure.rateLimited,
          reason: 'connect:rate_limited_after_exchange',
        );
      }
      return _fail(
        attempt,
        SignInFailure.fromConnect(e.code),
        reason: 'connect:${e.code.wire}',
      );
    }
    SignInResult? result;
    try {
      switch (attempt.lane) {
        case ConnectOAuthLane.linear || ConnectOAuthLane.linearApp:
          // Connect relays only Linear's one-time code; this server exchanges
          // it directly, so Connect never sees a Linear token.
          final linear = LinearCodeGrant.fromJson(claimed);
          final token = await _oauth.exchange(
            lane: attempt.lane,
            tokenEndpoint: ProviderSignInService.linearTokenEndpoint,
            clientId: attempt.clientId,
            clientSecret: '',
            code: linear.code,
            redirectUri: Uri.parse(linear.redirectUri),
            verifier: attempt.verifier,
            expectedScopes: linearConnectScopes,
            binding: binding,
          );
          result = _resultOf(attempt, token);
        case ConnectOAuthLane.github ||
            ConnectOAuthLane.google ||
            ConnectOAuthLane.slack:
          final grant = SealedGrant.fromJson(claimed);
          final installId =
              (await connect.identity(attempt.target))?.installId ?? '';
          result = _resultOf(
            attempt,
            ProviderToken(
              accessToken: grant.accessToken,
              expiresAt: grant.expiresAt,
              source: ForgeCredentialSource.connect,
              accountLogin: grant.accountLogin,
              accountId: grant.accountId,
              seal: grant.seal,
              sealInstallId: installId,
              connectOrigin: attempt.target.origin,
              appId: grant.appId,
            ),
            grant: grant,
          );
          if (attempt.lane != ConnectOAuthLane.slack) {
            // Connect's word on the account is checked against the provider
            // itself, with the same rules as an own-app exchange. Slack's
            // install is confirmed by `auth.test` when the lane stores it.
            final who = await _confirmConnectGrant(
              attempt,
              binding,
              result.token,
            );
            result = _resultOf(
              attempt,
              result.token.copyWith(
                accountId: who.id,
                accountLogin: who.login.isEmpty
                    ? grant.accountLogin
                    : who.login,
              ),
              grant: grant,
            );
          }
      }
      return await _finish(attempt, binding, result);
    } on FormatException {
      return _fail(
        attempt,
        SignInFailure.providerUnavailable,
        reason: 'malformed_grant',
      );
    } on _ExchangeRefused catch (e) {
      final unkept = result;
      if (unkept != null) {
        await _revokeUnkept(attempt, binding, unkept, e.reason);
      }
      return _fail(
        attempt,
        e.code,
        message: e.message,
        reason: e.reason,
        requestId: e.requestId,
      );
    } on Object catch (e) {
      return _fail(
        attempt,
        SignInFailure.providerUnavailable,
        reason: 'claim_error:${errorKindOf(e)}',
      );
    }
  }

  /// Connect answered a claim `rate_limited`. Its refusals that come before
  /// the login is taken (a per-address limit, a Slack team's exchange
  /// already in flight) leave the login claimable, so the attempt stays
  /// pending with [SignInFailure.rateLimited] as its code error and no wrong
  /// code counted. When the provider refused after the login was taken, the
  /// next claim answers `stale_request` and the attempt ends then.
  SignInAttempt _deferClaim(SignInAttempt attempt) {
    final next =
        _attempts.update(
          attempt.loginId,
          (a) => a._copy(codeError: SignInFailure.rateLimited),
        ) ??
        _attempts[attempt.loginId] ??
        attempt;
    forgeAudit(ForgeAuditEvent.signinClaimDeferred, {
      'lane': attempt.lane.wire,
      'user_id': attempt.userId,
      'attempt': attempt.loginId,
    });
    return next;
  }

  /// Who a Connect grant belongs to, confirmed with the provider: the same
  /// token-shape rules as an own-app exchange, and the account the provider
  /// names must be the one Connect reported. Throws [_ExchangeRefused].
  Future<SignInIdentity> _confirmConnectGrant(
    SignInAttempt attempt,
    SignInLaneBinding binding,
    ProviderToken token,
  ) async {
    _checkGitHubUserToken(attempt.lane, token);
    final who = await _confirmIdentity(binding, token.accessToken);
    if (token.accountId.isNotEmpty && token.accountId != who.id) {
      forgeAudit(ForgeAuditEvent.signinIdentityMismatch, {
        'lane': attempt.lane.wire,
        'user_id': attempt.userId,
        'attempt': attempt.loginId,
      });
      throw const _ExchangeRefused(
        SignInFailure.exchangeFailed,
        'The provider named a different account than the sign-in service '
        'reported, so the sign-in was refused.',
        reason: 'identity_mismatch',
      );
    }
    return who;
  }

  /// Renews a sealed grant through the Connect that sealed it.
  Future<RefreshOutcome> _refreshSealed(
    ConnectOAuthLane lane,
    ProviderToken expired, {
    String? slot,
    String? workspaceId,
  }) async {
    RefreshOutcome outcome(RefreshOutcome value, String reason) {
      forgeAudit(
        value is RefreshRejected
            ? ForgeAuditEvent.grantRefreshRejected
            : ForgeAuditEvent.grantRefreshUnavailable,
        {'lane': lane.wire, 'path': 'connect', 'reason': reason},
      );
      return value;
    }

    final target = await connect.targetFor(workspaceId);
    switch (sealStandingOf(
      sealInstallId: expired.sealInstallId,
      currentInstallId: target.enabled && target.origin == expired.connectOrigin
          ? (await connect.identity(target))?.installId
          : null,
    )) {
      case SealStanding.parked:
        // Connect off or pointed elsewhere: the grant is fine, only
        // unreachable from here until the setting comes back.
        return outcome(const RefreshUnavailable(), 'seal_parked');
      case SealStanding.dead:
        // Sealed for another install identity: Connect can never open it.
        return outcome(const RefreshRejected(), 'seal_dead');
      case SealStanding.usable:
        break;
    }
    try {
      final grant = await connect.refresh(
        target,
        lane.provider,
        SealRequest(
          seal: expired.seal,
          workspaceId: slot ?? globalWorkspaceScope,
        ),
      );
      forgeAudit(ForgeAuditEvent.grantRefreshed, {
        'lane': lane.wire,
        'path': 'connect',
      }, token: grant.accessToken);
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
      return outcome(
        e.code.clearsGrant
            ? const RefreshRejected()
            : const RefreshUnavailable(),
        'connect:${e.code.wire}',
      );
    }
  }
}
