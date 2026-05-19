import 'package:cc_harness/src/provider/provider_credential.dart';

/// Refreshes an OAuth [ProviderCredential] when it is near expiry, persisting the
/// new token. API-key / none-auth credentials pass through unchanged.
///
/// Implemented by the OAuth broker; injected into the dispatch path so a
/// harness run always builds its provider with a fresh token.
abstract interface class ProviderCredentialRefresher {
  /// Returns [credential] refreshed if it is an expiring OAuth token, else the
  /// credential unchanged (never throws — refresh failure returns the original).
  ///
  /// [force] refreshes even when the stored token still looks valid. The caller
  /// uses it after the provider rejected the token (a 401): the server's verdict
  /// beats our local expiry arithmetic, which can be wrong on clock skew or when
  /// the token was revoked early.
  Future<ProviderCredential> refreshIfNeeded(
    ProviderCredential credential, {
    bool force = false,
  });
}

/// Resolves the bearer to send on the next provider request.
///
/// Called immediately before each HTTP call rather than once when the provider
/// is built, because a run outlives its token: a Kimi Code access token lives
/// ~15 minutes, so a build-time bearer 401s partway through any real agent run.
/// [force] re-mints the token even when it still looks valid (used after a 401).
typedef ProviderTokenResolver = Future<String?> Function({bool force});

/// Keeps one credential's bearer fresh for the lifetime of a run.
///
/// Wraps a [ProviderCredentialRefresher] around a single credential, carrying
/// the refreshed credential forward: OAuth providers may rotate the refresh
/// token, so re-refreshing the *original* credential would replay a spent one.
/// Bind one of these per credential (the fallback chain rotates through
/// several) and hand [resolve] to the provider as its [ProviderTokenResolver].
class RefreshingCredential {
  /// Creates a holder that refreshes `credential` through `refresher`.
  RefreshingCredential(this._refresher, this._credential);

  final ProviderCredentialRefresher _refresher;
  ProviderCredential _credential;

  /// The most recently refreshed credential.
  ProviderCredential get credential => _credential;

  /// The bearer to send now, refreshing first when the token has expired (or
  /// when [force] is set). Null only when the credential carries no secret.
  Future<String?> resolve({bool force = false}) async {
    _credential = await _refresher.refreshIfNeeded(_credential, force: force);
    return _credential.secret;
  }
}
