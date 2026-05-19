/// Thrown by an invite redeemer that cannot admit another client right now.
///
/// This exists so `POST /invites/redeem` can tell "we are full" apart from
/// "that code is wrong". The route's generic catch flattens every failure to
/// `403 Invite is invalid or expired`, which is actively misleading for a
/// capacity refusal: it tells a visitor their link is broken when the truth is
/// that they should try again in a few minutes.
///
/// It lives here rather than in the demo subtree so `LocalRpcServer` can catch
/// it without importing anything demo-specific — which is what keeps the demo's
/// code (and its compiled-in fixtures) out of the production server binary.
class RedeemCapacityException implements Exception {
  /// Creates the exception with a visitor-facing [message].
  const RedeemCapacityException(this.message);

  /// Shown to the caller verbatim, so keep it human and actionable.
  final String message;

  @override
  String toString() => message;
}
