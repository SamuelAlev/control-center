import 'package:cc_domain/cc_domain.dart';
import 'package:cc_rpc/cc_rpc.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The app-wide Riverpod retry policy, passed to the root
/// `ProviderContainer`/`ProviderScope`.
///
/// Riverpod 3 retries a failed provider by default with exponential backoff
/// starting at 200ms ([ProviderContainer.defaultRetry]). For a provider backed
/// by an RPC subscription that default is a footgun: a subscription **stream
/// error re-runs the provider, which opens a fresh `sub/subscribe`** — so an
/// UNRECOVERABLE error (a GitHub rate limit, an auth failure) becomes a tight
/// resubscribe loop that hammers the server and, transitively, GitHub (the
/// original "cc_server spamming subscriptions" storm). A blind retry can never
/// fix such an error; only a state change — a new token, the rate-limit window
/// resetting, a reconnect — can, and each of those already re-runs the provider
/// on its own.
///
/// The policy:
///  * **never** retries an unrecoverable RPC error ([_unrecoverableRpcCodes]);
///  * retries a genuinely transient RPC error (a bare internal error) a few
///    times with a **≥1s floor** — never the 200ms default — so a brief server
///    hiccup rides out without a storm;
///  * never retries an unrecoverable [NetworkException] (a rate limit / auth
///    error that reaches a provider directly rather than through the RPC layer);
///  * defers to [ProviderContainer.defaultRetry] for every other error.
Duration? appProviderRetry(int retryCount, Object error) {
  if (error is RemoteRpcException) {
    if (_unrecoverableRpcCodes.contains(error.code)) {
      return null;
    }
    if (retryCount >= 3) {
      return null;
    }
    // 1s, 2s, 4s — bounded, and far slower than the 200ms default floor.
    return Duration(seconds: 1 << retryCount);
  }
  if (error is NetworkException &&
      _unrecoverableNetworkCodes.contains(error.code)) {
    return null;
  }
  return ProviderContainer.defaultRetry(retryCount, error);
}

/// RPC error codes a resubscribe can never resolve — retrying only re-issues
/// the same doomed upstream call.
const Set<int> _unrecoverableRpcCodes = {
  RpcErrorCodes.rateLimited,
  RpcErrorCodes.unauthorized,
  RpcErrorCodes.validation,
  RpcErrorCodes.opUnknown,
  RpcErrorCodes.opVersionUnsupported,
  RpcErrorCodes.workspaceMismatch,
  RpcErrorCodes.noWorkspaceBound,
  RpcErrorCodes.tooManySubscriptions,
  RpcErrorCodes.notFound,
};

/// [NetworkException.code] values that a retry can't fix.
const Set<String> _unrecoverableNetworkCodes = {'rate_limited', 'auth_error'};
