import 'dart:async';

import 'package:cc_domain/features/pr_review/domain/ports/forge_cancel_token.dart';
import 'package:rhttp/rhttp.dart';

final Expando<CancelToken> _bridged = Expando<CancelToken>('forgeCancel');

/// The rhttp [CancelToken] that follows [token], or null for no cancellation.
///
/// One rhttp token per domain token (rhttp cancels every request a token was
/// handed to), created on first use and cancelled the moment [token] is. A
/// token already cancelled yields an already-cancelled rhttp token, which
/// rhttp aborts immediately.
CancelToken? rhttpCancelTokenFor(ForgeCancelToken? token) {
  if (token == null) {
    return null;
  }
  final existing = _bridged[token];
  if (existing != null) {
    return existing;
  }
  final rhttp = CancelToken();
  _bridged[token] = rhttp;
  if (token.isCancelled) {
    // Synchronously flips rhttp's state, so the request about to be made with
    // it is refused rather than started.
    unawaited(rhttp.cancel());
    return rhttp;
  }
  // Never awaited: rhttp's `cancel` completes only once a native request has
  // observed the token, which an unused token never does.
  unawaited(token.whenCancelRequested.then((_) => unawaited(rhttp.cancel())));
  return rhttp;
}
