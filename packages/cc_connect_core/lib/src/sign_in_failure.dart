import 'package:cc_connect_core/src/wire_errors.dart';

/// Why a browser sign-in failed: the closed set a server reports for an
/// attempt (`oauth.status`, `oauth.complete`) and every client renders.
/// Anything else reads as [unknown].
enum SignInFailure {
  /// The attempt ran out of time.
  expired('expired'),

  /// The person declined at the provider, or the provider refused.
  accessDenied('access_denied'),

  /// The provider granted different permissions than the lane asks for.
  scopeMismatch('scope_mismatch'),

  /// A confirmation code did not match; the attempt stays open.
  codeMismatch('code_mismatch'),

  /// Too many wrong confirmation codes; the attempt is over.
  invalidCode('invalid_code'),

  /// The attempt is no longer known (already used, replaced or forgotten).
  staleRequest('stale_request'),

  /// The server does not know this attempt (it restarted, or the attempt
  /// was evicted): start a new sign-in.
  attemptUnknown('attempt_unknown'),

  /// The request could not be read.
  invalidRequest('invalid_request'),

  /// Too many sign-ins right now.
  rateLimited('rate_limited'),

  /// The provider or Connect is not answering.
  providerUnavailable('provider_unavailable'),

  /// The provider refused to exchange the authorization code.
  exchangeFailed('exchange_failed'),

  /// The grant came back but the server could not store it.
  storeFailed('store_failed'),

  /// The server's own app for this provider is set up wrongly.
  misconfigured('misconfigured'),

  /// A previous grant is gone, or the provider refused this one; sign in
  /// again.
  needsSignIn('needs_sign_in'),

  /// The app is not installed where it is needed.
  notInstalled('not_installed'),

  /// A Slack workspace is bound to another server.
  teamBoundElsewhere('team_bound_elsewhere'),

  /// The provider account that just signed in is already linked to another
  /// Control Center user on this server; nothing was stored.
  accountAlreadyBound('account_already_bound'),

  /// Connecting a Slack workspace the first time takes one of its admins.
  notAdmin('not_admin'),

  /// The installation or account is suspended.
  suspended('suspended'),

  /// This server is not allowed on its Connect.
  installBlocked('install_blocked'),

  /// A code this client does not know.
  unknown('');

  const SignInFailure(this.wire);

  /// The wire spelling.
  final String wire;

  /// Parses a wire value; null for an empty or absent one.
  static SignInFailure? fromWire(Object? wire) {
    if (wire is! String || wire.isEmpty) {
      return null;
    }
    for (final failure in values) {
      if (failure.wire == wire) {
        return failure;
      }
    }
    return unknown;
  }

  /// The failure a Connect refusal of a sign-in means.
  static SignInFailure fromConnect(ConnectErrorCode code) => switch (code) {
    ConnectErrorCode.needsSignIn => needsSignIn,
    // A mint refusal; never answered to a sign-in.
    ConnectErrorCode.accessDenied ||
    ConnectErrorCode.needsRequester => accessDenied,
    ConnectErrorCode.codeMismatch => codeMismatch,
    ConnectErrorCode.notInstalled ||
    ConnectErrorCode.repoNotSelected => notInstalled,
    ConnectErrorCode.teamBoundElsewhere => teamBoundElsewhere,
    ConnectErrorCode.notAdmin => notAdmin,
    ConnectErrorCode.suspended => suspended,
    ConnectErrorCode.rateLimited => rateLimited,
    ConnectErrorCode.providerUnavailable => providerUnavailable,
    ConnectErrorCode.installBlocked => installBlocked,
    ConnectErrorCode.staleRequest => staleRequest,
    ConnectErrorCode.invalidRequest => invalidRequest,
  };
}
