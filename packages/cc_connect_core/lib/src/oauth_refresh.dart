/// Provider error codes on a token refresh that mean the refresh credential
/// is dead (spent, revoked, expired, or issued to another client) and the
/// person must sign in again. Any other refusal is transient: retry later,
/// keep the grant.
///
/// `invalid_grant` and `unauthorized_client` are RFC 6749 §5.2;
/// `bad_refresh_token` is GitHub's answer for a spent, revoked or expired
/// refresh token. A provider with further codes of the same meaning keeps
/// them next to its own client, in addition to these.
const Set<String> oauthRefreshRejectedErrors = {
  'invalid_grant',
  'bad_refresh_token',
  'unauthorized_client',
};
