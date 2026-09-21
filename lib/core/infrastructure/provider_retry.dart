import 'package:cc_domain/cc_domain.dart';
import 'package:cc_rpc/cc_rpc.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// App-wide Riverpod retry policy for the root `ProviderContainer`.
///
/// Default 200ms backoff is a footgun for RPC subscriptions: a stream error
/// re-opens `sub/subscribe`, so unrecoverable errors (rate limit, auth) storm
/// the server. Never retry [_unrecoverableRpcCodes] or unrecoverable
/// [NetworkException]; transient RPC errors retry a few times with a ≥1s
/// floor; otherwise [ProviderContainer.defaultRetry].
Duration? appProviderRetry(int retryCount, Object error) {
  if (error is RemoteRpcException) {
    if (_unrecoverableRpcCodes.contains(error.code)) {
      return null;
    }
    if (retryCount >= 3) {
      return null;
    }
    // 1s, 2s, 4s — bounded and far slower than the 200ms default floor.
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
