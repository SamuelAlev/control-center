part of 'sign_in_service.dart';

/// A started sign-in, as reported to the client that started it.
///
/// Immutable: every change is a new attempt written through
/// [SignInAttemptStore.update], which only ever moves a pending attempt.
final class SignInAttempt {
  const SignInAttempt._({
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
    this.target = ConnectTarget.none,
    this.status = SignInAttemptStatus.pending,
    this.account = '',
    this.error,
    this.codeError,
    this.message = '',
    this.wrongCodes = 0,
    this.providerCode = '',
    this.confirmCode = '',
  });

  /// Opaque handle; for Connect it is Connect's login id (the deep link
  /// carries it back), for an own app a fresh random id.
  final String loginId;

  /// Which lane.
  final ConnectOAuthLane lane;

  /// Own app or Connect.
  final SignInLaneMode mode;

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

  /// The Connect a Connect sign-in started at, where it is claimed and
  /// whose origin its seal carries ([ConnectTarget.none] for an own app).
  final ConnectTarget target;

  /// Current status.
  final SignInAttemptStatus status;

  /// The connected account, when it succeeded.
  final String account;

  /// Why it failed, once [status] is failed.
  final SignInFailure? error;

  /// Why the last confirmation code was not accepted, while the attempt
  /// stays open for another ([SignInFailure.codeMismatch]); cleared by the
  /// next code.
  final SignInFailure? codeError;

  /// The server's own explanation of [error], when it has one more specific
  /// than the code (an own-app exchange the provider refused, a GitHub App
  /// whose tokens never expire). Written by this server, never a provider
  /// body, so it is safe to show.
  final String message;

  /// Wrong confirmation codes so far.
  final int wrongCodes;

  /// Own app: the provider's one-time authorization code, kept from the
  /// callback until the person who started the sign-in confirms it. Never
  /// leaves this process.
  final String providerCode;

  /// Own app: the confirmation code the callback page showed. Never leaves
  /// this process except on that page.
  final String confirmCode;

  /// Whether the provider has redirected back for this own-app attempt.
  bool get callbackSeen => providerCode.isNotEmpty;

  SignInAttempt _copy({
    SignInAttemptStatus? status,
    String? account,
    SignInFailure? error,
    SignInFailure? codeError,
    bool clearCodeError = false,
    String? message,
    int? wrongCodes,
    String? providerCode,
    String? confirmCode,
  }) => SignInAttempt._(
    loginId: loginId,
    lane: lane,
    mode: mode,
    userId: userId,
    workspaceId: workspaceId,
    slot: slot,
    verifier: verifier,
    expiresAt: expiresAt,
    url: url,
    state: state,
    redirectUri: redirectUri,
    clientId: clientId,
    target: target,
    status: status ?? this.status,
    account: account ?? this.account,
    error: error ?? this.error,
    codeError: clearCodeError ? null : (codeError ?? this.codeError),
    message: message ?? this.message,
    wrongCodes: wrongCodes ?? this.wrongCodes,
    providerCode: providerCode ?? this.providerCode,
    confirmCode: confirmCode ?? this.confirmCode,
  );

  /// The attempt failed with [failure]; the provider's code is dropped.
  SignInAttempt _failed(SignInFailure failure, {String message = ''}) => _copy(
    status: SignInAttemptStatus.failed,
    error: failure,
    message: message,
    clearCodeError: true,
    providerCode: '',
    confirmCode: '',
  );

  /// The grant for [account] was stored.
  SignInAttempt _succeeded(String account) => _copy(
    status: SignInAttemptStatus.succeeded,
    account: account,
    clearCodeError: true,
    providerCode: '',
    confirmCode: '',
  );

  /// One more wrong code: still pending with [SignInFailure.codeMismatch],
  /// or failed with [SignInFailure.invalidCode] once [maxWrongCodes] ran out.
  SignInAttempt _wrongCode(int maxWrongCodes) {
    final count = wrongCodes + 1;
    return count >= maxWrongCodes
        ? _copy(wrongCodes: count)._failed(SignInFailure.invalidCode)
        : _copy(wrongCodes: count, codeError: SignInFailure.codeMismatch);
  }

