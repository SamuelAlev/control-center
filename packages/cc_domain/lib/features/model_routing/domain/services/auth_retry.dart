/// Context handed to the key resolver on each step of the a/b/c retry.
class AuthResolveContext {
  /// Creates an [AuthResolveContext].
  const AuthResolveContext({this.error, this.lastChance = false});

  /// The auth error from the previous attempt, or null on the initial resolve.
  final Object? error;

  /// True only on the final step — the resolver should rotate to a sibling
  /// credential rather than refreshing the current one.
  final bool lastChance;

  /// Whether this is the initial resolve (no prior error).
  bool get isInitial => error == null;
}

/// Raised when no credential could be resolved at all.
class NoCredentialError implements Exception {
  /// Creates a [NoCredentialError].
  const NoCredentialError([this.message = 'No credential available']);

  /// Human-readable message.
  final String message;

  @override
  String toString() => 'NoCredentialError: $message';
}

/// The central a/b/c auth-retry policy.
///
/// Ordered recovery:
///   (a) initial attempt with the cached/best credential;
///   (b) on an auth error, force-refresh the **same** account (`forceRefresh`);
///   (c) still failing → rotate to a **sibling** account (`lastChance`).
///
/// Non-auth errors propagate immediately. A refreshed key identical to the last
/// one, or a null resolve, skips that step.
class AuthRetryPolicy {
  /// Creates an [AuthRetryPolicy].
  const AuthRetryPolicy({this.isAuthError = defaultIsAuthError});

  /// Decides whether a thrown error is auth-related (and thus retryable).
  final bool Function(Object error) isAuthError;

  /// Runs [attempt] with auth retries, resolving keys via [resolve].
  ///
  /// [resolve] is called up to three times with an [AuthResolveContext]; it
  /// returns the key to try (or null to skip the step). [attempt] performs the
  /// request with the resolved key and throws on failure.
  Future<T> run<T>({
    required Future<T> Function(String key) attempt,
    required Future<String?> Function(AuthResolveContext ctx) resolve,
  }) async {
    var lastKey = await _resolveSafe(resolve, const AuthResolveContext());
    if (lastKey == null) {
      throw const NoCredentialError();
    }

    Object? lastError;
    try {
      return await attempt(lastKey);
    } on Object catch (e) {
      if (!isAuthError(e)) {
        rethrow; // non-auth → propagate immediately
      }
      lastError = e;
    }

    // (b) force-refresh same account, then (c) rotate to sibling.
    for (final lastChance in const [false, true]) {
      final nextKey = await _resolveSafe(
        resolve,
        AuthResolveContext(error: lastError, lastChance: lastChance),
      );
      if (nextKey == null || nextKey == lastKey) {
        continue;
      }
      lastKey = nextKey;
      try {
        return await attempt(lastKey);
      } on Object catch (e) {
        if (!isAuthError(e)) {
          rethrow;
        }
        lastError = e;
      }
    }

    throw lastError!;
  }

  /// A resolve step that fails (e.g. a refresh endpoint is down) is a skipped
  /// recovery attempt, not a fatal error,
  /// which swallows resolver failures and returns null so the next step runs.
  static Future<String?> _resolveSafe(
    Future<String?> Function(AuthResolveContext ctx) resolve,
    AuthResolveContext ctx,
  ) async {
    try {
      return await resolve(ctx);
    } on Object {
      return null;
    }
  }

  /// A conservative default classifier: treats an error as auth-related when
  /// its string form names a 401 / unauthorized / usage-limit / quota / token
  /// condition. Callers with typed errors should pass their own.
  static bool defaultIsAuthError(Object error) {
    final s = error.toString().toLowerCase();
    return s.contains('401') ||
        s.contains('unauthorized') ||
        s.contains('forbidden') ||
        s.contains('403') ||
        s.contains('invalid_api_key') ||
        s.contains('invalid api key') ||
        s.contains('authentication') ||
        s.contains('expired') ||
        s.contains('usage limit') ||
        s.contains('usage_limit') ||
        s.contains('quota') ||
        s.contains('insufficient');
  }
}