  /// The wire shape for the client. Never the verifier, `state`, the
  /// provider's code or the confirmation code.
  Map<String, Object?> toJson() => {
    'login_id': loginId,
    'lane': lane.wire,
    'mode': mode.name,
    'url': url.toString(),
    'expires_at': expiresAt.toUtc().toIso8601String(),
    'status': status.wire,
    if (account.isNotEmpty) 'account': account,
    'error': ?error?.wire,
    if (message.isNotEmpty) 'message': message,
    'code_error': ?codeError?.wire,
  };
}

/// Every started sign-in, in memory.
///
/// The one place an attempt changes: [update] moves only a pending attempt,
/// so a finished one never changes again (no failed → succeeded).
final class SignInAttemptStore {
  /// Creates the store.
  SignInAttemptStore({required this._now});

  /// Attempts kept server-wide; the own-app callback is unauthenticated.
  static const int maxAttempts = 256;

  /// Pending attempts one person may hold at once; a fifth replaces their
  /// oldest.
  static const int maxPendingPerUser = 4;

  /// How long a finished attempt stays readable past its expiry, so a client
  /// cannot miss the outcome.
  static const Duration keepFinished = Duration(minutes: 5);

  final DateTime Function() _now;
  final Map<String, SignInAttempt> _byLogin = {};
  final Map<String, String> _byState = {};

  /// The attempt [loginId], or null.
  SignInAttempt? operator [](String loginId) => _byLogin[loginId];

  /// Adds [attempt], first dropping what is past [keepFinished], then the
  /// owner's oldest pending attempt over [maxPendingPerUser], then the
  /// oldest attempt over [maxAttempts].
  void add(SignInAttempt attempt) {
    final now = _now();
    for (final old in _byLogin.values.toList()) {
      if (now.isAfter(old.expiresAt.add(keepFinished))) {
        _drop(old);
      }
    }
    final mine =
        _byLogin.values
            .where(
              (a) =>
                  a.userId == attempt.userId &&
                  a.status == SignInAttemptStatus.pending,
            )
            .toList()
          ..sort((a, b) => a.expiresAt.compareTo(b.expiresAt));
    if (mine.length >= maxPendingPerUser) {
      for (final old in mine.take(mine.length - maxPendingPerUser + 1)) {
        _evict(old, 'per_user_limit');
      }
    }
    if (_byLogin.length >= maxAttempts) {
      final oldest = _byLogin.values.toList()
        ..sort((a, b) => a.expiresAt.compareTo(b.expiresAt));
      for (final old in oldest.take(_byLogin.length - maxAttempts + 1)) {
        _evict(old, 'server_limit');
      }
    }
    _byLogin[attempt.loginId] = attempt;
    if (attempt.state.isNotEmpty) {
      _byState[attempt.state] = attempt.loginId;
    }
  }

  /// The login id [state] belongs to, removed so a callback is used once.
  String? takeState(String state) => _byState.remove(state);

  /// Replaces the pending attempt [loginId] with [change] of it. Returns the
  /// new attempt, or null when there is none or it is no longer pending.
  SignInAttempt? update(
    String loginId,
    SignInAttempt Function(SignInAttempt pending) change,
  ) {
    final current = _byLogin[loginId];
    if (current == null || current.status != SignInAttemptStatus.pending) {
      return null;
    }
    final next = change(current);
    if (next.loginId != loginId) {
      throw StateError('an attempt cannot change its login id');
    }
    _byLogin[loginId] = next;
    if (next.status != SignInAttemptStatus.pending && next.state.isNotEmpty) {
      _byState.remove(next.state);
    }
    return next;
  }

  void _evict(SignInAttempt attempt, String reason) {
    if (attempt.status == SignInAttemptStatus.pending) {
      forgeAudit(ForgeAuditEvent.signinEvicted, {
        'lane': attempt.lane.wire,
        'user_id': attempt.userId,
        'workspace_id': attempt.workspaceId,
        'attempt': attempt.loginId,
        'reason': reason,
      });
    }
    _drop(attempt);
  }

  void _drop(SignInAttempt attempt) {
    _byLogin.remove(attempt.loginId);
    if (attempt.state.isNotEmpty) {
      _byState.remove(attempt.state);
    }
  }
}
